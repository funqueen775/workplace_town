"""第 3 月中旬·下旬节奏：把"两周"从一句话变成一屏有人说话的戏，并给 E12 一个入口。

册子先改（storybook_patch_m3_pacing.py），这里落数据：
  M03_BRIDGE  → 补 departNote（同区换时段也要交代）
  M03_MID     → 目标行 + 客户结果三版 + 王哥对清单的反应三版 + 小赵那条线 + 屏末交代
  E12         → 第一拍接中旬小赵那句；"修了三周"改成中旬演过的那条线
"""
import json
import shutil
import sys
import time
from pathlib import Path

ROOT = Path(r"E:\03_Projects\bear\workplace_town")
EVENTS = ROOT / "data" / "story" / "v12m" / "events.json"
BAK = ROOT / "test_artifacts"


def narr(text, when=None, goal=False):
    beat = {"type": "narration", "text": text}
    if when:
        beat["when"] = when
    if goal:
        beat["goalLine"] = True
    return beat


def say(speaker, text, when=None, emphasis=None):
    beat = {"type": "say", "speaker": speaker, "text": text}
    if when:
        beat["when"] = when
    if emphasis:
        beat["emphasis"] = emphasis
    return beat


E10_VARIANTS = [
    ("m03_e10_truth_with_fallback", "合同签了。附页那三行兜底是你写的，方经理每周让人来问一次：有没有照做。"),
    ("m03_e10_soft_clause", "合同签了，用的是「尽商业上合理努力」那一句。两个星期里没人来问过这句该怎么算。"),
    ("m03_e10_overpromise", "合同签了。小林把副本传上共享盘，从头到尾没跟你提那天会场上的事。"),
]

LIST_VARIANTS = [
    ("m03_e10_handoff_complete", "你那份清单我拿去开了周会。以后散会当天就发，别等到周四。"),
    ("m03_e10_handoff_partial", "清单我看到了。下次确认时间那一栏是空的——不给组里看，它就只是我们俩的备忘。"),
    ("m03_e10_handoff_blank", "周四过了，没人来问那份清单。下次散会当天发我，哪怕只写两行。"),
]


def main():
    apply = "--apply" in sys.argv
    data = json.loads(EVENTS.read_text(encoding="utf-8"))
    nodes = {n.get("id"): n for n in data.get("nodes", []) if isinstance(n, dict)}

    # ---- 1. 桥段收尾交代去中旬
    bridge = nodes.get("M03_BRIDGE")
    if bridge is None:
        raise SystemExit("[中止] 找不到 M03_BRIDGE")
    if bridge.get("departNote"):
        raise SystemExit("[中止] M03_BRIDGE 已有 departNote")
    bridge["departNote"] = "今天到这儿。那三行明天跟着版本上线，先看两个星期。"

    # ---- 2. 中旬那一屏
    mid = nodes.get("M03_MID")
    if mid is None:
        raise SystemExit("[中止] 找不到 M03_MID")
    old_lines = [b.get("text", "") for b in (mid.get("beats") or [])]
    if len(old_lines) != 1 or "跑了两周" not in old_lines[0]:
        raise SystemExit(f"[中止] M03_MID 现在不是那一句话：{old_lines}")
    beats = [narr("中旬 · 上午。那句兜底上线两个星期了，头一件回来找你的事在这儿。", goal=True),
             narr("散会那天王哥只要了三样东西，你发出去了。这两个星期，它有没有被用上？")]
    for flag, text in E10_VARIANTS:
        beats.append(narr(text, {"flag": flag}))
    for flag, text in LIST_VARIANTS:
        beats.append(say("王哥", text, {"flag": flag}))
    beats.append(say("小赵", "还是我那条线。三周里又撞上一次，还是没人知道以前撞过几次。"
                             "上旬你在群里问那个数，是不是到现在也没人回？"))
    beats.append(narr("他把手里的杯子往你桌上一放：傍晚别走，我翻到了一点东西，你一起看。"))
    mid["beats"] = beats
    mid["durationMinutes"] = 60
    mid["walkNote"] = "那三行上线两周了"
    mid["situation"] = "medium"
    mid["note"] = "中旬 · 上午｜这两周发生了什么"

    # ---- 3. E12 的入口与那句"三周"
    e12 = nodes.get("E12")
    if e12 is None:
        raise SystemExit("[中止] 找不到 E12")
    first = (e12.get("beats") or [{}])[0].get("text", "")
    if "你又打开" not in first:
        raise SystemExit(f"[中止] E12 第一拍不是预期的那句：{first[:30]}")
    e12["beats"][0]["text"] = ("傍晚回工位，你把那份《常见问题》又打开。"
                               "结论还在，怎么得出结论的过程不在。小赵把他翻到的东西拖到你屏幕上。")
    hit = False
    for beat in e12["beats"]:
        if "你修了三周的问题没有复发" in beat.get("text", ""):
            beat["text"] = "小赵那条线三周里又撞上一次。没人知道以前撞过几次——它不是被修好了，是从来没人记着它。"
            beat["emphasis"] = ["从来没人记着它"]
            hit = True
    if not hit:
        raise SystemExit("[中止] E12 里找不到「修了三周」那一句")

    print("M03_MID 拍数 %d（含客户三版 + 清单三版）；E12 入口已接上" % len(beats))
    if not apply:
        print("演练通过：加 --apply 才真写。")
        return
    stamp = time.strftime("%Y%m%d_%H%M")
    shutil.copy2(EVENTS, BAK / f"events_backup_{stamp}.json")
    EVENTS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"已写回 {EVENTS.name}（备份 stamp={stamp}）")


if __name__ == "__main__":
    main()
