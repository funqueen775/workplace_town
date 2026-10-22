extends Node

const MUSIC_PATH := "res://assets/audio/bgm.mp3"
const MUSIC_BUS := "Music"

var _player: AudioStreamPlayer

func _ready() -> void:
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus < 0:
		AudioServer.add_bus()
		bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, MUSIC_BUS)
	AudioServer.set_bus_send(bus, "Master")
	var settings := ConfigFile.new()
	var volume := 0.65
	if settings.load("user://town_ui_settings.cfg") == OK:
		volume = float(settings.get_value("display", "music", volume))
	set_volume_linear(volume)
	if OS.has_feature("web"):
		return

	_player = AudioStreamPlayer.new()
	_player.name = "BackgroundMusic"
	_player.bus = MUSIC_BUS
	_player.stream = load(MUSIC_PATH) as AudioStream
	if _player.stream == null:
		push_warning("背景音乐加载失败: %s" % MUSIC_PATH)
		return
	if _player.stream is AudioStreamMP3:
		(_player.stream as AudioStreamMP3).loop = true
	add_child(_player)
	_player.play()

func set_volume_linear(value: float) -> void:
	var volume := clampf(value, 0.0, 1.0)
	var bus := AudioServer.get_bus_index(MUSIC_BUS)
	if bus >= 0:
		AudioServer.set_bus_volume_linear(bus, volume)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__setTownMusicVolume && window.__setTownMusicVolume(%f)" % volume)

func is_playing() -> bool:
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("window.__townMusic && !window.__townMusic.paused"))
	return _player != null and _player.playing
