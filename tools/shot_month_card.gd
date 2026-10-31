extends Control
## 月初卡：一翻月先看到什么。用法 -- --month 4 --dir E:/...
var _dir := "user://month_card"
var _month := 4


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size(): _dir = args[i + 1]
		elif args[i] == "--month" and i + 1 < args.size(): _month = int(args[i + 1])
	DirAccess.make_dir_recursive_absolute(_dir)
	_run()


func _run() -> void:
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.4).timeout
	var panel = town.get("_story_event_panel")
	panel.reduced_motion = true
	panel.call("dismiss"); panel.visible = false
	town.call("debug_jump_to_month", _month, "A")
	await get_tree().create_timer(1.6).timeout
	var card = town.get("_month12_start_panel")
	print("[card] 月=", _month, " 卡开着=", card != null and bool(card.call("is_open")),
		" 面板开着=", bool(panel.call("is_open")))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/月初卡_M%d.png" % [_dir, _month])
	print("[shot] 月初卡_M%d" % _month)
	# 点"开始这一天"：应该先给一段黄线让玩家自己走过去，而不是直接弹剧情
	town.call("_on_month_start_continued")
	await get_tree().create_timer(0.9).timeout
	var wp: Vector2 = town.get("_month12_waypoint")
	var me: Vector2 = (town.get("_player") as Node2D).position
	print("[walk] phase=", town.get("_month12_phase"), " 落点=", wp, " 人=", me,
		" 距离=", roundi(me.distance_to(wp)), " 面板开=", bool(panel.call("is_open")))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/走过去_M%d.png" % [_dir, _month])
	print("[shot] 走过去_M%d" % _month)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
