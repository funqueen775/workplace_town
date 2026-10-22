extends Node2D


func _ready() -> void:
	var panel := StoryEventPanel.new()
	add_child(panel)
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/main_story_v11.json"))
	var first_event: Dictionary = (story.get("events", []) as Array)[0]
	panel.present(first_event)
	panel._end_entry()
	panel._next_beat()
	await RenderingServer.frame_post_draw
	panel._finish_typewriter()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("C:/Users/23342/Desktop/project/ai_town/.profile-review/dialogue_layout.png")
	panel._show_choices("")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("C:/Users/23342/Desktop/project/ai_town/.profile-review/choices_layout.png")
	panel._show_narration("你的工位干净得像一张还没决定要不要留下你的纸。显示器没开，桌角压着一本比键盘还厚的员工手册。")
	panel._finish_typewriter()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("C:/Users/23342/Desktop/project/ai_town/.profile-review/narration_layout.png")
	panel.dismiss()
	var activity: CanvasLayer = load("res://scripts/WeekendScenePanel.gd").new()
	add_child(activity)
	activity.present({
		"title": "篝火烧烤",
		"image": "res://assets/weekend_scenes/bbq_lawn.png",
		"lines": ["火光把每个人的影子拉得很长，手里的食物慢慢烤熟。"],
	})
	activity._advance()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("C:/Users/23342/Desktop/project/ai_town/.profile-review/activity_narration_layout.png")
	get_tree().quit()
