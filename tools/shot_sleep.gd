extends Control
## 月末回宿舍：先看黄线，再看进门熄灯那一下。
var _dir := "user://sleepshot"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size(): _dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	_run()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_dir, name])
	print("[shot] ", name)


func _run() -> void:
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.4).timeout
	var panel = town.get("_story_event_panel")
	panel.reduced_motion = true
	panel.call("dismiss"); panel.visible = false
	town.call("debug_jump_to_month", 3, "A")
	await get_tree().create_timer(1.4).timeout
	# 直接进"回宿舍"那一段：这一段不依赖整月跑完
	town.call("_start_sleep_walk", 3)
	await get_tree().create_timer(0.8).timeout
	var wp2: Vector2 = town.get("_month12_waypoint")
	var me: Vector2 = (town.get("_player") as Node2D).position
	print("[sleep] phase=", town.get("_month12_phase"), " 落点=", wp2, " 人=", me, " 距离=", roundi(me.distance_to(wp2)))
	await _shot("01_回宿舍_黄线")
	(town.get("_player") as Node2D).position = wp2
	await get_tree().create_timer(0.4).timeout
	if String(town.get("_month12_phase")) == "sleep_walk":
		town.call("_do_sleep")
	await get_tree().create_timer(0.45).timeout
	await _shot("02_进门_熄灯_夜景")
	await get_tree().create_timer(1.5).timeout
	await _shot("03_黑场")
	var ip = town.get("_interior_preview")
	var shade = ip.get("_shade") if ip != null else null
	print("[sleep] 熄灯后 phase=", town.get("_month12_phase"),
		" 罩子=", (shade.color if shade != null else "无"),
		" 内景开=", ip.call("is_open") if ip != null else false)
	get_tree().quit()
