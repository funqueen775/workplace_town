extends Node2D

func _ready() -> void:
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(1.2).timeout
	var toast_layer = town.get("_toast_layer")
	if toast_layer != null:
		toast_layer.hide()
	var town_ui = town.get("_town_ui_v2")
	town_ui.open_view("profile")
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("C:/Users/23342/Desktop/project/ai_town/.profile-review/profile_layout.png")
	get_tree().quit()
