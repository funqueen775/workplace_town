extends Control
## 字幕强调 A/B/C 排版样张：同一句台词三种强调方式。
## 字体、配色、对话框贴图都取自 StoryEventPanel；分行按 4 行排版，方便比较。
## 用法：godot --path . --resolution 1600x900 res://tools/emphasis_ab.tscn -- --dir <绝对目录>

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const DIALOG := preload("res://assets/对话框/角色对话框_空白.png")
const PLATE := preload("res://assets/对话框/姓名牌_空白_确认版.png")
const BG := preload("res://assets/场景内部图/云栖科技丘.png")
const CHARACTER_FRAME_REGION := Rect2(40, 168, 2088, 416)
const PLATE_REGION := Rect2(264, 288, 1368, 264)

const LINES := [
	"这两次评估不是一回事，",
	"转正通过不代表晋升。",
	"晋升看你能不能独立扛一块事，",
	"加班时间不算。",
]
## 0-based：第 2、4 行是关键词。
const EMPHASIS_LINES := [1, 3]
const INK := Color("56301e")
const BRICK := Color("8f3a26")
const ACCENT := Color("a35a3a")
const PENCIL := Color(0.45, 0.36, 0.26, 0.72)

var _dir := "user://emphasis_ab"
var _base_font: FontVariation
var _strong_font: FontVariation
var _frame: TextureRect
var _tag: Label
var _sub: Label
var _lines: Array[Label] = []
var _underlines: Array[Node] = []
var _variant := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--dir" and i + 1 < args.size():
			_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(_dir)
	_base_font = FontVariation.new()
	_base_font.base_font = FONT
	_base_font.variation_embolden = 0.6
	_strong_font = FontVariation.new()
	_strong_font.base_font = FONT
	_strong_font.variation_embolden = 1.0
	_build()
	_run()


func _build() -> void:
	var view := get_viewport_rect().size
	var bg := TextureRect.new()
	bg.texture = BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size = view
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.16, 0.28)
	dim.size = view
	add_child(dim)

	var frame_w := minf(1550.0, view.x - 56.0)
	_frame = TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = DIALOG
	atlas.region = CHARACTER_FRAME_REGION
	_frame.texture = atlas
	_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frame.stretch_mode = TextureRect.STRETCH_SCALE
	_frame.size = Vector2(frame_w, 330)
	_frame.position = Vector2((view.x - frame_w) * 0.5, view.y - 330.0 - 70.0)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)

	var plate := TextureRect.new()
	var plate_atlas := AtlasTexture.new()
	plate_atlas.atlas = PLATE
	plate_atlas.region = PLATE_REGION
	plate.texture = plate_atlas
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	plate.position = Vector2(355, -35)
	plate.size = Vector2(270, 70)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(plate)
	var name_label := _make_label("陈工", _base_font, 27, INK)
	name_label.position = Vector2(18, 13)
	name_label.size = Vector2(234, 44)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(name_label)

	var y := 72.0
	for line in LINES:
		var label := _make_label(line, _base_font, 30, INK)
		label.position = Vector2(95, y)
		label.size = Vector2(frame_w - 185.0, 46)
		_frame.add_child(label)
		_lines.append(label)
		y += 52.0

	var tag_plate := _paper_plate(Vector2(40, 36), Vector2(660, 86))
	add_child(tag_plate)
	_tag = _make_label("", _base_font, 24, ACCENT)
	_tag.position = Vector2(20, 12)
	_tag.size = Vector2(620, 34)
	tag_plate.add_child(_tag)
	_sub = _make_label("同一句台词 · 只看强调方式", _base_font, 16, Color("8a7259"))
	_sub.position = Vector2(20, 50)
	_sub.size = Vector2(620, 24)
	tag_plate.add_child(_sub)

	var foot_plate := _paper_plate(Vector2(40, view.y - 60), Vector2(1180, 40))
	add_child(foot_plate)
	var foot := _make_label("排版样张 · 字体 / 配色 / 对话框取自实机；分行按 4 行排版，不是实机截图", _base_font, 16, Color("8a7259"))
	foot.position = Vector2(20, 9)
	foot.size = Vector2(1140, 24)
	foot_plate.add_child(foot)


func _paper_plate(pos: Vector2, size: Vector2) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.98, 0.94, 0.94)
	style.border_color = Color("d8c6a8")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _make_label(value: String, font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _apply_variant(variant: int) -> void:
	_variant = variant
	var titles: Array[String] = [
		"A · 现在（全部 0.6 加粗）",
		"B · 稀疏加重（关键词 1.0 加粗，已是上限）",
		"C · 加重 + 铅笔下划线",
		"D · 加重 + 砖红",
	]
	_tag.text = titles[variant]
	for i in _lines.size():
		var strong := variant >= 1 and (i in EMPHASIS_LINES)
		_lines[i].add_theme_font_override("font", _strong_font if strong else _base_font)
		_lines[i].add_theme_color_override("font_color", BRICK if (variant == 3 and strong) else INK)
	# 清掉上一版的下划线
	for node in _underlines:
		if is_instance_valid(node):
			node.queue_free()
	_underlines.clear()
	if variant != 2:
		return
	for i in EMPHASIS_LINES:
		var line := _lines[i]
		var font: Font = _strong_font
		var width := font.get_string_size(LINES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		var start := line.position + Vector2(0, 44)
		var points := PackedVector2Array()
		var steps := maxi(8, int(width / 16.0))
		for s in steps + 1:
			var x := width * float(s) / float(steps)
			var wobble := sin(float(s) * 1.9 + float(i) * 2.3) * 0.9
			points.append(Vector2(x, wobble))
		var main := Line2D.new()
		main.position = start
		main.points = points
		main.width = 2.4
		main.default_color = PENCIL
		main.antialiased = true
		_frame.add_child(main)
		_underlines.append(main)
		var faint := Line2D.new()
		faint.position = start + Vector2(2, 2.2)
		faint.points = points
		faint.width = 1.2
		faint.default_color = Color(PENCIL.r, PENCIL.g, PENCIL.b, 0.28)
		faint.antialiased = true
		_frame.add_child(faint)
		_underlines.append(faint)


func _run() -> void:
	await get_tree().process_frame
	for variant in 4:
		_apply_variant(variant)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var names := ["a", "b", "c", "d"]
		var slug := String(names[variant])
		var path := "%s/ab_%s.png" % [_dir, slug]
		img.save_png(path)
		print("[ab] ", path)
		await get_tree().create_timer(0.2).timeout
	get_tree().quit()
