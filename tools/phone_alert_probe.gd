extends Node

## 手机那颗的提醒规则实拍：有没看的消息才红点+呼吸，点开/回完就该收掉。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/phone_alert_probe.tscn

var _town: Node
var _ui: Node


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.0)
	_ui = _town.get("_town_ui_v2")
	var panel = _town.get("_story_event_panel")
	if panel != null and bool(panel.call("is_open")):
		panel.call("dismiss")
	await _wait(0.4)
	# 1) 新消息到：该有红点 + 呼吸
	_town.call("_unlock_month_phone")
	_town.call("_reveal_month_phone_button")
	await _wait(0.5)
	print("有新消息 → ", _state())
	# 2) 点开收件箱（先把讲解卡那一步过掉）：两样都该收掉
	_town.call("_show_month_phone_drawer")
	await _wait(0.4)
	var drawer = _town.get("_month_phone_panel")
	if drawer == null:
		print("   抽屉没建出来，测不了")
	else:
		drawer.set("_tutorial_completed", true)
		_town.call("_show_month_phone_drawer")
		await _wait(0.8)
		print("点开看完 → ", _state())
	# 3) 回一句：仍然不该呼吸
	_town.call("_on_month_phone_reply_sent", "ack_env", "收到，我先装环境")
	await _wait(0.5)
	print("回完消息 → ", _state())
	await _shot("phone_alert_after_reply")
	# 4) 新批次再来：又该亮
	_town.set("_month_phone_unread", true)
	_town.call("_sync_phone_alert")
	await _wait(0.5)
	print("又来新消息 → ", _state())
	# 5) 玩家直接点 HUD 那颗（游戏里的正路）：也该收掉
	_town.set("_month_phone_unread", true)
	_town.call("_sync_phone_alert")
	_town.call("_open_ui_phone")
	await _wait(0.8)
	print("直接点手机图标 → ", _state())
	print("PHONE_ALERT_DONE")
	get_tree().quit(0)


func _state() -> String:
	var dot = _ui.get("_phone_dot")
	var attention = _ui.get("_phone_attention")
	return "红点=%s 呼吸=%s" % [
		"无" if dot == null else str((dot as Control).visible),
		"无" if attention == null else "有",
	]


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://test_artifacts/phone_alert/%s.png" % name)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test_artifacts/phone_alert"))
	print("shot %s -> %s" % [name, image.save_png(path)])
