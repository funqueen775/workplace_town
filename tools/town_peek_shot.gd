extends Node

## 拍镇子实景（默认第 5 月，可指定月份）：日期牌、立绘、HUD 都在这张图里看。
## 用法：<godot> --path <PROJ> --resolution 1920x1080 res://tools/town_peek_shot.tscn -- --month=5

const SHOT_DIR := "res://test_artifacts/town_peek"

var _town: Node


func _init() -> void:
	_log("script_loaded args=%s" % OS.get_cmdline_user_args())


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var month := 5
	for arg in OS.get_cmdline_user_args():
		if String(arg).begins_with("--month="):
			month = int(String(arg).get_slice("=", 1))
	_log("boot month=%d" % month)
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await _wait(3.6)
	_log("after_boot valid=%s" % is_instance_valid(_town))
	_town.call("debug_jump_to_month", month, "A")
	await _wait(2.6)
	_log("after_jump")
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and bool(start_panel.call("is_open")):
		_town.call("_on_month_start_continued")
		await _wait(1.4)
		_log("after_start_panel")
	await _shot("M%d_镇子" % month)
	_dump_date_plate()
	_log("done")
	get_tree().quit(0)


## 日期牌这五格到底落在哪儿：排版是自己算的，翻月过场还会 tween position，
## 光看截图猜不出来（2026-11-02 查 F9 时加的）。
func _dump_date_plate() -> void:
	var plate := _find_node_named("DatePlate", get_tree().root)
	if plate == null:
		_log("date_plate=not_found")
		return
	_log("-- as_shown --")
	_dump_cells(plate)
	if plate.has_method("relayout_date_cells"):
		plate.call("relayout_date_cells")
		_log("-- after_relayout --")
		_dump_cells(plate)
	else:
		_log("plate has no relayout; parent=" + str(plate.get_parent()))
		var up = plate.get_parent()
		var hops := 0
		while up != null and hops < 4:
			if up.has_method("relayout_date_cells"):
				up.call("relayout_date_cells")
				_log("-- after_relayout via %s --" % up)
				_dump_cells(plate)
				break
			up = up.get_parent()
			hops += 1


func _dump_cells(plate: Node) -> void:
	for child in plate.get_children():
		if child is Label:
			var label := child as Label
			_log("cell text=%s pos=%s size=%s min=%s" % [label.text, label.position, label.size, label.get_combined_minimum_size()])


func _find_node_named(target: String, node: Node) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var found := _find_node_named(target, child)
		if found != null:
			return found
	return null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("SHOT ", name, " saved=", image.save_png(ProjectSettings.globalize_path(SHOT_DIR + "/" + name + ".png")))
	_log("shot %s" % name)


## 进度写文件：stdout 被重定向时是块缓冲的，进程被强杀就什么都看不到（2026-11-02 排查用）。
func _log(message: String) -> void:
	print("PEEK " + message)
	var path := ProjectSettings.globalize_path(SHOT_DIR + "/_progress.txt")
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		print("PEEK log_failed err=", FileAccess.get_open_error(), " path=", path)
		return
	if f.get_length() > 0:
		f.seek_end()
	f.store_string(message + "\n")
	f.close()
