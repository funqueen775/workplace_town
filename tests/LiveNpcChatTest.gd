extends Node

const MAIN_SCENE := preload("res://Main.tscn")


func _ready() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.is_empty() or ApiClient.pending_event_count() != 0:
		_fail("scratch session ID missing or active queue not empty")
		return
	ApiClient._session_id = arguments[0]
	ApiClient._session_confirmed = true
	ApiClient._resume_session_id = ""
	WorldClock.reset_story()
	var town := MAIN_SCENE.instantiate()
	add_child(town)
	await get_tree().process_frame
	var phone = town.get("_town_ui_v2")
	var action_window = town.get("_action_window")
	var remaining_before: int = action_window.remaining
	town.call("_on_ui_chat_requested", "陈工")
	if phone.current_chat_id() != "chengong":
		_fail("phone chat did not open")
		return
	for label in phone.get("_root").find_children("*", "Label", true, false):
		if label.text == "说事。结论、成本、工期，挑重点。":
			_fail("fixed NPC prompt is presented as a reply")
			return
	var received := {"reply": "", "error": ""}
	ApiClient.chat_ready.connect(func(npc_id: String, reply: String):
		if npc_id == "chengong":
			received["reply"] = reply)
	ApiClient.chat_failed.connect(func(npc_id: String, reason: String):
		if npc_id == "chengong":
			received["error"] = reason)
	phone.phone_message_submitted.emit("chengong", "本月的预算和工期，我应该先汇报什么？")
	var deadline := Time.get_ticks_msec() + 25000
	while received["reply"] == "" and received["error"] == "" and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if received["reply"] == "" or ApiClient.pending_event_count() != 0:
		_fail("chat failed: %s" % received["error"])
		return
	var visible := false
	for label in phone.get("_root").find_children("*", "Label", true, false):
		if label.text.contains(received["reply"]):
			visible = true
			break
	if not visible:
		_fail("reply was not rendered in the phone")
		return
	if action_window.remaining != remaining_before:
		_fail("phone chat spent an action point")
		return
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://npc_phone_chat_test.png")
	phone.close_view()
	var interior = town.get("_interior_preview")
	interior.present({"code": "A", "name": "熊起东方总部"},
		"res://assets/场景内部图/熊起东方总部.png")
	interior.enable_exploration()
	interior.call("_talk_to_chen")
	interior.get("_message_input").text = "客户要求提前交付，我该怎么给出结论？"
	received["reply"] = ""
	received["error"] = ""
	interior.call("_send_player_message")
	deadline = Time.get_ticks_msec() + 25000
	while received["reply"] == "" and received["error"] == "" and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if received["reply"] == "" or ApiClient.pending_event_count() != 0:
		_fail("interior chat failed: %s" % received["error"])
		return
	if not received["reply"] in interior.get("_dialog_text").text:
		_fail("reply was not rendered in the interior")
		return
	if action_window.remaining != remaining_before:
		_fail("interior chat spent an action point")
		return
	if phone.is_open():
		_fail("closed phone reopened during interior chat")
		return
	var offline := {"reason": ""}
	ApiClient.chat_failed.connect(func(npc_id: String, reason: String):
		if npc_id == "chengong":
			offline["reason"] = reason)
	ApiClient._mode = "mock"
	ApiClient._session_confirmed = false
	ApiClient._pending_chats.append({"sourceId": "chengong",
		"createdAtMs": Time.get_ticks_msec() - 13000})
	ApiClient._try_send_chat()
	if offline["reason"] == "" or not ApiClient._pending_chats.is_empty():
		_fail("offline chat did not leave the pending state")
		return
	ApiClient._mode = "live"
	ApiClient._session_confirmed = true
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://npc_interior_chat_test.png")
	print("LIVE_NPC_CHAT_PASS: phone and interior replies rendered, queue drained")
	get_tree().quit(0)


func _fail(reason: String) -> void:
	push_error("LIVE_NPC_CHAT_FAIL: " + reason)
	get_tree().quit(1)
