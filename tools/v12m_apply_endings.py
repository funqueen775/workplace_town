"""把"转正只判一次 + 违纪解除 + 短收束"落到剧情数据上。

改的是 data/story/v12m/events.json 与 manifest.json：
  1. 第一月说明会当场念三条线（红线成立的前提是事先告知）。
  2. 第七月结果屏从「通过 / 延期」两版改成「转正 / 未转正 / 违纪解除」三版。
  3. 所有读 m07_probation_deferred 的门改读 probation_ended / probation_confirmed。
  4. 新增 M07_CLOSURE：停在第七月的人拿到的那份短收束。
  5. 三条红线的结果句各自写明"这是线不是分"。
每步都断言命中数，不对就整批中止；先备份。
"""
import io
import json
import shutil
import sys
import time
from pathlib import Path

ROOT = Path(r"E:\03_Projects\bear\workplace_town")
DATA = ROOT / "data" / "story" / "v12m"
BAK = ROOT / "test_artifacts"

EVENTS = DATA / "events.json"
MANIFEST = DATA / "manifest.json"


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def save(path, obj):
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def find_node(nodes, node_id):
    for node in nodes:
        if node.get("id") == node_id:
            return node
    raise SystemExit(f"[中止] 找不到节点 {node_id}")


def beat_index(node, needle, expect=1):
    hits = [i for i, b in enumerate(node.get("beats", [])) if needle in b.get("text", "")]
    if len(hits) != expect:
        raise SystemExit(f"[中止] {node.get('id')} 里「{needle[:20]}」应 {expect} 处，实际 {len(hits)}")
    return hits[0]


def drop_beat(node, needle):
    idx = beat_index(node, needle)
    return node["beats"].pop(idx)


def say(text, speaker="王哥", when=None, emphasis=None):
    beat = {"type": "say", "speaker": speaker, "text": text}
    if when:
        beat["when"] = when
    if emphasis:
        beat["emphasis"] = emphasis
    return beat


def narr(text, when=None):
    beat = {"type": "narration", "text": text}
    if when:
        beat["when"] = when
    return beat


def main():
    apply = "--apply" in sys.argv
    events = load(EVENTS)
    manifest = load(MANIFEST)
    nodes = events["nodes"]
    changed = 0

    # ---- 1. 第一月：入职说明会当众念三条线
    e01 = find_node(nodes, "E01")
    at = beat_index(e01, "写你做过的事，别写你想做的事")
    if any("是线，不是分数" in b.get("text", "") for b in e01["beats"]):
        raise SystemExit("[中止] E01 已经有那三条线了")
    e01["beats"].insert(at + 1, say(
        "还有几条是线，不是分数。没授权的承诺不许给客户；现场出了问题不许说成网络波动；"
        "绕过审批改了线上，当天就得把记录补上。这几条今天讲过，后面按今天说的处理。",
        speaker="陈工"))
    changed += 1

    # ---- 2. 第七月结果屏：两版改三版
    result = find_node(nodes, "M07_RESULT")
    for beat in result["beats"]:
        when = beat.get("when") or {}
        if when.get("notFlag") == "m07_probation_deferred":
            beat["when"] = {"flag": "probation_confirmed"}
    drop_beat(result, "系统状态更新成“延期转正”")
    drop_beat(result, "这次先延期")
    result["beats"] += [
        narr("系统状态更新成“解除劳动合同”。下面附三行：违反的是「{红线条文}」；"
             "记录落在{红线那月}；经办人 HR，日期就是今天。", {"flag": "probation_terminated"}),
        say("这次跟分数没关系。那条线入职那天当众讲过；纸上是哪一条、哪个月哪件事，都写着。",
            when={"flag": "probation_terminated"}),
        narr("系统状态更新成“未转正”。HR 把一份交接清单放在桌上，旁边附一句书面理由："
             "岗位标准里差的是「{差的那一维}」，依据是记录里那几条，不是谁的印象。",
             {"flag": "probation_not_confirmed"}),
        say("先把你手上的模块交清楚。哪些已经完成、哪些还没确认、下一步谁接，都写在这张表里。",
            when={"flag": "probation_not_confirmed"}),
        say("昨天客户 Demo 出了一条越过需求的回复，线上已经回滚。周五下午去 A 区会议室复盘，"
            "带上规则提交、审核和发布记录，按时间线把你负责的部分讲清。",
            speaker="陈工", when={"flag": "probation_confirmed"}),
    ]
    changed += 1

    # ---- 3. E19：只给转正的人；延期那几拍删掉
    e19 = find_node(nodes, "E19")
    e19["when"] = {"notFlag": "probation_ended"}
    before = len(e19["beats"])
    e19["beats"] = [b for b in e19["beats"] if (b.get("when") or {}).get("flag") != "m07_probation_deferred"]
    removed = before - len(e19["beats"])
    if removed != 3:
        raise SystemExit(f"[中止] E19 该删 3 拍延期台词，实际删了 {removed}")
    for beat in e19["beats"]:
        if (beat.get("when") or {}).get("notFlag") == "m07_probation_deferred":
            beat.pop("when")
    changed += 1

    # ---- 4. 那张纸：改成未转正 / 违纪解除的纸；复盘召集挪到结果屏
    paper = find_node(nodes, "M07_PAPER")
    paper["when"] = {"flag": "probation_ended"}
    drop_beat(paper, "周五下午去 A 区会议室复盘")
    at = beat_index(paper, "技能、产出、人脉、状态四项")
    paper["beats"][at]["text"] = "四项按技能判断、独立交付、协作与交接、署名与证据给，每项只写一条反馈，没有数字。"
    at = beat_index(paper, "材料我放你桌上了")
    paper["beats"][at]["text"] = "交接清单我放你桌上了。哪一项说不清，去问陈工，别自己猜。"
    at = beat_index(paper, "复核我会参加")
    paper["beats"][at]["text"] = "（路过）清单逐项对完再走。做完的、没确认的、谁接手，都写在这张表上。"
    paper["beats"].insert(1, narr("这张纸的抬头不一样：解除通知三行——条文、记录、经办人。",
                                  {"flag": "probation_terminated"}))
    changed += 1

    # ---- 5. 交接屏：两版收尾
    hand = find_node(nodes, "M07_HANDOVER")
    hand["when"] = {"flag": "probation_ended"}
    idx = beat_index(hand, "复核通过之前，后面的活不会派到你手上")
    hand["beats"].pop(idx)
    hand["beats"] += [
        narr("依据和条文都写在纸上。这段工作关系到这里为止。", {"flag": "probation_terminated"}),
        narr("差在哪一项写在纸上。这个月的活交完，后面的窗口再看。", {"flag": "probation_not_confirmed"}),
    ]
    changed += 1

    # ---- 6. 短收束那一屏（未转正 / 违纪解除共用）
    if any(n.get("id") == "M07_CLOSURE" for n in nodes):
        raise SystemExit("[中止] M07_CLOSURE 已经存在")
    closure = {
        "id": "M07_CLOSURE", "month": 7, "order": 216, "nodeType": "main_story", "required": True,
        "title": "那张收束的纸", "locationId": "B", "location": "B 区工位",
        "durationMinutes": 30, "situation": "weak", "timeBand": "afternoon", "phase": "mid",
        "reportUse": "story_only", "autoComplete": True, "walk": True,
        "walkNote": "纸收好，这一年的记录归拢",
        "when": {"flag": "probation_ended"},
        "setsFlags": ["m07_closure_seen"],
        "choices": [],
        "beats": [
            narr("下午，HR 把那份材料推过来。不是评定表，也没有分数。"),
            narr("左边一栏是这一年做过、并且留下记录的事；右边一栏是差的那一项；最下面一行是下一步。"),
            narr("条文那一行写着：{红线条文}。记录落在{红线那月}。", {"flag": "probation_terminated"}),
            narr("差的那一栏写着「{差的那一维}」——依据是记录里那几条。", {"flag": "probation_not_confirmed"}),
            say("这份你带走。下一次窗口要补什么，照着最下面那一行来。"),
            narr("第十二月末那份完整年度报告只对走完十二个月的人开放；这一份收在这里，只写已经发生的事。"),
        ],
    }
    nodes.append(closure)
    at = manifest["nodeOrder"].index("M07_HANDOVER")
    manifest["nodeOrder"].insert(at + 1, "M07_CLOSURE")
    changed += 1

    # ---- 7. 走了的人不再收到打球邀约与自由安排
    for node_id in ("M07_FREE", "M07_PHONE_XZ", "M07_PHONE_LZ", "M07_SPORTS_INVITE"):
        node = find_node(nodes, node_id)
        if node.get("when") not in (None, {}):
            raise SystemExit(f"[中止] {node_id} 已有 when：{node.get('when')}")
        node["when"] = {"notFlag": "probation_ended"}
    changed += 1

    # ---- 8. 三条红线的结果句：写清这是线不是分
    marks = [
        ("E10", "C", "小林把这一句单独抄进合同风险栏。超出授权的承诺，从今天起记在案上。"),
        ("M05_DEMO", "B", "陈工在复盘表上落了一行：归因先按可核验记录。这句话入职那天讲过。"),
        ("M05_NIGHT", "B", "工单始终没补。绕开审批动线上这一条，记在案上，不算进任何分数。"),
    ]
    for node_id, letter, tail in marks:
        node = find_node(nodes, node_id)
        for choice in node.get("choices", []):
            if choice.get("id") == letter:
                if tail in choice.get("outcome", ""):
                    raise SystemExit(f"[中止] {node_id}.{letter} 已经标过了")
                choice["outcome"] = choice.get("outcome", "") + tail
                break
        else:
            raise SystemExit(f"[中止] {node_id} 找不到选项 {letter}")
    changed += 1

    print(f"改动 {changed} 处；结果屏 {len(result['beats'])} 拍，那张纸 {len(paper['beats'])} 拍，"
          f"E19 {len(e19['beats'])} 拍，短收束 {len(closure['beats'])} 拍")
    if not apply:
        print("演练通过：加 --apply 才真写。")
        return
    stamp = time.strftime("%Y%m%d_%H%M")
    shutil.copy2(EVENTS, BAK / f"events_backup_{stamp}.json")
    shutil.copy2(MANIFEST, BAK / f"manifest_backup_{stamp}.json")
    save(EVENTS, events)
    save(MANIFEST, manifest)
    print(f"已写回 {EVENTS.name} / {MANIFEST.name}（备份 stamp={stamp}）")


if __name__ == "__main__":
    main()
