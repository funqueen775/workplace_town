extends Node

## 手机回复区实拍：回复项 0/1/2 个时「先不回，收起手机」都在不在、点了会不会把话发出去。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/phone_decline_shot.tscn

const SHOT_DIR := "res://test_artifacts/phone_decline"
const INBOX := preload("res://scripts/v12m/PhoneInboxPanel.gd")

var _panel: CanvasLayer


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var bg := ColorRect.new()
	bg.color = Color("6f7d5a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_panel = INBOX.new()
	_panel.tutorial_only = false
	_panel.hide_own_hud = true
	_panel.contact_name = "小赵"
	_panel.contact_role = "邻组"
	_panel.thread_date = "今天 10:20"
	_panel.thread_messages = [
		{"speaker": "小赵", "text": "Demo 那天我在群里说话了，没别的意思，就是别自己扛。"},
	]
	add_child(_panel)
	await _wait(0.4)
	_panel.open_phone()
	await _wait(0.6)
	for tag in ["none", "one", "two"]:
		match tag:
			"none":
				_panel.reply_options = []
			"one":
				_panel.reply_options = [{"id": "ack_env", "text": "收到，我先装环境"}]
			"two":
				_panel.reply_options = [
					{"id": "ack_env", "text": "收到，我先装环境"},
					{"id": "ask", "text": "那我周三再对一次"},
				]
		_panel.call("_fill_thread")
		await _wait(0.3)
		var decline := _find("DeclineReplyButton")
		print("%s 回复项 %d 个 · 先不回按钮=%s · 文案=[%s]" % [
			tag, (_panel.reply_options as Array).size(), "有" if decline != null else "没有",
			"" if decline == null else decline.text])
		await _shot("01_%s" % tag)
	# 点一句真回复：屏幕上只该冒一句"已回复"，不带后面的讲道理
	_panel.reply_options = [{"id": "ack_env", "text": "收到，我先装环境"}]
	_panel.call("_fill_thread")
	await _wait(0.3)
	var reply := _find("Reply_ack_env")
	if reply != null:
		reply.pressed.emit()
		await _wait(0.4)
		await _shot("02_replied_toast")
	# 点「先不回」：不该多发一句气泡，只该把手机收起来
	_panel.reply_options = [{"id": "ack_env", "text": "收到，我先装环境"}]
	_panel.call("_fill_thread")
	await _wait(0.3)
	var before: int = (_panel.get("_thread") as Control).get_child_count()
	var decline := _find("DeclineReplyButton")
	decline.pressed.emit()
	await _wait(0.8)
	var after: int = (_panel.get("_thread") as Control).get_child_count()
	print("点先不回：气泡 %d → %d（不该变多）· 手机还开着=%s" % [before, after, _panel.is_open()])
	print("PHONE_DECLINE_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	get_tree().quit(0)


func _find(node_name: String) -> Button:
	for node in _panel.find_children("*", "Button", true, false):
		if String(node.name) == node_name:
			return node as Button
	return null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [SHOT_DIR, name])
	print("shot %s -> %s" % [name, image.save_png(path)])
