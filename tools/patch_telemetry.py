# -*- coding: utf-8 -*-
"""心情账本的埋点补齐：结算事件带上前后值，月末收束发一条快照。"""
import sys

P = r'E:\03_Projects\bear\workplace_town\scripts\WorkplaceTown.gd'
s = open(P, encoding='utf-8', newline='').read().replace('\r\n', '\n')


def rep(old, new, tag):
    global s
    if old not in s:
        sys.exit('MISS %s :: %s' % (tag, old[:60]))
    s = s.replace(old, new, 1)


# 1) 结算前的读数留一下，事件里要写"从几到几"
rep('''var _mood_meter_lit := false''',
    '''## 这一笔结算前的心情读数：事件要写"从几到几"，不能只写结果。
var _mood_before_settle := 0
var _mood_meter_lit := false''', '1')

rep('''	var before := _mood
	_mood = clampi(_mood - cost + gain, 0, _mood_max)
	_refresh_mood_hud()
	return _mood - before''',
    '''	var before := _mood
	_mood_before_settle = before
	_mood = clampi(_mood - cost + gain, 0, _mood_max)
	_refresh_mood_hud()
	return _mood - before''', '2')

# 3) 自由活动事件：补前后值、花掉几点、还剩几格，并且给对 regionId
rep('''func _on_month12_activity_chosen(option_id: String) -> void:
	_month12_flags["activity"] = option_id
	ApiClient.record_event("m%02d_activity" % _month12_month, {"activityId": option_id})''',
    '''func _on_month12_activity_chosen(option_id: String) -> void:
	_month12_flags["activity"] = option_id
	var act := _month12_place_by_id(option_id)
	# regionId 必须是 A–H：传输层缺省会兜到"A"，人在心湖做完一件事却记成总部，
	# 报告侧按组团统计投入结构就全错了。
	ApiClient.record_event("m%02d_activity" % _month12_month, {
		"activityId": option_id,
		"regionId": String(act.get("locationId", "")),
		"apSpent": maxi(0, int(act.get("apCost", 1))),
		"slotsSpent": maxi(1, int(act.get("slots", 1))),
		"moodBefore": _mood_before_settle,
		"moodAfter": _mood,
		"apLeftAfter": _month12_ap_left,
		"slotsLeftAfter": _month12_slots_left if _month12_activity_generic else (0 if _month12_activity_taken else 1),
	})''', '3')

# 4) 主线选项那一笔补上前后值（4a 已单独落盘）
rep('''		ApiClient.record_event("m02_choice", {
			"node": String(node.get("id", "")),
			"choiceId": choice_id,
			"delta": (choice as Dictionary).get("stateDelta", {}),
		})''',
    '''		ApiClient.record_event("m02_choice", {
			"node": String(node.get("id", "")),
			"choiceId": choice_id,
			"delta": (choice as Dictionary).get("stateDelta", {}),
			"moodBefore": mood_before,
			"moodAfter": _mood,
		})''', '4b')

# 5) 月末收束快照：契约里本来就有 weekend_close 这一拍（月份/收束快照），十二个月这条线一直没发
rep('''func _start_month12_close() -> void:
	_month12_phase = "close"
	_settle_sleep_backup()''',
    '''func _start_month12_close() -> void:
	_month12_phase = "close"
	_settle_sleep_backup()
	_emit_month_close_snapshot()''', '5')

rep('''## 入夜那道光刷完之后再开月末回顾卡。''',
    '''## 月末收束快照：报告 8.1 里"自由活动回顾"和七行摘要的"状态行"要的就是这一条。
## 事件名用的是契约里已经注册的 weekend_close（月份 / 收束快照，不测评），
## 十二个月这条线之前一直没发过它。
func _emit_month_close_snapshot() -> void:
	var slept := false
	for entry in _month_ledger:
		if String((entry as Dictionary).get("what", "")) == "睡觉":
			slept = true
	ApiClient.record_event("weekend_close", {
		"month": _month12_month,
		"apBudget": _ap_total,
		"apSpent": _ap_total - _month12_ap_left,
		"apLeft": _month12_ap_left,
		"moodStart": _mood_month_start,
		"mood": _mood,
		"slept": slept,
		"ledger": _month_ledger.duplicate(true),
	})


## 入夜那道光刷完之后再开月末回顾卡。''', '6')

open(P, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n'))
print('telemetry enriched')
