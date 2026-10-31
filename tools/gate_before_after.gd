extends Node

## 第 3 月"先看手机"这道门槛，改前 / 改后各一张，摆一起看。
## 改前那一帧是照旧行为复现的：落点还留在上个月末的宿舍门口，线就一直拖着。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/gate_before_after.tscn

const SHOT_DIR := "res://test_artifacts/gate_before_after"
const DORM_DOOR := Vector2(955, 760)

var _town: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.6)
	_town.call("debug_jump_to_month", 3, "A")
	await _wait(2.4)
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
	await _wait(1.2)
	if not bool(_town.get("_phone_gate_waiting")):
		print("BA 门槛没等着，后面别看了")
		get_tree().quit(1)
		return
	# 改前：把落点按旧行为留在宿舍门口，线照铺
	_town.set("_month12_waypoint", DORM_DOOR)
	_town.set("_month12_guide_from", Vector2(-99999, -99999))
	_town.call("_lay_month12_guide", true)
	await _wait(0.6)
	print("BA 改前 线=", _guide_state())
	await _shot("01_改前_线还指着宿舍")
	# 改后：这一拍没有落点，旧线收掉
	_town.set("_month12_waypoint", Vector2(-99999, -99999))
	await _wait(0.6)
	print("BA 改后 线=", _guide_state())
	await _shot("02_改后_地上没有线")
	# 门槛横幅：钉住的这条，玩家不点不收
	await _wait(0.8)
	print("BA 横幅=", "在" if _town.get("_gate_banner") != null and (_town.get("_gate_banner") as Control).visible else "无")
	await _shot("03_钉住的门槛横幅")
	# 点叉应当收掉，且门槛还在（不算读过）
	var banner = _town.get("_gate_banner")
	if banner != null:
		for child in (banner as Control).get_children():
			if child is Button and (child as Button).name == "GateBannerClose":
				(child as Button).emit_signal("pressed")
	await _wait(0.4)
	print("BA 点叉之后：横幅=", "在" if _town.get("_gate_banner") != null and is_instance_valid(_town.get("_gate_banner")) else "无",
		" 门槛还在吗=", bool(_town.get("_phone_gate_waiting")), " 任务卡=", String(_town.get("_town_ui_v2").get("_task_title").text))
	await _shot("04_点叉收掉_门槛仍在")
	# 再点横幅本身（重新钉一条）应当直接打开手机
	_town.call("_show_gate_banner", "先看手机", "王哥这两条是下一屏的前提，点开看完再往下走",
		Callable(_town, "_open_ui_phone"))
	await _wait(0.6)
	await _wait(0.5)
	# 真按一下横幅正文（避开右边的叉）：该直接把收件箱打开
	var again = _town.get("_gate_banner")
	if again != null:
		var center := (again as Control).get_global_rect().get_center()
		center.x -= 120.0
		for pressed in [true, false]:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = pressed
			click.position = center
			click.global_position = center
			get_viewport().push_input(click, true)
			await _wait(0.1)
	await _wait(0.8)
	var panel = _town.get("_month_phone_panel")
	print("BA 点横幅正文之后：收件箱开=", panel != null and is_instance_valid(panel) and bool(panel.call("is_open")),
		" 横幅=", "在" if _town.get("_gate_banner") != null else "无")
	print("BA_DONE")
	get_tree().quit(0)


func _guide_state() -> String:
	var line = _town.get("_guide_line")
	if line == null or not is_instance_valid(line):
		return "无"
	var arr: PackedVector2Array = line.get("_points")
	if arr.size() == 0:
		return "没画"
	return "画了 %d 段，终点=%s" % [arr.size(), str(arr[arr.size() - 1].round())]


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("SHOT ", shot_name, " saved=", image.save_png(ProjectSettings.globalize_path(SHOT_DIR + "/" + shot_name + ".png")))
