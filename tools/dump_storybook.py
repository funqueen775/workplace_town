"""把剧情册.docx 按阅读顺序倒出来（段落 + 表格交错，莫漏表）。

docx 的正文在 body 里是按顺序排的 w:p / w:tbl；python-docx 的 .paragraphs 会把表全跳过，
所以这里自己走 XML，一段一段照原样输出，表格用 | 分行。

用法：python tools/dump_storybook.py [docx路径] [输出txt路径]
"""
from __future__ import annotations

import sys
from pathlib import Path

from docx import Document
from docx.table import Table
from docx.text.paragraph import Paragraph


def iter_block_items(parent):
    from docx.oxml.ns import qn

    body = parent.element.body
    for child in body.iterchildren():
        if child.tag == qn("w:p"):
            yield Paragraph(child, parent)
        elif child.tag == qn("w:tbl"):
            yield Table(child, parent)


def main() -> None:
    src = Path(sys.argv[1] if len(sys.argv) > 1 else r"E:\03_Projects\bear\剧情册.docx")
    out = Path(sys.argv[2] if len(sys.argv) > 2 else r"E:\03_Projects\bear\_storybook_dump.txt")
    doc = Document(str(src))
    lines: list[str] = []
    table_no = 0
    para_no = 0
    for block in iter_block_items(doc):
        if isinstance(block, Paragraph):
            text = block.text.strip()
            if not text:
                continue
            para_no += 1
            style = (block.style.name or "").lower()
            prefix = ""
            if "heading" in style or "标题" in style:
                prefix = "#" * max(1, int(style[-1]) if style[-1].isdigit() else 2) + " "
            lines.append(f"[P{para_no:04d}] {prefix}{text}")
        else:
            table_no += 1
            lines.append(f"\n[表 {table_no}]")
            for row in block.rows:
                cells = []
                for cell in row.cells:
                    cells.append(" ".join(cell.text.split()))
                lines.append("| " + " | ".join(cells) + " |")
            lines.append("")
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"段落 {para_no} 个 / 表格 {table_no} 张 / {sum(len(x) for x in lines)} 字 -> {out}")


if __name__ == "__main__":
    main()
