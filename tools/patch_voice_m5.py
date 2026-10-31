#!/usr/bin/env python3
"""第 5 月对白重写：路演、凌晨告警、客户现场三场戏。只改说法。

    python tools/patch_voice_m5.py            # 只看差异
    python tools/patch_voice_m5.py --apply    # 写回 events.json
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data/story/v12m/events.json"


def n(text: str, **extra) -> dict:
    beat = {"type": "narration", "text": text}
    beat.update(extra)
    return beat


def s(speaker: str, text: str, **extra) -> dict:
    beat = {"type": "say", "speaker": speaker, "text": text}
    beat.update(extra)
    return beat


def phone(speaker: str, text: str, **extra) -> dict:
    beat = {"type": "phone_cinematic", "speaker": speaker, "text": text}
    beat.update(extra)
    return beat


M05_OPEN = [
    n("上个月复盘会，「责任人」那一栏是你自己填的。", when={"flag": "m04_e07_clarified_in_room"}),
    n("上个月复盘会的纪要，「待定项」后面写了三个人的名字。", when={"flag": "m04_e07_process_review"}),
    n("上个月你认了那句没核清，散会以后没人接话。", when={"flag": "m04_e07_admitted_verification_gap"}),
    n("禾丰那套还在跑。18% 那条曲线被人截成图，在组里传了两轮。"),
    n("第五个月，上旬，早上。键盘边上放着一个牛皮纸袋，袋口没封。"),
    n("袋里一张路演流程单：「周五 14:00 · 会展码头 · 客户现场」。最后一行用马克笔加粗了——主讲，你。", emphasis=["主讲，你"]),
    n("背面还有一行小字，写着这场到底要干什么：十分钟，把拣货问答从头点到尾；客户会随手指一处，问「这里错了怎么办」。"),
    n("小林的便签贴在袋口，字很小：“屏幕是展厅的，接口自己想办法。麦在你手上，我在台下。”"),
    n("袋子底下还压着一个转接头。上次那个。"),
    s("小赵", "名单我看见了。王哥报的，他说讲自己写的那一段的人，只有你。"),
    n("你把日子算了一遍：中间只剩四天。"),
    s("王哥", "这周挑一天下午，我坐台下当客户。你先给我讲一遍，讲不顺的地方，那时候还改得动。"),
    n("四天：一天彩排，三天改稿，最后一天到会展码头。", goalLine=True),
]

M05_PREP = [
    n("那三天，那十分钟你改了四版。删掉的比留下的多。"),
    n("彩排那天下午，王哥搬了把椅子坐在你侧面，小林举着手机计时。"),
    s("王哥", "从头讲。我随时打断。"),
    n("你讲到第三页，他抬手。"),
    s("王哥", "「这里错了怎么办」——你刚才绕过去了。", emphasis=["绕过去了"]),
    n("你停了两秒。这条线这几天确实不太稳，监控上偶尔跳一下。"),
    s("王哥", "不稳就说稳了？换一句。"),
    n("你把那句改成：这一类会挂，挂了走备用流程。他点了下头，让你接着讲。"),
    n("第五遍讲完，小林按停计时器：九分四十。"),
    n("收电脑的时候，你瞥见监控面板上那条演示线路又跳了一下。"),
    s("王哥", "今晚别关灯。明天就是客户现场，我最怕它半夜自己动。", emphasis=["半夜自己动"]),
    n("天暗下来，整层只剩你这一排灯还亮着。"),
    n("你没走。先把这条线压住——明天下午两点，台上不能出事。"),
]

M05_NIGHT = [
    n("彩排完你没回去。外套垫在键盘上，睡到两点零七分，手机在耳边震。"),
    n("告警叠了四张，指向同一条线路——就是下午你讲了五遍的那条。明天下午两点，客户会看到它。"),
    phone("小赵", "正常审批要四个小时。客户四分钟后就该发现了。"),
    n("两分钟后，手机又亮了一下。"),
    phone("小赵", "这个点只有你在线。要不要我远程陪你？"),
    phone("王哥", "紧急通道不是后门。进去可以，得留下脚印。", emphasis=["得留下脚印"]),
    n("你往上翻了翻群聊。陈工在成员列表第一位，显示在线，没说话。"),
    n("亮起来的这个服务，是上周你提议移到下月、由王哥确认调整的那一格。现在它归你。", when={"flag": "m04_e05_full_evalset"}),
    n("四张告警里有一张，来自你那张表没盖住的地方。", when={"flag": "m04_e05_partial_evalset"}),
    n("审批页面开着，倒计时也开着。中间有一段改动，复制粘贴就能做完。你抬头看了眼整层楼，灯都亮着，没有人。"),
]

M05_DAWN = [
    n("处理完的时候，天已经蒙蒙亮。你趴在桌上又睡了三个小时，醒来是八点四十。"),
    n("日历翻过去了。上旬过完，今天就是中旬第一天，也是客户现场那天。"),
    n("会场门口，王哥已经在了。他把手机塞回口袋。"),
    s("王哥", "记录我看了。今天你只管讲，线上我来盯。"),
    n("你的审批记录里还空着一段。你没敢往上翻。", when={"flag": "m05_night_hotfix_unlogged"}),
    n("错误回复多留了三个半小时。这个数字，你今天得带进会场。", when={"flag": "m05_night_waited"}),
    n("工单号还在手机里，凌晨填完的那一张。你把它翻出来，存进了备忘录。", when={"flag": "m05_night_incident_recorded"}),
    n("十一点半，你出门。会展码头在镇子最南边，坐车过去还要一段。"),
    n("十二点五十到码头，一点半进主厅。两点，麦在你手上。"),
]

M05_DEMO = [
    n("两点差十分，主厅。展厅比想象的大，屏幕不是我们的。你们排第二组，前一组讲了二十分钟愿景，界面一次没打开。"),
    n("内网直播链接挂在群里。王哥没来，他在看。"),
    s("小林", "（低声）你那张表上不是写了哪几类最容易挂？今天别答错。", when={"flag": "m04_e05_full_evalset"}),
    s("小林", "（低声）等下客户问「错在哪一类」，我们手里一张表都没有。", when={"flag": "m04_e05_no_evalset"}),
    s("小林", "（低声）物流那类你测过，另外两类没底，讲到那儿别说满。", when={"flag": "m04_e05_partial_evalset"}),
    n("这条线昨晚被谁动过，你不知道。你只记得上午十一点四十才坐上出租车。", when={"flag": "m05_night_hotfix_unlogged"}),
    n("大屏上的助手停了两秒，然后告诉客户：“公司支持情绪退款，只要用户感觉受伤，就能全额赔付。”"),
    s("客户", "你们刚刚承诺了什么？"),
    s("小林", "这条不在脚本里。", emphasis=["这条不在脚本里"]),
    n("合同里没有「不会胡说」这句。上个月你和法务对到十点，才把边界写清楚。", when={"flag": "m03_e10_truth_with_fallback"}),
    n("合同写的是「尽商业上合理努力」。客户现在问的，是这次输出可不可靠。", when={"flag": "m03_e10_soft_clause"}),
    n("合同里那句「保证不胡说」，是你上个月点头加进去的。", when={"flag": "m03_e10_overpromise"}),
    n("你手里有评测记录，能看出哪类输入容易失败。", when={"flag": "m04_e05_full_evalset"}),
    n("你没有评测记录。这四张告警，只能靠嘴判断。", when={"flag": "m04_e05_no_evalset"}),
    n("表只覆盖了一部分，其他类别的结果还不确定。", when={"flag": "m04_e05_partial_evalset"}),
    s("老周", "看我没用。台上是你。"),
    phone("王哥", "备用流程在右下角。要切就现在。"),
    s("客户", "合同里不是写着不会胡说吗？"),
]

M05_COFFEE = [
    n("客户先走了。小林把电脑合上，说「坐下缓五分钟」，把你按在码头边那排外摆椅上。她打完电话回来，端着两杯咖啡，站在门口没往里走。"),
]

BEATS = {
    "M05_OPEN": M05_OPEN,
    "M05_PREP": M05_PREP,
    "M05_NIGHT": M05_NIGHT,
    "M05_DAWN": M05_DAWN,
    "M05_DEMO": M05_DEMO,
    "M05_COFFEE": M05_COFFEE,
}

CHOICES = {
    "M05_NIGHT": {
        "A": (None, "补丁 02:40 上线，工单 03:01 填完。第二天小林在纪要里引用了工单号，没人再问昨晚是谁动了线上。", None),
        "B": (None, "告警在第四分钟熄了。你趴在桌上睡到七点四十，赶上 Demo 前最后一趟车。审批记录里留了一段说不清的空白，工单始终没补。绕开审批动线上这一条，记在案上，不算进任何分数。", None),
        "C": (None, "审批四小时十七分才走完。错误回复多留了三个半小时。后来你在会议室里把这段时长念了出来。", None),
    },
    "M05_DEMO": {
        "A": (None, "大屏黑了半秒。你说刚才那句不可靠。第二排有人低头记了一句，客户把椅子往前挪了半寸，听你讲完最后两页。", None),
        "B": (None, "重来时换了措辞，结论没变。客户最后什么也没问。小林收线的时候把目光从屏幕上移开，回程谁都没提这件事。陈工在复盘表上落了一行：归因先按可核验记录。这句话，入职那天讲过。", None),
        "C": (None, "剩下三页讲得很稳，台下没人再提问。散场时你才发现转接头还插在投影仪上——那是从小林包里拿的。", None),
    },
    "M05_COFFEE": {
        "A": ("招手，让她过来坐", "她把杯子放到你面前，坐下，聊了十分钟，一句工作也没提。", None),
        "B": ("朝她点一下头", "她回了一下头，端着咖啡去了靠街那张桌子。", None),
        "C": ("掏出手机，假装回消息", "她站了一会儿，把另一杯留在你桌上，自己走了。", None),
    },
}

PROMPTS = {"M05_NIGHT": "这四分钟，你怎么办？"}
DEPART_NOTES = {
    "M05_OPEN": "周五下午两点，会展码头。在那之前，周四下午先彩排一遍。",
    "M05_PREP": "今晚不回宿舍了。灯不关，手机搁在手边。",
    "M05_NIGHT": "太晚了，回不去了。天亮还得去会展码头。",
}
MESSAGES = {
    "M05_PHONE": {"m05_zhao_1": "Demo 那天我在群里说话，没别的意思。就是觉得，别什么都自己扛。"},
    "M05_REMINDER": {"text": "下个月考评。材料自己先过一遍；真被问住了，就往我这边看一眼。"},
}
CARDS = {
    "M05_CLOSE": {
        "m05_night_incident_recorded": "那一夜你走了紧急通道，也把工单补齐了。",
        "m05_night_hotfix_unlogged": "那一夜你直接改了线上，没留下能对得上的记录。",
        "m05_night_waited": "你等到审批走完，代价是那三个半小时。",
        "m05_e17_admitted_error": "第二天在台上，你把那句不可靠说在了明处。",
        "m05_e17_blame_network": "第二天，你把翻车说成了网络抖动。",
        "m05_e17_continue": "那次翻车你没停，把后面几页讲完了。",
    }
}


def apply(nodes: list[dict]) -> list[str]:
    by_id = {str(node.get("id")): node for node in nodes}
    changes: list[str] = []

    for node_id, beats in BEATS.items():
        node = by_id[node_id]
        changes.append(f"{node_id}: beats {len(node.get('beats', []))} -> {len(beats)}")
        node["beats"] = beats

    for node_id, table in CHOICES.items():
        node = by_id[node_id]
        for choice in node.get("choices", []):
            cid = str(choice.get("id"))
            if cid not in table:
                continue
            text, outcome, emphasis = table[cid]
            if text:
                choice["text"] = text
            choice["outcome"] = outcome
            if emphasis:
                choice["emphasis"] = emphasis
            elif "emphasis" in choice:
                del choice["emphasis"]
        changes.append(f"{node_id}: {len(table)} 个选项")

    for node_id, prompt in PROMPTS.items():
        by_id[node_id]["prompt"] = prompt
        changes.append(f"{node_id}: prompt")

    for node_id, note in DEPART_NOTES.items():
        by_id[node_id]["departNote"] = note
        changes.append(f"{node_id}: departNote")

    for node_id, table in MESSAGES.items():
        node = by_id[node_id]
        for message in node.get("messages", []):
            mid = str(message.get("id", ""))
            if mid in table:
                message["text"] = table[mid]
            elif "text" in table:
                message["text"] = table["text"]
        changes.append(f"{node_id}: 消息")

    for node_id, table in CARDS.items():
        node = by_id[node_id]
        for card in node.get("cards", []):
            flag = str((card.get("when") or {}).get("flag", ""))
            if flag in table:
                card["text"] = table[flag]
        changes.append(f"{node_id}: 月末卡 {len(table)} 条")

    return changes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    data = json.loads(DATA.read_text(encoding="utf-8"))
    for line in apply(data["nodes"]):
        print(line)

    if not args.apply:
        print("\n（预演，未写回。加 --apply 写入）")
        return 0

    DATA.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"\n已写回 {DATA}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())