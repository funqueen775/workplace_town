# -*- coding: utf-8 -*-
"""第 6 月时间线修正（2026-10-30）：答辩排在"第二天早上"，走廊等候挪到答辩前。

现状（数据侧）：
  WALL/PICK/WALL_OUT 三屏的旬是「中旬」，而册子写的是「上旬 · 午后」；
  答辩五屏的旬是「下旬」，而册子写的是「中旬 · 上午」，王哥和陈工的消息也说"明天/中旬"；
  M06_CORRIDOR 前四句是"还没进门"的话（HRBP：你先在外面等一下），却排在答辩之后。
改法：
  1) 挑三件那一场（WALL / PICK / WALL_OUT）回到「上旬」；
  2) 答辩五屏与走廊那一屏回到「中旬」；
  3) "明天十点"改成"中旬，上午十点"（答辩确实隔了几天，不是第二天）；
  4) 走廊等候四句挪到答辩第一屏的开头，答辩那屏改成"中旬那天九点五十"；
  5) 走廊那屏只留出门后的三句，新增 M06_WAIT「回工位等通知」承接册子 E 段；
  6) WALL_OUT 补一句睡觉的离屏交代。

跑法（在 workplace_town/ 下）：python tools/v12m_fix_m6_timeline.py
写盘前会断言所有锚点；写盘后回读，确认同期另一条线的改动还在。
"""
import hashlib
import io
import json
import os
import sys

PATH = "data/story/v12m/events.json"


def load():
    with io.open(PATH, encoding="utf-8") as f:
        return json.load(f)


def save(data):
    with io.open(PATH, "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def one(node, text):
    hits = [b for b in node.get("beats", []) if b.get("text") == text]
    assert len(hits) == 1, "锚点找不到或有重复：%s / %s" % (node.get("id"), text[:24])
    return hits[0]


def main():
    before = os.stat(PATH)
    raw_before = io.open(PATH, "rb").read()
    data = load()
    by = {n["id"]: n for n in data["nodes"]}

    # 1) 旬：挑三件在「上旬」、答辩与走廊在「中旬」（2026-10-30 另一条线已先改到位，这里只核对）
    for nid in ("M06_WALL", "M06_PICK", "M06_WALL_OUT"):
        assert by[nid].get("phase") == "early", (nid, by[nid].get("phase"))
    for nid in ("M06_DEF1", "M06_DEF2", "M06_DEF3", "M06_DEF4", "M06_DEF5", "M06_CORRIDOR"):
        assert by[nid].get("phase") == "mid", (nid, by[nid].get("phase"))

    # 3) 王哥那句"明天十点"：答辩在中旬，不是第二天
    one(by["M06_OPEN"], "挑完回来写四页。明天十点，A 区小会议室，别迟到。")["text"] = \
        "挑完回来写四页。中旬，上午十点，A 区小会议室，别迟到。"
    wall_out = by["M06_WALL_OUT"]
    for beat in wall_out["beats"]:
        text = beat.get("text", "")
        if text.startswith("走了。明天十点答辩"):
            beat["text"] = text.replace("明天十点答辩", "中旬那天十点答辩", 1)
            break
    else:
        raise AssertionError("M06_WALL_OUT 第一句没找到")
    one(by["M06_WALL_OUT"], "改到十一点，四页删成三页半。你在便签背面写了一行：明天十点，A 区小会议室。")["text"] = \
        "改到十一点，四页删成三页半。你在便签背面写了一行：中旬，上午十点，A 区小会议室。"
    one(by["M06_WALL_OUT"], "关灯。明天要讲的，就是这些。")["text"] = \
        "关灯。中旬那天要讲的，就是这些。"
    by["M06_WALL_OUT"]["departNote"] = "睡吧。中旬那天十点，A 区小会议室。"

    # 4) 走廊等候四句挪到答辩之前
    corridor = by["M06_CORRIDOR"]
    wait_beats = [
        {"type": "say", "speaker": "HRBP", "text": "你先在外面等一下。"},
        {"type": "narration", "text": "走廊不长。门里有人说话，你听不清是谁。"},
        {"type": "narration", "text": "小赵靠着另一头的墙。他比你早进去，也晚一点出来。"},
        {"type": "narration", "text": "你们都没问对方答得怎么样。"},
    ]
    for beat in wait_beats:
        assert any(b.get("text") == beat["text"] for b in corridor["beats"]), beat["text"]
    def1 = by["M06_DEF1"]
    assert def1["beats"][0]["text"].startswith("第二天九点五十，A 区小会议室门口"), def1["beats"][0]["text"][:30]
    def1["beats"][0]["text"] = "中旬那天九点五十，A 区小会议室门口，老周已经在了，手里也拿着一叠。他看了你一眼，没问这几页改到几点。"
    def1["beats"][1:1] = wait_beats + [{"type": "narration", "text": "门里叫了你的名字。"}]

    # 5) 走廊那屏只留出门后的三句；回工位等通知单独一屏（册子 E 段）
    corridor["title"] = "会后 · 走廊"
    corridor["beats"] = [
        {"type": "narration", "text": "门开了。陈工拿着那叠表出来。"},
        {"type": "say", "speaker": "陈工", "text": "材料我留着，你自己来取。"},
        {"type": "narration", "text": "他没说过没过。评定结果留到下个月月初。"},
    ]
    corridor["departNote"] = "先回工位。结果下个月初才到。"

    wait = {
        "id": "M06_WAIT",
        "month": 6,
        "order": 235,
        "nodeType": "main_story",
        "title": "回工位等通知",
        "location": "B 区工位",
        "locationId": "B",
        "phase": "mid",
        "timeBand": "night",
        "walk": True,
        "walkNote": "答辩完了，回工位等通知",
        "beats": [
            {"type": "narration", "text": "回到工位，桌上没有评定表。"},
            {"type": "narration", "text": "你把四页材料收回文件夹。这半年做过的事，你挑了三件带进去。"},
            {"type": "narration", "text": "答辩结果还没到。"},
        ],
        "departNote": "结果下个月初到。这一月到这儿就完了。",
    }
    if "M06_WAIT" not in by:
        data["nodes"].append(wait)
    save(data)

    # 6) 回读：我的改动在、同期另一条线的改动也还在
    after = load()
    a = {n["id"]: n for n in after["nodes"]}
    assert a["M06_DEF1"]["phase"] == "mid"
    assert a["M06_WAIT"]["order"] == 235
    blob = io.open(PATH, encoding="utf-8").read()
    for mark in ("带回来的这几张", "只能挑一张当主讲", "M03_LATE", "M03_NOTICE", "这一旬你手上只欠一件事"):
        assert mark in blob, "写盘把另一条线的改动弄丢了：%s" % mark
    end = os.stat(PATH)
    print("写入完成：%d → %d 字节，mtime %d → %d" % (len(raw_before), end.st_size, before.st_mtime, end.st_mtime))
    print("sha256 新：%s" % hashlib.sha256(io.open(PATH, "rb").read()).hexdigest()[:16])


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print("没写盘：%s" % exc)
        sys.exit(1)
