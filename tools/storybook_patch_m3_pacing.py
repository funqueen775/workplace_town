"""册子先改：第 3 月补一节「中旬｜那两周发生了什么」，并把 E12 的入口接上去。"""
import shutil
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import storybook_patch_endings as S  # 这一份的 apply_fix 认 "\n"，会把它拆成新段落

from docx import Document

FIXES = [
    # 时间线那一行补上中旬那一屏
    ("时间线：自由安排放在 E10 散会当天下午；桥段约 18:30 触发，王哥要求的清单次日周四前交；"
     "E12 保留在月末最后一夜。",
     "时间线：自由安排放在 E10 散会当天下午；桥段当天傍晚触发，王哥要求的清单次日周四前交；"
     "下旬那一屏放在两周之后（中旬 · 上午），把这两周发生的事当面演一遍；"
     "E12 接在中旬那一屏的当天傍晚，仍在月末最后一夜之前收口。",
     1, "第3月时间线：补上中旬那一屏的位置"),
    ("旁白：你把“历史问题次数”标成待核，打开组里的《常见问题》文档，准备补上来源。",
     "旁白：你把“历史问题次数”标成待核，打开组里的《常见问题》文档，准备补上来源。\n"
     "屏末交代：今天到这儿。那三行明天跟着版本上线，先看两个星期。",
     1, "第3月 F 桥段：补离屏那句（同区换时段也要交代）"),
    # E12 的入口与那句"三周"
    ("G E12 它记不住中间那段  月末最后一夜，B 区工位；纯剧情，不计分。",
     "G E12 它记不住中间那段  紧接中旬那一屏的当天傍晚，B 区工位；纯剧情，不计分。",
     1, "第3月 E12：时间接上，不再凭空跳到月末"),
    ("旁白：你又打开那份《常见问题》。结论还在，怎么得出结论的过程不在。",
     "旁白：傍晚回工位，你把那份《常见问题》又打开。结论还在，怎么得出结论的过程不在。"
     "小赵把他翻到的东西拖到你屏幕上。",
     1, "第3月 E12 第一拍：接中旬小赵那句"),
    ("旁白：你修了三周的问题没有复发。它只是从来没真正被修过。",
     "旁白：小赵那条线三周里又撞上一次。没人知道以前撞过几次——它不是被修好了，是从来没人记着它。",
     1, "第3月 E12：「修了三周」改成中旬刚演过的那条线"),
]

# 锚点段之后插入新小节
INSERTS = [
    ("屏末交代：今天到这儿。那三行明天跟着版本上线，先看两个星期。",
     ["F1 中旬｜那两周发生了什么（约 1 分钟，B 区工位；走到才开，无选项）",
      "目标行：中旬 · 上午 · B 区工位。路上那行：那三行上线两周了。",
      "旁白：那句兜底上线两个星期了，头一件回来找你的事在这儿。",
      "旁白：散会那天王哥只要了三样东西，你发出去了。这两个星期，它有没有被用上？",
      "【下面三句只显示与 E10 选择相符的一句】",
      "旁白（E10 A 如实说边界）：合同签了。附页那三行兜底是你写的，方经理每周让人来问一次：有没有照做。",
      "旁白（E10 B 签软条款）：合同签了，用的是“尽商业上合理努力”那一句。两个星期里没人来问过这句该怎么算。",
      "旁白（E10 C 先答应）：合同签了。小林把副本传上共享盘，从头到尾没跟你提那天会场上的事。",
      "【下面三句只显示与 E10b 选择相符的一句】",
      "王哥（发到组内）：你那份清单我拿去开了周会。以后散会当天就发，别等到周四。",
      "王哥（只私发）：清单我看到了。下次确认时间那一栏是空的——不给组里看，它就只是我们俩的备忘。",
      "王哥（先不整理）：周四过了，没人来问那份清单。下次散会当天发我，哪怕只写两行。",
      "小赵（隔着半个工位，声音压着）：还是我那条线。三周里又撞上一次，还是没人知道以前撞过几次。"
      "上旬你在群里问那个数，是不是到现在也没人回？",
      "旁白：他把手里的杯子往你桌上一放：傍晚别走，我翻到了一点东西，你一起看。",
      "屏末交代：傍晚回工位，把小赵翻到的那条来源补上。",
      "因果说明：这一屏不评分、不占行动点，只做两件事——把 E10 与 E10b 的选择在下半个月当面用一次"
      "（m03_e10_truth_with_fallback / soft_clause / overpromise 与 "
      "m03_e10_handoff_complete / partial / blank 在这里各有消费者），"
      "并给 E12 一个入口：小赵翻到截图这件事由他当面约，不再凭空出现。"],
     "第3月：新增「F1 中旬」一屏（两周不再是一句旁白）"),
]


def add_route_row(doc):
    """转场副行总表里补一行：第3月 M03_MID 路上那行。"""
    target = None
    for tbl in doc.tables:
        head = " ".join(c.text for c in tbl.rows[0].cells)
        if "去哪儿" in head and "路上那行" in head:
            target = tbl
            break
    if target is None:
        raise SystemExit("[中止] 找不到转场副行总表")
    for row in target.rows:
        if "M03_MID" in row.cells[1].text:
            print("  已有 M03_MID 行，跳过")
            return
    import copy
    from docx.text.paragraph import Paragraph
    new_tr = copy.deepcopy(target.rows[-1]._tr)
    target._tbl.append(new_tr)
    row = target.rows[-1]
    values = ["第3月", "M03_MID", "B 区工位", "那三行上线两周了"]
    for i, cell in enumerate(row.cells):
        if i >= len(values):
            break
        paragraphs = cell.paragraphs
        S.set_text(paragraphs[0], values[i])
        for extra in paragraphs[1:]:
            S.set_text(extra, "")
    print("  表格加行  第3月 M03_MID 转场副行")


def main():
    apply = "--apply" in sys.argv
    doc = Document(str(S.DOCX))
    for old, new, expect, note in FIXES:
        S.apply_fix(doc, old, new, expect, note)
    for anchor, texts, note in INSERTS:
        S.insert_after(doc, anchor, texts, note)
    add_route_row(doc)
    if not apply:
        print("演练通过：加 --apply 才真写。")
        return
    stamp = time.strftime("%Y%m%d_%H%M")
    bak = S.BAK_DIR / f"storybook_backup_{stamp}.docx"
    shutil.copy2(S.DOCX, bak)
    print(f"备份 -> {bak}")
    doc.save(str(S.DOCX))
    print(f"已写回 {S.DOCX}")


if __name__ == "__main__":
    main()
