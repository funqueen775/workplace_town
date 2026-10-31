"""第三轮收尾：三条红线的「结果便签」在册子里写清"这是线不是分"，并统一"网络波动"叫法。"""
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import storybook_patch_coherence as S  # 复用同一套断言式替换

from docx import Document

FIXES = [
    ("结果便签 B：那晚我直接改了。",
     "结果便签 B：那晚我直接改了，工单没补——这条是线，不是分。",
     1, "第5月夜间：便签写清越线"),
    ("结果便签 B：把翻车说成了网络抖动。",
     "结果便签 B：把翻车说成网络波动——这条是线，不是分。",
     1, "第5月Demo：便签写清越线，并统一「网络波动」"),
    ("②把现场问题说成网络波动、推给不可控因素——第五月 E17「说是网络波动，再演一遍」（m05_e17_blame_network）；",
     "②把现场问题说成网络波动、推给不可控因素——第五月 E17「说是网络波动，再演一遍」（m05_e17_blame_network）；",
     1, "全年规则：红线条②用词已一致，不动"),
    ("陈工：还有几条是线，不是分数。没授权的承诺不许给客户；现场出了问题不许说成网络抖动；",
     "陈工：还有几条是线，不是分数。没授权的承诺不许给客户；现场出了问题不许说成网络波动；",
     1, "第1月：说明会那句跟着统一用词"),
]


def main():
    apply = "--apply" in sys.argv
    doc = Document(str(S.DOCX))
    for old, new, expect, note in FIXES:
        S.apply_fix(doc, old, new, expect, note)
    if not apply:
        print("演练通过：加 --apply 才真写。")
        return
    stamp = time.strftime("%Y%m%d_%H%M")
    import shutil
    bak = S.BAK_DIR / f"storybook_backup_{stamp}.docx"
    shutil.copy2(S.DOCX, bak)
    print(f"备份 -> {bak}")
    doc.save(str(S.DOCX))
    print(f"已写回 {S.DOCX}")


if __name__ == "__main__":
    main()
