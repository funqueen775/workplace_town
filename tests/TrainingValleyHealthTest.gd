extends Node

const TRAINING_SCENE := preload("res://training_valley/main.tscn")


func _ready() -> void:
	var training := TRAINING_SCENE.instantiate()
	add_child(training)
	await get_tree().process_frame
	training.call("_start_battle")
	await get_tree().process_frame
	var model = training.get("model")
	if model.player_hp != 10 or model.wang_hp != 10 or model.song_hp != 18:
		_fail("三人初始生命未减半")
		return
	if training.player_hp_label.text != "10 / 10" or training.wang_hp_label.text != "10 / 10" or training.song_hp_label.text != "18 / 18":
		_fail("血条数值与战斗模型不一致")
		return
	if training.player_hp_bar.max_value != 10 or training.wang_hp_bar.max_value != 10 or training.song_hp_bar.max_value != 18:
		_fail("血条上限未同步")
		return
	if not training.tutorial_text.text.contains("10点生命") or not training.tutorial_text.text.contains("18点生命"):
		_fail("教学文字仍使用旧生命值")
		return
	var screenshot_dir := OS.get_environment("TOWN_UI_SCREENSHOT_DIR")
	if not screenshot_dir.is_empty():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(screenshot_dir.path_join("training_health.png"))
	model.player_hp = 9
	model.wang_hp = 7
	var healed: Dictionary = model.use_heal("player")
	if not healed.get("used", false) or model.player_hp != 10 or model.wang_hp != 7:
		_fail("治疗没有遵守减半后的生命上限")
		return
	model.reset(42)
	if model.player_hp != 10 or model.wang_hp != 10 or model.song_hp != 18:
		_fail("重置战斗后没有恢复新的生命上限")
		return
	print("TRAINING_HEALTH_PASS player=10 wang=10 song=18")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("TRAINING_HEALTH_FAIL " + message)
	get_tree().quit(1)
