# -*- coding: utf-8 -*-
"""F4 + F6 一次落数据：
   F4：给第 3 月 E12 的另两支补第 4 月回响（句子先写进剧情册，这里只是接上）。
   F6：五处语气被猜反的台词，显式写 expression。"""
import io
import json

DATA = r"E:\03_Projects\bear\workplace_town\data\story\v12m\events.json"

ECHO = {
    "m03_e12_team_knowledge_base": "组里新开了一个知识库，链接你发过两回。第一次有人回了个「好」，第二次没人回。",
    "m03_e12_own_module_index": "你自己那半页有了目录，哪一条都指得出来。别人的半页还是老样子，问起来还得挨个找人。",
}
EXPR = [
    ("M03_OPEN", 3, "认真"),
    ("M09_NAME", 9, "认真"),
    ("E10", 1, "自然"),
    ("E31", 1, "开心"),
    ("M06_DEF5", 6, "开心"),
]

raw = io.open(DATA, encoding="utf-8", newline="").read()
data = json.loads(raw)
by_id = {str(n.get("id")): n for n in data.get("nodes", [])}
log = []

host = by_id.get("M04_OPEN")
beats = host.get("beats") or []
anchor = None
for i, b in enumerate(beats):
    if str((b.get("when") or {}).get("flag", "")) == "m03_e12_bold_note":
        anchor = i
assert anchor is not None, "找不到加粗那一拍"
existing = {str((b.get("when") or {}).get("flag", "")) for b in beats}
insert = []
for flag, text in ECHO.items():
    if flag in existing:
        log.append("跳过（已有）：%s" % flag)
        continue
    insert.append({"type": "narration", "text": text, "when": {"flag": flag}})
beats[anchor + 1:anchor + 1] = insert
log.append("M04_OPEN 插入回响 %d 条（在第 %d 拍之后）" % (len(insert), anchor))

for nid, index, face in EXPR:
    node = by_id.get(nid)
    if node is None:
        log.append("找不到节点 %s" % nid)
        continue
    bs = node.get("beats") or []
    if index >= len(bs):
        log.append("%s 第 %d 拍越界" % (nid, index))
        continue
    beat = bs[index]
    rebuilt = {}
    for k, v in beat.items():
        rebuilt[k] = v
        if k == "text":
            rebuilt["expression"] = face
    beat.clear()
    beat.update(rebuilt)
    log.append("%s b%d %s → 显式表情「%s」" % (nid, index, beat.get("speaker"), face))

io.open(DATA, "w", encoding="utf-8", newline="").write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
io.open(
    r"E:\03_Projects\bear\workplace_town\test_artifacts\_f46_applied.txt", "w", encoding="utf-8"
).write("\n".join(log))
print("\n".join(log).encode("unicode_escape").decode()[:200])
print("lines", len(log))
