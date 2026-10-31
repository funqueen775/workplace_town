# -*- coding: utf-8 -*-
"""心情读数的登场节奏 + 睡觉兜底。"""
import json
import sys

P = r'E:\03_Projects\bear\workplace_town\scripts\WorkplaceTown.gd'
s = open(P, encoding='utf-8', newline='').read().replace('\r\n', '\n')


def rep(old, new, tag):
    global s
    if old not in s:
        sys.exit('MISS %s :: %s' % (tag, old[:60]))
    s = s.replace(old, new, 1)


# A) 首月不亮读数
rep('''		# 十二个月这条线：那罐蜂蜜是心情 H，不是体力。
		_town_ui_v2.set_energy_visible(true)''',
    '''		# 那罐蜂蜜是心情 H，不是体力。首月不亮：这个月没有任何东西会扣心情，
		# 摆一个不会动的读数上去，等于让玩家盯一件没有后果的事。
		# 第 2 月月初起账时它才登场（见 _begin_month_ledger）。
		_town_ui_v2.set_energy_visible(false)''', 'A')

# B) 读数状态位
rep('''var _mood_h_init := -1''',
    '''var _mood_h_init := -1
## 心情读数亮不亮、以及"这个月刚亮起来"没有：亮起来这件事要搭在本来就要弹的那条提示上，
## 不另开一次停顿（解锁预算）。
var _mood_meter_lit := false
var _mood_meter_just_lit := false''', 'B')

# C) 起账时决定亮不亮
rep('''	_mood_month_start = _mood
	_ap_total = int(_ap_by_month.get(month_value, 0))''',
    '''	_mood_month_start = _mood
	# 读数第 2 月登场：那个月第一次出现"选它会累"（评审室那一档 −1），
	# 有了后果再给读数，顺序不能反。
	var show_meter := month_value >= 2
	if show_meter and not _mood_meter_lit:
		_mood_meter_just_lit = true
	_mood_meter_lit = show_meter
	if _town_ui_v2 != null:
		_town_ui_v2.set_energy_visible(show_meter)
	_ap_total = int(_ap_by_month.get(month_value, 0))''', 'C')

# D) 手册提示捎带上罐子
rep('''	_show_reminder_toast("手册有新页", "第一章后几页散开了，右下角能翻")''',
    '''	var sub := "第一章后几页散开了，右下角能翻"
	if _mood_meter_just_lit:
		# 不另开一次停顿：顶上那罐亮起来这件事，搭在这条本来就要弹的提示上。
		sub = "多了几页；顶上那罐也亮了——它是心情"
		_mood_meter_just_lit = false
	_show_reminder_toast("手册有新页", sub)''', 'D')

# E) 睡觉兜底
rep('''func _start_month12_close() -> void:
	_month12_phase = "close"''',
    '''func _start_month12_close() -> void:
	_month12_phase = "close"
	_settle_sleep_backup()''', 'E1')

rep('''## 入夜那道光刷完之后再开月末回顾卡。''',
    '''## 睡觉兜底：心情 ≤1 而这个月还有没花掉的格子时，那些格子自动拿去睡觉，每格回 1 点。
## 只在玩家没花的时候发生——想硬扛的人照样能把格子花出去，它不抢选择。
## 回的是 1 点，跟天台一样：如果睡觉回得比专门跑一趟天台还多，天台那页卡就白写了。
func _settle_sleep_backup() -> void:
	var left := 0
	if _month12_activity_generic:
		left = _month12_slots_left
	elif not _month12_activity_taken:
		left = 1
	if left <= 0 or _mood > 1:
		return
	var before := _mood
	_mood = mini(_mood_max, _mood + left)
	_record_ledger("睡觉", 0, _mood - before)
	_refresh_mood_hud()


## 入夜那道光刷完之后再开月末回顾卡。''', 'E2')

open(P, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n'))

# F) 第 2 月的手册节点：把新页 1.5 一起解锁（读数讲的就是这一页）
#    只做定点插入，不整档重写——这个文件是 prettier 口径，重排会产生一屏无意义 diff。
Q = r'E:\03_Projects\bear\workplace_town\data\story\v12m\events.json'
raw = open(Q, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in raw else '\n'
t = raw.replace('\r\n', '\n')
old = '''        {
          "pageId": "1.4",
          "title": "每一次调用都在花钱",
          "bodyKey": "tech.1.4"
        }'''
new = '''        {
          "pageId": "1.4",
          "title": "每一次调用都在花钱",
          "bodyKey": "tech.1.4"
        },
        {
          "pageId": "1.5",
          "title": "你还有没有余力",
          "bodyKey": "tech.1.5"
        }'''
if old not in t:
    sys.exit('MISS F')
t = t.replace(old, new, 1)
open(Q, 'w', encoding='utf-8', newline='').write(t.replace('\n', nl))
import json
json.loads(open(Q, encoding='utf-8').read())
print('engine + handbook node updated')
