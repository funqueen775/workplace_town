extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var startup: Control = load("res://Startup.tscn").instantiate()
	root.add_child(startup)
	startup.call("_show_login_screen")
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://tools/startup_home_preview.png")
	var result := root.get_viewport().get_texture().get_image().save_png(output)
	print("STARTUP_HOME_SHOT ", output, " result=", result)
	var start_button := startup.get_node("HomeCanvas/StartGame") as TextureButton
	start_button.mouse_entered.emit()
	await create_timer(0.22).timeout
	await RenderingServer.frame_post_draw
	var hover_output := ProjectSettings.globalize_path("res://tools/startup_home_hover_preview.png")
	var hover_result := root.get_viewport().get_texture().get_image().save_png(hover_output)
	print("STARTUP_HOME_HOVER_SHOT ", hover_output, " result=", hover_result)
	quit(0 if result == OK and hover_result == OK else 1)
