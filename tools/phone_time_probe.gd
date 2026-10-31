extends Node

## 手机时间分隔实拍：第 2 月末那批 + 第 3 月开场那批落在同一个会话里。
## 要看到的两件事：
##   ① 每条分隔都带月份，跨月之后一眼能看出先后（不能只有"周三上午""今天 10:00"）；
##   ② 同一批的两三条只顶一个时间药丸，不一句一个。
## 用法：<godot> --path . --resolution 1600x900 res://tools/phone_time_probe.tscn
## 截图落在 %TEMP%\phone_time_shots：本机沙箱只放行工作区根与临时目录，
## res://test_artifacts 在这台机器上写不进去（不是代码问题）。

var _town: Node
var _shot_dir := ""


func _ready() -> void:
	_shot_dir = OS.get_environment("TEMP").replace("\\", "/") + "/phone_time_shots"
	DirAccess.make_dir_recursive_absolute(_shot_dir)
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.2)
	var story = _town.get("_story_event_panel")
	if story != null and bool(story.call("is_open")):
		story.call("dismiss")
	var start_card = _town.get("_month12_start_panel")
	if start_card != null and is_instance_valid(start_card):
		start_card.hide()
	await _wait(0.4)

	var m2: Dictionary = _node("M02_PHONE_2")
	var m3: Dictionary = _node("M03_PHONE_1")
	print("[TIME] M02 消息时间=", _town.call("_phone_date_text", m2),
		" / 列表=", _town.call("_phone_date_short", m2))
	print("[TIME] M03 消息时间=", _town.call("_phone_date_text", m3),
		" / 列表=", _town.call("_phone_date_short", m3))

	_town.call("_phone_thread_push", "wang_ge", "王哥", "技术导师", _messages(m2), [],
		_town.call("_phone_date_text", m2), _town.call("_phone_date_short", m2), "probe_m02")
	_town.call("_phone_thread_push", "wang_ge", "王哥", "技术导师", _messages(m3),
		(m3.get("replyOptions", []) as Array), _town.call("_phone_date_text", m3),
		_town.call("_phone_date_short", m3), "probe_m03")
	_town.set("_month_phone_messages", _messages(m3))
	_town.set("_month_phone_contact", {"id": "wang_ge", "name": "王哥", "role": "技术导师"})
	_town.set("_month_phone_date_text", _town.call("_phone_date_text", m3))
	# 背景里的日期牌也摆到第 3 月：这张会话跨了两个月，牌面停在第一月会让人以为读数又错了。
	_town.call("_write_date_plate", 3, "上旬", "白天", "morning")

	var drawer = _town.call("_ensure_month_phone_panel")
	drawer.set("_tutorial_completed", true)
	_town.call("_show_month_phone_drawer")
	await _wait(0.7)
	drawer.call("_open_conversation", "wang_ge")
	await _wait(0.6)
	await _shot("01_thread")
	print("[TIME] 聊天里的分隔=", _dividers(drawer))

	# 回一句（走玩家那条路：点回复键）：回复该跟在最后一条下面，不再顶一个新药丸。
	var reply := _find_button(drawer, "知道了，我提前到。")
	if reply != null:
		reply.pressed.emit()
	else:
		print("[TIME] 没找到回复键")
	await _wait(0.5)
	await _shot("02_thread_replied")
	print("[TIME] 回复后的分隔=", _dividers(drawer))

	drawer.call("back_to_list")
	await _wait(0.5)
	await _shot("03_list")

	# 后面的月份：小赵这条会话攒了 7 批（第 3 → 11 月）。点进去该停在最新那条，
	# 停在最上面玩家看到的是三个月前的信，会以为手机没收到新的。
	for node in _sender_nodes("xiao_zhao"):
		_town.call("_phone_thread_push", "xiao_zhao", "小赵", "邻组",
			_messages(node), (node.get("replyOptions", []) as Array),
			_town.call("_phone_date_text", node), _town.call("_phone_date_short", node),
			"probe_" + String(node.get("id", "")), _town.call("_phone_time_key", node))
	_town.call("_ensure_month_phone_panel")
	drawer.call("_open_conversation", "xiao_zhao")
	await _wait(0.6)
	var scroll = drawer.get("_scroll")
	var bar = scroll.get_v_scroll_bar()
	print("[TIME] 长会话 scroll=", scroll.scroll_vertical, " / max=", bar.max_value,
		" / 可视高=", scroll.size.y, " / 分隔=", _dividers(drawer))
	await _shot("05_long_thread")

	# 关掉再点开手机：该直接落在还没看的小赵头上（最新一条），不是停在列表。
	drawer.call("close_phone")
	await _wait(0.7)
	_town.call("_show_month_phone_drawer")
	await _wait(0.8)
	var reopened = drawer.get("_scroll")
	print("[TIME] 重开手机落在=", String(drawer.get("_active_id")),
		" / 视图=", String(drawer.get("_view")),
		" / scroll=", reopened.scroll_vertical, " / ", _dividers(drawer))
	await _shot("06_reopen")

	# 返回列表：最近有消息的排最上面。
	drawer.call("back_to_list")
	await _wait(0.5)
	print("[TIME] 列表顺序=", _list_rows(drawer))
	await _shot("07_list_sorted")

	# 首月手机交接：陈工那条的时间话该是"第 1 月 · 上旬 · 上午"，不是写死的"今天 14:20"。
	_town.call("_unlock_month_phone")
	print("[TIME] 首月交接=", _thread_times("chen_gong"))

	# 剧情里弹手机：历史按各自批次顶分隔，只有新到那条顶"刚刚"，而且只顶一个。
	drawer.call("close_phone")
	await _wait(0.6)
	_town.set("_phone_log", [
		{"speaker": "王哥", "text": "上周那两张图我看了。", "time": _town.call("_phone_date_text", m2)},
		{"speaker": "王哥", "text": "先别急着推。", "time": _town.call("_phone_date_text", m3)},
	])
	_town.call("_peek_phone_for_story", "王哥", "客户那边改到周四了。", m3)
	await _wait(0.6)
	print("[TIME] 剧情弹手机的分隔=", _dividers(drawer))
	await _shot("04_peek")

	print("PHONE_TIME_DONE ", _shot_dir)
	get_tree().quit(0)


## 从 events.json 里取某个节点：时间话只认节点自带的 month / phase / timeBand / whenText。
func _node(node_id: String) -> Dictionary:
	for month in range(1, 13):
		for value in (_town.call("_load_month_nodes", month) as Array):
			var node := Dictionary(value)
			if String(node.get("id", "")) == node_id:
				return node
	return {}


func _messages(node: Dictionary) -> Array:
	var out: Array = []
	for value in (node.get("messages", []) as Array):
		out.append({"speaker": "npc", "text": String((value as Dictionary).get("text", ""))})
	return out


## 某位同事在所有月份里的消息批次（按月份、顺序）。
func _sender_nodes(sender_id: String) -> Array:
	var out: Array = []
	for month in range(1, 13):
		for value in (_town.call("_load_month_nodes", month) as Array):
			var node := Dictionary(value)
			if String(node.get("nodeType", "")) == "phone_batch" and String(node.get("senderId", "")) == sender_id:
				out.append(node)
	return out


## 面板上真正画出来的时间药丸文字：一句一个还是几句一个，看这个。
func _dividers(drawer: Node) -> String:
	var thread = drawer.get("_thread")
	var out: Array = []
	if thread == null:
		return "（没有聊天列表）"
	for child in thread.get_children():
		# 同名的第二个节点会被 Godot 自动改名（@PanelContainer@xx），所以按前缀认。
		if not (child is Control) or not String(child.name).begins_with("TimeDivider"):
			continue
		for label in child.get_children():
			if label is Label and not (label as Label).text.is_empty():
				out.append(String((label as Label).text))
	return " | ".join(out)


## 会话里每条消息自己记的时间：交接和投递走的是这条数据，不是界面。
func _thread_times(contact_id: String) -> String:
	var thread: Dictionary = _town.call("_phone_thread", contact_id)
	var out: Array = []
	for value in (thread.get("messages", []) as Array):
		out.append(String((value as Dictionary).get("time", "")))
	return " | ".join(out)


## 会话列表从上到下的顺序（行节点名 Row_<id>），看最新那条是不是排最上面。
func _list_rows(drawer: Node) -> String:
	var box = drawer.get("_list_box")
	var out: Array = []
	if box == null:
		return "（没有列表）"
	for child in box.get_children():
		var row_name := String(child.name)
		if row_name.begins_with("Row_"):
			out.append(row_name.trim_prefix("Row_"))
	return " | ".join(out)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _find_button(root: Node, text: String) -> Button:
	for child in root.get_children():
		if child is Button and String((child as Button).text) == text:
			return child as Button
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_shot_dir, shot_name]
	print("shot ", shot_name, " -> ", image.save_png(path), " ", path)