extends Node

## 把区里的场景图裁成一张讲解卡配图（620×420，和 assets/ui/place_cards 里那批同尺寸）。
## 用法：
##   <godot> --path <proj> --headless res://tools/make_place_card.tscn -- \
##       --src=res://assets/场景内部图/观澜展会码头.png --dst=res://assets/ui/place_cards/place_card_expo_1.png
## 不给参数时按第 5 月默认那一对走：码头场景 → place_card_expo_1.png。

const WANT := Vector2i(620, 420)


func _ready() -> void:
	var src := "res://assets/场景内部图/观澜展会码头.png"
	var dst := "res://assets/ui/place_cards/place_card_expo_1.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--src="):
			src = arg.substr(6)
		elif arg.begins_with("--dst="):
			dst = arg.substr(6)
	var image := Image.load_from_file(ProjectSettings.globalize_path(src))
	if image == null or image.is_empty():
		print("[card] 读不到 %s" % src)
		get_tree().quit(1)
		return
	# 先按目标准比例中间裁一刀，再等比缩放——直接硬拉会把图拉扁。
	var target_ratio := float(WANT.x) / float(WANT.y)
	var src_ratio := float(image.get_width()) / float(image.get_height())
	var crop_w := image.get_width()
	var crop_h := image.get_height()
	if src_ratio > target_ratio:
		crop_w = int(float(image.get_height()) * target_ratio)
	else:
		crop_h = int(float(image.get_width()) / target_ratio)
	var sx := int((image.get_width() - crop_w) / 2.0)
	var sy := int((image.get_height() - crop_h) / 2.0)
	image = image.get_region(Rect2i(sx, sy, crop_w, crop_h))
	image.resize(WANT.x, WANT.y, Image.INTERPOLATE_LANCZOS)
	var path := ProjectSettings.globalize_path(dst)
	var err := image.save_png(path)
	print("[card] %s → %s (%dx%d) err=%d" % [src, dst, image.get_width(), image.get_height(), err])
	get_tree().quit(0 if err == OK else 1)
