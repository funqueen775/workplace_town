extends Node

## 第 3 月"先看手机"这道门槛上，地上那条黄线到底指着哪儿。
## 玩家读到的是：任务卡说"右下角那颗"，线却还在往某个建筑拖——两边不一致就是 bug。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/phone_gate_line_probe.tscn

var _town: Node
const SHOT_DIR := "res://test_artifacts/phone_gate_line"


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.6)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	_town.call("debug_jump_to_month", 3, "A")
	await _wait(2.4)
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
		await _wait(1.2)
	_report("门槛等着时")
	await _shot("01_门槛_没有线")
	# 造一条"上一拍留下的线"：把黄线铺到宿舍门口（上个月末回宿舍就是这条），
	# 门槛还等着的时候它该被收掉，而不是继续拖在脚下。
	var line = _town.get("_guide_line")
	var player: Node = _town.get("_player")
	if line != null and player != null:
		line.call("set_path", PackedVector2Array([player.position, Vector2(955, 760)]), true)
		_town.set("_month12_guide_from", player.position)
	await _wait(0.5)
	_report("门槛还等着+拖着一条旧线")
	await _shot("02_旧线被收掉")
	# 玩家点开收件箱再看关掉，线该不该跟着变
	_town.call("_open_ui_phone")
	await _wait(0.8)
	var panel = _town.get("_month_phone_panel")
	if panel != null and is_instance_valid(panel):
		panel.emit_signal("phone_closed")
	await _wait(2.2)
	_report("读完手机之后")
	await _shot("03_读完之后线指工位")
	var banner = _town.get("_gate_banner")
	print("PROBE 读完之后横幅=", "还钉着" if (banner != null and is_instance_valid(banner)) else "已收掉")
	print("PHONE_GATE_LINE_DONE")
	get_tree().quit(0)


func _report(tag: String) -> void:
	var waypoint: Vector2 = _town.get("_month12_waypoint")
	var player: Node = _town.get("_player")
	var player_pos: Vector2 = player.position if player != null else Vector2.ZERO
	print("PROBE[%s] 门槛=%s 相位=%s 节点=%s" % [
		tag, bool(_town.get("_phone_gate_waiting")), String(_town.get("_month12_phase")), _node_id(),
	])
	print("PROBE[%s] 落点=%s 人在=%s 距离=%.0f 线=%s" % [
		tag, str(waypoint.round()), str(player_pos.round()),
		waypoint.distance_to(player_pos), _guide_state(),
	])
	var ui = _town.get("_town_ui_v2")
	if ui != null:
		print("PROBE[%s] 任务卡=%s / %s" % [
			tag, String(ui.get("_task_title").text), String(ui.get("_task_note").text),
		])


## 黄线现在画没画、终点在哪。
func _guide_state() -> String:
	var line = _town.get("_guide_line")
	if line == null or not is_instance_valid(line):
		return "无"
	var points = line.get("_points")
	if points == null:
		return "无路径字段"
	var arr := points as PackedVector2Array
	if arr.size() == 0:
		return "没画"
	return "画了 %d 段，终点=%s" % [arr.size(), str(arr[arr.size() - 1].round())]


func _node_id() -> String:
	var runner = _town.get("_month_runner")
	if runner == null or not is_instance_valid(runner):
		return "-"
	return String((runner.get("current") as Dictionary).get("id", ""))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("SHOT ", shot_name, " saved=", image.save_png(ProjectSettings.globalize_path(SHOT_DIR + "/" + shot_name + ".png")))
