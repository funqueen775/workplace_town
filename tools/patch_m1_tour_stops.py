# -*- coding: utf-8 -*-
"""把第 1 月带巡的「每站收尾」补进剧情册.docx（与 events.json 里 E01_TOUR.stops[].beats 一致）。

做法：不动样式，复制同段落（王哥单 run 的普通正文段）当模板，换掉 <w:t> 里的字再插到锚点前。
第 5 站那句是就地替换，不是新增——它原来没有"好了，转完了"这半句。

用法：python tools/patch_m1_tour_stops.py [docx路径]
"""
import re
import shutil
import sys
import zipfile
from pathlib import Path

SRC = Path(sys.argv[1] if len(sys.argv) > 1 else r"E:\03_Projects\bear\剧情册.docx")
BAK = SRC.with_name(SRC.stem + "_bak_站末句前.docx")

# 模板：一整个王哥单 run 正文段，用来复制 pPr / 字体设置。
TEMPLATE = ('<w:p><w:pPr><w:keepLines/>'
            '<w:spacing w:after="60" w:line="269" w:lineRule="auto"/><w:ind w:left="115"/>'
            '</w:pPr><w:r><w:t>{}</w:t></w:r></w:p>')

# (锚点句的开头, 新增句) —— 新句插在锚点那段之前。
INSERTS = [
    ("王哥：这栋楼是 A 区总部",
     "王哥：好了，工位认过了。我们去下一个地方吧——A 区总部。"),
    ("王哥：中午别在一楼吃",
     "王哥：好了，手机拿着。看完这张卡我们就走，下一个地方是水道。"),
    ("王哥：想一个人待着就来这儿",
     "王哥：好了，水道就是条过路。走，我们去下一个地方——心湖步道。"),
    ("【旁白】 回到 B 区，王哥指了指工位上的手册。",
     "王哥：好了，湖也看了。走完这几处，我们回工位吧。"),
]

OLD_LAST = "王哥：手册在你桌上。先看第一章。我三点还有个会，你自己坐会儿。"
NEW_LAST = "王哥：好了，转完了。手册在你桌上，先看第一章。我三点还有个会，你自己坐会儿。"


def main() -> None:
    z = zipfile.ZipFile(SRC)
    xml = z.read("word/document.xml").decode("utf-8")
    items = [(i, z.read(i.filename)) for i in z.infolist()]
    z.close()

    for anchor, sentence in INSERTS:
        index = xml.find(anchor)
        if index < 0:
            raise SystemExit(f"锚点找不到：{anchor}")
        if xml.count(anchor) != 1:
            raise SystemExit(f"锚点不唯一：{anchor}")
        start = xml.rfind("<w:p>", 0, index)
        if start < 0:
            raise SystemExit(f"锚点不在段落里：{anchor}")
        xml = xml[:start] + TEMPLATE.format(sentence) + xml[start:]

    if xml.count(OLD_LAST) != 1:
        raise SystemExit("第 5 站那句不唯一或找不到")
    xml = xml.replace(OLD_LAST, NEW_LAST)

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

    # 回读核对：四句都进去了，且顺序在册子里读得通。
    check = zipfile.ZipFile(SRC).read("word/document.xml").decode("utf-8")
    paras = re.findall(r"<w:p[ >].*?</w:p>", check, re.S)
    lines = ["".join(re.findall(r"<w:t[^>]*>(.*?)</w:t>", p, re.S)) for p in paras]
    for _, sentence in INSERTS:
        print(("有" if sentence in lines else "缺"), "|", sentence)
    print(("有" if NEW_LAST in lines else "缺"), "|", NEW_LAST)
    for i, line in enumerate(lines):
        if line.startswith("C E01 带巡"):
            for row in lines[i:i + 18]:
                print("   ", row[:70])


if __name__ == "__main__":
    main()
