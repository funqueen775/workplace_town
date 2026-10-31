# -*- coding: utf-8 -*-
"""月初的"今天"卡：把数据里那三行接到月初卡上，别一翻月就直接跳进剧情。"""
import json
import sys

ROOT = r'E:\03_Projects\bear\workplace_town'
GD = ROOT + r'\scripts\WorkplaceTown.gd'
MP = ROOT + r'\scripts\v12m\MonthStartPanel.gd'
EV = ROOT + r'\data\story\v12m\events.json'

# ---------------------------------------------------------------- 1) 月初卡支持三行
raw = open(MP, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in raw else '\n'
p = raw.replace('\r\n', '\n')
old = 'func open(month: int, destination: String, first_task: String, intro: String) -> void:'
new = ('## today_lines：本月第一屏自带的"今天"三行（4.17）。有就照它写，没有才用 intro。\n'
       'func open(month: int, destination: String, first_task: String, intro: String, today_lines: Array = []) -> void:')
assert old in p, 'panel open'
p = p.replace(old, new, 1)

old_body = '''	var body := _label(intro, 24, Color("5a3a24"))
	body.position = Vector2(56, 158)
	body.size = Vector2(788, 72)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_constant_override("line_spacing", 7)
	_card.add_child(body)'''
new_body = '''	if today_lines.is_empty():
		var body := _label(intro, 24, Color("5a3a24"))
		body.position = Vector2(56, 158)
		body.size = Vector2(788, 72)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_constant_override("line_spacing", 7)
		_card.add_child(body)
	else:
		# "今天"三行：谁叫你去、带什么、几点在哪。一行一行摆，不挤成一段。
		var y := 150.0
		for i in today_lines.size():
			var line := _label(String(today_lines[i]), 26, Color("5a3a24"))
			line.position = Vector2(56, y)
			line.size = Vector2(788, 38)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_card.add_child(line)
			y += 46.0'''
assert old_body in p, 'panel body'
p = p.replace(old_body, new_body, 1)
open(MP, 'w', encoding='utf-8', newline='').write(p.replace('\n', nl))

# ---------------------------------------------------------------- 2) 城镇侧：取本月的今天三行
graw = open(GD, encoding='utf-8', newline='').read()
gnl = '\r\n' if '\r\n' in graw else '\n'
g = graw.replace('\r\n', '\n')

old_sig = 'func _show_month_start(month: int, destination: String, first_task: String, intro: String, next_step: Callable) -> void:'
new_sig = 'func _show_month_start(month: int, destination: String, first_task: String, intro: String, today_lines: Array, next_step: Callable) -> void:'
assert old_sig in g, 'show sig'
g = g.replace(old_sig, new_sig, 1)

old_open = '\t_month12_start_panel.open(month, destination, first_task, intro)'
old_open2 = '\t_month12_start_panel.open(month, destination, first_task, intro)'
old_call = '_month12_start_panel.open(month, destination, first_task, intro)'
assert old_call in g, 'panel call'
g = g.replace(old_call, '_month12_start_panel.open(month, destination, first_task, intro, today_lines)', 1)

# 在 _start_month_nodes 里找本月第一个带 todayCard 的主线节点
old_pick = '''	var first_story: Dictionary = {}
	for value in month_nodes:
		var node := value as Dictionary
		if String(node.get("nodeType", "main_story")) == "main_story":
			first_story = node
			break'''
new_pick = '''	var first_story: Dictionary = {}
	var today_lines: Array = []
	for value in month_nodes:
		var node := value as Dictionary
		if String(node.get("nodeType", "main_story")) != "main_story":
			continue
		if first_story.is_empty():
			first_story = node
		# "今天"三行挂在本月第一屏上（4.17）：有就拿来当月初卡的正文，
		# 免得一翻月就有一块剧情面板砸下来。
		if today_lines.is_empty():
			var card := node.get("todayCard", {}) as Dictionary
			var lines := card.get("lines", []) as Array
			if not lines.is_empty():
				today_lines = lines.duplicate()'''
assert old_pick in g, 'pick'
g = g.replace(old_pick, new_pick, 1)

old_call2 = '''	_show_month_start(month_value, destination, first_task, intro, func():'''
new_call2 = '''	_show_month_start(month_value, destination, first_task, intro, func():'''
assert old_call2 in g
# 调用改成 today_lines 在 lambda 之前
old_call3 = '_show_month_start(month_value, destination, first_task, intro, func():'
new_call3 = '_show_month_start(month_value, destination, first_task, intro, today_lines, func():'
assert old_call3 in g, 'call3'
g = g.replace(old_call3, new_call3, 1)

