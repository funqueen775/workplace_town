extends Node
## 提示条实拍：信息型纸条（_show_reminder_toast）与门槛横幅（_show_gate_banner）各一张，
## 用来核对「提示压在哪儿、有多大声」。改 11.10 的提示条位置/配色后跑一遍。
## 用法：<godot> --path <proj> res://tools/toast_shot.tscn -- --dir E:/.../toast_check
## 需要本机 API 在 8077（和其他 shot 工具一样，游戏起不来就拍不到）。

const DEFAULT_DIR := "res://test_artifacts/toast_check"

var _town: Node
var _dir := DEFAULT_DIR


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.6).timeout
	print("[toast] phase=", String(_town.get("_month12_phase")))
	# 信息型：说明一件事，说完就走，不该抢视线。
	_town.call("_show_reminder_toast", "周四下午彩排", "王哥当客户，先把那十分钟讲顺")
	await get_tree().create_timer(0.6).timeout
	await _shot("00_info_toast")
	# 动手型：钉住不收，深底金边，和上面对比。
	_town.call("_show_gate_banner", "先看一眼手机", "王哥把消息发到你手机上了", Callable(), "probe_gate")
	await get_tree().create_timer(0.6).timeout
	await _shot("01_gate_banner")
	print("TOAST_SHOTS_DONE ", ProjectSettings.globalize_path(_dir))
	get_tree().quit(0)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [_dir, name])
	print("shot %s -> %s" % [name, image.save_png(path)])