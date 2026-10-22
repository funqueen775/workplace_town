extends Node

func _ready() -> void:
	await get_tree().process_frame
	var player := AudioManager.get_node_or_null("BackgroundMusic") as AudioStreamPlayer
	var bus := AudioServer.get_bus_index("Music")
	if player == null or bus < 0 or not player.playing:
		push_error("BACKGROUND_MUSIC_FAIL: player or Music bus not active")
		get_tree().quit(1)
		return
	if not (player.stream is AudioStreamMP3) or not (player.stream as AudioStreamMP3).loop:
		push_error("BACKGROUND_MUSIC_FAIL: MP3 loop disabled")
		get_tree().quit(1)
		return
	AudioManager.set_volume_linear(0.25)
	if absf(AudioServer.get_bus_volume_linear(bus) - 0.25) > 0.01:
		push_error("BACKGROUND_MUSIC_FAIL: volume not applied")
		get_tree().quit(1)
		return
	print("BACKGROUND_MUSIC_PASS")
	player.stop()
	player.stream = null
	get_tree().quit(0)
