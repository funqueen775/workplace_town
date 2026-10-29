"""按审计清单就地改剧情册.docx：只改有冲突的句子，并把六张分支图嵌进去。

- 不新建文档：所有改动写回 E:\\03_Projects\\bear\\剧情册.docx
- 每处替换都要求"原文只出现一次"，出现 0 次或多次都报错并中止，避免误改
- 插入的段落复制相邻段落的格式，尽量不改字号字体

用法：python tools/storybook_patch.py --dry     # 只演练，打印改动
      python tools/storybook_patch.py --apply   # 真写
"""
from __future__ import annotations

import copy
import sys
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.shared import Inches
from docx.table import Table
from docx.text.paragraph import Paragraph

DOCX = Path(r"E:\03_Projects\bear\剧情册.docx")
CHARTS = Path(__file__).resolve().parents[1] / "test_artifacts" / "storybook_charts"


# ---------------------------------------------------------------- 改文

# (原文, 新文, 说明)
REPLACE: list[tuple[str, str, str]] = [
    ("E E02 第一次被轻视 时间：入职后第一次跨组周会；作为月中必达事件。",
     "E E02 第一次被轻视 时间：入职后第二次跨组周会；作为月中必达事件。",
     "第1月：E02 场次改成第二次，与下一句一致"),
    ("旁白：第二次跨组周会。排期表上没有你的名字，尽管上周那份方案是你整理的。",
     "旁白：第二次跨组周会。上一次你坐在最后一排，只记了纪要；这一次排期表上没有你的名字，尽管上周那份方案是你整理的。",
     "第1月：补出第一次周会，交代为什么是第二次"),
    ("旁白：行动栏显示 2 个行动点。三个去处可重复到访，本月最多两次；同一位 NPC 当月最多主动约见一次。重复到访不重复结算属性、恢复或剧情旗标。",
     "旁白：行动栏显示 2 个行动点。四个去处可重复到访，本月最多两次；同一位 NPC 当月最多主动约见一次。重复到访不重复结算属性、恢复或剧情旗标。",
     "第3月：去处由三处改为四处（与首月三处、实装一致）"),
    ("【界面】 B 区组内小工具：消耗 1 点。A 区天台：消耗 1 点，也占一个去处名额。C 区水巷咖啡：消耗 1 点。",
     "【界面】 B 区组内小工具：消耗 1 点。A 区天台：消耗 1 点，也占一个去处名额。C 区水巷咖啡：消耗 1 点。心湖木栈道：消耗 1 点。",
     "第3月：面板补上湖边，四处对齐"),
    ("旁白：助手停了两秒，然后告诉客户：“公司支持情绪退款，只要用户感觉受伤，就能全额赔付。”",
     "旁白：助手停了两秒，然后告诉客户：“按我们的新规则，这一单可以直接免单，不需要审批。”",
     "第5月：助手承诺改成“免单”，与第7月复盘同一件事"),
    ("客户：合同里不是写着不会胡说吗？",
     "【界面】以下三句只显示与第 3 月 E10 选择相符的一句。",
     "第5月：客户那句改成按第3月三版显示"),
    ("产品同事：客户说机器人答应免单。需求里只写了安抚，没有人批过这个额度。",
     "产品同事：这条话术不是客户问出来的。有人照着步骤一句一句喂进去，助手就把整套说法都说完了。",
     "第8月：换掉从第7月搬来的免单台词"),
    ("【界面】本周有三格个人时间，六个去处开放；玩家可进行三次到访，地点可重复；同一位 NPC 当月最多主动约见一次；同一活动 ID 的属性、恢复和剧情旗标每月只结算一次。书院是新地点，去过才触发第三周的交接场景。",
     "【界面】本周有三格个人时间，六个去处开放；玩家可进行三次到访，地点可重复；同一位 NPC 当月最多主动约见一次；同一活动 ID 的属性、恢复和剧情旗标每月只结算一次。书院一楼的长桌本月第一次开放，去过才触发第三周的交接场景。",
     "第9月：“书院是新地点”改为“一楼长桌本月第一次开放”（第2月已进过书院二楼）"),
    ("小赵：也可能是周老师忘了。反正我还是实习生，名字写谁好像都差不多。",
     "小赵：也可能是周老师忘了。反正我还没转正，名字写谁好像都差不多。",
     "第9月：小赵身份与第6月同一批答辩对齐（未转正，不再说“实习生”）"),
    ("陈工：上旬，十点，A 区小会议室。十分钟，不用做 PPT，四页以内。去年有人做了十二页。",
     "陈工：中旬，上午，A 区小会议室。十分钟，不用做 PPT，四页以内。去年有人做了十二页。",
     "第6月：答辩挪到中旬，会前准备回到上旬"),
    ("旁白：中旬的一个下午，心湖北岸没什么人。你沿着木栈道走到那面记忆墙前。",
     "旁白：上旬的一个下午，心湖北岸没什么人。你沿着木栈道走到那面记忆墙前。",
     "第6月：会前准备改回上旬"),
    ("【交互】玩家翻到表格背面。背面空白。目标行显示“中旬 · 午后 · 心湖北岸”，作为答辩的会前准备。",
     "【交互】玩家翻到表格背面。背面空白。目标行显示“上旬 · 午后 · 心湖北岸”，作为答辩的会前准备。",
     "第6月：目标行与小节标题同步"),
    ("【场景】上旬 · 上午。正式评估人是陈工；HRBP 负责流程和记录；",
     "【场景】中旬 · 上午。正式评估人是陈工；HRBP 负责流程和记录；老周作为资深同事列席、可追问工作细节；王哥作为带教旁听，不参与打分，只有被问到时发言。",
     "第6月：答辩场景改到中旬"),
    ("旁白：那是你上个月写的交接文档。",
     "旁白（第九月 E28 写过交接文档时）：那是你上个月写的交接文档。",
     "第10月：开场那句改成条件句（写全/留一手时）"),
    ("属性变化：S +2，O -1，H -1，风险 -2，生命 -1，CFC +2。  旗标：m04_e05_full_evalset",
     "属性变化：S +2，O -1，H -1，风险 -2，身体负担 +1，CFC +2。  旗标：m04_e05_full_evalset",
     "第4月：生命 → 身体负担（全册统一一个名字）"),
    ("【界面】 只在 E05.A 实际造成生命 -1 时显示生命变化；不为 B、C 假造数值。",
     "【界面】 只在 E05.A 实际造成身体负担 +1 时才显示这一栏；本版身体负担不单独上界面，只在材料与报告里作为事实引用。",
     "第4月：界面说明同步"),
    ("生命、身体负担与行动点分开记录。",
     "身体负担与行动点分开记录（本版身体负担只记录，不上界面）。",
     "全年规则：删掉未启用的“生命”这一轨"),
    ("H为心理余量（界面称心情），生命和身体负担单独记录。首月只教学行动点，不同时显示H或身体状态条。",
     "H为心理余量（界面称心情），身体负担单独记录（本版不上界面）。首月只教学行动点，不同时显示H或身体负担。",
     "第1月：同上，字段口径统一"),
    ("旁白：第 2 月 · 上旬。B 区工位，早上九点。",
     "旁白：第 2 月 · 上旬。B 区工位，上午。",
     "第2月：正文不写钟点"),
    ("第七天 十一点 旁白：你已把书院查到的旧记录与本周验证分开，方案里补上了能执行的回滚步骤。你手上有能带去评审的东西了。",
     "第七天 夜里 旁白：你已把书院查到的旧记录与本周验证分开，方案里补上了能执行的回滚步骤。你手上有能带去评审的东西了。",
     "第2月：字卡标题不写钟点"),
    ("D E03 AI 代码标注  第七天夜里十一点，B 区工位；目标约 2 分钟。",
     "D E03 AI 代码标注  上旬末的夜里，B 区工位；目标约 2 分钟。",
     "第2月：小节标题不写钟点"),
    ("G E12 它记不住中间那段  月末最后一夜 23:00，B 区工位；纯剧情，不计分。",
     "G E12 它记不住中间那段  月末最后一夜，B 区工位；纯剧情，不计分。",
     "第3月：小节标题不写钟点"),
    ("A 第 1 周 工位上的工单  周一 09:00，B 区科技丘工位；当面开场，不用手机。",
     "A 第 1 周 工位上的工单  上旬 · 上午，B 区科技丘工位；当面开场，不用手机。",
     "第4月：小节标题不写星期与钟点"),
    ("B 周四深夜 02:10 科技丘 夜间故障  版本的日期和月份从当前存档读取；不要把第 5 月写死在黑场中。",
     "B 深夜 科技丘 夜间故障  版本的日期和月份从当前存档读取；不要把第 5 月写死在黑场中。",
     "第5月：小节标题不写星期与钟点"),
    ("C 周五下午 14:00 会展码头 客户 Demo  E17 客户现场；夜间选择影响一条旁白。",
     "C 下午 会展码头 客户 Demo  E17 客户现场；夜间选择影响一条旁白。",
     "第5月：同上"),
]

# 表格里的替换（单元格整格替换）
CELL_REPLACE: list[tuple[str, str, str]] = [
    ("D 区 · 书院长桌（新）", "D 区 · 书院长桌（本月新开）", "第9月：表33 不再叫“新地点”"),
    ("去过触发 E28；新地点的行动点成本须在活动表统一确认。",
     "去过触发 E28；本月新开的去处，成本在活动表统一确认。", "第9月：表33 备注同步"),
    ("S +2，O -1，H -1，风险 -2，生命 -1，CFC +2",
     "S +2，O -1，H -1，风险 -2，身体负担 +1，CFC +2", "第4月：表10 同步"),
    ("body_load_delta=+1；H和生命状态不变。若同时选择E25.A，接口负责人协助核对日志，重构启动顺延7天。",
     "身体负担 +1（本版只记录，不进任何结果）；心情与 H 不变。若同时选择 E25.A，接口负责人协助核对日志，重构启动顺延 7 天。",
     "第8月：表30 术语统一"),
    ("复现论文（树影书院或工位，新）", "复现论文（树影书院长桌，新）",
     "第11月：复现只在书院，与 E41 触发条件一致"),
]

# 在锚点段之后插入的段落
INSERT_AFTER: list[tuple[str, list[str], str]] = [
    ("选择后：你在天台待了会儿。回工位时，待办还在，但你没那么急着盯着它们。",
     ["C｜湖边散步（消耗 1 点）｜去心湖步道走一圈。",
      "选择后：你走了两圈。回来的时候，那件事还在，但你能想下去了。",
      "属性变化：行动点 1→0；其余不变。  埋点标记：m1_activity_lake"],
     "第1月：补上第三个去处（湖边），与表 4 和实装一致"),
    ("C 区水巷咖啡：外摆的椅子有点晃，咖啡一般，但话比咖啡多。",
     ["心湖木栈道：沿湖走一圈，不赶时间。散步不恢复心情。"],
     "第3月：补上湖边那一处的结果句"),
    ("旁白：E07 结果里，纪要写下责任人或待定项时，读过手册的人能认出这两条。没有读过的人也能看懂剧情。",
     ["旁白（第三月 E12 只在文档里加了一行加粗时）：那份《常见问题》你又点开过一次。加粗那一行还在，问题还是没人接手。"],
     "第4月：兑现第3月 E12.C 的承诺"),
    ("【界面】以下三句只显示与第 3 月 E10 选择相符的一句。",
     ["客户（第 3 月 A 如实说明边界）：合同里没有“保证不胡说”那句。你们凭什么让我信这次？",
      "客户（第 3 月 B 签软条款）：合同里写的是“尽商业上合理努力”。刚才那句算合理吗？",
      "客户（第 3 月 C 先答应）：合同里那句“保证不胡说”，是你上个月点头加进去的。现在呢？"],
     "第5月：客户那一问的三版"),
    ("旁白（第九月 E28 写过交接文档时）：那是你上个月写的交接文档。",
     ["旁白（第九月 E28 说过“下个迭代再写”时）：桌角没有你的文档——上个月说“下个迭代再写”，目录第一行还是空的。",
      "旁白（第九月没去书院时）：桌角那份材料不是你写的，是共享盘里原来那一份。"],
     "第10月：开场那句的另外两版"),
    ("老周：我不是让你改数。你得想清楚，谁会看这份材料。",
     ["旁白（第七月把事故归为模型异常时）：老周停了一下，又说：“上次复盘，你先说的是模型。这次这个数，也先别怪公式。”"],
     "第11月：兑现第7月 E19.C 的承诺"),
    ("旁白：他不是来确认你会不会写代码。他要知道这件事值不值得交给更高一级的人负责。",
     ["旁白（第十月公告栏上那条不属于你的经历一直没更正时）：答辩材料里没有那项经历，也没有任何一页解释它为什么曾在你名下。"],
     "第12月：兑现第10月“沉默”那条承诺"),
]

# 表格加行：(表内某行首格文字, 新行各格, 说明)
TABLE_ADD_ROW: list[tuple[str, list[str], str]] = [
    ("天台休息", ["自由安排", "湖边散步", "1→0", "不变（散步不恢复心情）", "m1_activity_lake"],
     "第1月：表4 加湖边一行"),
    ("水巷咖啡", ["自由安排", "湖边散步", "消耗 1 行动点；不加属性", "activity_lake"],
     "第3月：表8 加湖边一行"),
]


# ---------------------------------------------------------------- 工具

def body_paragraphs(doc):
    for child in doc.element.body.iterchildren():
        if child.tag == qn("w:p"):
            yield Paragraph(child, doc)
        elif child.tag == qn("w:tbl"):
            yield Table(child, doc)


def set_paragraph_text(paragraph: Paragraph, text: str) -> None:
    """把整段文字换掉，但保留第一个 run 的字体。"""
    runs = paragraph.runs
    if not runs:
        paragraph.add_run(text)
        return
    runs[0].text = text
    for run in runs[1:]:
        run.text = ""


def find_paragraph(doc, needle: str) -> Paragraph | None:
    hits = [p for p in body_paragraphs(doc) if isinstance(p, Paragraph) and needle in p.text]
    if len(hits) > 1:
        raise SystemExit(f"原文出现 {len(hits)} 次，改不动：{needle[:30]}")
    return hits[0] if hits else None


def replace_anywhere(doc, old: str, new: str, note: str) -> str:
    p = find_paragraph(doc, old)
    if p is not None:
        set_paragraph_text(p, new)
        return "段"
    hits = []
    for table in doc.tables:
        for row in table.rows:
            for cell in row.cells:
                for paragraph in cell.paragraphs:
                    if old in paragraph.text:
                        hits.append(paragraph)
    if len(hits) != 1:
        raise SystemExit(f"找不到或找到 {len(hits)} 处：{note} | {old[:30]}")
    set_paragraph_text(hits[0], new)
    return "单元格"


def insert_after(doc, anchor: str, texts: list[str], note: str) -> None:
    p = find_paragraph(doc, anchor)
    if p is None:
        raise SystemExit(f"锚点找不到：{note} | {anchor[:30]}")
    previous = p
    for text in texts:
        new_p = copy.deepcopy(p._p)
        # 去掉书签/批注一类附属节点，只留段落本身
        for tag in ("w:bookmarkStart", "w:bookmarkEnd"):
            for node in new_p.findall(qn(tag)):
                new_p.remove(node)
        previous._p.addnext(new_p)
        paragraph = Paragraph(new_p, p._parent)
        set_paragraph_text(paragraph, text)
        previous = paragraph


def add_table_row(doc, first_cell: str, values: list[str], note: str) -> None:
    from docx.table import _Row

    for table in doc.tables:
        rows = list(table.rows)
        for index, row in enumerate(rows):
            if not row.cells:
                continue
            if all(cell.text.strip() != first_cell for cell in row.cells):
                continue
            if len(row.cells) != len(values):
                print(f"跳过（列数 {len(row.cells)} 与 {len(values)} 不符）：{note}")
                continue
            new_tr = copy.deepcopy(row._tr)
            row._tr.addnext(new_tr)
            new_row = _Row(new_tr, table)
            for cell, value in zip(new_row.cells, values):
                set_paragraph_text(cell.paragraphs[0], value)
            return
    raise SystemExit(f"表格加行失败：{note}")


def insert_charts(doc, anchor: str) -> None:
    p = find_paragraph(doc, anchor)
    if p is None:
        raise SystemExit("图表锚点找不到")
    charts = [
        ("图 1｜第 1–2 月的选择，落在后面哪一屏", "chart1_m1_m2.png"),
        ("图 2｜第 3 月：客户那一问、会后清单、团队记忆", "chart2_m3.png"),
        ("图 3｜第 4–5 月：评测表、复盘会与那一夜", "chart3_m4_m5.png"),
        ("图 4｜第 6 月：一场答辩，三种第七月", "chart4_m6.png"),
        ("图 5｜第 7–8 月：事故、路线与第二次事故", "chart5_m7_m8.png"),
        ("图 6｜第 9–12 月：署名、交接、口径与那两扇门", "chart6_m9_m12.png"),
    ]
    intro = ["全年分支图：每个选择落在后面哪一屏",
             "读法：左边一列是这个月的选项，右边一列是它后面会出现的那一屏；同一份图里没画到的回响，以正文为准。"]
    for text in intro:
        new_p = copy.deepcopy(p._p)
        p._p.addprevious(new_p)
        paragraph = Paragraph(new_p, p._parent)
        set_paragraph_text(paragraph, text)
    for caption, name in charts:
        image_path = CHARTS / name
        if not image_path.exists():
            raise SystemExit(f"缺图：{image_path}")
        # 说明段（一行小字），图另起一段，居中；都插在锚点之前，顺序不乱
        cap_p = copy.deepcopy(p._p)
        p._p.addprevious(cap_p)
        set_paragraph_text(Paragraph(cap_p, p._parent), caption)
        picture_p = copy.deepcopy(p._p)
        p._p.addprevious(picture_p)
        image_paragraph = Paragraph(picture_p, p._parent)
        set_paragraph_text(image_paragraph, "")
        image_paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
        image_paragraph.add_run().add_picture(str(image_path), width=Inches(6.1))


def main() -> None:
    apply = "--apply" in sys.argv
    doc = Document(str(DOCX))
    before_paragraphs = len(list(body_paragraphs(doc)))
    before_images = len(doc.inline_shapes)

    for old, new, note in REPLACE:
        where = replace_anywhere(doc, old, new, note)
        print(f"[{where}] {note}")
    for old, new, note in CELL_REPLACE:
        where = replace_anywhere(doc, old, new, note)
        print(f"[{where}] {note}")
    for anchor, texts, note in INSERT_AFTER:
        insert_after(doc, anchor, texts, note)
        print(f"[插入 {len(texts)} 段] {note}")
    for first_cell, values, note in TABLE_ADD_ROW:
        add_table_row(doc, first_cell, values, note)
        print(f"[加行] {note}")
    insert_charts(doc, "第一个月流程")
    print("[插图] 全年分支图 6 张")

    print(f"段落 {before_paragraphs} → {len(list(body_paragraphs(doc)))}；插图 {before_images} → {len(doc.inline_shapes)}")
    if apply:
        doc.save(str(DOCX))
        print("已写回", DOCX)
    else:
        print("演练结束（加 --apply 才真写）")


if __name__ == "__main__":
    main()
