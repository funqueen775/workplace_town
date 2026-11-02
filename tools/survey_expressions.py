# -*- coding: utf-8 -*-
"""F6 内容：把全年 say 拍按现在的关键词猜测器跑一遍，挑出语气明显对不上的。
   只读，不改数据。产物：test_artifacts/_f6_expr.txt"""
import io
import json
import os

DATA = r"E:\03_Projects\bear\workplace_town\data\story\v12m\events.json"
ART = r"E:\03_Projects\bear\workplace_town\assets\角色立绘"

POS = ["不错", "笑", "做得好", "可以", "点头"]
CONF = ["无奈", "只能", "算了"]
SERIOUS = ["不", "别", "问题", "责任", "必须"]
FRIENDLY = ["谢谢", "辛苦", "没事", "行", "好嘞", "没问题", "干得"]
INTENT = ["我来", "我去", "我跟", "我负责", "算我", "这就", "马上"]


def guess(text):
    if "?" in text or "？" in text or "怎么" in text or "为什么" in text:
        return "疑惑"
    for k in POS:
        if k in text:
            return "开心"
    for k in CONF:
        if k in text:
            return "无奈"
    for k in SERIOUS:
        if k in text:
            return "认真"
    return "自然"


def faces(name):
    d = os.path.join(ART, name)
    if not os.path.isdir(d):
        return set()
    return {f[len(name) + 1:-4] for f in os.listdir(d) if f.endswith(".png") and not f.startswith(".")}


events = json.load(io.open(DATA, encoding="utf-8"))
rows = []
for node in events.get("nodes", []):
    nid = str(node.get("id"))
    month = node.get("month")
    for i, beat in enumerate(node.get("beats") or []):
        if not isinstance(beat, dict) or beat.get("type") != "say":
            continue
        text = str(beat.get("text", ""))
        spk = str(beat.get("speaker", ""))
        g = guess(text)
        have = faces(spk)
        why = []
        if g == "开心" and any(k in text for k in ["不", "没", "别", "错", "风险", "延期"]):
            why.append("因「%s」判开心，但这句在说负面事" % next(k for k in POS if k in text))
        if g == "疑惑" and (text.rstrip().endswith("。") or text.rstrip().endswith("！")) and any(
                k in text for k in INTENT):
            why.append("是表态不是提问，却挂疑惑")
        if g == "疑惑" and "？" in text and any(k in text for k in INTENT):
            why.append("句里带问号但重点是我要去做")
        if g == "认真" and any(k in text for k in FRIENDLY):
            why.append("因「%s」判认真，但这句是安抚/客气" % next(k for k in SERIOUS if k in text))
        if g == "自然" and any(k in text for k in ["谢谢", "辛苦", "恭喜", "不错"]):
            why.append("句里有明显情绪，却给了中性脸")
        if have and g not in have:
            why.append("该角色没有「%s」这张脸，实际会退回自然" % g)
        if why:
            rows.append("第%s月 %s b%d｜%s｜猜→%s｜%s\n        %s" % (
                month, nid, i, spk, g, "；".join(why), text[:64]))

io.open(r"E:\03_Projects\bear\workplace_town\test_artifacts\_f6_expr.txt", "w", encoding="utf-8").write(
    "可疑 %d 处 / 全年 say 拍若干\n\n" % len(rows) + "\n".join(rows))
print("suspicious", len(rows))
