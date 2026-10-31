extends Node

## 底部圆钮的尺寸核对：手册 / 手机 / 设置，拍一排看牌面是不是一样大、
## 有没有因为月历、档案撤下而留下空位（档案入口已改到左上角岗位栏，不再占圆钮）。
## 用法：<godot> --path <proj> --resolution 1600x900 res://tools/hud_buttons_shot.tscn

const SHOT_DIR := "res://test_artifacts/hud_buttons"
const UI := preload("res://scripts/TownUiV2.gd")

const KEYS := ["_manual_button", "_phone_button", "_settings_button"]

var _done := false


func _ready() -> void:
	_watchdog()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var bg := ColorRect.new()
	bg.color = Color("8fae63")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var ui := UI.new()
	add_child(ui)
	await _wait(0.3)
	ui.call("set_phone_visible", true)
	ui.call("set_manual_visible", true)
	ui.call("set_phone_red_dot", true)
	ui.call("_layout_hud")
	await _wait(0.4)
	for key in KEYS:
		var button: Button = ui.get(key)
		var caption := String(button.get_meta("caption", ""))
		print("BTN ", key, " pos=", button.position, " size=", button.size,
			" visible=", button.visible, " text=", button.text, " caption=", caption)
	print("MONTH_BUTTON_GONE=", ui.get("_month_button"))
	await _shot("01_row")
	print("HUD_BUTTONS_DONE ", ProjectSettings.globalize_path(SHOT_DIR))
	_done = true
	get_tree().quit(0)


## 探针挂住就强制收场，别留一个死等的窗口进程。
func _watchdog() -> void:
	await get_tree().create_timer(25.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path(SHOT_DIR + "/" + shot_name + ".png")
	print("SHOT ", shot_name, " saved=", image.save_png(path))
