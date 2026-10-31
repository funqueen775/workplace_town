"""旬首交代：每个旬的第一屏，开头就要说清"谁把你叫到这儿、这一旬欠着哪件事"。

换旬那张卡只有「第 N 月 · 某旬 · 白天」六个字，不代替剧情；上一旬的尾巴又隔了一两周，
玩家第一眼如果是一句无主的旁白，就变成"不知道发生了什么"。
册子与数据同步改，第 3 月先做成样张。
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
BAK = ROOT / "test_artifacts"

BOOK_FIXES = [
    ("剧情开场：除第 1 月入职说明会外，所有剧情都要玩家走到地点才开场；不瞬移、不直接开、不自动开场。",
     "剧情开场：除第 1 月入职说明会外，所有剧情都要玩家走到地点才开场；不瞬移、不直接开、不自动开场。\n"
     "旬首交代：换旬那张卡只有「第几月 · 某旬 · 白天／夜里」六个字，不代替剧情。"
     "所以每个旬的第一屏，第一句要交代两件事——谁把你叫到这儿、这一旬你手上欠着哪件事；"
     "上一旬留下的悬念（谁答应过什么、哪个数还没核）要在这一旬的头一屏被人当面提一次，不能靠玩家自己想起来。"
     "同屏内的一问一答不受这条约束。",
     1, "全年规则：新增「旬首交代」"),
    ("时间线：自由安排放在 E10 散会当天下午；桥段当天傍晚触发，王哥要求的清单次日周四前交；"
     "下旬那一屏放在两周之后（中旬 · 上午）",
     "时间线：自由安排放在 E10 散会当天下午；桥段当天傍晚触发，王哥要求的清单次日周四前交；"
     "中旬那一屏放在两周之后（中旬 · 午后）",
     1, "第3月时间线：把新屏的位置写成中旬午后"),
    ("目标行：中旬 · 上午 · B 区工位。路上那行：那三行上线两周了。",
     "目标行：中旬 · 午后 · B 区工位。路上那行：那三行上线两周了。",
     1, "F1 目标行：上午改午后"),
    ("旁白：那句兜底上线两个星期了，头一件回来找你的事在这儿。",
     "旁白：周会刚散，王哥把笔记本合上，让你留两分钟——上旬那单的合同这两天签了，"
     "散会那天他要的三样东西，他要当面说一句。",
     1, "F1 第一句：有人、有事，不再是一句无主的旁白"),
    ("旁白：散会那天王哥只要了三样东西，你发出去了。这两个星期，它有没有被用上？",
     "旁白：那三行兜底跟着版本上线两个星期了。头一件回来找你的事，就在这两分钟里。",
     1, "F1 第二句：改成落点，不重复提问"),
    ("小赵（隔着半个工位，声音压着）：还是我那条线。",
     "旁白：回到工位，杯子里的咖啡凉了。\n"
     "小赵（声音压着）：还是我那条线。",
     1, "F1 小赵出场前给一句位置交代"),
    ("旁白：月末最后一夜，工位只剩你。那份《常见问题》又打开：结论还在，怎么得出结论的过程不在。"
     "手机亮了一下——中旬那天小赵说的那张截图，他发过来了。",
     "旁白：这一旬你手上只欠一件事：上旬标成「待核」的那个数字，还没有来源。"
     "月末最后一夜，工位只剩你，那份《常见问题》又打开：结论还在，怎么得出结论的过程不在。"
     "手机亮了一下——中旬小赵说的那张截图，他发过来了。",
     1, "第3月 G：下旬第一句先说清这一旬欠着什么"),
]

DATA_FIXES = [
    ("M03_MID", "中旬 · 午后。那句兜底上线两个星期了，头一件回来找你的事在这儿。",
     "周会刚散，王哥把笔记本合上，让你留两分钟——上旬那单的合同这两天签了，"
     "散会那天他要的三样东西，他要当面说一句。"),
    ("M03_MID", "散会那天王哥只要了三样东西，你发出去了。这两个星期，它有没有被用上？",
     "那三行兜底跟着版本上线两个星期了。头一件回来找你的事，就在这两分钟里。"),
    ("E12", "月末最后一夜，工位只剩你。那份《常见问题》又打开：结论还在，怎么得出结论的过程不在。"
            "手机亮了一下——中旬那天小赵说的那张截图，他发过来了。",
     "这一旬你手上只欠一件事：上旬标成「待核」的那个数字，还没有来源。月末最后一夜，工位只剩你，"
     "那份《常见问题》又打开：结论还在，怎么得出结论的过程不在。"
     "手机亮了一下——中旬小赵说的那张截图，他发过来了。"),
]


def patch_data():
    data = json.loads(EVENTS.read_text(encoding="utf-8"))
    nodes = {n.get("id"): n for n in data.get("nodes", []) if isinstance(n, dict)}
    hits = 0
    for node_id, old, new in DATA_FIXES:
        node = nodes.get(node_id)
        if node is None:
            raise SystemExit(f"[中止] 找不到节点 {node_id}")
        done = False
        for beat in node.get("beats") or []:
            if beat.get("text", "") == old:
                beat["text"] = new
                done = True
                hits += 1
                break
        if not done:
            raise SystemExit(f"[中止] {node_id} 里没有这句：{old[:24]}")
    mid = nodes["M03_MID"]
    at = None
    for i, beat in enumerate(mid["beats"]):
        if beat.get("speaker") == "小赵":
            at = i
    if at is None:
        raise SystemExit("[中止] M03_MID 找不到小赵那一拍")
    if "杯子里的咖啡凉了" not in mid["beats"][max(at - 1, 0)].get("text", ""):
        mid["beats"].insert(at, {"type": "narration", "text": "回到工位，杯子里的咖啡凉了。"})
        hits += 1
    print(f"  数据同步 {hits} 处")
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
