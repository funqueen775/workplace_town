"""三条红线的「结果便签」（memoryNote）写清这是线不是分——册子 P0246 要求便签与结果句一致。"""
import json
import shutil
import sys
import time
from pathlib import Path

ROOT = Path(r"E:\03_Projects\bear\workplace_town")
EVENTS = ROOT / "data" / "story" / "v12m" / "events.json"
BAK = ROOT / "test_artifacts"

WANTS = [
    ("E10", "C", "先应下了——这句超出了授权。是线，不是分。"),
    ("M05_NIGHT", "B", "那晚我直接改了，工单没补。是线，不是分。"),
    ("M05_DEMO", "B", "把翻车说成网络波动。是线，不是分。"),
]


def main():
    apply = "--apply" in sys.argv
    data = json.loads(EVENTS.read_text(encoding="utf-8"))
    nodes = {n.get("id"): n for n in data.get("nodes", []) if isinstance(n, dict)}
    for node_id, letter, text in WANTS:
        node = nodes.get(node_id)
        if node is None:
            raise SystemExit(f"[中止] 找不到节点 {node_id}")
        notes = node.get("memoryNote")
        if not isinstance(notes, dict) or letter not in notes:
            raise SystemExit(f"[中止] {node_id} 没有 memoryNote[{letter}]")
        old = str(notes[letter].get("text", ""))
        if old == text:
            print(f"  已改过 {node_id}.{letter}")
            continue
        notes[letter]["text"] = text
        print(f"  {node_id}.{letter}：{old} → {text}")
    if not apply:
        print("演练通过：加 --apply 才真写。")
        return
    stamp = time.strftime("%Y%m%d_%H%M")
    shutil.copy2(EVENTS, BAK / f"events_backup_{stamp}.json")
    EVENTS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"已写回 {EVENTS.name}（备份 stamp={stamp}）")


if __name__ == "__main__":
    main()
