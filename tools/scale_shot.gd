extends Node

## 镇上这些人到底是谁、多大：拍一张镇面，再把每个 NPC 的贴图尺寸 / 缩放 / 位置打出来。
## 用法：<godot> --path . --resolution 1600x900 res://tools/scale_shot.tscn -- --no-resume

const OUT_DIR := "res://test_artifacts/scale"

var _town: Node
var _done := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_watchdog()
	_town = load("res://Main.tscn").instantiate()
	add_child(_town)
	await get_tree().create_timer(3.2).timeout
	var start = _town.get("_month12_start_panel")
	for i in 60:
		await get_tree().create_timer(0.1).timeout
		start = _town.get("_month12_start_panel")
		if start != null and is_instance_valid(start) and bool(start.call("is_open")):
			_town.call("_on_month_start_continued")
			await get_tree().create_timer(0.8).timeout
			break
	var story = _town.get("_story_event_panel")
	if story != null and is_instance_valid(story):
		story.call("dismiss")
		await get_tree().create_timer(0.4).timeout
	_report_sprite("玩家", _town.get("_player_sprite"))
	var npcs: Array = _town.get("_npc_instances")
	print("[scale] 镇上 NPC 数=", npcs.size())
	for entry in npcs:
		var dict := Dictionary(entry)
		var character = dict.get("character")
		print("[scale] --- ", String(dict.get("name", "?")), " zone=", String(dict.get("zone", "?")),
			" 可见=", (character != null and is_instance_valid(character) and bool(character.visible)))
		if character != null and is_instance_valid(character):
			print("[scale]     位置=", character.position, " 缩放=", character.scale,
				" 装扮=", String(dict.get("loadout", "?")))
			for child in character.get_children():
				if child is Sprite2D or child is AnimatedSprite2D:
					_report_sprite(String(dict.get("name", "?")) + "/" + child.name, child)
	await _shot("镇面")
	print("SCALE_SHOT_DONE")
	_done = true
	get_tree().quit(0)


func _report_sprite(who: String, node) -> void:
	if node == null or not is_instance_valid(node):
		print("[scale] ", who, " 没有精灵")
		return
	var frame := Vector2.ZERO
	if node is Sprite2D:
		var still := node as Sprite2D
		if still.texture != null:
			frame = still.texture.get_size()
	elif node is AnimatedSprite2D:
		var anim := node as AnimatedSprite2D
		var still_frame: Texture2D = anim.frames.get_frame(anim.animation, anim.frame)
		if still_frame != null:
			frame = still_frame.get_size()
	var node2d := node as Node2D
	var src := ""
	if node is Sprite2D and (node as Sprite2D).texture != null:
		src = String((node as Sprite2D).texture.resource_path)
	print("[scale] ", who, " scale=", node2d.scale, " 单帧=", frame,
		" 实际占位=", Vector2(frame.x * node2d.scale.x, frame.y * node2d.scale.y),
		" 偏移=", node2d.position, " 图=", src)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT_DIR + "/" + name + ".png"))


func _watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	if _done:
		return
	print("WATCHDOG forced quit")
	get_tree().quit(1)
