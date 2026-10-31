# -*- coding: utf-8 -*-
"""月末回宿舍睡一觉，再翻月。"""
p = r'E:\03_Projects\bear\workplace_town\scripts\WorkplaceTown.gd'
s = open(p, encoding='utf-8', newline='').read().replace('\r\n', '\n')


def rep(old, new, tag, count=1):
    global s
    if old not in s:
        raise SystemExit('MISS ' + tag)
    s = s.replace(old, new, count)


rep('var _walk_skip_offered := false',
    'var _walk_skip_offered := false\n'
    '## 回宿舍那一夜：记着睡的是哪个月，睡醒翻到下一个月。\n'
    'var _month12_sleep_month := 0', 'state')

rep('\t_show_reminder_toast("第 %d 月完成" % finished_month, "月历和档案入口已开放；本月选择与行动已保存")\n'
    '\t_date_then(finished_month + 1, "early", "morning", func(): _start_month_nodes(finished_month + 1))',
    '\t_show_reminder_toast("第 %d 月完成" % finished_month, "把这个月收好，回去睡一觉")\n'
    '\t# 最后一个月不睡：那天之后是年度报告，不是下个月。\n'
    '\tif finished_month >= 12:\n'
    '\t\t_date_then(finished_month + 1, "early", "morning", func(): _start_month_nodes(finished_month + 1))\n'
    '\t\treturn\n'
    '\t_start_sleep_walk(finished_month)\n'
    '\n'
    '\n'
    '## 月末不回工位直接翻月：先走回宿舍，进门熄灯，睡完才开下个月。\n'
    '## 宿舍用现成的 H 区内景，不新做美术；走位有兜底（30 秒提示、60 秒自动带到门口）。\n'
    'func _start_sleep_walk(finished_month: int) -> void:\n'
    '\tvar zone := _zone_by_code("H")\n'
    '\tif zone.is_empty():\n'
    '\t\t_date_then(finished_month + 1, "early", "morning", func(): _start_month_nodes(finished_month + 1))\n'
    '\t\treturn\n'
    '\tvar door: Vector2 = _snap_month12_point(zone.get("entrance", Vector2.ZERO))\n'
    '\t_month12_sleep_month = finished_month\n'
    '\t_month12_waypoint = door\n'
    '\t_month12_phase = "sleep_walk"\n'
    '\t_walk_started_msec = Time.get_ticks_msec()\n'
    '\t_walk_skip_offered = false\n'
    '\tif _player != null and _player.position.distance_to(door) > 620.0:\n'
    '\t\t_player.position = _approach_point(door)\n'
    '\tif _town_ui_v2 != null:\n'
    '\t\t_town_ui_v2.set_task_card("回宿舍", "慢生活园 · 宿舍与桌游馆")\n'
    '\t\t_town_ui_v2.set_task_note("回去睡一觉，明天再继续")\n'
    '\t_set_objective("第 %d 月" % finished_month, "慢生活园 · 宿舍", "回去睡一觉", "", false)\n'
    '\tif _guide_line != null and _player != null:\n'
    '\t\t_guide_line.set_path(_build_guide_path(_player.position, door))\n'
    '\n'
    '\n'
    '## 到了宿舍门口：进门、熄灯、翻月。那两秒停顿是让"这一夜过去了"有实感。\n'
    'func _do_sleep() -> void:\n'
    '\tif _month12_phase != "sleep_walk":\n'
    '\t\treturn\n'
    '\tvar month := _month12_sleep_month\n'
    '\t_month12_phase = "done"\n'
    '\t_month12_waypoint = Vector2(-99999, -99999)\n'
    '\tif _guide_line != null:\n'
    '\t\t_guide_line.clear()\n'
    '\tvar zone := _zone_by_code("H")\n'
    '\tif not zone.is_empty():\n'
    '\t\t_enter_month12_interior(zone, "")\n'
    '\t_show_reminder_toast("熄灯", "今天到这儿。明天再来。")\n'
    '\tawait get_tree().create_timer(1.8).timeout\n'
    '\t_exit_zone()\n'
    '\t_date_then(month + 1, "early", "morning", func(): _start_month_nodes(month + 1))', 'close')

# 走位兜底：sleep_walk 也算
rep('\tif _month12_phase == "node_walk" and not _month12_reading()',
    '\tif _month12_phase in ["node_walk", "sleep_walk"] and not _month12_reading()', 'fb-phase', count=2)
rep('\t\t\tand _walk_fallback_enabled()',
    '\t\t\tand (_walk_fallback_enabled() or _month12_phase == "sleep_walk")', 'fb-enabled')

rep('\t\tif _month_runner != null:\n\t\t\t_month_runner.on_walk_arrived()\n\t\treturn',
    '\t\tif _month12_phase == "sleep_walk":\n\t\t\t_do_sleep()\n\t\t\treturn\n'
    '\t\tif _month_runner != null:\n\t\t\t_month_runner.on_walk_arrived()\n\t\treturn', 'fb-arrive')

rep('\t\t"node_walk":\n\t\t\tif _month_runner != null:\n\t\t\t\t_month_runner.on_walk_arrived()',
    '\t\t"node_walk":\n\t\t\tif _month_runner != null:\n\t\t\t\t_month_runner.on_walk_arrived()\n'
    '\t\t"sleep_walk":\n\t\t\t_do_sleep()', 'match')

open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n'))
print('回宿舍睡觉已接')
