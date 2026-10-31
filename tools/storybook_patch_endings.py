"""出局与红线 + 全年分支触发表：写回剧情册.docx。

同 storybook_patch_coherence.py 的做法：每条断言命中次数，次数不对整批中止。
"""
import copy
import shutil
import sys
import time

from docx import Document
from docx.oxml.ns import qn
from docx.table import Table
from docx.text.paragraph import Paragraph
from pathlib import Path

DOCX = Path(r"E:\03_Projects\bear\剧情册.docx")
BAK_DIR = Path(r"E:\03_Projects\bear\workplace_town\test_artifacts")

FIXES = [
    # ---------- 全年统一规则：评估那条重写
    ("评估：第六月是转正评估，结论为通过、延期复核或未转正；延期者在第七月完成一次补充复核，"
     "未转正者完成交接后结束在岗主线。",
     "评估：转正评估只做一次，就在第六月末，结论只有两种——转正、未转正。不设「延期复核」这一档，"
     "也不再补第二次判定：试用期不能延长，同一公司对同一个人只约定一次试用期，所以这个年度里不出两次结论。"
     "判定之前先过一道违纪检查（见下面「红线」那条）。未转正者完成交接后结束在岗主线，"
     "第七月只演结果落地与交接。",
     1, "全年规则：删掉延期复核档，改成一次定两态 + 判定前先过红线"),

    # ---------- 第6月 C 段：判定顺序
    ("王哥作为带教旁听，不参与打分，只有被问到时发言。",
     "王哥作为带教旁听，不参与打分，只有被问到时发言。\n"
     "【先红线后分数】这一场先看第三到第五月有没有落进「红线」那三条的记录：落进一条，当场按违纪解除处理，"
     "下面四拍不再走；一条都没有，才按四维证据问。红线不参与打分，也不与「证据不足」混写。",
     1, "第6月：把红线检查写进答辩场景，顺序是先违纪后分数"),

    # ---------- 第1月：制度条文要先讲
    ("第十二月做年度晋升评估，看你能否承担更高一级的职责。",
     "第十二月做年度晋升评估，看你能否承担更高一级的职责。\n"
     "【必须当场讲】陈工接着把三条线当众念一遍（原文见「红线」那条）。现实里解除合同的合法性就卡在这一步："
     "制度事先没公示、录用条件没告知，事后就不能拿它当理由。所以必须先有这一屏，第六月才允许按红线判。\n"
     "陈工：还有几条是线，不是分数。没授权的承诺不许给客户；现场出了问题不许说成网络抖动；"
     "绕过审批改了线上，当天就得把记录补上。这几条今天讲过，后面就按今天说的处理。",
     1, "第1月：红线成立的前提是事先告知，说明会补上制度条文这一屏"),

    # ---------- 手册 3.2 时间口径
    ("【3.2 时间】本局第六月是转正评估，第七月是延期后的补充复核，第十二月是年度晋升评估；"
     "具体时间以 HR 通知为准。",
     "【3.2 时间】本局转正评估只做一次，在第六月；没有第二次复核，第七月是结果落地与交接。"
     "第十二月是年度晋升评估。具体时间以 HR 通知为准。",
     1, "手册第三章：删掉「第七月补充复核」"),

    # ---------- 第7月 A 段：三态改两态 + 违纪解除
    ("A 月初｜答辩结果落地（三态，约 1 分钟）",
     "A 月初｜结果落地（两态，另有一条违纪解除，约 1 分钟）",
     1, "第7月：结果三态改两态，另立违纪解除一条"),

    ("【延期版】旁白：系统状态更新为“延期复核”。下面附了需要补充的两项材料和复核时间。",
     "【违纪解除版】旁白：系统状态更新为“解除劳动合同”。下面附三行：违反的是哪一条制度、"
     "记录落在哪个月哪件事、经办人和日期。没有出现处分、开除或人格评价。",
     1, "第7月：延期版整块换成违纪解除版（附书面理由，对齐解除须说明理由的现实做法）"),

    ("王哥：这次先延期。不是让你把整半年重来，HR 通知这月补一次复核。",
     "王哥：这次跟分没关系。是你那句超出了授权——入职那天讲过的线。",
     1, "第7月：王哥那句跟着改"),

    ("【延期复核版状态】probation_status=deferred",
     "【违纪解除版状态】probation_status=terminated；写入 employment_arc=ended；"
     "解除依据的制度条文 ID 与触发的记录事件一起存档。",
     1, "第7月：状态字段改 terminated"),

    ("【未转正版】旁白：系统状态更新为“未转正”。HR 把一份交接清单放在桌上，没有出现处分、开除或人格评价。",
     "【未转正版】旁白：系统状态更新为“未转正”。HR 把一份交接清单放在桌上，附一句书面理由："
     "岗位标准里哪几项没达到、依据是哪几件做过的事。没有出现处分、开除或人格评价。",
     1, "第7月：解除要书面说明理由，未转正那一版也给出依据，不只一张清单"),

    ("【未转正版状态】probation_status=not_confirmed；完成交接后写入 employment_arc=ended；"
     "不开放第八至第十二月在岗主线。",
     "【未转正版状态】probation_status=not_confirmed；完成交接后写入 employment_arc=ended；"
     "不开放第八至第十二月在岗主线。\n"
     "【收束｜未转正与违纪解除共用】停在第七月的人也要拿到一份书面收束：做过的记录、差在哪一维或违了哪一条、"
     "下一步建议，只写已经发生的事实。这份材料不叫年度报告；第十二月末那份完整年度报告只对走完十二个月的人开放。"
     "总览里「所有玩家获得年度收束」按这个口径成立。",
     1, "第7月：提前结束必须有结局，否则总览那句承诺是假的"),

    # ---------- 第7月 B 段：复核取消
    ("B 延期分支｜王哥的反馈纸与复核准备（通过版不出现）",
     "B 未转正分支｜王哥的反馈纸与交接准备（通过版不出现）",
     1, "第7月：B 段不再是延期复核，改成未转正的交接准备"),

    ("B1 第七月补充复核（只对 M6 deferred 开放一次）",
     "B1 第七月不再判定，只做交接",
     1, "第7月：取消补充复核"),

    ("【界面】按反馈纸列出的短板或证据不足维度加载一项新的岗位样例，不重播原题、不重复刷分："
     "S 为不完整日志的根因判断；O 为范围变化中的限期交付；N 为模块交接并写清待定项、负责人和确认时间；"
     "D 为发现不实记录后用可核验材料纠正。",
     "【界面】本月不再加载新的岗位样例，也不重播原题。反馈纸照发，纸上四项仍按四维分档给措辞，"
     "但它的作用是交接对照表和下一步建议的依据，不是一场补考。",
     1, "第7月：把「补一次样例」的机制删掉，纸留着当对照"),

    ("【判定】短板维度≥3、总分≥13/16且没有任何维度<2，复核通过并更新 probation_status=confirmed；"
     "职级不变。否则记 not_confirmed，先完成交接，再结束在岗主线。",
     "【判定】本月不产生新判定，也不改第六月的结论：probation_status 到月初就定了。"
     "confirmed 继续在岗主线；not_confirmed 与 terminated 都走交接与收束。职级不变。",
     1, "第7月：判定只发生一次，写死在第六月末"),

    ("02 结果文本库（延期版按档位显示）",
     "02 结果文本库（未转正版按档位显示）",
     1, "第7月：文本库标题跟着两态改"),
]

REDLINE = (
    "红线（违纪解除，与能力判定分开）：本局只认三条，且必须先在第一月入职说明会上当众讲过才生效。"
    "①超出授权向客户承诺——第三月 E10「先答应，先把单子拿下」（m03_e10_overpromise）；"
    "②把现场问题说成网络波动、推给不可控因素——第五月 E17「说是网络波动，再演一遍」（m05_e17_blame_network）；"
    "③绕过审批改了线上、事后不补记录——第五月夜间「先止血，不补完整记录」（m05_night_hotfix_unlogged；"
    "走了紧急通道但当天把工单补齐的不算越线）。三条里任何一条实际落进记录，第六月评估当场按违纪解除，"
    "不看四维分，也不留到后面。"
    "第八月「先观察」压着滥用不上报（m08_e25_observe）、第十月「保持沉默」让不实的署名留在自己名下并写进"
    "晋升材料（m10_name_kept_by_silence）——这两件同样越线，但都发生在转正之后：本版只判"
    "「书面警告 + 记进档案」，警告进报告，不结束主线。"
    "红线不计分、不均值、不与证据不足混写；措辞上不出现开除、处分、人格评价。"
)

BRANCH_TABLE = {
    "header": ["岔口", "什么时候判", "看什么", "去向", "后面谁读它"],
    "rows": [
        ["转正判定", "第六月末最后一屏结算", "先查红线三条；没有才看四维证据（每维取最高一档）",
         "违纪解除 / 未转正 / 转正", "第七月 A、B 两段；E19；第八到十二月开不开；第十二月的收束"],
        ["提名", "第十一月初，王哥只报一个人", "册子要求按证据（四维里至少三维有两条硬记录 + 一件别人能用的东西）；"
         "现在只看你在那一场里选了哪句", "有提名 / 没提名", "第十二月整月分叉：答辩厅九拍，还是小会议桌面谈"],
        ["晋升", "第十二月「当天下午结果」开场前", "册子写按规则表（证据完整度+归属+口径+下一级范围）；"
         "现在直接套第六月那套分数", "晋升 / 这次没晋升", "反馈纸那一屏；年度报告"],
        ["条件屏（不改结局，只决定出不出）", "各月当场", "到过没到过、做过没做过",
         "水巷门口那个人（去过水巷咖啡）；长桌对面那个人与交接文档（去过书院长桌）；"
         "谁来定义成功（做过论文复现）；那张纸放哪儿（第七月＝未转正纸，第十二月＝没晋升纸）；"
         "告警单（第十月硬上线）", "只在当月显形，不跨月"],
        ["已接上的跨月因果", "——", "——",
         "第三月怎么答客户→第四月开场、第五月台上；第四月建没建评测表→第五月 Demo 四版；"
         "第四月复盘会怎么答→第九月名单、第十月公告栏；第九月交接三态→第十月新人四版、第十二月材料；"
         "第七月那张纸放哪儿→第十二月一句；第五月怪网络→第十一月一句；第十月硬上线→第十一月初；"
         "第十月不更正→第十二月一句旁白", "这些是真的会改玩家看到的句子"],
        ["册子写了、实现里没人读", "——", "——",
         "第八月「先小修」册子说第十月兑现，第十月不看；第七月「归为模型异常」的回响在第十一月无条件出现；"
         "第六月四拍怎么答后面一屏都不读（册子却写「用于第十一月表达线」）；"
         "全年 150 个选择里 89 个只写不读，其中第十二月 32 个本该由年度报告读，而报告模板还没建",
         "逐条记在开发册 15.6"],
    ],
}


def blocks(doc):
    for child in doc.element.body.iterchildren():
        if child.tag == qn("w:p"):
            yield Paragraph(child, doc)
        elif child.tag == qn("w:tbl"):
            yield Table(child, doc)


def all_paragraphs(doc):
    for block in blocks(doc):
        if isinstance(block, Paragraph):
            yield block
        else:
            for row in block.rows:
                for cell in row.cells:
                    for paragraph in cell.paragraphs:
                        yield paragraph


def set_text(paragraph, text):
    runs = paragraph.runs
    if not runs:
        paragraph.add_run(text)
        return
    runs[0].text = text
    for run in runs[1:]:
        run.text = ""


def split_after(p, needle):
    """把一段文字在 needle 处切成两段（保留原格式）。"""
    text = p.text
    idx = text.find(needle)
    if idx < 0:
        return
    tail = text[idx + len(needle):]
    if not tail.strip():
        return
    set_text(p, text[:idx + len(needle)])
    new_p = copy.deepcopy(p._p)
    for tag in ("w:bookmarkStart", "w:bookmarkEnd"):
        for node in new_p.findall(qn(tag)):
            new_p.remove(node)
    p._p.addnext(new_p)
    set_text(Paragraph(new_p, p._parent), tail)


def apply_fix(doc, old, new, expect, note):
    hits = [p for p in all_paragraphs(doc) if old in p.text]
    if len(hits) != expect:
        raise SystemExit(f"[中止] {note}：应命中 {expect} 处，实际 {len(hits)} 处 -> {old[:34]}")
    for p in hits:
        merged = p.text.replace(old, new)
        parts = merged.split("\n")
        set_text(p, parts[0])
        tail = p
        for extra in parts[1:]:
            new_p = copy.deepcopy(p._p)
            for tag in ("w:bookmarkStart", "w:bookmarkEnd"):
                for node in new_p.findall(qn(tag)):
                    new_p.remove(node)
            tail._p.addnext(new_p)
            tail = Paragraph(new_p, p._parent)
            set_text(tail, extra)
    print(f"  × {len(hits)}  {note}")


def insert_after(doc, anchor, texts, note):
    if not texts:
        return
    hits = [p for p in all_paragraphs(doc) if anchor in p.text]
    if len(hits) != 1:
        raise SystemExit(f"[中止] 插入锚点应 1 处，实际 {len(hits)}：{note} | {anchor[:30]}")
    base = hits[0]
    previous = base
    for text in texts:
        new_p = copy.deepcopy(base._p)
        for tag in ("w:bookmarkStart", "w:bookmarkEnd"):
            for node in new_p.findall(qn(tag)):
                new_p.remove(node)
        previous._p.addnext(new_p)
        paragraph = Paragraph(new_p, base._parent)
        set_text(paragraph, text)
        previous = paragraph
    print(f"  插入 × {len(texts)}  {note}")


def add_branch_table(doc, anchor_text, note):
    hits = [p for p in all_paragraphs(doc) if anchor_text in p.text]
    if len(hits) != 1:
        raise SystemExit(f"[中止] 表锚点应 1 处，实际 {len(hits)}：{note}")
    anchor = hits[0]
    model = None
    for tbl in doc.tables:
        if tbl.rows and "月份接续" in tbl.rows[0].cells[0].text:
            model = tbl
            break
    if model is None:
        raise SystemExit("[中止] 找不到可参照的跨月状态表")
    spec = BRANCH_TABLE
    table = doc.add_table(rows=len(spec["rows"]) + 1, cols=len(spec["header"]))
    try:
        table.style = model.style
    except Exception:
        pass
    for i, text in enumerate(spec["header"]):
        table.rows[0].cells[i].text = text
    for r, row in enumerate(spec["rows"], start=1):
        for c, text in enumerate(row):
            table.rows[r].cells[c].text = text
    anchor._p.addprevious(table._tbl)
    print(f"  插入表格 × 1（{len(spec['rows'])} 行）  {note}")


def main():
    apply = "--apply" in sys.argv
    doc = Document(str(DOCX))
    print(f"读入 {DOCX.name}")
    for old, new, expect, note in FIXES:
        apply_fix(doc, old, new, expect, note)
    insert_after(doc, "行动点、H及身体负担不计入晋升分。", [REDLINE],
                 "全年规则：新增红线条（第6月一条真出局，转正后两件只警告）")
    add_branch_table(doc, "全年分支图：每个选择落在后面哪一屏",
                     "跨月关键状态之后：全年岔口与触发条件总表")
    if not apply:
        print("演练通过：加 --apply 才真写。")
        return
    stamp = time.strftime("%Y%m%d_%H%M")
    bak = BAK_DIR / f"storybook_backup_{stamp}.docx"
    shutil.copy2(DOCX, bak)
    print(f"备份 -> {bak}")
    doc.save(str(DOCX))
    print(f"已写回 {DOCX}")


if __name__ == "__main__":
    main()
