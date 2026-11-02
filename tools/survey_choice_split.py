# -*- coding: utf-8 -*-
"""把剧情册里的「选项 / 玩家看到的台词·行动」两列和 events.json 的选项文字对上，
   找出哪些选项是把两列拼成了一行（F1）。只读，不改数据。"""
import io
import json
import re

import docx

BOOK = r"E:\03_Projects\bear\剧情册.docx"
DATA = r"E:\03_Projects\bear\workplace_town\data\story\v12m\events.json"


def norm(s):
    s = str(s or "")
    s = s.replace("\u3000", " ").replace("\n", " ")
    s = re.sub(r"[“”\"「」『』]", "", s)
    s = re.sub(r"\s+", "", s)
    return s


doc = docx.Document(BOOK)
# 每个四列表：表头含「选项」，第一列是 "A 短标签"，第二列是台词/行动
pairs = {}
for ti, tb in enumerate(doc.tables):
    if len(tb.columns) < 2:
        continue
    head = [norm(c.text) for c in tb.rows[0].cells]
    if not head or "选项" not in head[0]:
        continue
    for ri, row in enumerate(tb.rows[1:], start=1):
        cells = [c.text.strip() for c in row.cells]
        label = cells[0]
        m = re.match(r"^([ABC])\s*(.+)$", label.strip(), re.S)
        if not m:
            continue
        letter, short = m.group(1), m.group(2).strip()
        action = cells[1].strip() if len(cells) > 1 else ""
        pairs.setdefault(norm(short), []).append((ti, ri, letter, short, action))
        # 也按「短标签 + 整条台词」登记，方便反向查
        pairs.setdefault(norm(short) + norm(action), []).append((ti, ri, letter, short, action))

events = json.load(io.open(DATA, encoding="utf-8"))
plan = []
unmatched = []
for node in events.get("nodes", []):
    nid = str(node.get("id"))
    for ch in node.get("choices") or []:
        text = str(ch.get("text", ""))
        if "：" not in text:
            continue
        head, rest = text.split("：", 1)
        head = head.strip()
        rest = rest.strip()
        if len(head) > 14 or len(rest) < 12:
            continue
        if head.endswith(("说", "道", "讲", "回", "问", "答", "称")):
            continue
        hit = pairs.get(norm(head))
        if not hit:
            unmatched.append("%s %s | %s || %s" % (nid, ch.get("id"), head, rest[:40]))
            continue
        ti, ri, letter, short, action = hit[0]
        # 册子里第二列和拼进来的解释是否一致（允许标点差异）
        same = norm(action) == norm(rest)
        plan.append(
            "%s %s | 表%d r%d | 选项→「%s」 | 结果前补「%s」 | 册子第二列与拼进去的%s"
            % (nid, ch.get("id"), ti, ri, short, action[:44], "一致" if same else "有出入")
        )

out = io.open(
    r"E:\03_Projects\bear\workplace_town\test_artifacts\_f1_plan.txt", "w", encoding="utf-8"
)
out.write("册子里能对上号的短标签：%d 个\n" % len(pairs))
out.write("可转换的选项：%d 条\n" % len(plan))
out.write("拼了长解释但对不上册子的：%d 条\n" % len(unmatched))
out.write("\n===== 可转换 =====\n")
out.write("\n".join(plan))
out.write("\n\n===== 对不上 =====\n")
out.write("\n".join(unmatched))
out.close()
print("convertible=%d unmatched=%d" % (len(plan), len(unmatched)))
