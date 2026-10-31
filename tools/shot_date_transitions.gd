extends Control

## 时间过场验图：把四档各播一遍，在动画中途与落定各截一张。
## 用法：Godot --path . res://tools/shot_date_transitions.tscn --dir <输出目录>
## 剧情面板先藏起来，截的是「玩家在镇子里走路时看到的那一屏」。

var _dir := "user://date_transitions"
var _quality := 0
var _style := 0
## 过场自己的速度旋钮（TIME_SCALE）：截图的等待点要跟着它一起挪，
## 否则放慢之后截到的还是同一瞬，看不出变化。
var _scale := 1.0
var _t0 := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
		elif args[i] == "--quality" and i + 1 < args.size():
			_quality = int(args[i + 1])
		elif args[i] == "--style" and i + 1 < args.size():
			_style = int(args[i + 1])
	DirAccess.make_dir_recursive_absolute(_dir)
	_run()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_dir, name]
	img.save_png(path)
	print("[shot] ", path)


func _on_wipe_finished(tier: String) -> void:
	if _t0 > 0:
		print("[time] %s = %.2f 秒" % [tier, (Time.get_ticks_msec() - _t0) / 1000.0])


func _wait_idle(town: Node) -> void:
	var started := _t0
	for i in 200:
		await get_tree().create_timer(0.05).timeout
		if not bool(town.call("wipe_playing")):
			return


func _run() -> void:
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.2).timeout
	# --quality 1 / 2 用来验「简洁」「关闭」两档不会卡住、字照样落位。
	# --style 0 / 1 / 2 是三套过场皮肤的样张：单层斜杠 / 多层色块暖色 / 硬边黑红。
	var wipe = town.get("_wipe")
	if wipe != null:
		wipe.quality = _quality
		wipe.style = _style
		_scale = float(wipe.get_script().get_script_constant_map().get("TIME_SCALE", 1.0))
	if _scale <= 0.0:
		_scale = 1.0
	print("[time] TIME_SCALE=", _scale)
	# 时长以过场自己收尾那一刻为准：截图存盘也要花时间，拿等待点量会虚高。
	if wipe != null:
		wipe.finished.connect(_on_wipe_finished)
	# 藏掉剧情面板与导览，只留小镇 + HUD + 过场层。
	var panel = town.get("_story_event_panel")
	if panel != null:
		# 只藏起来不算关：is_open() 还是真，派读数会被"等面板关掉"这条门禁攒住，
		# 量出来的时长就串到下一档头上。要 dismiss 掉才算玩家真的能自由走动。
		panel.call("dismiss")
		panel.visible = false
	var tour = town.get("_hud_tour")
	if tour != null:
		tour.visible = false
	# 开局那一拍已经把读数写成「第一月 · 上旬 · 白天」，先截一张基准。
	await _shot("00_banner_月初基准")

	# ① 上旬 → 中旬：跨旬大档。
	_t0 = Time.get_ticks_msec()
	town.call("push_date", 1, "mid", "morning", -1)
	await get_tree().create_timer(0.42 * _scale).timeout
	await _shot("01_跨旬_旧字甩出")
	await get_tree().create_timer(0.45 * _scale).timeout
	await _shot("02_跨旬_新字砸入")
	await _wait_idle(town)
	await _shot("03_跨旬_落定")

	# ② 中旬 → 下旬：同一档，镜像 + 更暗。
	_t0 = Time.get_ticks_msec()
	town.call("push_date", 1, "late", "morning", -1)
	await get_tree().create_timer(0.62 * _scale).timeout
	await _shot("04_下旬_镜像砸入")
	await _wait_idle(town)
	await _shot("05_下旬_落定")

	# ③ 白天 → 夜晚：只在格子里刷一道光。
	_t0 = Time.get_ticks_msec()
	town.call("push_date", 1, "late", "night", -1)
	await get_tree().create_timer(0.16 * _scale).timeout
	await _shot("06_昼夜_光带擦过")
	await _wait_idle(town)
	await get_tree().create_timer(0.7).timeout
	await _shot("07_昼夜_落定")

	# ④ 翻月：最重的一档，金色斜杠 + 整格翻页。
	_t0 = Time.get_ticks_msec()
	town.call("push_date", 2, "early", "morning", 2)
	await get_tree().create_timer(0.55 * _scale).timeout
	await _shot("08_翻月_砸入")
	await get_tree().create_timer(0.55 * _scale).timeout
	await _shot("09_翻月_三格换完")
	await _wait_idle(town)
	await _shot("10_翻月_落定")

	# 时段卡已删：上午→午后不该再冒任何东西，这里确认一下画面是干净的。
	_t0 = Time.get_ticks_msec()
	town.call("push_date", 2, "early", "afternoon", -1)
	await get_tree().create_timer(0.35 * _scale).timeout
	await _shot("11_午后_已不播")
	await _wait_idle(town)
	# 顺手验一眼设置页：「减少动态效果」已换成「过场动画」三档。
	town.get("_town_ui_v2").call("open_view", "settings")
	await get_tree().create_timer(0.4).timeout
	await _shot("12_设置_过场三档")
	print("DATE SHOTS DONE")
	get_tree().quit()
