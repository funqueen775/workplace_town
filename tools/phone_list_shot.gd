extends Node

## 手机会话列表样张：看列表行头像（尤其没有专属立绘的小赵）裁得对不对。
## 用法：<godot> --path <proj> --resolution 1920x1080 res://tools/phone_list_shot.tscn

const PANEL := preload("res://scripts/v12m/PhoneInboxPanel.gd")
const DIR := "res://test_artifacts/v12m_phone"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var panel := PANEL.new()
	add_child(panel)
	panel.set("hide_own_hud", true)
	panel.set("conversations", [
		{"id": "wang_ge", "name": "王哥", "role": "技术导师",
			"messages": [{"speaker": "npc", "text": "两张图我看了，先别急着推。"}],
			"unread": false, "date": "第 2 月 · 下旬 · 夜里", "date_short": "第 2 月",
			"sort": 222, "reply_options": []},
		{"id": "xiao_zhao", "name": "小赵", "role": "邻组同事",
			"messages": [{"speaker": "npc", "text": "客户那边居然签了。你怎么想到当面把话说开的？"}],
			"unread": true, "date": "第 11 月 · 上旬 · 午后", "date_short": "第 11 月",
			"sort": 1101, "reply_options": []},
		{"id": "chen_gong", "name": "陈工", "role": "邻组 Leader",
			"messages": [{"speaker": "npc", "text": "结论是什么？预算和工期，一句话说完。"}],
			"unread": false, "date": "第 11 月 · 下旬 · 夜里", "date_short": "第 11 月",
			"sort": 1122, "reply_options": []},
		{"id": "lao_zhou", "name": "老周", "role": "老同事",
			"messages": [{"speaker": "npc", "text": "复盘会上有不同说法。"}],
			"unread": false, "date": "第 12 月 · 中旬 · 午后", "date_short": "第 12 月",
			"sort": 1221, "reply_options": []},
	])
	await get_tree().create_timer(0.5).timeout
	# true = 停在会话列表，不自动进那位还没看的会话（这张样张要看的是列表）。
	panel.call("open_phone", true)
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	print("phone list -> %s" % image.save_png(ProjectSettings.globalize_path(DIR + "/phone_list.png")))
	get_tree().quit(0)
