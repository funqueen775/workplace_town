"""给剧情册画分支图：每一屏的选项，落在后面哪一屏。

输出 PNG（不是文档），由 storybook_patch.py 嵌进 剧情册.docx。

用法：python tools/storybook_charts.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT_PATH = ROOT / "assets" / "fonts" / "NotoSansCJKsc-Regular.otf"
OUT_DIR = ROOT / "test_artifacts" / "storybook_charts"

W = 1600
MARGIN = 30
INNER = W - MARGIN * 2
TITLE_H = 86
BAND_TITLE_H = 60
ROW_H = 96
ROW_GAP = 12
BAND_PAD = 16

BG = (247, 242, 231)
INK = (47, 42, 36)
SUB = (106, 95, 82)
CHOICE_FILL = (255, 253, 247)
CHOICE_BORDER = (201, 184, 148)
BAND_FILL = (59, 49, 39)
BAND_TEXT = (243, 231, 201)
LETTER = {"A": (180, 85, 46), "B": (47, 107, 95), "C": (107, 90, 142)}
MONTH_COLOR = {
    1: (122, 106, 85), 2: (201, 139, 63), 3: (122, 139, 63), 4: (63, 122, 139),
    5: (139, 63, 107), 6: (139, 107, 63), 7: (95, 139, 63), 8: (139, 63, 63),
    9: (63, 95, 139), 10: (139, 122, 63), 11: (63, 139, 122), 12: (107, 63, 139),
}

F_TITLE = ImageFont.truetype(str(FONT_PATH), 52)
F_SUB = ImageFont.truetype(str(FONT_PATH), 26)
F_BAND = ImageFont.truetype(str(FONT_PATH), 38)
F_ROW = ImageFont.truetype(str(FONT_PATH), 34)
F_CHIP = ImageFont.truetype(str(FONT_PATH), 26)


def wrap(text: str, font, max_width: int) -> list[str]:
    lines: list[str] = []
    current = ""
    for ch in text:
        candidate = current + ch
        if font.getlength(candidate) <= max_width or not current:
            current = candidate
        else:
            lines.append(current)
            current = ch
    if current:
        lines.append(current)
    return lines


def rounded(draw, box, radius, fill, outline=None, width=2):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def _row_height(choice: str, dest: str) -> int:
    left_w, arrow_gap = 560, 50
    right_w = INNER - 16 - left_w - arrow_gap
    c_lines = len(wrap(choice, F_ROW, left_w - 96))
    d_lines = len(wrap(dest, F_ROW, right_w - 150))
    return max(ROW_H, 24 + max(c_lines, d_lines) * 44)


def draw_row(draw, x, y, width, height, letter, choice, month, dest):
    """一行：左=选项，右=落点（带月份签）。"""
    left_w = 560
    arrow_gap = 50
    right_x = x + left_w + arrow_gap
    right_w = width - left_w - arrow_gap

    rounded(draw, (x, y, x + left_w, y + height), 12, CHOICE_FILL, CHOICE_BORDER, 2)
    chip = LETTER.get(letter, (120, 110, 95))
    rounded(draw, (x + 14, y + 16, x + 60, y + 62), 8, chip)
    draw.text((x + 28, y + 25), letter, font=F_CHIP, fill=(255, 255, 255))
    choice_lines = wrap(choice, F_ROW, left_w - 96)
    ty = y + (height - len(choice_lines) * 44) // 2 + 2
    for line in choice_lines:
        draw.text((x + 74, ty), line, font=F_ROW, fill=INK)
        ty += 44

    ay = y + height // 2
    draw.line((x + left_w + 8, ay, right_x - 12, ay), fill=(150, 136, 112), width=3)
    draw.polygon([(right_x - 4, ay), (right_x - 18, ay - 9), (right_x - 18, ay + 9)], fill=(150, 136, 112))

    rounded(draw, (right_x, y, right_x + right_w, y + height), 12, (255, 252, 244), (222, 210, 186), 2)
    tag = f"第{month}月"
    tag_w = F_CHIP.getlength(tag) + 26
    color = MONTH_COLOR.get(month, (122, 106, 85))
    rounded(draw, (right_x + 12, y + 16, right_x + 12 + tag_w, y + 54), 8, color)
    draw.text((right_x + 24, y + 22), tag, font=F_CHIP, fill=(255, 255, 255))
    dest_lines = wrap(dest, F_ROW, right_w - 150)
    dy = y + (height - len(dest_lines) * 44) // 2 + 2
    for line in dest_lines:
        draw.text((right_x + 18 + tag_w, dy), line, font=F_ROW, fill=INK)
        dy += 44


def draw_chart(title: str, subtitle: str, bands: list[dict], path: Path) -> None:
    height = TITLE_H + 8 + 56
    for band in bands:
        height += BAND_TITLE_H + 12 + BAND_PAD + 22
        height += sum(_row_height(r["choice"], r["dest"]) + ROW_GAP for r in band["rows"])
    image = Image.new("RGB", (W, height), BG)
    draw = ImageDraw.Draw(image)

    draw.text((MARGIN, 24), title, font=F_TITLE, fill=INK)
    draw.text((MARGIN, 92), subtitle, font=F_SUB, fill=SUB)

    y = TITLE_H + 8 + 56
    for band in bands:
        rounded(draw, (MARGIN, y, W - MARGIN, y + BAND_TITLE_H), 10, BAND_FILL)
        draw.text((MARGIN + 18, y + 12), band["title"], font=F_BAND, fill=BAND_TEXT)
        y += BAND_TITLE_H + 12
        for row in band["rows"]:
            row_h = _row_height(row["choice"], row["dest"])
            draw_row(draw, MARGIN + 8, y, INNER - 16, row_h, row["letter"], row["choice"], row["month"], row["dest"])
            y += row_h + ROW_GAP
        y += BAND_PAD + 6

    image.save(path)
    print("图 ->", path)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    draw_chart(
        "图 1｜第 1–2 月：每个选择落在后面哪一屏",
        "同一行右端，就是它后面会出现的那一屏；没画到的，以正文为准。",
        [
            {
                "title": "第 1 月 · E02 第一次被轻视（三选一）",
                "rows": [
                    {"letter": "A", "choice": "当场说明：那份方案是我上周讲的", "month": 2,
                     "dest": "陈工先请你讲：“上次那份方案你在会上说清楚了”；第 6 月答辩只做事实核对"},
                    {"letter": "B", "choice": "会后把方案发进组内记录并署名", "month": 2,
                     "dest": "陈工：“我看过你署名发来的版本了。这次你讲，王哥补充”"},
                    {"letter": "C", "choice": "先把手头工作做完", "month": 2,
                     "dest": "陈工仍让王哥先讲；第 6 月不额外强调名字"},
                ],
            },
            {
                "title": "第 2 月 · E04 技术选型（三选一）",
                "rows": [
                    {"letter": "A", "choice": "自研和开源各做一版，都跑一遍", "month": 12,
                     "dest": "答辩第一张投影就是这次选型：自研对比那版；第 2 月第四天字卡：自研先跑通"},
                    {"letter": "B", "choice": "先用开源把流程跑通", "month": 12,
                     "dest": "答辩投影：先用开源那版；未验证的部分要自己讲清"},
                    {"letter": "C", "choice": "先问王哥踩过哪些坑", "month": 12,
                     "dest": "答辩投影：依据旧事故补验证那版；口述不能替代旧事故单"},
                ],
            },
            {
                "title": "第 2 月 · E03 代码改动说明（三选一）",
                "rows": [
                    {"letter": "A", "choice": "写清工具参与范围", "month": 8,
                     "dest": "白板上不会出现这一条；第 2 月月末王哥陪你过“还没把握”那段"},
                    {"letter": "B", "choice": "删掉工具参与说明", "month": 8,
                     "dest": "白板多一行：“那次提交没有注明 AI 参与范围”"},
                    {"letter": "C", "choice": "写“部分参考了公开资料”", "month": 8,
                     "dest": "白板不出这一条；第 2 月王哥追问“具体指哪段”"},
                ],
            },
        ],
        OUT_DIR / "chart1_m1_m2.png",
    )

    draw_chart(
        "图 2｜第 3 月：客户那一问、会后清单、团队记忆",
        "第 3 月的三个选择分别落在第 4、5、12 月；这是全册回响最密的一个月。",
        [
            {
                "title": "第 3 月 · E10 客户要“保证不胡说”（三选一）",
                "rows": [
                    {"letter": "A", "choice": "如实说明边界并给兜底", "month": 5,
                     "dest": "Demo：合同里没有“不会胡说”，你和法务对到深夜才把边界写清"},
                    {"letter": "B", "choice": "签“尽商业上合理努力”", "month": 5,
                     "dest": "Demo：合同写的是这句软话，客户当场问“刚才那句算合理吗”"},
                    {"letter": "C", "choice": "先答应，把单子拿下", "month": 5,
                     "dest": "Demo：合同里那句“保证不胡说”是你点头加进去的；第六月按红线判违纪解除"},
                ],
            },
            {
                "title": "第 3 月 · E10b 会后清单（强制三选一，只记协作证据）",
                "rows": [
                    {"letter": "A", "choice": "发到组内：待定项、负责人、下次确认时间", "month": 12,
                     "dest": "第 12 月“你怎么说明自己的角色”有据可引"},
                    {"letter": "B", "choice": "只私发王哥，没同步下次确认时间", "month": 12,
                     "dest": "证据少一段，答辩只能讲一半"},
                    {"letter": "C", "choice": "先不整理", "month": 12,
                     "dest": "这一项没有材料可引"},
                ],
            },
            {
                "title": "第 3 月 · E12 它记不住中间那段（三选一）",
                "rows": [
                    {"letter": "A", "choice": "建团队共用的知识库", "month": 4,
                     "dest": "第 4 月《常见问题》开始有人补；小赵建目录"},
                    {"letter": "B", "choice": "只给自己模块加分段索引", "month": 4,
                     "dest": "自己那段好查了，别人的模块还在猜"},
                    {"letter": "C", "choice": "在文档里加一行加粗", "month": 4,
                     "dest": "第 4 月：加粗那行还在，问题没人接手（补写的回响）"},
                ],
            },
        ],
        OUT_DIR / "chart2_m3.png",
    )

    draw_chart(
        "图 3｜第 4–5 月：评测表、复盘会与那一夜",
        "第 4 月建不建那张表，决定第 5 月 Demo 上有几张牌、第 12 月材料里少不少一项。",
        [
            {
                "title": "第 4 月 · E05 评测集（三选一）",
                "rows": [
                    {"letter": "A", "choice": "建完整评测集，向王哥提延期", "month": 5,
                     "dest": "Demo 有表，能看出哪类输入容易失败；第 9 月表还压在长桌角；第 12 月材料第一项"},
                    {"letter": "B", "choice": "先不建", "month": 5,
                     "dest": "Demo 四张告警只能靠口头判断；第 12 月材料清清楚楚少一项"},
                    {"letter": "C", "choice": "先建最小版，灰度观察", "month": 5,
                     "dest": "Demo 表只覆盖物流一类；第 12 月材料算半项"},
                ],
            },
            {
                "title": "第 4 月 · E07 复盘会上的甩锅（三选一）",
                "rows": [
                    {"letter": "A", "choice": "举起截图，当场说清", "month": 9,
                     "dest": "第 9 月回忆：“四个月前那次复盘，你也把能核对的记录摆上了桌”"},
                    {"letter": "B", "choice": "要求先按流程核对", "month": 8,
                     "dest": "第 8 月白板：“那场会没有留下完整的三项记录”"},
                    {"letter": "C", "choice": "先认下来", "month": 10,
                     "dest": "第 9、10 月都有回响：“你先把责任接了下来，没有继续追署名”"},
                ],
            },
            {
                "title": "第 5 月 · 深夜那一改（三选一）",
                "rows": [
                    {"letter": "A", "choice": "走紧急通道，补齐工单", "month": 5,
                     "dest": "第二天纪要引用工单号，没人再问昨晚是谁动的线上"},
                    {"letter": "B", "choice": "先止血，不补记录", "month": 5,
                     "dest": "Demo 开场旁白：“这条线昨晚被谁动过，你不知道”；第六月按红线判违纪解除"},
                    {"letter": "C", "choice": "等审批走完", "month": 5,
                     "dest": "后来说出“四小时十七分”这段等待；错误回复多留了三个半小时"},
                ],
            },
            {
                "title": "第 5 月 · E17 台上翻车（三选一）",
                "rows": [
                    {"letter": "A", "choice": "切备用流程并承认错误", "month": 7,
                     "dest": "第 7 月复盘按日志核对规则提交与审核；这一条不预先洗白"},
                    {"letter": "B", "choice": "说是网络波动，再演一遍", "month": 11,
                     "dest": "第 11 月 E41：“有人说先把能看的数补齐”——你想起 Demo 那次；第六月按红线判违纪解除"},
                    {"letter": "C", "choice": "继续讲完后面三页", "month": 11,
                     "dest": "同上，第 11 月回响；第 7 月的日志核对照旧"},
                ],
            },
        ],
        OUT_DIR / "chart3_m4_m5.png",
    )

    draw_chart(
        "图 4｜第 6 月：一次判定，两条路 + 一条线",
        "四拍问答不当场判；第六月末一次定，结论只有转正与未转正。违纪解除另走一条线：先看有没有越线，再看分。",
        [
            {
                "title": "第 6 月末 · 判定顺序（本版没有第二次复核）",
                "rows": [
                    {"letter": "A", "choice": "红线：第三到五月三条里有一条落进记录", "month": 7,
                     "dest": "违纪解除：书面理由（违反哪条制度、哪个月哪件事、经办人）；第七月交接 + 短收束，不进 E19，不开第 8 到 12 月"},
                    {"letter": "B", "choice": "未转正：举证充分且分数不到", "month": 7,
                     "dest": "交接清单逐项对文档/待办/权限；第七月短收束——第 8 到 12 月没有内容"},
                    {"letter": "C", "choice": "转正：无红线且分数够（或举不出证）", "month": 7,
                     "dest": "门禁写“转正状态：已确认”，职级不动；王哥让你补接手文档；进 E19 与第 8 到 12 月主线"},
                ],
            },
            {
                "title": "第 6 月 · 会前挑三张便签（不改属性，只改第 12 月回放）",
                "rows": [
                    {"letter": "A", "choice": "三张里有受挫/未完成的那张", "month": 12,
                     "dest": "六幕回放里“事故与责任”那一幕有真实便签可挂"},
                    {"letter": "B", "choice": "三张全是做成的", "month": 12,
                     "dest": "回放那一幕空着，不用通用图补"},
                ],
            },
            {
                "title": "第 6 月 · 会前第四栏“之后想做什么”（三选一）",
                "rows": [
                    {"letter": "A", "choice": "写具体方向", "month": 6,
                     "dest": "交付维度 +1；小赵：“那至少知道该先问谁了”"},
                    {"letter": "B", "choice": "划掉这一栏", "month": 6,
                     "dest": "不加分也不扣；小赵看了一眼没追问"},
                    {"letter": "C", "choice": "写“先把手上的事做稳”", "month": 6,
                     "dest": "署名与证据维度 +1；小赵：“这句我也差点写上”"},
                ],
            },
        ],
        OUT_DIR / "chart4_m6.png",
    )

    draw_chart(
        "图 5｜第 7–8 月：事故、路线与第二次事故",
        "第 7 月的复盘决定第 11 月那句回响；第 8 月的两条选择互相咬合，会改排期。",
        [
            {
                "title": "第 7 月 · E19 事故复盘（三选一）",
                "rows": [
                    {"letter": "A", "choice": "摊开日志，按提交/审核/上线讲", "month": 7,
                     "dest": "老周月末：会上你把日志摊开了；产品关系 -1，第 11 月不额外回响"},
                    {"letter": "B", "choice": "先认审核责任", "month": 7,
                     "dest": "老周月末：该你负责的部分你没往外推；补回归测试与负责人"},
                    {"letter": "C", "choice": "归为模型异常", "month": 11,
                     "dest": "第 11 月老周：“上次复盘你先说的是模型。这次这个数，也先别怪公式”（补写的回响）"},
                ],
            },
            {
                "title": "第 8 月 · E23 重构路线（三选一）",
                "rows": [
                    {"letter": "A", "choice": "建议大重构，三个月少接新需求", "month": 8,
                     "dest": "第二天回查旧接口时发现多出来的入口；若同时选 E25.A，启动顺延 7 天"},
                    {"letter": "B", "choice": "先继续小修", "month": 8,
                     "dest": "第八天安全组把线索转给你；第 10 月 E40 兑现这笔债"},
                    {"letter": "C", "choice": "把维护外包", "month": 8,
                     "dest": "老周发来供应商演示页：“这段对外演示，谁批过？”"},
                ],
            },
            {
                "title": "第 8 月 · E25 有人拿它干坏事（三选一）",
                "rows": [
                    {"letter": "A", "choice": "立即上报并推动防护", "month": 12,
                     "dest": "第 12 月走廊里小赵：“合规那件我也放进去了”；与 E23.A 同选则改派接口负责人"},
                    {"letter": "B", "choice": "只加过滤规则", "month": 8,
                     "dest": "第二天类似内容换种写法又出现；报告里留一条复现记录"},
                    {"letter": "C", "choice": "先观察，不扩大", "month": 8,
                     "dest": "举报工单挂着，没人能说问题已经停了"},
                ],
            },
        ],
        OUT_DIR / "chart5_m7_m8.png",
    )

    draw_chart(
        "图 6｜第 9–12 月：署名、交接、口径与那两扇门",
        "第 9 月那份文档写多全，决定第 10 月许棠的第一句话；第 11 月那个数怎么写，决定第 12 月进哪扇门。",
        [
            {
                "title": "第 9 月 · 申报名单上少了一个名字（三选一）",
                "rows": [
                    {"letter": "A", "choice": "在申报群补提交记录", "month": 10,
                     "dest": "第 10 月老周发消息：小赵敢在申报会上开口了；第 12 月告别：“你上次替我补了贡献记录”"},
                    {"letter": "B", "choice": "去走廊私下跟老周说", "month": 10,
                     "dest": "老周同样发消息（帮助过他）；名单私下补上，群里没提"},
                    {"letter": "C", "choice": "不介入", "month": 12,
                     "dest": "没有第 10 月那条消息；第 12 月小赵的告别台词换到疏一档"},
                ],
            },
            {
                "title": "第 9 月 · E28 交接文档（三选一，或没去书院）",
                "rows": [
                    {"letter": "A", "choice": "写完整：故障案例、判断、排查步骤", "month": 10,
                     "dest": "许棠：“我按到第七页了，还自己加了一条”；第 12 月椅子那题接得上"},
                    {"letter": "B", "choice": "写能跑起来的版本，关键判断留在脑子里", "month": 10,
                     "dest": "许棠：“到这一步我不确定该选哪条，所以先停了”"},
                    {"letter": "C", "choice": "下个迭代再写", "month": 10,
                     "dest": "许棠：“我先照着共享盘里另一份材料做的，第一步之后就对不上”"},
                ],
            },
            {
                "title": "第 10 月 · E40 许棠的路线（三选一）",
                "rows": [
                    {"letter": "A", "choice": "这次先用成熟方案", "month": 10,
                     "dest": "交付很稳；新方案收进“待定”，第 11 月没有告警"},
                    {"letter": "B", "choice": "挑一段低风险流程跑两天", "month": 11,
                     "dest": "两周对照记录留下来；第 11 月谈口径时能引用它"},
                    {"letter": "C", "choice": "直接按新路线上线", "month": 11,
                     "dest": "第 11 月月初告警单：许棠的提交 + 你的确认记录，陈工要补根因"},
                ],
            },
            {
                "title": "第 11 月 · 18% 还是 41%（三选一）",
                "rows": [
                    {"letter": "A", "choice": "拆分试点与外推，标待核实", "month": 12,
                     "dest": "王哥仍报你上去 → 第 12 月进答辩厅；准备回答口径问题"},
                    {"letter": "B", "choice": "走内网匿名反馈，不改材料", "month": 12,
                     "dest": "材料不改，提名照旧 → 第 12 月进答辩厅；报告里留一条受理状态"},
                    {"letter": "C", "choice": "按 41% 原样提交", "month": 12,
                     "dest": "王哥报了孙哥 → 第 12 月进小会议桌，反馈面谈而不是答辩"},
                ],
            },
        ],
        OUT_DIR / "chart6_m9_m12.png",
    )


if __name__ == "__main__":
    main()
