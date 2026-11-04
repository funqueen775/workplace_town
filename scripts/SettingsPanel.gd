extends CanvasLayer
## 精简设置：只提供背景音乐音量和返回标题。

signal settings_closed()
signal title_requested()

const FONT := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const PANEL_ART := preload("res://assets/ui/rework_v1/profile/components/01_基础面板/空白大底板.png")
const TITLE_ART := preload("res://assets/ui/rework_v1/profile/components/01_基础面板/无字标题牌.png")
const MUSIC_ART := preload("res://assets/游戏设置/13_背景音乐滑条.png")
const RETURN_TITLE_ART := preload("res://assets/游戏设置/08_返回标题.png")
const RETURN_TITLE_REGION := Rect2(391, 192, 1390, 355)
const CARD_SIZE := Vector2(820, 760)
const MUSIC_CONFIG_PATH := "user://town_ui_settings.cfg"

const COLOR_BACKDROP := Color(0.02, 0.03, 0.06, 0.58)
const COLOR_TEXT := Color("63301d")

var _root: Control
var _card: Control
var _open_flag := false
var _music_slider: HSlider
var _music_volume := 0.8


func _ready() -> void:
	layer = 200
	_load_music_setting()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	add_child(_root)

	var backdrop := ColorRect.new()
	backdrop.color = COLOR_BACKDROP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(backdrop)

	_card = Control.new()
	_card.size = CARD_SIZE
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_card)
	_build_content()
	_root.resized.connect(_layout_card)
	_layout_card()


func open() -> void:
	if _open_flag:
		return
	_open_flag = true
	_root.visible = true

func close() -> void:
	if not _open_flag:
		return
	_open_flag = false
	_root.visible = false
	settings_closed.emit()


func is_open() -> bool:
	return _open_flag


func _unhandled_input(event: InputEvent) -> void:
	if _open_flag and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()


func _build_content() -> void:
	_add_art(PANEL_ART, Vector2.ZERO, CARD_SIZE, _card)
	_add_art(TITLE_ART, Vector2(255, 24), Vector2(310, 76), _card)

	var title := _label("游戏设置", 36)
	title.position = Vector2(275, 76)
	title.size = Vector2(270, 58)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.add_child(title)

	var music_label := _label("背景音乐", 24)
	music_label.position = Vector2(142, 280)
	music_label.size = Vector2(150, 46)
	_card.add_child(music_label)
	_add_art(MUSIC_ART, Vector2(300, 284), Vector2(350, 42), _card)

	_music_slider = HSlider.new()
	_music_slider.name = "MusicVolumeSlider"
	_music_slider.position = Vector2(320, 284)
	_music_slider.size = Vector2(310, 42)
	_music_slider.min_value = 0.0
	_music_slider.max_value = 1.0
	_music_slider.step = 0.01
	_music_slider.value = _music_volume
	_music_slider.value_changed.connect(_on_music_volume_changed)
	_card.add_child(_music_slider)

	var return_texture := AtlasTexture.new()
	return_texture.atlas = RETURN_TITLE_ART
	return_texture.region = RETURN_TITLE_REGION
	var return_button := TextureButton.new()
	return_button.name = "ReturnToTitleButton"
	return_button.ignore_texture_size = true
	return_button.texture_normal = return_texture
	return_button.texture_hover = return_texture
	return_button.texture_pressed = return_texture
	return_button.position = Vector2(190, 594)
	return_button.size = Vector2(440, 112)
	return_button.stretch_mode = TextureButton.STRETCH_SCALE
	return_button.pressed.connect(_on_return_to_title)
	_card.add_child(return_button)


func _layout_card() -> void:
	if _card == null or _root == null:
		return
	var available := _root.size - Vector2(40, 40)
	var scale_factor := minf(1.0, minf(available.x / CARD_SIZE.x, available.y / CARD_SIZE.y))
	_card.scale = Vector2.ONE * scale_factor
	_card.position = (_root.size - CARD_SIZE * scale_factor) * 0.5


func _on_music_volume_changed(value: float) -> void:
	_music_volume = value
	_apply_music_volume()
	_save_music_setting()


func _on_return_to_title() -> void:
	_save_music_setting()
	close()
	title_requested.emit()


func _apply_music_volume() -> void:
	if AudioServer.get_bus_index("Music") >= 0:
		AudioManager.set_volume_linear(_music_volume)


func _load_music_setting() -> void:
	var config := ConfigFile.new()
	if config.load(MUSIC_CONFIG_PATH) == OK:
		_music_volume = clampf(float(config.get_value("display", "music", _music_volume)), 0.0, 1.0)
	_apply_music_volume()


func _save_music_setting() -> void:
	var config := ConfigFile.new()
	config.load(MUSIC_CONFIG_PATH)
	config.set_value("display", "music", _music_volume)
	config.save(MUSIC_CONFIG_PATH)


func _add_art(texture: Texture2D, at: Vector2, size_value: Vector2, parent: Control) -> TextureRect:
	var art := TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.position = at
	art.size = size_value
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	return art


func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
