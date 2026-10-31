"""第 4 月的旬界：上旬→中旬补「两周后」+ 旬首第一拍，中旬→下旬补一屏。

用户实况（2026-10-30 晚）：「第四个月的上中下旬没有什么衔接」。
根因两条：
1. 第 4 月两个旬界卡的 gapText 都是空的，旬卡只剩「中旬」「下旬」六个字；
   E05 → M04_NOTICE 还同区同时段，收尾句兜底直接跳过，屏末一句都没有。
2. 下旬根本没有屏：M04_PHONE（中旬·夜里）之后直接开月末卡。

册子先改，数据和 manifest 跟着改。默认演练，加 --apply 才写。
"""
import json
import shutil
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import storybook_patch_endings as S

from docx import Document

ROOT = Path(r"E:\03_Projects\bear\workplace_town")
EVENTS = ROOT / "data" / "story" / "v12m" / "events.json"
MANIFEST = ROOT / "data" / "story" / "v12m" / "manifest.json"
BAK = ROOT / "test_artifacts"

# ---------------------------------------------------------------- 册子

NOTICE_A_OLD = ("旁白（E05 A）：两周。你把41条工单整理并扩展成118条测试记录，其中9条仍无法复现。"
                "小林负责的第二期移到了下月，看板上登记的排期调整人是王哥。")
NOTICE_A_NEW = ("旁白：中旬，周一早上。桌上多了一张打印纸。\n"
                "旁白（E05 A）：表挂在共享表最上面。第二期移到下月，看板上登记的调整人是王哥。")

NOTICE_B_OLD = "旁白（E05 B）：两周。这单按时交了，陈工把需求数往前推了一格。评测表还没填表头。"
NOTICE_B_NEW = "旁白（E05 B）：陈工把需求数往前推了一格。评测表还是空的，表头都没填。"

NOTICE_C_OLD = ("旁白（E05 C）：两周。你那张表盖住了物流那一类，另外两类仍没人能证明什么，"
                "第二期也留了一半。")
NOTICE_C_NEW = "旁白（E05 C）：表只盖住物流那一类，另外两类仍没人能证明什么；第二期留了一半。"

BOOK_FIXES = [
    (NOTICE_A_OLD, NOTICE_A_NEW, 1, "第4月 B 段：中旬第一拍报时，删掉与 E05 结果重复的「两周。」"),
    (NOTICE_B_OLD, NOTICE_B_NEW, 1, "第4月 B 段 B 分支：删掉重复的「两周。」"),
    (NOTICE_C_OLD, NOTICE_C_NEW, 1, "第4月 B 段 C 分支：删掉重复的「两周。」"),
    ("F 月末回顾  主句对应 E07，小字对应 E05；自动存档。",
     "G 月末回顾  主句对应 E07，小字对应 E05；自动存档。",
     1, "第4月：月末回顾后移一位，给下旬腾出 F"),
]

LATE_HEAD = "F 下旬｜上旬那句问话的答案（约 40 秒，B 区工位；走到才开，无选项）"
LATE_BODY = [
    "目标行：下旬 · 夜里 · B 区工位。路上那行：回工位，王哥还有一句话问。",
    "旁白：下旬。夜里，工位上还亮着几盏灯。王哥走过来，在你桌边站住。",
    "王哥：纪要我看过了。",
    "旁白（E07 A）：他没提“责任人”那一栏是你自己填的。",
    "旁白（E07 B）：“待定项”后面那三个名字，他一个也没念。",
    "旁白（E07 C）：他没提那天你认下来的那一段。",
    "王哥：上旬问你的那件事，现在能说了吗？",
    "旁白（E05 A）：能。118 条里 9 条复现不了，剩下的能指出坏在哪一类、坏在哪一步。",
    "旁白（E05 B）：说不出来。7 条待复现，每条都只能再找人试一遍。",
    "旁白（E05 C）：物流那一类能说清，另外两类说不了。表上那半页还写着“待补”。",
    "王哥（E05 A）：表留着。以后谁再问，先看表。",
    "王哥（E05 B）：下次先有那张表，再答我。",
    "王哥（E05 C）：把那半页补上，别让它空着。",
    "旁白：他把中旬那张打印纸的边角按平，走了。",
    "屏末交代：月末最后一夜。工位上的灯还亮着，这个月到这儿了。",
]
# 插在 E 段【界面】那句之后、G 月末回顾之前
LATE_ANCHOR = "【界面】 结果页不弹手册、不解释“你答对了”；第三章仍留到第六月末考评后。"

# ---------------------------------------------------------------- 数据

# 数据里原样的三拍（带空格、带「两周。」），用来确认改的是同一版
NOTICE_OLD_BEATS = [
    "两周。你把 41 条工单整理并扩展成 118 条测试记录，其中 9 条仍无法复现。"
    "小林负责的第二期移到了下月，看板上登记的排期调整人是王哥。",
    "两周。这单按时交了，陈工把需求数往前推了一格。评测表还没填表头。",
    "两周。你那张表盖住了物流那一类，另外两类仍没人能证明什么，第二期也留了一半。",
]

NOTICE_BEATS = [
    {"type": "narration", "text": "中旬，周一早上。桌上多了一张打印纸。"},
    {"type": "narration",
     "text": "表挂在共享表最上面。第二期移到下月，看板上登记的调整人是王哥。",
     "when": {"flag": "m04_e05_full_evalset"}},
    {"type": "narration",
     "text": "陈工把需求数往前推了一格。评测表还是空的，表头都没填。",
     "when": {"flag": "m04_e05_no_evalset"}},
    {"type": "narration",
     "text": "表只盖住物流那一类，另外两类仍没人能证明什么；第二期留了一半。",
     "when": {"flag": "m04_e05_partial_evalset"}},
]

LATE_NODE = {
    "id": "M04_LATE",
    "month": 4,
    "order": 245,
    "nodeType": "main_story",
    "required": True,
    "title": "上旬那句问话",
    "locationId": "B",
    "location": "B 区工位",
    "durationMinutes": 10,
    "situation": "weak",
    "autoComplete": True,
    "beats": [
        {"type": "narration", "text": "下旬。夜里，工位上还亮着几盏灯。王哥走过来，在你桌边站住。"},
        {"type": "say", "speaker": "王哥", "text": "纪要我看过了。"},
        {"type": "narration", "text": "他没提“责任人”那一栏是你自己填的。",
         "when": {"flag": "m04_e07_clarified_in_room"}},
        {"type": "narration", "text": "“待定项”后面那三个名字，他一个也没念。",
         "when": {"flag": "m04_e07_process_review"}},
        {"type": "narration", "text": "他没提那天你认下来的那一段。",
         "when": {"flag": "m04_e07_admitted_verification_gap"}},
        {"type": "say", "speaker": "王哥", "text": "上旬问你的那件事，现在能说了吗？"},
        {"type": "narration", "text": "能。118 条里 9 条复现不了，剩下的能指出坏在哪一类、坏在哪一步。",
         "when": {"flag": "m04_e05_full_evalset"}},
        {"type": "narration", "text": "说不出来。7 条待复现，每条都只能再找人试一遍。",
         "when": {"flag": "m04_e05_no_evalset"}},
        {"type": "narration", "text": "物流那一类能说清，另外两类说不了。表上那半页还写着“待补”。",
         "when": {"flag": "m04_e05_partial_evalset"}},
        {"type": "say", "speaker": "王哥", "text": "表留着。以后谁再问，先看表。",
         "when": {"flag": "m04_e05_full_evalset"}},
        {"type": "say", "speaker": "王哥", "text": "下次先有那张表，再答我。",
         "when": {"flag": "m04_e05_no_evalset"}},
        {"type": "say", "speaker": "王哥", "text": "把那半页补上，别让它空着。",
         "when": {"flag": "m04_e05_partial_evalset"}},
        {"type": "narration", "text": "他把中旬那张打印纸的边角按平，走了。"},
    ],
    "choices": [],
    "timeBand": "night",
    "phase": "late",
    "reportUse": "story_only",
    "day": 22,
    "hour": 20,
    "note": "下旬 · 夜里",
    "gapText": "几天后",
    "walkNote": "回工位，王哥还有一句话问",
    "departNote": "月末最后一夜。工位上的灯还亮着，这个月到这儿了。",
}

# 各节点补 id 之外的日期字段：(after_key, [(key, value), ...])
DATE_FIELDS = {
    "M04_OPEN": [("day", 1), ("hour", 9), ("note", "上旬 · 上午")],
    "E05": [("day", 1), ("hour", 9), ("note", "上旬 · 上午")],
    "M04_NOTICE": [("day", 15), ("hour", 9), ("note", "中旬 · 上午"), ("gapText", "两周后")],
    "E07": [("day", 19), ("hour", 10), ("note", "中旬 · 上午")],
    "M04_PHONE": [("day", 19), ("hour", 18), ("whenText", "中旬 · 周五")],
    "M04_CLOSE": [("day", 28), ("hour", 22)],
}


def _insert_after_key(node: dict, anchor: str, pairs: list) -> dict:
    out = {}
    for key, value in node.items():
        out[key] = value
        if key == anchor:
            for name, new_value in pairs:
                if name in node:
                    continue
                out[name] = new_value
    return out


def patch_data():
    data = json.loads(EVENTS.read_text(encoding="utf-8"))
    nodes = data["nodes"]
    by_id = {n.get("id"): n for n in nodes}

    notice = by_id["M04_NOTICE"]
    beats = notice.get("beats") or []
    texts = [b.get("text", "") for b in beats[:3]]
    if texts != NOTICE_OLD_BEATS:
        raise SystemExit(f"[中止] M04_NOTICE 前三拍与预期不符：{texts}")
    notice["beats"] = NOTICE_BEATS + beats[3:]

    for node_id, pairs in DATE_FIELDS.items():
        node = by_id[node_id]
        anchor = "reportUse" if "reportUse" in node else "phase"
        by_id[node_id] = _insert_after_key(node, anchor, pairs)

    if "M04_LATE" in by_id:
        raise SystemExit("[中止] M04_LATE 已存在，先确认是不是已经打过这一版")
    pos = next(i for i, n in enumerate(nodes) if n.get("id") == "M04_PHONE")
    nodes.insert(pos + 1, LATE_NODE)
    # DATE_FIELDS 换的是副本，把新字典写回原数组
    data["nodes"] = [by_id.get(n.get("id"), n) for n in nodes]
    return data


def patch_manifest():
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    order = manifest.get("nodeOrder") or []
    if "M04_LATE" in order:
        print("  manifest.nodeOrder 里已有 M04_LATE，跳过")
        return manifest
    at = order.index("M04_CLOSE")
    order.insert(at, "M04_LATE")
    manifest["nodeOrder"] = order
    return manifest


def main():
    argv = sys.argv[1:]
    apply = "--apply" in argv
    json_out = None
    if "--json-out" in argv:
        json_out = Path(argv[argv.index("--json-out") + 1])

    # 本机 shell 对 workplace_town/ 的写入被挡（见开发册 §15.10），
    # 这里只负责改册子与导出"目标 JSON"；events / manifest 用编辑工具落地。
    doc = Document(str(S.DOCX))
    for old, new, expect, note in BOOK_FIXES:
        S.apply_fix(doc, old, new, expect, note)
    S.insert_after(doc, LATE_ANCHOR, [LATE_HEAD] + LATE_BODY, "第4月：新增下旬一屏")
    # 插进来的那一段是从正文段落复制的，标题那行要换成小标题的样式
    head = [p for p in S.all_paragraphs(doc) if p.text.startswith("F 下旬｜")]
    g_head = [p for p in S.all_paragraphs(doc) if p.text.startswith("G 月末回顾  主句对应 E07")]
    if len(head) != 1 or len(g_head) != 1:
        raise SystemExit(f"[中止] 下旬标题 {len(head)} 处 / G 月末回顾 {len(g_head)} 处")
    head[0].style = g_head[0].style
    print("  下旬小标题样式 ->", head[0].style.name)

    if "--book-only" not in argv:
        data = patch_data()
        manifest = patch_manifest()
        print(f"  数据：M04_NOTICE 改 {len(NOTICE_BEATS)} 拍、新增 M04_LATE、6 个节点补日期")
        print(f"  manifest.nodeOrder：M04_LATE 插在 M04_CLOSE 前（第 {manifest['nodeOrder'].index('M04_LATE') + 1} 位）")
        if json_out is not None:
            json_out.mkdir(parents=True, exist_ok=True)
            (json_out / "events.target.json").write_text(
                json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            (json_out / "manifest.target.json").write_text(
                json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            print(f"  目标 JSON 已导出到 {json_out}")

    if not apply:
        print("演练通过：加 --apply 才真写册子。")
        return
    stamp = time.strftime("%Y%m%d_%H%M")
    bak_dir = Path(r"E:\03_Projects\bear\_bak_20261030_m04xun")
    bak_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(S.DOCX, bak_dir / f"剧情册_{stamp}.docx")
    shutil.copy2(S.DOCX, Path(r"E:\03_Projects\bear") / "剧情册_bak_第四月旬首.docx")
    doc.save(str(S.DOCX))
    print(f"已写回剧情册.docx（备份 __bak_20261030_m04xun/剧情册_{stamp}.docx 与根仓 剧情册_bak_第四月旬首.docx）")


if __name__ == "__main__":
    main()