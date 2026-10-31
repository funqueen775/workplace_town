extends Node

## 首月回宿舍能不能走到：触发 sleep_walk 后，按游戏自己的可走判定一步步挪过去，
## 走到就说到达，走不动就报卡在哪一格、离门口多远。

var _town: Node


func _ready() -> void:
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.6).timeout
	var start_panel = _town.get("_month12_start_panel")
	if start_panel != null and is_instance_valid(start_panel) and bool(start_panel.call("is_open")):
		start_panel.emit_signal("continued")
		await get_tree().create_timer(1.2).timeout
	# 从玩家截图里那个位置起（心湖西侧），并且按真按钮，不走内部函数
	(_town.get("_player") as Node2D).position = Vector2(525, 720)
	var button = _town.get("_end_month_button")
	print("结束这个月按钮在吗：", button != null and is_instance_valid(button) and bool(button.visible))
	if button != null and is_instance_valid(button):
		button.emit_signal("pressed")
	else:
		_town.call("_on_end_month_pressed")
	await get_tree().create_timer(4.0).timeout
	var close_panel = _town.get("_month12_close_panel")
	print("月末卡开了吗：", close_panel != null and is_instance_valid(close_panel))
	if close_panel != null and is_instance_valid(close_panel):
		var root: Control = close_panel.get("_root")
		print("  卡可见：", root != null and root.visible)
		close_panel.call("close")
	_town.call("_on_month12_close_finished")
	await get_tree().create_timer(2.0).timeout
	var player: Node2D = _town.get("_player")
	var waypoint: Vector2 = _town.get("_month12_waypoint")
	print("宿舍落点=", waypoint, " 玩家=", player.position, " 相位=", String(_town.get("_month12_phase")))
	var blocked_at := Vector2.INF
	for i in 900:
		await get_tree().create_timer(0.02).timeout
		if String(_town.get("_month12_phase")) != "sleep_walk":
			print("到达/睡着：相位=", String(_town.get("_month12_phase")), " 走了 ", i, " 步")
			break
		var target: Vector2 = _town.get("_month12_waypoint")
		if target.x < -90000.0:
			print("落点被清空，相位=", String(_town.get("_month12_phase")))
			break
		if player.position.distance_to(target) <= 70.0:
			print("已在门口 70 像素内：", player.position, " 相位=", String(_town.get("_month12_phase")))
		var step := 12.0
		var dir := (target - player.position).normalized()
		var tries: Array[Vector2] = [player.position + dir * step,
			Vector2(player.position.x + dir.x * step, player.position.y),
			Vector2(player.position.x, player.position.y + dir.y * step)]
		var moved := false
		for candidate in tries:
			if bool(_town.call("_is_walkable_position", candidate)):
				player.position = candidate
				moved = true
				blocked_at = Vector2.INF
				break
		if not moved:
			if blocked_at == Vector2.INF:
				blocked_at = player.position
				print("走不动了：卡在 ", player.position, " 离门口 %.0f 像素" % player.position.distance_to(target))
			if i % 60 == 0:
				print("  仍卡着：", player.position)
	print("最后：相位=", String(_town.get("_month12_phase")), " 玩家=", player.position)
	print("SLEEP_WALK_DONE")
	get_tree().quit(0)
