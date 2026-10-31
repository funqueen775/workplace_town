extends Control

## 封条四种做法的实机样张：同一块地上各立一扇门，一次截一张，挑完就固定一种。
## 用法：Godot --path . res://tools/shot_seal_styles.tscn -- --dir <输出目录>

const TOWN_PORTAL := preload("res://scripts/TownPortal.gd")

var _dir := "user://seal_styles"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	_run()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_dir, name]
	img.save_png(path)
	print("[shot] ", path)


func _run() -> void:
	var town: Node = load("res://Main.tscn").instantiate()
	add_child(town)
	await get_tree().create_timer(3.2).timeout
	var panel = town.get("_story_event_panel")
	if panel != null:
		panel.visible = false
	var player: Node2D = town.get("_player")
	var spot := Vector2(700, 520)
	for style in 4:
		for child in town.get_children():
			if String(child.name).begins_with("SealSample"):
				child.queue_free()
		var door: Node2D = TOWN_PORTAL.new()
		door.name = "SealSample"
		door.position = spot
		door.z_index = 44
		door.set("seal_style", style)
		town.add_child(door)
		door.call("set_sealed", true)
		player.position = spot + Vector2(0, 96)
		await get_tree().create_timer(0.7).timeout
		await _shot("封条%d" % style)
	print("SEAL SAMPLES DONE")
	get_tree().quit()
