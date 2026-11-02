# -*- coding: utf-8 -*-
"""F1：把「选项：台词/行动」这一行拆回剧情册的两列。
   选项列 → choice.text（短标签）；台词/行动列 → choice.detail（选之前仍然看得见，只是小一号）。
   只动那 57 条能对上册子「选项」列的，其余一字不改。"""
import io
import json
import re

import docx

BOOK = r"E:\03_Projects\bear\剧情册.docx"
DATA = r"E:\03_Projects\bear\workplace_town\data\story\v12m\events.json"


def norm(s):
    s = str(s or "").replace("\u3000", " ").replace("\n", " ")
    s = re.sub(r"[“”\"「」『』]", "", s)
    return re.sub(r"\s+", "", s)


doc = docx.Document(BOOK)
labels = set()
for tb in doc.tables:
    if len(tb.columns) < 2:
        continue
    head = [norm(c.text) for c in tb.rows[0].cells]
    if not head or "选项" not in head[0]:
        continue
    for row in tb.rows[1:]:
        m = re.match(r"^([ABC])\s*(.+)$", row.cells[0].text.strip(), re.S)
        if m:
            labels.add(norm(m.group(2)))

raw = io.open(DATA, encoding="utf-8", newline="").read()
data = json.loads(raw)
changed = []
for node in data.get("nodes", []):
    nid = str(node.get("id"))
    new_choices = []
    for ch in node.get("choices") or []:
        text = str(ch.get("text", ""))
        if "：" in text:
            head, rest = text.split("：", 1)
            head = head.strip()
            rest = rest.strip()
            if (
                norm(head) in labels
                and len(head) <= 14
                and len(rest) >= 12
                and "detail" not in ch
            ):
                rebuilt = {}
                for k, v in ch.items():
                    if k == "text":
                        rebuilt["text"] = head
                        rebuilt["detail"] = rest
                    else:
                        rebuilt[k] = v
                ch = rebuilt
                changed.append("%s %s → 「%s」+ 小字%d字" % (nid, ch.get("id"), head, len(rest)))
        new_choices.append(ch)
    if node.get("choices") is not None:
        node["choices"] = new_choices

out = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
io.open(DATA, "w", encoding="utf-8", newline="").write(out)
io.open(
    r"E:\03_Projects\bear\workplace_town\test_artifacts\_f1_applied.txt", "w", encoding="utf-8"
).write("changed=%d\n" % len(changed) + "\n".join(changed))
print("changed", len(changed))
