extends Node


func _ready() -> void:
	if not ApiClient.is_live_mode() or ApiClient.pending_event_count() != 0:
		push_error("LIVE_API_HANDSHAKE_FAIL: configuration or queue")
		get_tree().quit(1)
		return
	ApiClient.start_or_resume()
	var deadline := Time.get_ticks_msec() + 8000
	while not ApiClient.is_session_confirmed() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var state := ApiClient.server_state()
	if not ApiClient.is_session_confirmed() or String(state.get("currentNodeId", "")) != "E01":
		push_error("LIVE_API_HANDSHAKE_FAIL: no authoritative initial state")
		get_tree().quit(1)
		return
	var session_id := ApiClient.current_session_id()
	ApiClient._stale_local_state = true
	if not ApiClient._live_ready() or ApiClient.current_session_id() != session_id:
		push_error("LIVE_API_HANDSHAKE_FAIL: compatible session did not recover")
		get_tree().quit(1)
		return
	ApiClient.start_or_resume()
	deadline = Time.get_ticks_msec() + 8000
	while not ApiClient.is_session_confirmed() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if not ApiClient.is_session_confirmed():
		push_error("LIVE_API_HANDSHAKE_FAIL: recovered session did not resume")
		get_tree().quit(1)
		return
	var report_error := {"text": ""}
	ApiClient.report_failed.connect(func(reason: String): report_error["text"] = reason)
	ApiClient.fetch_report()
	deadline = Time.get_ticks_msec() + 8000
	while report_error["text"] == "" and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if not String(report_error["text"]).contains("第 48 月终局"):
		push_error("LIVE_API_HANDSHAKE_FAIL: unfinished report reason missing")
		get_tree().quit(1)
		return
	print("LIVE_API_HANDSHAKE_PASS: ", ApiClient.current_session_id())
	get_tree().quit(0)
