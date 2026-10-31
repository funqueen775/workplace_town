# -*- coding: utf-8 -*-
"""把「换区必交代去向」的三处修订补进剧情册.docx（与 events.json 同步）。

1) 第 8 月 E23→E25 过桥：三版分支之后补一句安全组的下文（去 A 区合规复盘室）。
2) 第 12 月 A 段：旁白「明天九点，评委…」补上地点「A 区大会议室」。
3) 第 12 月 F 段：六幕回放前补一句「从工位走到心湖北岸」。

做法：不改样式，复制普通正文段当模板，换 <w:t> 里的字再插到锚点前；替换是就地改文本。
用法：python tools/patch_departure_lines.py [docx路径]
"""
import re
import shutil
import sys
import zipfile
from pathlib import Path

SRC = Path(sys.argv[1] if len(sys.argv) > 1 else r"E:\03_Projects\bear\剧情册.docx")
BAK = Path(r"E:\03_Projects\bear\_bak_20261030_departure") / SRC.name

TEMPLATE = ('<w:p><w:pPr><w:keepLines/>'
            '<w:spacing w:after="60" w:line="269" w:lineRule="auto"/><w:ind w:left="115"/>'
            '</w:pPr><w:r><w:t>{}</w:t></w:r></w:p>')

# (锚点, 新句) —— 新句插在锚点所在段落之前
INSERTS = [
    ("【分支实现】每位玩家只看与自己路线对应的一版",
     "旁白：下班前安全组回了一行：明天上午十点，A 区合规复盘室，把你查到的东西带过去。"),
    ("【界面】标题：“六幕，你都走过来了”。",
     "旁白：从工位一路走到心湖北岸，风把楼道里的空调味吹掉了。最后半天，墙前没有别人。"),
]

REPLACES = [
    ("旁白：明天九点，评委会问你这一年负责过什么。",
     "旁白：明天九点，A 区大会议室。评委会问你这一年负责过什么。"),
]


def main() -> None:
    z = zipfile.ZipFile(SRC)
    xml = z.read("word/document.xml").decode("utf-8")
    items = [(i, z.read(i.filename)) for i in z.infolist()]
    z.close()

    for anchor, sentence in INSERTS:
        if xml.count(anchor) != 1:
            raise SystemExit("锚点不唯一或找不到（%d 次）：%s" % (xml.count(anchor), anchor))
        index = xml.find(anchor)
        start = xml.rfind("<w:p>", 0, index)
        if start < 0:
            raise SystemExit("锚点不在段落里：%s" % anchor)
        xml = xml[:start] + TEMPLATE.format(sentence) + xml[start:]

    for old, new in REPLACES:
        if xml.count(old) != 1:
            raise SystemExit("待替换句不唯一或找不到（%d 次）：%s" % (xml.count(old), old))
        xml = xml.replace(old, new)

    BAK.parent.mkdir(parents=True, exist_ok=True)
    if not BAK.exists():
        shutil.copy2(SRC, BAK)
        print("备份：", BAK)

    tmp = SRC.with_name(SRC.stem + "_tmp.docx")
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as out:
        for info, data in items:
            if info.filename == "word/document.xml":
                data = xml.encode("utf-8")
            out.writestr(info, data)
    tmp.replace(SRC)

    check = zipfile.ZipFile(SRC).read("word/document.xml").decode("utf-8")
    paras = re.findall(r"<w:p[ >].*?</w:p>", check, re.S)
    lines = ["".join(re.findall(r"<w:t[^>]*>(.*?)</w:t>", p, re.S)) for p in paras]
    for _, sentence in INSERTS:
        print(("有" if sentence in lines else "缺"), "|", sentence)
    for _, new in REPLACES:
        print(("有" if any(new in l for l in lines) else "缺"), "|", new)


if __name__ == "__main__":
    main()
