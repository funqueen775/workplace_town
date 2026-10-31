extends SceneTree

func _init() -> void:
	var panel = load("res://scripts/StoryEventPanel.gd").new()
	root.add_child(panel)
	await process_frame
	for who in ["大领导", "记录评委", "HRBP", "产品同事", "许棠", "跨部门评委", "方经理", "陈工"]:
		var name := String(panel.call("_portrait_name", who))
		var tex = panel.call("_portrait_texture", who, "自然")
		print("PORTRAIT ", who, " name=", name, " tex=", tex != null, " size=", tex.get_size() if tex != null else "null")
	quit()
