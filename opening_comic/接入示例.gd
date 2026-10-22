extends Node

## 示例一：把 OpeningComic.tscn 实例化为当前场景的子节点后，监听完成信号。
@onready var opening_comic: OpeningComic = $OpeningComic


func _ready() -> void:
	opening_comic.comic_finished.connect(_on_opening_comic_finished)


func _on_opening_comic_finished() -> void:
	# 替换成你们真正的入职问卷场景路径。
	get_tree().change_scene_to_file("res://ui/EntryQuestionnaire.tscn")
