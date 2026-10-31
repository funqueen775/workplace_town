"""第 3 月节奏补丁的修正轮：一个月只能有一句目标行；E12 仍留在月末最后一夜，
但入口改成中旬那一屏约下的那张截图（不再凭空出现）。"""
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
BAK = ROOT / "test_artifacts"

BOOK_FIXES = [
    ("E12 接在中旬那一屏的当天傍晚，仍在月末最后一夜之前收口。",
     "E12 仍在月末最后一夜，但开场那句接的是中旬小赵当面约下的那张截图。",
     1, "时间线：E12 回到月末最后一夜"),
    ("G E12 它记不住中间那段  紧接中旬那一屏的当天傍晚，B 区工位；纯剧情，不计分。",
     "G E12 它记不住中间那段  月末最后一夜，B 区工位；纯剧情，不计分。",
     1, "E12 小节标题还原时间口径"),
    ("旁白：傍晚回工位，你把那份《常见问题》又打开。结论还在，怎么得出结论的过程不在。"
     "小赵把他翻到的东西拖到你屏幕上。",
     "旁白：月末最后一夜，工位只剩你。那份《常见问题》又打开：结论还在，怎么得出结论的过程不在。"
     "手机亮了一下——中旬那天小赵说的那张截图，他发过来了。",
     1, "E12 第一拍：时间不动，来源接中旬"),
    ("屏末交代：傍晚回工位，把小赵翻到的那条来源补上。",
     "屏末交代：这两周的事先到这儿。那张截图还没找着，找着了小赵会发你。",
     1, "中旬那一屏的离屏句：不再暗示当天傍晚"),
    ("旁白：他把手里的杯子往你桌上一放：傍晚别走，我翻到了一点东西，你一起看。",
     "旁白：他把杯子留在你桌上：截图他还没翻着，翻着了发你。",
     1, "中旬那一屏倒数第二拍同步"),
]

BOOK_INSERT_NOTE = ("因果说明：这一屏不评分、不占行动点，只做两件事",
                    "，并给 E12 一个入口：小赵翻到截图这件事由他当面约，不再凭空出现。"
                    "E12 仍在月末最后一夜——中间隔的是半个月，不是一句旁白。")


def patch_data():
    data = json.loads(EVENTS.read_text(encoding="utf-8"))
    nodes = {n.get("id"): n for n in data.get("nodes", []) if isinstance(n, dict)}
    mid = nodes.get("M03_MID")
    e12 = nodes.get("E12")
    if mid is None or e12 is None:
        raise SystemExit("[中止] 节点缺失")
    changed = 0
    # ① 目标行只留月初那一句
    if mid["beats"][0].pop("goalLine", None) is not None:
        changed += 1
    # ② 上午 → 午后（这一屏的 timeBand 是 afternoon）
    for beat in mid["beats"]:
        if beat.get("text", "").startswith("中旬 · 上午。"):
            beat["text"] = beat["text"].replace("中旬 · 上午。", "中旬 · 午后。")
            changed += 1
    # ③ 离屏句与倒数第二拍
    for beat in mid["beats"]:
        text = beat.get("text", "")
        if "傍晚别走，我翻到了一点东西" in text:
            beat["text"] = "旁白：他把杯子留在你桌上：截图他还没翻着，翻着了发你。这两周的事，先到这儿。"
            if beat.get("type") == "narration":
                pass
            changed += 1
    for beat in e12["beats"]:
        if beat.get("text", "").startswith("傍晚回工位，你把那份《常见问题》又打开"):
            beat["text"] = ("月末最后一夜，工位只剩你。那份《常见问题》又打开：结论还在，"
                            "怎么得出结论的过程不在。手机亮了一下——中旬那天小赵说的那张截图，他发过来了。")
            changed += 1
    if changed < 3:
        raise SystemExit(f"[中止] 数据只改了 {changed} 处，锚点没对上")
    print(f"  数据改动 {changed} 处")
    return data


def main():
    apply = "--apply" in sys.argv
    doc = Document(str(S.DOCX))
    for old, new, expect, note in BOOK_FIXES:
        S.apply_fix(doc, old, new, expect, note)
    data = patch_data()
    if not apply:
        print("演练通过：加 --apply 才真写。")
        return
    stamp = time.strftime("%Y%m%d_%H%M")
    shutil.copy2(S.DOCX, S.BAK_DIR / f"storybook_backup_{stamp}.docx")
    shutil.copy2(EVENTS, BAK / f"events_backup_{stamp}.json")
    doc.save(str(S.DOCX))
    EVENTS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"已写回 剧情册.docx 与 events.json（备份 stamp={stamp}）")


if __name__ == "__main__":
    main()
