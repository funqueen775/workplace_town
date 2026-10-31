extends Node
## 用真输入事件（push_input）点标题页的「开始游戏」：带 hover → 按下 → 抬起，
## 走的是和玩家鼠标一模一样的那条路。headless 下也能跑。

func _ready() -> void:
	var flow = load("res://Startup.tscn").instantiate()
	add_child(flow)
	await get_tree().create_timer(0.6).timeout
	var btn = flow.find_child("StartGame", true, false)
	if btn == null:
		print("[probe] 找不到 StartGame")
		get_tree().quit()
		return
	var vp: Viewport = flow.get_viewport()
	# push_input 吃的是视口坐标；get_global_rect 给的是画布坐标，
	# 画布开了 stretch 时两者差一个缩放（1280 窗口下是 1.5 倍）。
	var canvas_point: Vector2 = btn.get_global_rect().get_center()
	var point: Vector2 = vp.get_screen_transform() * canvas_point
	print("[probe] 视口=", vp.get_visible_rect().size, " 控件=", flow.size,
		" 按钮 global_rect=", btn.get_global_rect(),
		" 画布点=", canvas_point, " 视口点=", point)
	btn.mouse_entered.connect(func(): print("[事件] mouse_entered"))
	btn.mouse_exited.connect(func(): print("[事件] mouse_exited"))
	btn.button_down.connect(func(): print("[事件] button_down"))
	btn.button_up.connect(func(): print("[事件] button_up"))
	btn.pressed.connect(func(): print("[事件] pressed"))
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	vp.push_input(motion)
	await get_tree().process_frame
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = point
	down.global_position = point
	vp.push_input(down)
	await get_tree().process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = point
	up.global_position = point
	vp.push_input(up)
	for delay in [0.2, 0.6, 1.5, 3.0]:
		await get_tree().create_timer(delay).timeout
		print("[点后 %0.1fs] mode=%s 按钮disabled=%s" % [
			delay, flow.get("_mode"), str(btn.disabled) if is_instance_valid(btn) else "已释放"])
	get_tree().quit()