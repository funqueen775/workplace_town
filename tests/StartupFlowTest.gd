extends Node

const STARTUP_SCENE := preload("res://Startup.tscn")

func _ready() -> void:
	var startup := STARTUP_SCENE.instantiate()
	add_child(startup)
	await get_tree().process_frame
	await get_tree().process_frame
	var comic := startup.get_node_or_null("OpeningComic")
	if comic == null:
		_fail("开场漫画没有正确显示")
		return
	comic.call("skip")
	await get_tree().process_frame
	if not _has_text(comic, "点击继续"):
		_fail("漫画结束后没有等待用户继续")
		return
	comic.call("_continue_to_login")
	await get_tree().process_frame
	if not _has_text(startup, "正在加载"):
		_fail("漫画结束后没有显示加载过渡")
		return
	await get_tree().create_timer(1.3).timeout
	await get_tree().process_frame
	var home := startup.get_node_or_null("HomeCanvas") as Control
	if home == null or not _home_button_ready(home, "StartGame") or not _home_button_ready(home, "Settings") or not _home_button_ready(home, "ExitGame") or not _home_button_ready(home, "MyReport"):
		_fail("新首页的背景或按钮没有正确显示")
		return
	var start_button := home.get_node("StartGame") as TextureButton
	start_button.mouse_entered.emit()
	await get_tree().create_timer(0.20).timeout
	if start_button.scale.x < 1.02 or start_button.position.y >= 481:
		_fail("首页按钮悬停动效没有生效")
		return
	start_button.button_down.emit()
	await get_tree().create_timer(0.09).timeout
	if start_button.scale.x > 0.99:
		_fail("首页按钮按下反馈没有生效")
		return
	start_button.mouse_exited.emit()
	await get_tree().create_timer(0.20).timeout
	if absf(start_button.scale.x - 1.0) > 0.01:
		_fail("鼠标离开后按钮没有恢复")
		return
	(home.get_node("Settings") as TextureButton).pressed.emit()
	await get_tree().create_timer(0.15).timeout
	var settings := startup.get_node_or_null("SettingsPanel")
	if settings == null or not settings.call("is_open"):
		_fail("首页设置按钮没有打开设置弹窗")
		return
	settings.call("close")
	(home.get_node("StartGame") as TextureButton).pressed.emit()
	await get_tree().create_timer(0.15).timeout
	if not _has_text(startup, "认识职场小镇") or not _has_text(startup, "小镇介绍"):
		_fail("小镇导览首页没有正确显示")
		return
	startup.call("_go_page", 1)
	await get_tree().process_frame
	if not _has_text(startup, "人物名单") or not _has_text(startup, "陈工"):
		_fail("人物名单页没有正确显示")
		return
	var chen_avatar := load("res://assets/ui/rework_v1/profile/components/03_人际关系/小赵头像.png") as Texture2D
	if not _has_texture(startup, chen_avatar):
		_fail("陈工没有使用奶白西装熊头像")
		return
	startup.call("_go_page", 2)
	await get_tree().process_frame
	if not _has_text(startup, "39") or not _has_text(startup, "12") or not _has_text_containing(startup, "24 次自由活动窗口"):
		_fail("旅程页的主线和自由活动数量未与 V1.2 配置一致")
		return
	var screenshot_dir := OS.get_environment("TOWN_UI_SCREENSHOT_DIR")
	if not screenshot_dir.is_empty() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(screenshot_dir.path_join("startup_journey.png"))
	print("STARTUP_FLOW_PASS home_assets=true settings=true intro_pages=3 cast=true")
	get_tree().quit(0)

func _home_button_ready(home: Control, name: String) -> bool:
	var button := home.get_node_or_null(name) as TextureButton
	return button != null and button.texture_normal != null and button.size.x > 0

func _has_text(root: Node, value: String) -> bool:
	if root is Label and (root as Label).text == value:
		return true
	if root is Button and (root as Button).text == value:
		return true
	for child in root.get_children():
		if _has_text(child, value):
			return true
	return false

func _has_texture(root: Node, texture: Texture2D) -> bool:
	if root is TextureRect and (root as TextureRect).texture == texture:
		return true
	for child in root.get_children():
		if _has_texture(child, texture):
			return true
	return false

func _has_text_containing(root: Node, value: String) -> bool:
	if root is Label and (root as Label).text.contains(value):
		return true
	for child in root.get_children():
		if _has_text_containing(child, value):
			return true
	return false

func _fail(message: String) -> void:
	push_error("STARTUP_FLOW_FAIL " + message)
	get_tree().quit(1)
