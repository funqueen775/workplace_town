"""开发册同步：转正只判一次（两态）+ 违纪解除（红线），并把待实现清单记进 15.7。"""
import shutil
import sys
import time
from pathlib import Path

DOC = Path(r"E:\03_Projects\bear\十二个月开发文档_V1.md")
BAK_DIR = Path(r"E:\03_Projects\bear\workplace_town\test_artifacts")

EDITS = [
    ("| 做转正、复核、晋升、年度报告 |", "| 做转正、违纪解除、晋升、年度报告 |", 1, "分工表"),
    ("3. 能力证据轨与 M6 转正、M7 补复核、M12 年度晋升。",
     "3. 能力证据轨与 M6 转正（一次定两态）、M12 年度晋升；M7 不判定，只交接。", 1, "总目标"),
    ('{"id": "M7", "month": 7, "type": "recheck", "onlyIf": "deferred"},',
     '{"id": "M7", "month": 7, "type": "handover", "onlyIf": "probation_status in (not_confirmed, terminated)"},',
     1, "checkpoints：M7 不再是复核"),

    ('    "direct": {"minEach": 3, "minTotal": 14, "requireAllSufficient": true},\n'
     '    "deferred": {"minTotal": 11, "maxTotal": 13, "minThreeAtLeast": 3, "minRemaining": 2},\n'
     '    "nearMiss": {"minTotal": 14, "exactlyOneAtTwo": true},\n'
     '    "notConfirmed": {"anyBelow": 2, "totalBelow": 11}',
     '    "redlinesFirst": true,\n'
     '    "redlines": ["m03_e10_overpromise", "m05_e17_blame_network", "m05_night_hotfix_unlogged"],\n'
     '    "postProbationWarnings": ["m08_e25_observe", "m10_name_kept_by_silence"],\n'
     '    "confirmed": {"minEach": 3, "minTotal": 14},\n'
     '    "notConfirmed": {"anyBelow": 2, "totalBelow": 11, "minObservedDimensions": 3}',
     1, "rubrics 样例：删 deferred 与 nearMiss，红线优先，未转正要举得出证"),

    ('  "m7": {"minShortDimension": 3, "minTotal": 13, "minAnyDimension": 2},',
     '  "m7": {"judgement": false, "handoverOnly": true},', 1, "m7 门槛：不再判定"),

    ('        "deferred_confirmed": {\n          "text": "{name}在第 6 月延期复核，第 7 月确认转正。",\n'
     '          "refs": ["checkpoint:M6", "checkpoint:M7"]\n        },',
     '        "terminated": {\n          "text": "{name}在试用期内违反了事先告知过的制度条文，'
     '公司有记录、有书面理由，双方办完交接后结束劳动合同。",\n'
     '          "refs": ["checkpoint:M6", "redline:flag"]\n        },',
     1, "报告文案：延期确认换成违纪解除"),

    ("| 第 7 月 | `补充复核`（只给延期转正的人看；直接通过者按常规月显示） | `checkpoints[type=recheck]` + `probation_status` |",
     "| 第 7 月 | `交接`（只给未转正或违纪解除的人看；其余按常规月显示） | `checkpoints[type=handover]` + `probation_status` |",
     1, "月度显示：第7月不叫补充复核"),

    ('    probation_status: str = "pending"   # pending / confirmed / deferred / not_confirmed',
     '    probation_status: str = "pending"   # pending / confirmed / not_confirmed / terminated',
     1, "RunState 字段枚举"),

    ("   - M7：仅 `probation_status=deferred`；",
     "   - M7：`probation_status` 为 `not_confirmed` 或 `terminated` 时走交接，不产生新判定；", 1, "检查点触发条件"),

    ("4. 按规则表判定 `confirmed` / `deferred` / `not_confirmed`。",
     "4. 按规则表判定 `terminated` / `not_confirmed` / `confirmed`（顺序见下）。", 1, "M6 流程第 4 步"),

    ("1. 任一维 `<2` → `not_confirmed`。\n"
     "2. 任一维 `insufficient`：\n"
     "   - 其余维都 `>=2` → `deferred`；\n"
     "   - 另有维 `<2` → `not_confirmed`。\n"
     "3. 四维都 `sufficient`：\n"
     "   - 每维 `>=3` 且总分 `>=14` → `confirmed`；\n"
     "   - 总分 `14` 但恰好一维 `=2`，其余三维 `>=3` → `deferred`（近失带）；\n"
     "   - 总分 `11–13`，至少三维 `>=3`，剩余 `>=2` → `deferred`；\n"
     "   - 其余 → `not_confirmed`。",
     "1. 先看红线：`redlines` 三个旗标里任意一个为真 → `terminated`，不进分数计算。\n"
     "2. 再看举证：有充分观察（>=2 条跨月证据）的维度不足 3 个 → 不得判未转正，直接 `confirmed`，"
     "缺的维度写进证据缺口。\n"
     "3. 举证充分才比分数：任一维 `<2`、或两维及以上 `<3`、或总分 `<11` → `not_confirmed`；否则 `confirmed`。\n"
     "4. 近失带（总分 `>=14` 但恰好一维 `=2`）并入 `confirmed`，弱维进书面材料，不再延期。",
     1, "判定顺序：红线优先 + 举证门 + 两态"),

    ("“未纠正的重大隐瞒”单独检查：直接转正与延期复核都要求不存在未纠正的重大隐瞒；若存在，只能判 `not_confirmed`。",
     "“未纠正的重大隐瞒”单独检查：它走红线，不走分数；若到评审时仍未纠正，判 `terminated`。",
     1, "重大隐瞒归红线"),

    ("### 7.4 M7\n\n只在 `probation_status=deferred` 时出现，且只出现一次。\n\n"
     "1. 找最低分或 `insufficient` 的维度。\n"
     "2. 从 `rubrics.json` 的 `m7Samples` 选对应样例。\n"
     "3. 新样例是独立节点，有 3 个选项，锚点 3/2/1；不重播原题。\n"
     "4. 复核判定：短板维 `>=3`、总分 `>=13`、无任何维 `<2` → `confirmed`；否则 `not_confirmed`。\n"
     "5. M7 通过不改职级；M7 未通过，完成交接后进入未转正结局，不开放 M8–M12 在职主线。",
     "### 7.4 M7（不判定，只交接）\n\n本版没有第二次判定：试用期不得延长、同一单位对同一人只约定一次试用期，"
     "所以第六月的结论就是结论。M7 按 `probation_status` 分三种走法：\n\n"
     "1. `confirmed`：照常进第八月；E19 与训练谷按现有节点。\n"
     "2. `not_confirmed`：交接清单逐项对文档 / 待办 / 权限，然后给一份短收束，不开放 M8–M12。\n"
     "3. `terminated`：同上交接，但纸上的内容换成解除理由三行（违反哪条制度、记录是哪个月哪件事、经办人与日期）。"
     "两版都写 `employment_arc=ended`。\n"
     "4. 短收束不是年度报告：只列已经发生的事实、差在哪一维或哪一条、下一步建议。"
     "第十二月末那份完整报告只对走完十二个月的人开放。",
     1, "7.4 整节改写"),

    ("| 其余（含 M11.C、未转正、M7 未通过） | 未获提名面谈 |",
     "| 其余（含 M11.C 照原文提交） | 未获提名面谈 |", 1, "M12 分流：去掉 M7 未通过"),

    ("- [ ] M6 能输出 confirmed/deferred/not_confirmed，且理由可追到 evidence_id。",
     "- [ ] M6 只判一次，能输出 confirmed / not_confirmed / terminated，"
     "且理由可追到 evidence_id 或红线旗标。",
     1, "15.1 验收：判定口径"),

    ("- [ ] M7 只对 deferred 开放一次，通过不改职级。",
     "- [ ] M7 不再判定：`not_confirmed` 与 `terminated` 都走交接 + 短收束；`confirmed` 正常进 M8。\n"
     "- [ ] 阈值一律从 `rubrics.json` 读，代码里不写死 14/13/≥3 这些数。",
     1, "15.1 验收：M7 与阈值"),
]

SECTION = """
### 15.7 2026-10-30 出局与红线：本轮定下的口径

现实核对（劳动合同法）：试用期被证明不符合录用条件可以解除且无需补偿（第三十九条第一项）；
试用期同一单位只能约定一次、不得延长（第十九条）。所以：

1. 「第六月判 + 第七月复核」这个结构本身站不住——第七月已经在试用期外。本版改成**转正只判一次**，
   结论两种：转正、未转正。`deferred` 从三册里删除。
2. 会让人中途走的不是分数，是**违纪解除**：三条红线（第3月超授权承诺、第5月把现场问题说成网络波动、
   第5月绕审批改线上又不补记录），必须先在第1月入职说明会上当众讲过才生效，第六月评估时先查红线再查分。
   第8月压着不报、第10月默许不实署名这两件发生在转正之后，本版只判书面警告并记档，不结束主线。
3. 停在第七月的人必须有**短收束**（只写已发生事实 + 差在哪 + 下一步建议），
   否则总览那句「所有玩家获得年度收束」是假的。年度报告仍只对走完十二个月的人开放。

已写进册子：剧情册（全年规则两态与红线条、第1月说明会、第6月答辩顺序、第7月 A/B 段、手册 3.2、
分支与触发条件总表）；算法册（5.5 判定表、5.6 红线、结局矩阵、样例 B、测试用例、统计口径）。

留给工程的，按顺序：

- [ ] `rubrics.json` 的 `m6` 换成红线优先 + 两态门槛，客户端与后端都从它读，删掉写死在
      `WorkplaceTown.gd::_evaluate_probation` 与 `_evaluate_promotion` 里的 14 / ≥3。
- [ ] `_evaluate_probation` 输出第三态 `terminated`；`_end_year_early()` 目前对所有延期者触发，
      改成只在 `not_confirmed` / `terminated` 触发，并按两种理由分版。
- [ ] `events.json` 里读 `m07_probation_deferred` 的门（E19、M07_PAPER、M07_HANDOVER）全部换成读
      `probation_status`；第7月不再有任何「复核」文案。
- [ ] 红线三条要有可见反馈：第1月说明会那一屏、触发当月的结果便签要写清这是线不是分。
- [ ] 短收束一屏（未转正 / 违纪解除共用），含 `employment_arc=ended` 的写入点。
- [ ] `MonthJump` 要能造出 `terminated` 与 `not_confirmed` 两条路径，否则 F8 跳月看片看不到这两个结局。
- [ ] 第十二月晋升判定（本版仍写按第六月基线）改按算法册的规则表，并让未提名的人也跑一次判定，
      不然 `m12_not_passed` 永远不为真。

"""


def main():
    apply = "--apply" in sys.argv
    text = DOC.read_text(encoding="utf-8")
    original = text
    for old, new, expect, note in EDITS:
        got = text.count(old)
        if got != expect:
            raise SystemExit(f"[中止] {note}：应出现 {expect} 次，实际 {got} 次 -> {old[:44]}")
        text = text.replace(old, new)
        print(f"  × {got}  {note}")
    anchor = "\n---\n\n## 16. 未决项与默认处理"
    if text.count(anchor) != 1:
        raise SystemExit(f"[中止] 15.7 插入锚点异常：{text.count(anchor)}")
    text = text.replace(anchor, "\n" + SECTION + anchor)
    print("  插入  15.7 出局与红线：口径与待实现清单")
    if not apply:
        print("演练通过：加 --apply 才真写。")
        return
    stamp = time.strftime("%Y%m%d_%H%M")
    (BAK_DIR / f"devdoc_backup_{stamp}.md").write_text(original, encoding="utf-8")
    print(f"备份 -> devdoc_backup_{stamp}.md")
    DOC.write_text(text, encoding="utf-8")
    print(f"已写回 {DOC}")


if __name__ == "__main__":
    main()
