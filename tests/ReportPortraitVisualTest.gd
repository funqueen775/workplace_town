extends Control


func _ready() -> void:
	var panel: CanvasLayer = load("res://scripts/ReportPanel.gd").new()
	add_child(panel)
	panel.visible = true
	panel.render({
		"skippedStoryIds": ["E01", "E02", "E03"],
		"layers": {"persona": {
			"portraitStatus": "provisional",
			"bigfive": [
				{"trait": "O", "portraitScore": 55, "portraitEvidence": "limited"},
				{"trait": "C", "portraitScore": 59, "portraitEvidence": "limited"},
				{"trait": "E", "portraitScore": 53, "portraitEvidence": "limited"},
				{"trait": "A", "portraitScore": 47, "portraitEvidence": "limited"},
				{"trait": "N", "portraitScore": 50, "portraitEvidence": "none"},
			],
			"styleTags": ["计划周密", "探索新路"],
		}},
	})
	for frame in 4:
		await get_tree().process_frame
	var output := ProjectSettings.globalize_path("res://artifacts/report_portrait_preview.png")
	var error := get_viewport().get_texture().get_image().save_png(output)
	if error != OK:
		push_error("报告截图失败：" + str(error))
	panel.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if error == OK else 1)
