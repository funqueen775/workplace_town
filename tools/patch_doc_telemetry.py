# -*- coding: utf-8 -*-
"""4.15.4 心情与行动点的埋点对账（谁发、谁收、谁读）。"""
import sys

P = r'E:\03_Projects\bear\十二个月开发文档_V1.md'
s = open(P, encoding='utf-8', newline='').read().replace('\r\n', '\n')

anchor = '### 4.16 自由活动：进门按一件东西'
if anchor not in s:
    sys.exit('MISS 4.16')

block = '''#### 4.15.4 这两本账埋在哪儿、谁读它（2026-10-28 对账）

**发出去的三条**（`tools/shot_ledger.tscn` 第 ⑧b 步直接把本地队列打出来核过）：

| 事件 | 什么时候发 | 带什么 | 契约认不认 |
|---|---|---|---|
| `m01_activity` / `m03_activity`… | 一处自由活动结算完 | activityId、**regionId**（按去处所在区给，不再兜到 A）、apSpent、slotsSpent、**moodBefore → moodAfter**、apLeftAfter、slotsLeftAfter | ✗ 不在 `PlayerEvent.eventType` 枚举里 |
| `m02_choice` | 主线选项确认 | node、choiceId、delta（含 H）、**moodBefore → moodAfter** | ✗ 同上 |
| `weekend_close` | 月末入夜之前（睡觉兜底算完之后） | month、apBudget / apSpent / apLeft、**moodStart → mood**、slept、整月 ledger | ✓ 契约里本来就有这一拍（月份 / 收束快照，**不测评**），十二个月这条线之前一直没发过它 |

**“不在枚举里”意味着什么**：`ApiClient.record_event` 不做本地校验，离线模式下事件只是攒进本地队列——**看起来埋了，联机时服务端按契约拒收**。这跟当年 `handbook_read` 那个坑一模一样（代码里就写着这条教训）。所以要么把名字映射到契约已有的拍子上，要么正式给契约加名。**建议映射**（不新增测评维度，全部落在契约已有的“叙事流补充 / 不测评”那一组）：主线选项 → `option_click`（本来就是“选前状态快照”那一拍）；自由活动 → `explore_click`（“自由周末：活动 / 类型 / 同伴 → 投入结构”）；手机回复 → `npc_dialogue_complete`；地点解锁 → 不发或并进 `event_trigger`。**这一步要后端点头才能改**，因为报告侧按 eventType 分组统计。

**谁读它**：报告 8.1 里两处——`parts[activities].ap {budget, spent, byMonth}` 和七行摘要里的**“状态行”**（`refs: ["activity:m05"]`）。数据源就是上面 `weekend_close` 那条快照。**但 `report_templates.json` 还没建**（校验器第 9 条一直在警告），所以“谁读”目前是个空位：账记对了，还没有人把它算成报告里那句话。状态行的算法（四档形状 + 每句必须带出处）见 4.15.3 与 8.1，尚未实现。

**还欠三条**：① 存档只写不读——`user://workplace_town_month12.json` 每步都写，开局却从不读回来，重启就回到第 1 月、心情 6，这条最影响自己试玩；② 上面那组事件名要落契约；③ 状态行算法与模板。

'''
s = s.replace(anchor, block + anchor, 1)
open(P, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n'))
print('4.15.4 written')
