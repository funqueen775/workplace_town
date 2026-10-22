class_name BattleFx
extends Control

const DiceButtonScript = preload("res://training_valley/scripts/dice_button.gd")
const FxTrailsScript = preload("res://training_valley/scripts/fx_trails.gd")
const CHINESE_FONT = preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const CREAM := Color("#fff6df")

var focus_target: Control
var focus_margin := 14.0
var focus_group: Control
var focus_dim: ColorRect
var focus_frame: Panel
var focus_hint: Label
var focus_tween: Tween
var combat_group: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 35
	_build_focus_group()
	_build_combat_group()


func _process(_delta: float) -> void:
	if focus_group.visible and is_instance_valid(focus_target):
		_layout_focus()


func focus(control: Control, hint: String, margin: float = 14.0) -> void:
	if not is_instance_valid(control):
		clear_focus()
		return
	focus_target = control
	focus_margin = margin
	focus_hint.text = hint
	focus_hint.visible = not hint.is_empty()
	focus_group.visible = true
	_layout_focus()
	if focus_tween and focus_tween.is_valid():
		focus_tween.kill()
	focus_frame.modulate = Color.WHITE
	focus_tween = create_tween().set_loops()
	focus_tween.tween_property(focus_frame, "modulate", Color("#fff0a8"), 0.55)
	focus_tween.tween_property(focus_frame, "modulate", Color.WHITE, 0.55)


func clear_focus() -> void:
	focus_target = null
	focus_group.visible = false
	if focus_tween and focus_tween.is_valid():
		focus_tween.kill()


func roll_dice(row: HBoxContainer, values: Array, hidden_mask: Array = [], emphasize: bool = true) -> void:
	clear_focus()
	_clear_children(row)
	for i in range(values.size()):
		var die := DiceButtonScript.new()
		die.configure(randi_range(1, 6), false, false)
		die.disabled = true
		row.add_child(die)
	await get_tree().process_frame
	if emphasize:
		focus(row, "骰子正在滚动，先看点数落定", 12)
	for step in range(10):
		for child in row.get_children():
			child.configure(randi_range(1, 6), false, false)
			child.rotation += 0.62
			child.scale = Vector2.ONE * (1.08 if step % 2 == 0 else 0.94)
		await get_tree().create_timer(0.11).timeout
	for i in range(values.size()):
		var hidden := i < hidden_mask.size() and bool(hidden_mask[i])
		var die: Button = row.get_child(i)
		die.configure(int(values[i]), false, hidden)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(die, "rotation", 0.0, 0.38).set_trans(Tween.TRANS_BACK)
		tween.tween_property(die, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(0.58).timeout


func highlight_choice(row: HBoxContainer, index: int, role_text: String, emphasize: bool = true) -> void:
	if index < 0 or index >= row.get_child_count():
		return
	var chosen: Button = row.get_child(index)
	chosen.configure(chosen.die_value, true, chosen.is_hidden)
	if emphasize:
		focus(chosen, role_text, 18)
	var tween := create_tween()
	tween.tween_property(chosen, "scale", Vector2(1.24, 1.24), 0.3).set_trans(Tween.TRANS_BACK)
	tween.tween_property(chosen, "scale", Vector2.ONE, 0.3)
	await tween.finished
	await get_tree().create_timer(0.65).timeout


func reveal_die(die: Button, value: int, emphasize: bool = false) -> void:
	if emphasize:
		focus(die, "未知骰已选中，正在揭晓点数", 18)
	for step in range(8):
		die.configure(randi_range(1, 6), true, false)
		die.rotation += 0.8
		die.scale = Vector2.ONE * (1.12 if step % 2 == 0 else 0.92)
		await get_tree().create_timer(0.11).timeout
	die.configure(value, true, false)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(die, "rotation", 0.0, 0.38).set_trans(Tween.TRANS_BACK)
	tween.tween_property(die, "scale", Vector2(1.18, 1.18), 0.3).set_trans(Tween.TRANS_BACK)
	await tween.finished
	die.scale = Vector2.ONE


func transfer_dice(source_row: HBoxContainer, indices: Array, target: Control, emphasize: bool = true) -> void:
	if indices.is_empty() or not is_instance_valid(target):
		return
	clear_focus()
	combat_group.visible = true
	var target_rect := target.get_global_rect()
	var ghosts: Array[Button] = []
	for order in range(indices.size()):
		var source: Button = source_row.get_child(int(indices[order]))
		var ghost := DiceButtonScript.new()
		ghost.configure(source.die_value, false, false)
		ghost.position = source.get_global_rect().position
		ghost.size = source.size
		ghost.pivot_offset = ghost.size * 0.5
		combat_group.add_child(ghost)
		ghosts.append(ghost)
		var destination := Vector2(
			target_rect.position.x + target_rect.size.x * (0.72 + 0.17 * order),
			target_rect.position.y + 4
		)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(ghost, "position", destination, 0.88).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(ghost, "rotation", TAU, 0.88)
		tween.tween_property(ghost, "scale", Vector2(1.14, 1.14), 0.44)
		tween.chain().tween_property(ghost, "scale", Vector2.ONE, 0.34)
	await get_tree().create_timer(0.96).timeout
	for ghost in ghosts:
		ghost.queue_free()
	combat_group.visible = false
	if emphasize:
		focus(target, "王哥留下的两枚骰子加入你的骰池", 15)
	await get_tree().create_timer(0.8).timeout


func combat_resolution(
	attacker_name: String,
	attack: int,
	defender_name: String,
	defense: int,
	attacker_anchor: Control,
	defender_anchor: Control,
	target_portrait: Control,
	damage: int,
	blocked: bool
) -> void:
	clear_focus()
	combat_group.visible = true
	var dim := ColorRect.new()
	dim.color = Color("#07101882")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combat_group.add_child(dim)
	var trails := FxTrailsScript.new()
	combat_group.add_child(trails)
	var attack_die := _floating_die(attack, Color("#ff6a45"))
	var defense_die := _floating_die(randi_range(1, 6), Color("#58c8ff"))
	var attack_start := _anchor_position(attacker_anchor, attack_die.size)
	var defense_start := _anchor_position(defender_anchor, defense_die.size)
	attack_die.position = attack_start
	defense_die.position = defense_start
	attack_die.modulate.a = 0.0
	defense_die.modulate.a = 0.0
	combat_group.add_child(attack_die)
	combat_group.add_child(defense_die)
	var attack_label := _combat_label("%s · 攻击 %d" % [attacker_name, attack], Color("#ff8a60"))
	var defense_label := _combat_label("%s · 防御 ?" % defender_name, Color("#79d7ff"))
	attack_label.position = Vector2(260, 214)
	defense_label.position = Vector2(710, 214)
	attack_label.modulate.a = 0.0
	defense_label.modulate.a = 0.0
	combat_group.add_child(attack_label)
	combat_group.add_child(defense_label)
	var attack_stage := Vector2(405, 282)
	var defense_stage := Vector2(765, 282)
	var intro := create_tween().set_parallel(true)
	intro.tween_property(attack_die, "position", attack_stage, 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	intro.tween_property(defense_die, "position", defense_stage, 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	intro.tween_property(attack_die, "modulate:a", 1.0, 0.22)
	intro.tween_property(defense_die, "modulate:a", 1.0, 0.22)
	intro.tween_property(attack_label, "modulate:a", 1.0, 0.32).set_delay(0.18)
	intro.tween_property(defense_label, "modulate:a", 1.0, 0.32).set_delay(0.18)
	await intro.finished
	for _step in range(8):
		var face := randi_range(1, 6)
		defense_die.configure(face, false, false)
		defense_label.text = "%s · 防御 %d" % [defender_name, face]
		defense_die.rotation += 0.8
		await get_tree().create_timer(0.1).timeout
	defense_die.configure(defense, true, false)
	defense_label.text = "%s · 防御 %d" % [defender_name, defense]
	var settle := create_tween()
	settle.tween_property(defense_die, "rotation", 0.0, 0.36).set_trans(Tween.TRANS_BACK)
	await settle.finished
	trails.set_points(attack_stage + attack_die.size * 0.5, defense_stage + defense_die.size * 0.5)
	trails.set_impact(0.2)
	var charge := create_tween().set_parallel(true)
	charge.tween_method(func(value: float): trails.set_impact(value), 0.2, 1.0, 0.46)
	charge.tween_property(attack_die, "position:x", 505.0, 0.46).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	charge.tween_property(defense_die, "position:x", 665.0, 0.46).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	charge.tween_property(attack_die, "scale", Vector2(1.18, 1.18), 0.46)
	charge.tween_property(defense_die, "scale", Vector2(1.18, 1.18), 0.46)
	await charge.finished
	trails.set_points(attack_die.position + attack_die.size * 0.5, defense_die.position + defense_die.size * 0.5)
	trails.set_impact(1.0, "block" if blocked else "hit")
	var clash := create_tween().set_parallel(true)
	clash.tween_property(attack_die, "scale", Vector2(1.32, 1.32), 0.16).set_trans(Tween.TRANS_BACK)
	clash.tween_property(defense_die, "scale", Vector2(1.32, 1.32), 0.16).set_trans(Tween.TRANS_BACK)
	await clash.finished
	var result := _label("格挡成功" if blocked else "命中 · 造成 %d 点伤害" % damage, 34, CREAM)
	result.position = Vector2(365, 475)
	result.size = Vector2(550, 66)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_color_override("font_color", Color("#91e7ff") if blocked else Color("#ff8c6b"))
	result.add_theme_color_override("font_outline_color", Color("#132a35") if blocked else Color("#4b201c"))
	result.add_theme_constant_override("outline_size", 12)
	result.modulate.a = 0.0
	result.rotation = -0.025 if blocked else 0.035
	result.pivot_offset = result.size * 0.5
	combat_group.add_child(result)
	var impact := create_tween()
	impact.tween_property(result, "modulate:a", 1.0, 0.2)
	impact.parallel().tween_property(result, "scale", Vector2(1.1, 1.1), 0.2).from(Vector2(0.72, 0.72))
	impact.tween_property(result, "scale", Vector2.ONE, 0.28)
	await impact.finished
	if damage > 0:
		show_damage(target_portrait, damage)
	await get_tree().create_timer(1.15).timeout
	var fade := create_tween()
	fade.tween_property(combat_group, "modulate:a", 0.0, 0.32)
	await fade.finished
	_clear_children(combat_group)
	combat_group.modulate.a = 1.0
	combat_group.visible = false


func show_damage(target: Control, amount: int) -> void:
	if amount <= 0 or not is_instance_valid(target):
		return
	var rect := target.get_global_rect()
	var label := _label("-%d" % amount, 56, Color("#ff493d"))
	label.position = rect.get_center() - Vector2(80, 30)
	label.size = Vector2(160, 80)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color("#fff4df"))
	label.add_theme_constant_override("outline_size", 12)
	label.pivot_offset = label.size * 0.5
	add_child(label)
	var original := target.position
	var original_modulate := target.modulate
	target.modulate = Color("#ff7d70")
	var shake := create_tween()
	shake.tween_property(target, "position:x", original.x - 12, 0.05)
	shake.tween_property(target, "position:x", original.x + 12, 0.05)
	shake.tween_property(target, "position:x", original.x - 8, 0.05)
	shake.tween_property(target, "position", original, 0.07)
	shake.parallel().tween_property(target, "modulate", original_modulate, 0.22)
	var number := create_tween().set_parallel(true)
	number.tween_property(label, "scale", Vector2(1.25, 1.25), 0.13).from(Vector2(0.45, 0.45)).set_trans(Tween.TRANS_BACK)
	number.tween_property(label, "position:y", label.position.y - 70, 1.3)
	number.tween_property(label, "modulate:a", 0.0, 1.3).set_delay(0.62)
	number.finished.connect(label.queue_free)


func _build_focus_group() -> void:
	focus_group = Control.new()
	focus_group.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_group.visible = false
	add_child(focus_group)
	focus_dim = ColorRect.new()
	focus_dim.color = Color.WHITE
	focus_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec2 hole_center = vec2(0.5);
uniform vec2 hole_half_size = vec2(0.15, 0.10);
uniform float corner_radius = 0.025;
uniform float softness = 0.018;
uniform float dim_alpha = 0.64;

float rounded_box_sdf(vec2 point, vec2 half_size, float radius) {
	vec2 q = abs(point) - half_size + vec2(radius);
	return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - radius;
}

void fragment() {
	float distance_to_hole = rounded_box_sdf(UV - hole_center, hole_half_size, corner_radius);
	float outside = smoothstep(-softness, softness, distance_to_hole);
	COLOR = vec4(0.025, 0.045, 0.050, outside * dim_alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	focus_dim.material = material
	focus_group.add_child(focus_dim)
	focus_frame = Panel.new()
	focus_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_style := _style(Color.TRANSPARENT, 20, Color("#ffe7a0"), 2)
	glow_style.shadow_color = Color("#ffd45e88")
	glow_style.shadow_size = 16
	focus_frame.add_theme_stylebox_override("panel", glow_style)
	focus_group.add_child(focus_frame)
	focus_hint = _label("", 18, CREAM)
	focus_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	focus_hint.add_theme_color_override("font_color", Color("#fff0b0"))
	focus_hint.add_theme_color_override("font_outline_color", Color("#30231fcc"))
	focus_hint.add_theme_constant_override("outline_size", 8)
	focus_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_group.add_child(focus_hint)


func _build_combat_group() -> void:
	combat_group = Control.new()
	combat_group.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	combat_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combat_group.visible = false
	add_child(combat_group)


func _layout_focus() -> void:
	var viewport_size := size
	var transform_to_local := get_global_transform().affine_inverse() * focus_target.get_global_transform()
	var corners := [
		transform_to_local * Vector2.ZERO,
		transform_to_local * Vector2(focus_target.size.x, 0),
		transform_to_local * focus_target.size,
		transform_to_local * Vector2(0, focus_target.size.y),
	]
	var rect := Rect2(corners[0], Vector2.ZERO)
	for corner in corners:
		rect = rect.expand(corner)
	rect = rect.grow(focus_margin)
	rect = rect.intersection(Rect2(Vector2.ZERO, viewport_size))
	var material := focus_dim.material as ShaderMaterial
	material.set_shader_parameter("hole_center", rect.get_center() / viewport_size)
	material.set_shader_parameter("hole_half_size", rect.size * 0.5 / viewport_size)
	material.set_shader_parameter("corner_radius", minf(0.035, 20.0 / viewport_size.y))
	focus_frame.position = rect.position
	focus_frame.size = rect.size
	var hint_width := clampf(maxf(330.0, rect.size.x + 60.0), 330.0, 660.0)
	var hint_y := rect.position.y - 76.0
	if hint_y < 14.0:
		hint_y = rect.end.y + 12.0
	var hint_x := clampf(rect.get_center().x - hint_width * 0.5, 12.0, viewport_size.x - hint_width - 12.0)
	if rect.position.y > viewport_size.y * 0.70:
		hint_x = rect.end.x + 18.0
		if hint_x + hint_width > viewport_size.x - 12.0:
			hint_x = rect.position.x - hint_width - 18.0
		hint_y = rect.get_center().y - 22.0
	focus_hint.position = Vector2(hint_x, hint_y)
	focus_hint.size = Vector2(hint_width, 44)


func _floating_die(value: int, glow_color: Color) -> Button:
	var die := DiceButtonScript.new()
	die.configure(value, true, false)
	die.disabled = true
	die.size = Vector2(110, 110)
	die.custom_minimum_size = die.size
	die.pivot_offset = die.size * 0.5
	die.self_modulate = glow_color.lightened(0.22)
	return die


func _anchor_position(anchor: Control, item_size: Vector2) -> Vector2:
	if not is_instance_valid(anchor):
		return Vector2(640, 360) - item_size * 0.5
	return anchor.get_global_rect().get_center() - item_size * 0.5


func _combat_label(text_value: String, color: Color) -> Label:
	var label := _label(text_value, 25, color)
	label.size = Vector2(310, 52)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color("#18222bcc"))
	label.add_theme_constant_override("outline_size", 9)
	return label


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", CHINESE_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _style(bg: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	if width > 0:
		style.border_color = border
		style.border_width_left = width
		style.border_width_right = width
		style.border_width_top = width
		style.border_width_bottom = width
	return style


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
