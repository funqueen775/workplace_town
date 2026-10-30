extends Node

# Frontend transport boundary for the OpenAPI contract.
#
# 两种模式（由 data/integration/api_config.json 的 mode 决定）：
#   mock —— 事件只进本地队列，一个网络包都不发。行为与接入前完全一致（默认值）。
#   live —— 队列当重传缓冲：2xx 才出队；网络错误/超时/5xx 留在队头下轮重试；
#           4xx 说明 payload 本身不合格，重试一百次也一样 → 出队并明确告警（不静默丢、
#           也不让一颗坏事件把整条队列堵死）。
#
# live 下 sessionId 必须由服务端签发：后端 POST /events 会先查会话存在性，
# 客户端自带的 uuid 会一路 404 —— 所以 start_or_resume() 会先去换一个回来。
#
# 红线：这里只做传输。不落分数、不推剧情、不解释规则 —— 权威永远在服务端。
signal session_ready(session: Dictionary)
signal session_established(session_id: String)
signal state_changed(state: Dictionary)
signal event_recorded(envelope: Dictionary, response: Dictionary)
signal chat_recorded(npc_id: String, message: String)
signal chat_ready(npc_id: String, reply: String)
signal chat_failed(npc_id: String, reason: String)
signal transport_warning(message: String)
signal report_ready(report: Dictionary)   # GET /report 的成功回包（整份三层报告）
signal report_failed(reason: String)      # 拉不到报告的原因（mock 未接 / 404 未生成 / 网络错）
signal assessment_ready(result: Dictionary)
signal assessment_failed(reason: String)

const CONFIG_PATH := "res://data/integration/api_config.json"
const QUEUE_PATH := "user://workplace_town_api_queue.json"
const SESSION_PATH := "user://workplace_town_api_session.json"
# 被后端拒收（4xx）的事件在这里留底，一行一条 JSONL —— 出队是为了不堵队列，
# 但玩家的选择不能真丢，事后可以从这个文件回捞。
const REJECTED_PATH := "user://workplace_town_api_rejected.jsonl"

const API_PREFIX := "/api/v1"
const CLIENT_CONTENT_VERSION := "v1.2"
const FLUSH_INTERVAL := 2.0            # 重传轮询间隔（秒）
const REQUEST_TIMEOUT := 8.0           # 单次请求超时（秒）
const CHAT_WAIT_TIMEOUT_MS := 60000
const CHAT_QUEUE_GRACE_MS := 2000

var _mode := "mock"
var _base_url := ""
var _content_version := "v1.2"
var _session_id := ""
var _session_token := ""
var _queue: Array = []
## 服务端最近一次下发的会话状态。**职级与处境的唯一权威来源**（2026-09-17 拍板）：
## Godot 只负责显示，本地不算也不镜像一份，否则同一个东西会有两份会漂移的真相。
## 没接到之前留空 —— 消费方按「还不知道」降级，绝不本地估算一个看起来像的值。
var _server_state: Dictionary = {}

var _http: HTTPRequest
var _chat_http: HTTPRequest
var _pending_chats: Array[Dictionary] = []
var _chat_in_flight := false
var _flush_timer: Timer
var _in_flight := false          # HTTPRequest 同一时刻只允许一个请求在飞，重复 request() 返回 ERR_BUSY
var _in_flight_kind := ""        # "session" / "event"
var _session_confirmed := false  # 服务端是否签发过当前 sessionId
var _resume_session_id := ""
var _session_unavailable := false
var _session_retry_at_ms := 0
var _last_warning := ""          # 连续相同的告警只报一次，别每 2 秒刷屏
var _pending_assessment_month := 0
var _stale_local_state := false
var _report_pending := false

func _ready() -> void:
	_load_config()
	_load_local_state()
	if _stale_local_state:
		_warn("发现旧剧情版本的本地会话或事件队列，已暂停发送。请先备份并迁移 user:// 的 API 状态文件。")
	# HTTPRequest 是节点，必须挂在树上才会转发信号。
	_http = HTTPRequest.new()
	_http.name = "Http"
	_http.timeout = REQUEST_TIMEOUT
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_chat_http = HTTPRequest.new()
	_chat_http.name = "NpcChatHttp"
	_chat_http.timeout = 20.0
	add_child(_chat_http)
	_chat_http.request_completed.connect(_on_chat_completed)
	# 重传轮询：什么模式都挂着，非 live 时 _flush_next 第一行就返回。
	_flush_timer = Timer.new()
	_flush_timer.name = "FlushTimer"
	_flush_timer.wait_time = FLUSH_INTERVAL
	_flush_timer.autostart = true
	add_child(_flush_timer)
	_flush_timer.timeout.connect(_flush_next)
	_flush_timer.timeout.connect(_try_send_chat)

func start_or_resume() -> Dictionary:
	if _live_ready():
		if not _session_confirmed:
			_ensure_session()
	elif _session_id.is_empty():
		# mock：保持接入前的行为，本地自己生成 id。
		_session_id = _uuid_v4()
		_save_session()
	# 有服务端状态就用它，没有才退回本地占位形状（首次握手是异步的，
	# 第一次调用拿不到很正常；session_established 之后自然就接上了）。
	var initial: Dictionary = {"chapterId":"M1", "currentNodeId":"M1-E01", "unlockedRegionIds":["A", "H"]}
	var session := {
		"sessionId": _session_id,
		"contentVersion": _content_version,
		"state": _server_state.duplicate(true) if not _server_state.is_empty() else initial,
	}
	session_ready.emit(session)
	return session


## 服务端下发的最新会话状态（只读副本）。空字典 = 还没接到服务端任何回包，
## 或者当前是 mock 模式 —— 调用方要按「还不知道」处理，不要编。
func server_state() -> Dictionary:
	return _server_state.duplicate(true)


## 每次拿到服务端回包都刷新权威状态。302 重定向之外的所有成功响应都带 state。
func _absorb_state(response: Dictionary) -> void:
	var state = response.get("state", {})
	if state is Dictionary and not (state as Dictionary).is_empty():
		_server_state = (state as Dictionary).duplicate(true)
		state_changed.emit(_server_state.duplicate(true))
	var sid := String(response.get("sessionId", ""))
	if not sid.is_empty():
		_session_id = sid

## 连接状态：会话是否已被服务端签发过。UI 拿它显示「已连接/未连接」，
## 探针拿它判断还需不需要等 session_established —— 那个信号每个会话只会发一次。
func is_session_confirmed() -> bool:
	return _session_confirmed

func has_session_issue() -> bool:
	return _session_unavailable

func _mark_session_unavailable() -> void:
	_session_confirmed = false
	_session_unavailable = true
	_server_state.clear()
	state_changed.emit({})
	_warn("后端会话已失效，旧事件已停止发送；请先核对存档，不能自动新建并重放。")

func _auth_headers(headers: PackedStringArray) -> PackedStringArray:
	if not _session_token.is_empty():
		headers.append("Authorization: Bearer %s" % _session_token)
	return headers

## 当前会话 id。未确认时是本地占位值（服务端不认），确认后是服务端签发的权威 id。
func current_session_id() -> String:
	return _session_id

## 契约硬要求：每个事件的 payload.regionId 必须是 A–H 单字母，缺了或错了会被服务端 400 拒收
## （server.py post_event）。与其让每个埋点各自兜底 —— FreeTimePanel 有、WorkplaceTown 好几处
## 没有，漏一个就静默丢一批事件 —— 统一在传输层补齐：先认 regionId，再从 zone / locationId
## 这类同义字段推断，都落空才退回总部 "A"。宁可标成总部，也不要发空串让整条事件被隔离。
## 2026-09-18：隔离日志里 112 条事件正是这么丢的（node_enter 传空串、explore_click 缺字段）。
static func normalize_region_id(payload: Dictionary) -> String:
	for key in ["regionId", "zone", "locationId", "region", "zoneId"]:
		var raw := String(payload.get(key, "")).strip_edges()
		if raw.is_empty():
			continue
		var code := raw.split("_")[0].to_upper()
		if code.length() == 1 and "ABCDEFGH".contains(code):
			return code
	return "A"

func record_event(event_type: String, payload: Dictionary, duration_seconds := 0) -> Dictionary:
	var session := start_or_resume()
	var safe_payload: Dictionary = payload.duplicate(true)
	safe_payload["regionId"] = normalize_region_id(safe_payload)
	var envelope := {
		"eventId": _uuid_v4(),
		"eventType": event_type,
		"contentVersion": _content_version,
		"clientTime": _iso_time(),
		"durationSeconds": maxi(0, duration_seconds),
		"payload": safe_payload,
	}
	_queue.append(envelope)
	_save_queue()
	# 返回值只镜像契约的传输形状，供调用方做本地反馈（调用方一律忽略它）。
	# 真正的 accepted / state 以服务端响应为准，走 event_recorded 信号回来。
	var response := {"eventId": envelope["eventId"], "accepted": true, "duplicate": false, "state": session["state"]}
	event_recorded.emit(envelope, response)
	if _mode == "live" and not _live_ready():
		_warn("未发送到后端：剧情版本或服务地址尚未填好，事件已安全保存在本地队列。")
	elif _live_ready():
		_flush_next()
	return response

func record_npc_chat(npc_id: String, message: String, region_id: String) -> String:
	var canonical_id: String = String({
		"wange": "wang_ge", "chengong": "chen_gong",
		"xiaolin": "xiao_lin", "laozhou": "lao_zhou",
	}.get(npc_id, npc_id))
	var transcript := message.strip_edges().substr(0, 500)
	var response := record_event("npc_dialogue_complete", {
		"regionId": region_id, "npcId": canonical_id,
		"message": transcript, "messageLength": transcript.length(),
		"month": int(WorldClock.snapshot().get("month", 1)),
	})
	chat_recorded.emit(npc_id, message)
	return String(response.get("eventId", ""))

func request_npc_chat(npc_id: String, message: String, region_id: String) -> void:
	var transcript := message.strip_edges().substr(0, 500)
	if transcript.is_empty():
		return
	if not _live_ready():
		chat_failed.emit(npc_id, _live_block_reason())
		return
	start_or_resume()
	var event_id := _uuid_v4()
	chat_recorded.emit(npc_id, transcript)
	_pending_chats.append({
		"npcId": String({"wange":"wang_ge", "chengong":"chen_gong",
			"xiaolin":"xiao_lin", "laozhou":"lao_zhou"}.get(npc_id, npc_id)),
		"sourceId": npc_id, "text": transcript, "regionId": region_id, "eventId": event_id,
		"clientTime": _iso_time(), "createdAtMs": Time.get_ticks_msec(),
	})
	if not _session_confirmed:
		_ensure_session()
	_try_send_chat()

func _try_send_chat() -> void:
	if _chat_in_flight or _pending_chats.is_empty():
		return
	var chat: Dictionary = _pending_chats[0]
	if _session_unavailable:
		_pending_chats.pop_front()
		chat_failed.emit(String(chat["sourceId"]), "后端会话已失效，请检查存档后重新开始")
		return
	if not _session_confirmed:
		if _session_retry_at_ms > Time.get_ticks_msec():
			_pending_chats.pop_front()
			chat_failed.emit(String(chat["sourceId"]), "新会话请求过于频繁，请稍后重试")
			return
		if Time.get_ticks_msec() - int(chat["createdAtMs"]) >= CHAT_WAIT_TIMEOUT_MS:
			_pending_chats.pop_front()
			chat_failed.emit(String(chat["sourceId"]), "后端连接超时，请检查网络后重试")
		return
	if not _queue.is_empty() and Time.get_ticks_msec() - int(chat["createdAtMs"]) < CHAT_QUEUE_GRACE_MS:
		return
	_chat_in_flight = true
	var url := "%s%s/sessions/%s/npcs/%s/chat" % [
		_base_url, API_PREFIX, _session_id, chat["npcId"]]
	var body := {"eventId": chat["eventId"], "contentVersion": _content_version,
		"clientTime": chat["clientTime"], "text": chat["text"], "regionId": chat["regionId"]}
	var err := _chat_http.request(url, _auth_headers(PackedStringArray(["Content-Type: application/json"])),
		HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_chat_in_flight = false
		chat_failed.emit(String(chat["sourceId"]), "聊天请求未能发出")
		_pending_chats.pop_front()

func _on_chat_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_chat_in_flight = false
	if _pending_chats.is_empty():
		return
	var chat: Dictionary = _pending_chats.pop_front()
	var response = JSON.parse_string(body.get_string_from_utf8())
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and response is Dictionary \
			and not String(response.get("reply", "")).is_empty():
		chat_ready.emit(String(chat["sourceId"]), String(response["reply"]))
	else:
		chat_failed.emit(String(chat["sourceId"]), "暂时无法取得回复（%d）" % code)
	_try_send_chat()

func pending_event_count() -> int:
	return _queue.size()

func is_live_mode() -> bool:
	return _mode == "live"

func request_assessment(month: int) -> void:
	if not _live_ready():
		assessment_failed.emit("尚未连接后端，无法确认晋升结果。")
		return
	_pending_assessment_month = month
	_flush_next()


## 请求生成报告，再读取报告；服务端负责校验终局是否完成。
## 沿用同一个 HTTPRequest 串行骨架（kind="report"），不开第二套传输。
## 红线：报告只在服务端算 —— mock 模式下这里就是拿不到报告，如实说，不做本地兜底计算
## （scoring_cards 不得下发前端，本地没有可算的数据）。
func fetch_report() -> void:
	if not _live_ready():
		report_failed.emit("报告暂时无法读取：%s" % _live_block_reason())
		return
	if _in_flight:
		if _in_flight_kind != "report" and _in_flight_kind != "report_generate":
			_report_pending = true
		return
	if not _queue.is_empty():
		_report_pending = true
		_flush_next()
		return
	if not _session_confirmed:
		_report_pending = true
		_ensure_session()
		return
	_report_pending = false
	_in_flight = true
	_in_flight_kind = "report_generate"
	var err := _http.request(
		"%s%s/sessions/%s/report" % [_base_url, API_PREFIX, _session_id],
		_auth_headers(PackedStringArray()), HTTPClient.METHOD_POST)
	if err != OK:
		_in_flight = false
		_in_flight_kind = ""
		report_failed.emit("请求未能发出（错误码 %d）。" % err)

## live 是否真的可以发包：mode=live + 地址合规 + 版本等于后端认的那个。
func _live_ready() -> bool:
	_refresh_stale_state()
	return _mode == "live" and not _base_url.is_empty() \
		and not _base_url.contains("example.com") \
		and _content_version == CLIENT_CONTENT_VERSION and not _stale_local_state \
		and not _session_unavailable

func _refresh_stale_state() -> void:
	if not _stale_local_state or not FileAccess.file_exists(SESSION_PATH):
		return
	if _queue.any(func(item): return not (item is Dictionary) or String(item.get("contentVersion", "")) != _content_version):
		return
	var saved = JSON.parse_string(FileAccess.get_file_as_string(SESSION_PATH))
	if not (saved is Dictionary) or String(saved.get("contentVersion", "")) != _content_version:
		return
	var saved_id := String(saved.get("sessionId", ""))
	if saved_id.is_empty() or (not _session_id.is_empty() and _session_id != saved_id):
		return
	if FileAccess.file_exists(QUEUE_PATH):
		var disk_queue = JSON.parse_string(FileAccess.get_file_as_string(QUEUE_PATH))
		if not (disk_queue is Array) or disk_queue != _queue:
			return
	_session_id = saved_id
	_session_token = String(saved.get("sessionToken", ""))
	_resume_session_id = saved_id if bool(saved.get("confirmed", false)) else ""
	_session_confirmed = false
	_server_state.clear()
	_stale_local_state = false

func _live_block_reason() -> String:
	if _mode != "live":
		return "当前模式是 %s，不会请求服务端。" % _mode
	if _base_url.is_empty():
		return "没有配置后端地址。"
	if _content_version != CLIENT_CONTENT_VERSION:
		return "剧情版本不一致（客户端 %s，要求 %s）。" % [_content_version, CLIENT_CONTENT_VERSION]
	if _stale_local_state:
		return "本地会话或事件队列属于旧剧情版本，请先迁移存档。"
	if _session_unavailable:
		return "本地会话已失效，请重新开始或恢复有效存档。"
	return "后端连接尚未完成。"

## 串行发送队头事件。HTTPRequest 一次只能有一个请求在飞，所以必须一个一个来。
func _flush_next() -> void:
	if not _live_ready() or _in_flight:
		return
	if not _session_confirmed:
		_ensure_session()
		return
	if _queue.is_empty():
		if _pending_assessment_month > 0:
			_send_assessment()
		elif _report_pending:
			fetch_report()
		return
	var envelope: Dictionary = _queue[0]
	_in_flight = true
	_in_flight_kind = "event"
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Idempotency-Key: %s" % String(envelope.get("eventId", "")),
	])
	var err := _http.request(
		"%s%s/sessions/%s/events" % [_base_url, API_PREFIX, _session_id],
		_auth_headers(headers), HTTPClient.METHOD_POST, JSON.stringify(envelope))
	if err != OK:
		_in_flight = false
		_in_flight_kind = ""
		_warn("请求未能发出（错误码 %d），事件留在本地队列等待重试。" % err)

func _send_assessment() -> void:
	_in_flight = true
	_in_flight_kind = "assessment"
	var err := _http.request(
		"%s%s/sessions/%s/assessments/%d" % [
			_base_url, API_PREFIX, _session_id, _pending_assessment_month],
		_auth_headers(PackedStringArray()), HTTPClient.METHOD_POST)
	if err != OK:
		_in_flight = false
		_in_flight_kind = ""
		assessment_failed.emit("晋升请求未能发出（错误码 %d）。" % err)

## 向服务端要一个权威 sessionId。失败不阻塞游戏，下一轮继续试。
func _ensure_session() -> void:
	if _in_flight or not _live_ready() or Time.get_ticks_msec() < _session_retry_at_ms:
		return
	_in_flight = true
	_in_flight_kind = "session"
	var body := {"contentVersion": _content_version}
	if not _resume_session_id.is_empty():
		body["resumeSessionId"] = _resume_session_id
		if not _session_token.is_empty():
			body["sessionToken"] = _session_token
	var err := _http.request(
		_base_url + API_PREFIX + "/sessions",
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		JSON.stringify(body))
	if err != OK:
		_in_flight = false
		_in_flight_kind = ""
		_warn("建会话请求未能发出（错误码 %d），稍后重试。" % err)

func _on_request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var kind := _in_flight_kind
	_in_flight = false
	_in_flight_kind = ""
	var ok := result == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 300

	if kind == "session":
		if ok:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary and parsed.has("sessionId"):
				_absorb_state(parsed)
				_session_id = String(parsed["sessionId"])
				_session_token = String(parsed.get("sessionToken", _session_token))
				_session_confirmed = true
				_resume_session_id = ""
				_save_session()
				_last_warning = ""
				session_established.emit(_session_id)
				_flush_next()
				_try_send_chat()
			else:
				_warn("后端建会话返回里没有 sessionId，事件继续留在本地队列。")
				if _pending_assessment_month > 0:
					assessment_failed.emit("后端会话响应无效，晋升结果尚未确认。")
		else:
			if code in [403, 404] and not _resume_session_id.is_empty():
				# 公网试玩的旧浏览器存档可能只保存了已失效的 token。
				# 没有待同步事件时可以安全开新会话；有事件时必须停下，避免
				# 把旧会话的选择重放到另一条剧情线上。
				if _queue.is_empty():
					_session_id = ""
					_session_token = ""
					_resume_session_id = ""
					_session_confirmed = false
					_session_unavailable = false
					_save_session()
					_ensure_session()
				else:
					_mark_session_unavailable()
					if _pending_assessment_month > 0:
						assessment_failed.emit("保存的后端会话已失效，晋升结果尚未确认。")
				_try_send_chat()
				if _report_pending:
					_report_pending = false
					report_failed.emit("后端会话已失效，请核对存档。")
			elif code == 429:
				_session_retry_at_ms = Time.get_ticks_msec() + 60000
				_warn("后端限制了短时间内的新会话数量，请稍后重试。")
				if _pending_assessment_month > 0:
					assessment_failed.emit("后端暂时限制了新会话请求，晋升结果尚未确认。")
				while not _pending_chats.is_empty():
					var pending: Dictionary = _pending_chats.pop_front()
					chat_failed.emit(String(pending["sourceId"]), "新会话请求过于频繁，请稍后重试")
			else:
				_warn("后端未接受建会话（code=%d），事件继续留在本地队列。" % code)
				if _pending_assessment_month > 0:
					assessment_failed.emit("后端连接失败（网络结果 %d，HTTP %d），晋升结果尚未确认。" % [result, code])
				if _report_pending:
					_report_pending = false
					report_failed.emit("后端会话暂时无法确认（code=%d），请检查服务后重试。" % code)
		return

	if kind == "report":
		# Batch 3：报告是只读拉取，成败都直接回信号，不碰事件队列。
		if ok:
			var report = JSON.parse_string(body.get_string_from_utf8())
			if report is Dictionary and (report as Dictionary).has("layers"):
				_last_warning = ""
				report_ready.emit(report)
			else:
				report_failed.emit("报告响应形状不对（缺 layers），请联系排查。")
		elif code == 404:
			report_failed.emit("服务端还没有这份报告，请重新请求生成。")
		else:
			report_failed.emit("拉取报告失败（code=%d）。" % code)
		return

	if kind == "report_generate":
		if not ok:
			if code == 404:
				_mark_session_unavailable()
				report_failed.emit("后端会话已失效，请先核对存档。")
				return
			if code == 409:
				var month := int(_server_state.get("currentMonth", 0))
				var decisions := int((_server_state.get("scoreSummary", {}) as Dictionary).get("decisions", 0))
				report_failed.emit("后端记录到第 %d 月、%d 次选择；完成第 48 月终局并等待同步后才能生成报告。" % [month, decisions])
			else:
				report_failed.emit("报告尚未就绪：%s" % _brief_error(body))
			return
		var status = JSON.parse_string(body.get_string_from_utf8())
		if not (status is Dictionary) or String(status.get("status", "")) != "ready":
			report_failed.emit("报告尚未生成，请稍后重试。")
			return
		_in_flight = true
		_in_flight_kind = "report"
		var err := _http.request(
			"%s%s/sessions/%s/report" % [_base_url, API_PREFIX, _session_id],
			_auth_headers(PackedStringArray()), HTTPClient.METHOD_GET)
		if err != OK:
			_in_flight = false
			_in_flight_kind = ""
			report_failed.emit("报告读取请求未能发出（错误码 %d）。" % err)
		return

	if kind == "assessment":
		if ok:
			var result_body = JSON.parse_string(body.get_string_from_utf8())
			if result_body is Dictionary and int(result_body.get("month", 0)) == _pending_assessment_month:
				_pending_assessment_month = 0
				_absorb_state(result_body)
				assessment_ready.emit(result_body)
			else:
				assessment_failed.emit("晋升结果格式不正确。")
		elif code >= 400 and code < 500:
			_pending_assessment_month = 0
			assessment_failed.emit("晋升结算被拒绝：%s" % _brief_error(body))
		else:
			assessment_failed.emit("晋升结算暂时失败，将自动重试。")
		return

	if kind != "event":
		return

	if ok:
		var sent: Dictionary = _queue.pop_front() if not _queue.is_empty() else {}
		_save_queue()
		_last_warning = ""
		var parsed_body = JSON.parse_string(body.get_string_from_utf8())
		if parsed_body is Dictionary:
			# 服务端算完会回权威 state（职级 / 处境跟着这一跳更新）
			_absorb_state(parsed_body)
			event_recorded.emit(sent, parsed_body)
			_flush_next()          # 队列还有就接着发
			_try_send_chat()
		return

	if code >= 400 and code < 500:
		# payload 或状态不合格 —— 重试一百次结果一样。出队，但不真丢：
		# 先落一份隔离日志，再说清楚是哪个事件被拒、为什么。
		# 否则一颗坏事件会把整条队列永久堵死，后面所有事件跟着积压。
		var bad: Dictionary = _queue.pop_front() if not _queue.is_empty() else {}
		_save_queue()
		_quarantine(bad, code, body)
		_warn("后端拒收事件「%s」（code=%d）已移出队列并留底隔离日志：%s"
			% [String(bad.get("eventType", "")), code, _brief_error(body)])
		if code == 404:
			_mark_session_unavailable()
		_flush_next()
		return

	_warn("发送失败（code=%d, result=%d），事件留在本地队列等待重试。" % [code, result])
	if _report_pending:
		_report_pending = false
		report_failed.emit("还有事件未同步到后端，网络恢复后请重新拉取报告。")

func _warn(message: String) -> void:
	if message == _last_warning:
		return
	_last_warning = message
	transport_warning.emit(message)

## 被拒事件留底（JSONL 追加）。写不进去也不能影响主流程 —— 传输层不阻塞游戏。
func _quarantine(envelope: Dictionary, code: int, body: PackedByteArray) -> void:
	var record := {
		"ts": _iso_time(), "code": code, "error": _brief_error(body), "envelope": envelope,
	}
	var file: FileAccess = null
	if FileAccess.file_exists(REJECTED_PATH):
		file = FileAccess.open(REJECTED_PATH, FileAccess.READ_WRITE)
		if file != null:
			file.seek_end()
	else:
		file = FileAccess.open(REJECTED_PATH, FileAccess.WRITE)
	if file != null:
		file.store_line(JSON.stringify(record))
		file.close()

func _brief_error(body: PackedByteArray) -> String:
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Dictionary and parsed.has("error"):
		return String(parsed["error"])
	var raw := body.get_string_from_utf8()
	return raw.substr(0, 120) if not raw.is_empty() else "（无响应体）"

func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var config = JSON.parse_string(file.get_as_text())
	if config is Dictionary:
		_mode = String(config.get("mode", _mode))
		_base_url = String(config.get("baseUrl", _base_url)).rstrip("/")
		_content_version = String(config.get("contentVersion", _content_version))
	if OS.has_feature("web"):
		var browser_origin = JavaScriptBridge.eval("window.location.origin")
		if browser_origin is String and (browser_origin.begins_with("http://") or browser_origin.begins_with("https://")):
			_base_url = browser_origin.rstrip("/")

func _load_local_state() -> void:
	if FileAccess.file_exists(SESSION_PATH):
		var session_file := FileAccess.open(SESSION_PATH, FileAccess.READ)
		var session = JSON.parse_string(session_file.get_as_text())
		if session is Dictionary:
			if String(session.get("contentVersion", "")) != _content_version:
				_stale_local_state = true
			else:
				_session_id = String(session.get("sessionId", ""))
				_session_token = String(session.get("sessionToken", ""))
				if _mode == "live" and bool(session.get("confirmed", false)):
					_resume_session_id = _session_id
				else:
					_session_confirmed = bool(session.get("confirmed", false)) and _mode != "live"
	if FileAccess.file_exists(QUEUE_PATH):
		var queue_file := FileAccess.open(QUEUE_PATH, FileAccess.READ)
		var saved_queue = JSON.parse_string(queue_file.get_as_text())
		if saved_queue is Array:
			_queue = saved_queue
			if _queue.any(func(item): return not (item is Dictionary) or String(item.get("contentVersion", "")) != _content_version):
				_stale_local_state = true

func _save_session() -> void:
	var file := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({
			"sessionId": _session_id,
			"sessionToken": _session_token,
			"contentVersion": _content_version,
			"confirmed": _session_confirmed,
		}))

func _save_queue() -> void:
	var file := FileAccess.open(QUEUE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_queue))

func _iso_time() -> String:
	var value := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02dT%02d:%02d:%02d+08:00" % [value.year, value.month, value.day, value.hour, value.minute, value.second]

func _uuid_v4() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var hex := ""
	for index in 32:
		hex += "%x" % rng.randi_range(0, 15)
	return "%s-%s-4%s-%s%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(13, 3), "89ab"[rng.randi_range(0, 3)], hex.substr(17, 3), hex.substr(20, 12)]
