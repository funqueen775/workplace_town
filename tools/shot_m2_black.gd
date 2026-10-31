extends Control
## 第 2 月一路走一路截图：找"第一次回去之后黑屏"到底是哪一屏、哪一层盖住的。
## 用法：<godot> --path <PROJ> --user-data-dir=<tmp> res://tools/shot_m2_black.tscn -- --dir <out>

var _dir := "user://m2black"
var _town: Node
var _panel
var _done_streak := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.4).timeout
	_panel = _town.get("_story_event_panel")
	_panel.reduced_motion = true
	if bool(_panel.call("is_open")):
		_panel.call("dismiss")
	_town.call("debug_jump_to_month", 2, "A")
	_run()


func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_dir, tag])
	var info := _layers()
	print("[shot] %s | %s" % [tag, info])


## 把每个全屏黑东西的可见性打出来：谁盖在上面一目了然。
func _layers() -> String:
	var parts: Array = []
	var root := get_tree().root
	parts.append("室内=%s" % _is_open(_town.get("_interior_preview")))
	parts.append("切场锁=%s" % bool(_town.get("_date_cutscene_lock")))
	parts.append("phase=%s" % String(_town.get("_month12_phase")))
	parts.append("屏=%s" % String((_panel.get("_event") as Dictionary).get("id", "")))
	parts.append("叠加=%s" % (_town.get("_training_overlay") != null))
	parts.append("黑块=")
	parts[-1] += str(_black_rects(root, 0))
	return " ".join(parts)


## 递归找"全屏、不透明、接近纯黑"的 ColorRect / TextureRect，以及盖着的 CanvasLayer。
func _black_rects(node: Node, depth: int) -> Array:
	var found: Array = []
	for child in node.get_children():
		var vis := true
		var n: Node = child
		while n != null:
			if n is CanvasItem and not (n as CanvasItem).visible:
				vis = false
				break
			n = n.get_parent()
		if not vis:
			continue
		if child is ColorRect:
			var cr := child as ColorRect
			var col := cr.color
			var sz := cr.size
			if col.a > 0.85 and col.r < 0.12 and col.g < 0.12 and col.b < 0.16 and sz.x > 900.0 and sz.y > 500.0:
				found.append("%s%s(a=%.2f,%.0fx%.0f)" % [
					"·".repeat(depth), String(child.name), col.a, sz.x, sz.y])
		found += _black_rects(child, depth + 1)
	return found


func _is_open(node: Node) -> bool:
	return node != null and bool(node.call("is_open"))


func _run() -> void:
	var n := 0
	for tick in 3000:
		await get_tree().create_timer(0.04).timeout
		var phase := String(_town.get("_month12_phase"))
		var start = _town.get("_month12_start_panel")
		if start != null and bool(start.call("is_open")):
			_town.call("_on_month_start_continued")
			continue
		if bool(_town.get("_hud_tour_active")):
			_town.get("_hud_tour").call("advance")
			continue
		var tutorial = _town.get("_month_phone_tutorial")
		if tutorial != null and bool(tutorial.get("_card").visible):
			tutorial.call("close_tutorial")
			continue
		var unlock = _town.get("_month12_place_panel")
		if unlock != null and bool(unlock.call("is_open")):
			unlock.call("_on_unlock_ok", "")
			continue
		var visit_id := String(_town.get("_month12_visit_id"))
		if not visit_id.is_empty():
			var door = _town.get("_story_door")
			if door != null:
				_town.get("_player").position = (door as Node2D).position
			await get_tree().create_timer(0.12).timeout
			_town.call("_begin_interaction")
			await get_tree().create_timer(0.3).timeout
			n += 1
			await _shot("%02d_进门_%s" % [n, visit_id])
			var place: Dictionary = _town.call("_month12_visit_place")
			if not place.is_empty():
				_town.call("_on_activity_selected", place)
			continue
		if phase in ["tour", "e02_walk", "node_walk", "sleep_walk"]:
			var wp: Vector2 = _town.get("_month12_waypoint")
			if wp.x > -90000.0:
				_town.get("_player").position = wp
			continue
		if bool(_panel.call("is_open")):
			var event: Dictionary = _panel.get("_event")
			var eid := String(event.get("id", ""))
			n += 1
			await _shot("%02d_屏_%s" % [n, eid])
			var stage := String(_panel.get("_stage"))
			if stage == "choices":
				_panel.call("_on_choice_picked", eid, "A", 45)
			elif stage == "interaction" or stage == "handbook":
				pass
			else:
				_panel.call("_advance")
			continue
		if phase == "handbook":
			var book = _town.get("_month12_handbook")
			if book != null and bool(book.call("is_open")):
				book.call("close")
			continue
		if phase == "activity":
			await _do_activity()
			continue
		if phase == "close":
			n += 1
			await _shot("%02d_月末卡" % n)
			_town.call("_on_month12_close_finished")
			continue
		if phase == "done":
			# 睡觉那 2.2 秒里 phase 也是 done，不能一看到就收工：连着很多帧才算真结束。
			_done_streak += 1
			if _done_streak > 120:
				break
			continue
		_done_streak = 0
	print("[done] 共 %d 张" % n)
	get_tree().quit()


func _do_activity() -> void:
	var runner = _town.get("_month_runner")
	var node: Dictionary = runner.current if runner != null else {}
	var ids: Array = node.get("activityIds", []) as Array
	var slots: int = int(_town.get("_month12_slots_left"))
	var pending: Array = []
	for value in ids:
		var aid := String(value)
		if bool(_town.call("_month12_activity_visited", aid)):
			continue
		pending.append(aid)
	if slots <= 0 or pending.is_empty():
		_town.call("_on_end_month_pressed")
		return
	_town.call("_on_month12_place_confirmed", String(pending[0]))
	await get_tree().create_timer(0.25).timeout
	var scene = _town.get("_weekend_scene_panel")
	if scene != null and bool(scene.call("is_open")):
		scene.call("_advance")
