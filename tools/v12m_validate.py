#!/usr/bin/env python3
"""十二个月流程（`12m_v1`）配置校验器。

对应《十二个月开发文档_V1.md》4.9 的 33 条构建期校验，外加严格 JSON 与重复键检查。
只读：这个脚本不写任何文件，改数据是人的事。

    python tools/v12m_validate.py              # 校验 manifest.authoredMonths 声明的月份
    python tools/v12m_validate.py --months 1   # 只校验第一月切片
    python tools/v12m_validate.py --full       # 十二个月齐全后使用；无消费者旗标算失败

为什么要 scoped：第一月切片阶段后面十一个月的节点还不存在，
`m01_activity_tool` 这类旗标的消费者在第二三月才出现，
所以默认只警告；`--full` 才把它升级成失败。
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

# Windows 控制台默认 GBK，中文报错会糊成一团；CI 里也一样，先把自己切成 UTF-8 输出。
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data/story/v12m"
FIXTURES = ROOT / "contracts/fixtures/v12m"
PLACE_SHOTS = ROOT / "assets/ui/place_cards"

NODE_TYPES = {"main_story", "phone_batch", "handbook", "activity", "month_close", "checkpoint", "report"}
ANCHORS = {"shell_toast", "objective", "activity_card", "phone_edge"}
DISMISS = {"first_move", "drawer_opened", "handbook_closed", "activity_done", "month_closed"}
TRIGGER_HEADS = {
    "month_started",
    "node_started",
    "node_completed",
    "hook",
    "first_move",
    "drawer_opened",
    "handbook_closed",
    "activity_open",
    "activity_done",
    "activity_skipped",
    "place_unlocked",
    "portal_reached",
}
PHONE_FORBIDDEN = {"compose", "input", "chat", "freeText", "typing", "draft"}
ZONE_IDS = {"A", "B", "C", "D", "E", "F", "G", "H"}
DIMENSIONS = {"S", "O", "N", "D"}
## 能力五格的五个名字（开发文档 4.19）：标签和第 5 格点亮都只认这五个。
ABILITIES = {"technical", "collaboration", "expression", "integrity", "resilience"}
FORBIDDEN_IN_RESPONSE = {"stateDelta", "competency", "anchor", "coef", "threshold", "rubric", "scores"}
PUNCTUATION = set("，。、；：？！“”‘’（）《》〈〉…—－·,.；:?!\"'()[]{}<>/\\|-_+*=&%$#@~^ \t\n\r")


## 地点前缀 → 区域：B 区开头就是 B；书院/心湖/码头这些固定地点用习惯码。
LOCATION_AREA_ALIASES = {
    "树影书院": "D",
    "心湖": "E",
    "观澜会展码头": "F",
    "慢生活园": "H",
    "松风训练谷": "E",
    "暖邻康护院": "G",
    "启程广场": "A",
    "云栖科技工厂": "B",
    "创意水巷": "C",
    "飓起东方总部": "A",
    "市场部": "A",
    "研发部": "B",
    "销售部": "C",
    "人事部": "D",
    "财务部": "E",
    "运营部": "F",
    "行政部": "G",
    "生产部": "H",
}


def expected_area(location: str) -> str:
    """地点字符串应当落在哪个区；判断不了就返回空串，交给人工看。"""
    text = location.strip()
    match = re.match(r"^([A-H])\s*区", text)
    if match:
        return match.group(1)
    match = re.match(r"^([A-H])\s*总部", text)
    if match:
        return match.group(1)
    for name, code in LOCATION_AREA_ALIASES.items():
        if text.startswith(name):
            return code
    return ""


class DupKey(Exception):
    pass


def _no_dup_pairs(pairs: list[tuple[str, Any]]) -> dict:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise DupKey(key)
        result[key] = value
    return result


def strict_load(path: Path, errors: list[str]) -> Any:
    if not path.exists():
        errors.append(f"{path.name} 不存在：{path}")
        return None
    text = path.read_text(encoding="utf-8")
    try:
        return json.loads(text, object_pairs_hook=_no_dup_pairs)
    except DupKey as exc:
        errors.append(f"{path.name} 有重复键：{exc}")
    except json.JSONDecodeError as exc:
        errors.append(f"{path.name} 严格解析失败（尾逗号、注释都不允许）：第 {exc.lineno} 行 {exc.msg}")
    return None


def visible_length(text: str) -> int:
    return sum(1 for char in text if char not in PUNCTUATION)


def trigger_head(trigger: str) -> str:
    return trigger.split(":", 1)[0]


def walk_flags(condition: Any, sink: list[str], loose: list[str] | None = None) -> None:
    """把 when 条件里引用的旗标名收进 sink。
    loose 单收"反向条件"（notFlag / noneOf）：它们只证明这个旗标有人读，
    不该因为没人写它就报错——没写恰恰意味着"这条永远成立"，是合法写法。"""
    if not isinstance(condition, dict):
        return
    for key, value in condition.items():
        if key == "flag":
            sink.append(str(value))
        elif key in {"all", "any", "anyOf", "allOf"} and isinstance(value, list):
            sink.extend(str(item) for item in value)
        elif key == "not":
            walk_flags(value, sink, loose)
        elif key in {"notFlag", "eqFlag"}:
            target = loose if loose is not None else sink
            target.append(str(value))
        elif key == "noneOf" and isinstance(value, list) and loose is not None:
            loose.extend(str(item) for item in value)


def all_beats(node: dict) -> list[dict]:
    """节点自身的 beats 加上走位停靠点里的 beats；钩子和说话人都按这个全集查。"""
    beats = list(node.get("beats", []) or [])
    for stop in node.get("stops", []) or []:
        beats.extend(stop.get("beats", []) or [])
    return beats


def node_flags(node: dict) -> list[str]:
    written: list[str] = []
    for choice in node.get("choices", []) or []:
        written.extend(str(flag) for flag in choice.get("flags", []) or [])
    for flag in node.get("flags", []) or []:
        written.append(str(flag))
    if node.get("nodeType") == "activity" and node.get("skipFlag"):
        written.append(str(node["skipFlag"]))
    return written


def main() -> int:
    parser = argparse.ArgumentParser(description="校验 12m_v1 配置")
    parser.add_argument("--months", type=int, nargs="*", help="只校验这些月份")
    parser.add_argument("--full", action="store_true", help="十二个月齐全模式，旗标无消费者即失败")
    args = parser.parse_args()

    errors: list[str] = []
    warnings: list[str] = []

    manifest = strict_load(DATA / "manifest.json", errors)
    events = strict_load(DATA / "events.json", errors)
    activities = strict_load(DATA / "activities.json", errors)
    hints = strict_load(DATA / "hints.json", errors)
    rubrics = strict_load(DATA / "rubrics.json", errors)
    terms_path = DATA / "terms.json"
    terms = strict_load(terms_path, errors) if terms_path.exists() else {}
    if errors:
        for line in errors:
            print(f"ERROR {line}")
        return 1

    for name, blob in (("manifest", manifest), ("events", events), ("activities", activities), ("hints", hints), ("rubrics", rubrics)):
        if blob is not None and not isinstance(blob, dict):
            errors.append(f"{name}.json 顶层必须是对象，当前是 {type(blob).__name__}")
    if errors:
        for line in errors:
            print(f"ERROR {line}")
        return 1

    nodes: list[dict] = events.get("nodes", [])
    by_id: dict[str, dict] = {str(node["id"]): node for node in nodes}
    if len(by_id) != len(nodes):
        errors.append("events.json 节点 ID 有重复")

    declared_raw = manifest.get("authoredMonths", [])
    if not isinstance(declared_raw, list):
        # 并发改动或手滑会把数组写成单个数字；这里兜住，给出可读报错而不是 traceback
        errors.append(f"manifest.authoredMonths 必须是数组，当前是 {type(declared_raw).__name__}：{declared_raw}")
        declared_raw = [declared_raw] if isinstance(declared_raw, int) else []
    declared = [int(m) for m in declared_raw]
    if args.months:
        scope = set(args.months)
    elif args.full:
        scope = set(range(1, 13))
    else:
        scope = set(declared)
    if declared != sorted(declared) or (declared and declared[0] != 1):
        errors.append(f"manifest.authoredMonths 必须是从 1 开始的连续月份，当前 {declared}")
    for node in nodes:
        month = int(node.get("month", 0))
        if month not in range(1, 13):
            errors.append(f"{node.get('id')} 的 month 越界：{month}")
        if scope != set(range(1, 13)) and month not in scope:
            warnings.append(f"{node.get('id')} 属于第 {month} 月，不在本次校验范围，规则只部分适用")

    ap_by_month = {int(k): int(v) for k, v in manifest.get("apByMonth", {}).items()}
    node_order = [str(nid) for nid in manifest.get("nodeOrder", [])]
    missing_order = [str(node["id"]) for node in nodes if int(node.get("month", 0)) in scope and str(node["id"]) not in node_order]
    if missing_order:
        errors.append(f"这些节点没进 manifest.nodeOrder：{missing_order}")

    order_seen: dict[tuple[int, int], str] = {}
    for node in nodes:
        if int(node.get("month", 0)) not in scope:
            continue
        key = (int(node["month"]), int(node.get("order", 0)))
        if key in order_seen:
            errors.append(f"{node['id']} 与 {order_seen[key]} 在第 {key[0]} 月占同一个 order={key[1]}")
        order_seen[key] = str(node["id"])

    hooks_in_beats: set[str] = set()
    competency_refs: list[tuple[str, int, str]] = []
    cast_names: dict[str, str] = {}
    for npc in manifest.get("npcs", []):
        cast_names[str(npc.get("id"))] = str(npc.get("name"))

    for node in nodes:
        if int(node.get("month", 0)) not in scope:
            continue
        node_id = str(node["id"])
        node_type = str(node.get("nodeType"))
        if node_type not in NODE_TYPES:
            errors.append(f"{node_id} 的 nodeType 非法：{node_type}")
        if not node.get("reportUse"):
            errors.append(f"{node_id} 缺 reportUse")
        # 地点和区必须对得上：剧情在 B 区，结束后就不能落到别的区。
        location = str(node.get("location") or "").strip()
        location_id = str(node.get("locationId") or "").strip()
        if location:
            if not location_id:
                errors.append(f"{node_id} 有地点「{location}」但没有 locationId")
            else:
                area = expected_area(location)
                if area and area != location_id:
                    errors.append(f"{node_id} 的地点「{location}」属于 {area} 区，但 locationId={location_id}")
        if node_type == "main_story":
            if not location:
                errors.append(f"{node_id} 是 main_story，但没有 location，无法走到开场")
            if not location_id:
                errors.append(f"{node_id} 是 main_story，但没有 locationId，无法走到开场")
            elif location_id not in ZONE_IDS:
                errors.append(f"{node_id} 的 locationId 不在 A–H：{location_id}")
        # 一条手机消息也能点亮去处（第 7 月小赵那句"周末打球不"一次开两扇门）：
        # 它不挂在台词拍上，挂在节点的 placeHooks 里，一样算"有人带到"。
        for hook in node.get("placeHooks", []) or []:
            hooks_in_beats.add(str(hook))
        for beat in all_beats(node):
            if beat.get("hook"):
                hooks_in_beats.add(str(beat["hook"]))
            if beat.get("type") == "say":
                speaker = str(beat.get("speaker", ""))
                known = {entry.get("name") for entry in node.get("cast", []) or []} | set(cast_names.values())
                if speaker not in known:
                    warnings.append(f"{node_id} 的台词说话人「{speaker}」不在演员表里，需要群演占位图")
            if beat.get("type") not in {"narration", "say", "phone_cinematic", "card", "choice"}:
                errors.append(f"{node_id} 用了不在 beat 白名单里的类型：{beat.get('type')}")
        landmarks = {str(item) for item in manifest.get("landmarks", []) or []}
        for stop in node.get("stops", []) or []:
            stop_id = str(stop.get("id", ""))
            if not stop_id or not stop.get("beats"):
                errors.append(f"{node_id} 的停靠点 {stop_id or '(无 id)'} 缺 id 或 beats")
            at = stop.get("at") or {}
            if "zoneId" in at:
                if str(at["zoneId"]) not in ZONE_IDS:
                    errors.append(f"{node_id}.{stop_id} 的 zoneId 越界：{at['zoneId']}")
            elif "landmark" in at:
                if str(at["landmark"]) not in landmarks:
                    errors.append(f"{node_id}.{stop_id} 的 landmark 不在 manifest.landmarks 里：{at['landmark']}")
            else:
                errors.append(f"{node_id}.{stop_id} 的 at 必须给 zoneId 或 landmark 之一")
        if str(node.get("nodeType")) == "phone_batch":
            hit = sorted(PHONE_FORBIDDEN & set(node.keys()))
            if hit:
                errors.append(f"{node_id} 出现被禁字段 {hit}：十二个月的手机只收消息、回短句、约人，不聊天")
        if str(node.get("senderId")) and str(node.get("senderId")) not in cast_names and node_type == "phone_batch":
            errors.append(f"{node_id} 的发件人 {node.get('senderId')} 不在 manifest.npcs 里")
        for page in node.get("pages", []) or []:
            if not page.get("bodyKey") or not page.get("title"):
                errors.append(f"{node_id} 的手册页缺 title 或 bodyKey")
        source = node.get("bodySource")
        if source:
            resolved = ROOT / str(source).replace("res://", "")
            if not resolved.exists():
                errors.append(f"{node_id} 的 bodySource 指不到文件：{source}")

    for node in nodes:
        if int(node.get("month", 0)) not in scope:
            continue
        node_id = str(node["id"])
        choices = node.get("choices")
        if str(node.get("nodeType")) == "main_story":
            if choices is None:
                errors.append(f"{node_id} 是 main_story 但没有 choices 字段（纯剧情请写空数组）")
                continue
            if len(choices) not in (0, 2, 3):
                errors.append(f"{node_id} 有 {len(choices)} 个选项；只允许 3 个（三选）或 2 个"
                              f"（册子里那两处「反馈纸放哪儿」就是两版），纯剧情节点 0 个")
            if len(choices) == 0 and str(node.get("reportUse")) != "story_only":
                errors.append(f"{node_id} 没有选项，却把 reportUse 写成 {node.get('reportUse')}")
            if len(choices) == 3 and [str(choice.get("id")) for choice in choices] != ["A", "B", "C"]:
                errors.append(f"{node_id} 的选项 ID 或顺序不是 A/B/C")
            if len(choices) == 2 and [str(choice.get("id")) for choice in choices] != ["A", "B"]:
                errors.append(f"{node_id} 的两个选项 ID 或顺序不是 A/B")
        for choice in choices or []:
            cost = int(choice.get("apCost", -1))
            if cost not in (0, 1):
                errors.append(f"{node_id} 选项 {choice.get('id')} 的 apCost 必须是 0 或 1，当前 {choice.get('apCost')}")
            if not choice.get("text") or not choice.get("outcome"):
                errors.append(f"{node_id} 选项 {choice.get('id')} 缺 text 或 outcome")
            if str(choice.get("reportUse")) == "evidence":
                if not isinstance(choice.get("stateDelta"), dict):
                    errors.append(f"{node_id} 选项 {choice.get('id')} 是计分选项但没有 stateDelta")
                entries = choice.get("competency") or []
                if not entries:
                    errors.append(f"{node_id} 选项 {choice.get('id')} 是计分选项但没有 competency 证据")
                seen_dimensions: set[str] = set()
                for entry in entries:
                    if str(entry.get("dimension")) not in DIMENSIONS:
                        errors.append(f"{node_id} 选项 {choice.get('id')} 的证据维度非法：{entry.get('dimension')}")
                    anchor = int(entry.get("anchor", -1))
                    if anchor not in range(0, 5):
                        errors.append(f"{node_id} 选项 {choice.get('id')} 的 anchor 越界：{anchor}")
                    if not entry.get("behaviorCode") or not entry.get("result"):
                        errors.append(f"{node_id} 选项 {choice.get('id')} 的证据缺 behaviorCode 或 result")
                    dimension = str(entry.get("dimension"))
                    if dimension in seen_dimensions:
                        errors.append(f"{node_id} 选项 {choice.get('id')} 同一维度写了多条证据")
                    seen_dimensions.add(dimension)
                    competency_refs.append((dimension, anchor, f"{node_id} 选项 {choice.get('id')}"))
            for dimension in (choice.get("stateDelta") or {}):
                if str(dimension) not in {"S", "O", "N", "D", "H", "risk"}:
                    errors.append(f"{node_id} 选项 {choice.get('id')} 的 stateDelta 键越界：{dimension}")
            # 能力五格（4.19）：三选一的必玩选项必须显式写能力标签。
            # 允许写空对象——"这一选什么都不长"也是一个决定，但不能不填，
            # 否则十二个月铺完，五格里有几格是没人填过的空洞。
            if str(node.get("nodeType")) == "main_story" and len(choices or []) == 3:
                if not isinstance(choice.get("abilityTags"), dict):
                    errors.append(f"{node_id} 选项 {choice.get('id')} 没写 abilityTags："
                                  "每个必玩选项都要显式决定这一选长哪一格（不填报，不长写空对象）")
                else:
                    for key, value in choice["abilityTags"].items():
                        if str(key) not in ABILITIES:
                            errors.append(f"{node_id} 选项 {choice.get('id')} 的能力标签越界：{key}")
                        if not isinstance(value, int) or not 1 <= value <= 2:
                            errors.append(f"{node_id} 选项 {choice.get('id')} 的能力标签一次只能给 1–2 点：{key}={value}")
            # 第 5 格只认剧情点亮（4.19）：写了就必须是合法能力名。
            peak = choice.get("abilityPeak")
            if peak is not None:
                if not isinstance(peak, list) or not peak:
                    errors.append(f"{node_id} 选项 {choice.get('id')} 的 abilityPeak 必须是非空数组")
                else:
                    for name in peak:
                        if str(name) not in ABILITIES:
                            errors.append(f"{node_id} 选项 {choice.get('id')} 的第 5 格点亮越界：{name}")

    for node in nodes:
        if int(node.get("month", 0)) not in scope:
            continue
        if str(node.get("nodeType")) != "activity":
            continue
        month = int(node["month"])
        budget = node.get("budget") or {}
        slots = int(budget.get("slots", -1))
        if slots != ap_by_month.get(month, 0):
            errors.append(f"{node['id']} 的 budget.slots={slots} 与 apByMonth[{month}]={ap_by_month.get(month, 0)} 不一致")
        if slots <= 0:
            errors.append(f"{node['id']} 在没有行动点预算的月份里挂了活动节点")
        pool = node.get("activityIds") or []
        if len(pool) < slots:
            errors.append(f"第 {month} 月有 {slots} 格却只配了 {len(pool)} 个去处：玩家有行动点但没地方花")
        if node.get("entryMode") != "on_site":
            errors.append(f"{node['id']} 的 entryMode 必须是 on_site：自由活动是走进去，不是弹菜单")

    activity_by_id: dict[str, dict] = {}
    inviteable = {str(npc.get("id")) for npc in manifest.get("npcs", []) if npc.get("inRelationSystem")}
    for activity in (activities or {}).get("activities", []):
        activity_by_id[str(activity.get("id"))] = activity
        if int(activity.get("apCost", 0)) > int(activity.get("slots", 0)):
            errors.append(f"活动 {activity.get('id')} 的 apCost 大于 slots")
        if visible_length(str(activity.get("name", ""))) > 8:
            errors.append(f"活动 {activity.get('id')} 的名称超过 8 字，装不进卡面")
        mode = str(activity.get("mode", "solo"))
        if mode not in {"solo", "multi"}:
            errors.append(f"活动 {activity.get('id')} 的 mode 非法：{mode}")
        invited = activity.get("invitableNpcs") or []
        if invited and mode != "multi":
            errors.append(f"活动 {activity.get('id')} 是 solo，却挂了 invitableNpcs：只有多人活动才能用手机约人")
        for npc_id in invited:
            if str(npc_id) not in inviteable:
                errors.append(f"活动 {activity.get('id')} 约不到 {npc_id}：不在可邀请名单（陈工这类事务型 NPC 不进关系系统）")
        # 第 26 条：到访制要求每个活动都有门、有解锁时机、有讲解卡
        portal = activity.get("portal") or {}
        if not portal:
            errors.append(f"活动 {activity.get('id')} 没有 portal：玩家没有门可进")
        if "zoneId" in portal and str(portal["zoneId"]) not in ZONE_IDS:
            errors.append(f"活动 {activity.get('id')} 的 portal.zoneId 越界：{portal['zoneId']}")
        if "landmark" in portal and str(portal["landmark"]) not in {str(x) for x in manifest.get("landmarks", [])}:
            errors.append(f"活动 {activity.get('id')} 的 portal.landmark 不在 manifest.landmarks 里")
        if not activity.get("unlockAfter") and not activity.get("unlockHook"):
            errors.append(f"活动 {activity.get('id')} 既没有 unlockAfter 也没有 unlockHook：它什么时候解锁说不清")
        if activity.get("unlockAfter") and str(activity["unlockAfter"]) not in by_id:
            errors.append(f"活动 {activity.get('id')} 的 unlockAfter 指向不存在的节点 {activity['unlockAfter']}")
        if activity.get("unlockHook") and str(activity["unlockHook"]) not in hooks_in_beats:
            errors.append(f"活动 {activity.get('id')} 的 unlockHook「{activity['unlockHook']}」在剧情里没人挂——带巡那一句要加 hook")
        card = activity.get("card") or {}
        lines = card.get("lines") or []
        if not card.get("title") or not lines or not card.get("shots"):
            errors.append(f"活动 {activity.get('id')} 的讲解卡缺 title、lines 或 shots")
        if len(lines) > 3:
            errors.append(f"活动 {activity.get('id')} 的讲解卡有 {len(lines)} 行，上限 3 行")
        for line in lines:
            if visible_length(str(line)) > 22:
                errors.append(f"活动 {activity.get('id')} 的讲解卡某行超过 22 字：{line}")
        # 第 30 条：卡上说的配图必须真的存在，别等上线才发现卡是空的
        for shot in card.get("shots") or []:
            if not (PLACE_SHOTS / str(shot)).exists():
                errors.append(f"活动 {activity.get('id')} 的讲解卡配图找不到文件：assets/ui/place_cards/{shot}")
        # 第 31 条：进门得有一件能按的东西，而且卡上要告诉玩家按什么
        obj = str(activity.get("object", ""))
        if not obj:
            errors.append(f"活动 {activity.get('id')} 没有 object：进门之后玩家找不到能按的东西")
        if not activity.get("againLine"):
            errors.append(f"活动 {activity.get('id')} 没有 againLine：第二次去是空场景")
        if obj and lines and obj not in str(lines[-1]):
            errors.append(f"活动 {activity.get('id')} 的卡片最后一行没提到「{obj}」，玩家进门不知道该按什么")

    # §4.25 心情账（2026-10-30）：R1 每处至少一个非零效果；R2 每月至少各有一个回心处、耗心处。
    def _mood(activity: dict) -> tuple[int, int]:
        return (max(0, int(activity.get("hCost", 0))),
                int((activity.get("stateDelta") or {}).get("H", 0)))

    for activity in activity_by_id.values():
        cost, gain = _mood(activity)
        state = activity.get("stateDelta") or {}
        if cost == 0 and gain == 0 and not any(int(v or 0) != 0 for v in state.values()):
            errors.append(f"活动 {activity.get('id')} 既不扣心也不回心、属性也全空：玩家没有理由去（§4.25 R1）")
    for node in nodes:
        if str(node.get("nodeType")) != "activity":
            continue
        pool = [activity_by_id.get(str(x)) or {} for x in (node.get("activityIds") or [])]
        if not pool:
            continue
        if not any(_mood(a)[1] > 0 for a in pool):
            errors.append(f"{node['id']} 这一月没有回心的去处：累了没地方缓（§4.25 R2）")
        if not any(_mood(a)[0] > 0 for a in pool):
            errors.append(f"{node['id']} 这一月没有耗心的去处：心情永远满着，翻倍和强制休息都撞不上（§4.25 R2）")
    # 第 29 条：贴封条的地点，所在月必须有必玩主线，否则封条永远不存在
    required_months = {int(n.get("month", 0)) for n in nodes if n.get("required") and str(n.get("nodeType")) == "main_story"}
    for node in nodes:
        if str(node.get("nodeType")) != "activity":
            continue
        month = int(node.get("month", 0))
        for activity_id in node.get("activityIds", []) or []:
            item = activity_by_id.get(str(activity_id)) or {}
            if str(item.get("gatedBy", "month_required")) == "month_required" and month not in required_months:
                errors.append(f"{node['id']} 引用的活动 {activity_id} 靠封条挡人，但第 {month} 月没有任何必玩主线")
    for node in nodes:
        for activity_id in node.get("activityIds", []) or []:
            if activity_id not in activity_by_id:
                errors.append(f"{node['id']} 引用了不存在的活动 {activity_id}")

    for month, budget in ap_by_month.items():
        if month not in scope or budget <= 0:
            continue
        gate = [node for node in nodes if int(node.get("month", 0)) == month and str(node.get("nodeType")) == "activity"]
        if not gate:
            continue
        mains = [node for node in nodes if int(node.get("month", 0)) == month and str(node.get("nodeType")) == "main_story" and node.get("required") and node.get("choices")]
        if not mains:
            continue
        cheapest = min(int(activity_by_id.get(str(aid), {}).get("apCost", 1)) for node in gate for aid in node.get("activityIds", []) or ["x"])
        for node in mains:
            for choice in node.get("choices", []):
                cost = int(choice.get("apCost", 0))
                if cost and cost + cheapest > budget:
                    errors.append(
                        f"第 {month} 月自相矛盾：{node['id']} 选项 {choice.get('id')} 要花 {cost} 点，"
                        f"而这个月只有 {budget} 点，最便宜的活动还要 {cheapest} 点——"
                        f"选了它就没法自由安排，活动节点和 hints 里的行动点教学会变成假话"
                    )

    written: dict[str, list[str]] = {}
    for node in nodes:
        for flag in node_flags(node):
            written.setdefault(flag, []).append(f"{node['id']}")
    for activity in (activities or {}).get("activities", []):
        if activity.get("rewardFlag"):
            written.setdefault(str(activity["rewardFlag"]), []).append(f"activities:{activity['id']}")

    referenced: set[str] = set()
    read_negatively: set[str] = set()
    for node in nodes:
        collected: list[str] = []
        loose: list[str] = []
        walk_flags(node.get("when"), collected, loose)
        # 剧情拍上的 when 也要查：第 5 月那句"合同写的是尽商业上合理努力"就长在拍里，
        # 之前只查节点/卡/消息，拍里写错旗标名没人拦得住。
        for beat in all_beats(node):
            walk_flags(beat.get("when"), collected, loose)
        for card in node.get("cards", []) or []:
            walk_flags(card.get("when"), collected, loose)
        for choice in node.get("choices", []) or []:
            walk_flags(choice.get("variantWhen"), collected, loose)
        # 手机里一条消息可以按旗标只在某一支发出去（月末那句按当月选择变文案）；
        # 整批仍算一批，所以这些旗标要算"有消费者"。
        for message in node.get("messages", []) or []:
            walk_flags(message.get("when"), collected, loose)
        for flag in node.get("requiresFlags", []) or []:
            collected.append(str(flag))
        referenced.update(collected)
        read_negatively.update(loose)

    # 引擎在运行时自己写的旗标，不是任何选项写出来的，when 引到它们不算"引用了不存在的旗标"：
    #   visit_<月>_<活动>  到访结算（F 段每次第一次到访写一条）
    #   peak_<能力>        能力第 5 格点亮（剧情那一幕写）
    #   hook_<钩子>        讲解卡钩子已触发
    # 另外后端结算结果（转正是否延期、是否提名、答辩是否通过）也是运行时才有，列进白名单。
    for node in nodes:
        if str(node.get("nodeType")) != "activity":
            continue
        month = int(node.get("month", 0))
        for aid in node.get("activityIds", []) or []:
            written.setdefault(f"visit_{month}_{aid}", []).append("engine:到访结算")
    SETTLEMENT_FLAGS = {
        "m07_probation_deferred", "m12_not_nominated", "m12_not_passed",
        # 第六月末一次定：判定与结局旗标由城镇写，不在数据里（4.21）。
        "probation_confirmed", "probation_not_confirmed", "probation_terminated",
        "probation_ended", "m07_closure_seen",
    }

    def _engine_flag(flag: str) -> bool:
        return (flag.startswith(("visit_", "peak_", "hook_", "handbook_page_"))
                or flag in SETTLEMENT_FLAGS or flag in {"handbook_read", "activity", "e02", "m06_has_notes"})

    unconsumed = sorted(flag for flag in written
                        if flag not in referenced and flag not in read_negatively
                        and not _engine_flag(flag))
    if unconsumed:
        line = f"这些旗标没有消费者：{unconsumed}"
        (errors if args.full else warnings).append(line + ("（后面几个月的节点还没填，切片阶段只警告）" if not args.full else ""))

    # §4.25 R3：扣心的去处必须带一条能被读到的后果，否则这次去等于白去。
    # 现在先记 WARN——第 7/9/11 月那三条后果还没写；补完之后这条改 append 到 errors。
    for activity in (activities or {}).get("activities", []):
        cost = max(0, int(activity.get("hCost", 0)))
        if cost <= 0:
            continue
        reward = str(activity.get("rewardFlag", ""))
        if not reward:
            warnings.append(f"活动 {activity.get('id')} 扣 {cost} 心却没有 rewardFlag：只扣不回报（§4.25 R3）")
        elif reward not in referenced and reward not in read_negatively:
            warnings.append(f"活动 {activity.get('id')} 扣 {cost} 心，但 {reward} 没人读：这次去没有任何后续（§4.25 R3；后果补完后改成 error）")

    unknown_refs = sorted(ref for ref in referenced if ref not in written and not _engine_flag(ref))
    if unknown_refs:
        errors.append(f"when 引用了从未写入的旗标：{unknown_refs}")

    if "E14" in json.dumps({"m": manifest, "e": events, "a": activities, "h": hints}, ensure_ascii=False):
        errors.append("本版不启用 E14，但数据里出现了 E14")

    hint_ids: set[str] = set()
    all_hint_ids = {str(hint.get("id")) for hint in (hints or {}).get("hints", [])}
    hint_hooks: set[str] = set()
    # 行话小圆点（4.17）：全年只留六个词，每个词都得真的在已铺剧情里出现过。
    story_text = ""
    for node in nodes:
        for beat in all_beats(node):
            story_text += f"{beat.get('text', '')}{beat.get('label', '')}"
        for choice in node.get("choices", []) or []:
            # 选项本身和它的结果句也算：「尽商业上合理努力」就是写在 B 选项的结果里的，
            # 玩家是在那一句上看到小圆点的。
            story_text += f"{choice.get('text', '')}{choice.get('outcome', '')}"
    seen_words: set[str] = set()
    for term in (terms or {}).get("terms", []) or []:
        word = str(term.get("word", ""))
        plain = str(term.get("plain", ""))
        if not word or not plain:
            errors.append(f"terms.json 词条缺 word 或 plain：{term}")
            continue
        if word in seen_words:
            errors.append(f"terms.json 词条重复：{word}")
        seen_words.add(word)
        if visible_length(word) > 10:
            errors.append(f"词条「{word}」超过 10 字，气泡上挂不下")
        if visible_length(plain) > 22:
            errors.append(f"词条「{word}」的人话超过 22 字：{plain}")
        if word not in story_text:
            warnings.append(f"词条「{word}」在已铺的剧情里还没出现（等它出现那天才会挂点）")

    teach_per_month: dict[int, int] = {}
    for hint in (hints or {}).get("hints", []):
        hint_id = str(hint.get("id"))
        if hint_id in hint_ids:
            errors.append(f"hints.json 里 id 重复：{hint_id}")
        hint_ids.add(hint_id)
        month = int(hint.get("month", 0))
        if month not in range(1, 13):
            errors.append(f"提示 {hint_id} 的 month 越界：{month}")
        anchor = str(hint.get("anchor"))
        if anchor not in ANCHORS:
            errors.append(f"提示 {hint_id} 的 anchor 非法：{anchor}")
        trigger = str(hint.get("trigger", ""))
        if trigger_head(trigger) not in TRIGGER_HEADS:
            errors.append(f"提示 {hint_id} 的 trigger 不在词表里：{trigger}")
        if trigger_head(trigger) == "hook":
            hint_hooks.add(trigger.split(":", 1)[1])
        if trigger_head(trigger) in {"node_started", "node_completed"}:
            target = trigger.split(":", 1)[1]
            if target not in by_id:
                errors.append(f"提示 {hint_id} 监听的节点 {target} 不存在")
        if hint.get("dismissOn"):
            dismiss = str(hint["dismissOn"])
            if dismiss not in DISMISS and trigger_head(dismiss) not in {"node_completed", "node_started"}:
                errors.append(f"提示 {hint_id} 的 dismissOn 不在词表里：{dismiss}")
            elif trigger_head(dismiss) in {"node_completed", "node_started"}:
                target = dismiss.split(":", 1)[1]
                if target not in by_id:
                    errors.append(f"提示 {hint_id} 的 dismissOn 指向不存在的节点：{target}")
        if hint.get("replace") and str(hint["replace"]) not in all_hint_ids:
            errors.append(f"提示 {hint_id} 的 replace 指向不存在的提示：{hint['replace']}")
        if hint.get("persist") and hint.get("autoDismissMs"):
            errors.append(f"提示 {hint_id} 既写 persist 又写 autoDismissMs：动手型提示不许定时消失")
        if hint.get("autoDismissMs") and int(hint["autoDismissMs"]) > 3000:
            errors.append(f"提示 {hint_id} 的 autoDismissMs={hint['autoDismissMs']} 超过 3000ms；旧版 3600 一律禁用")
        if anchor in {"shell_toast", "objective"}:
            if not hint.get("title") or not hint.get("sub"):
                errors.append(f"提示 {hint_id} 缺 title 或 sub")
            if visible_length(str(hint.get("title", ""))) > 12:
                errors.append(f"提示 {hint_id} 的主句 {hint.get('title')} 超过 12 字")
            if visible_length(str(hint.get("sub", ""))) > 22:
                errors.append(f"提示 {hint_id} 的副句 {hint.get('sub')} 超过 22 字")
        if anchor in {"activity_card", "phone_edge"}:
            if not hint.get("text"):
                errors.append(f"提示 {hint_id} 是 {anchor} 却没有 text")
            elif visible_length(str(hint["text"])) > 24:
                errors.append(f"提示 {hint_id} 的 text 超过 24 字")
        if anchor == "activity_card":
            teach_per_month[month] = teach_per_month.get(month, 0) + 1
        if anchor == "objective" and hint.get("until") != "month_closed":
            errors.append(f"提示 {hint_id} 常驻本月卡，必须写 until: month_closed")
    for month, count in teach_per_month.items():
        if count > 2:
            errors.append(f"第 {month} 月有 {count} 张教学卡，上限 2 张")
    dangling = sorted(hint_hooks - hooks_in_beats)
    if dangling:
        errors.append(f"这些提示等不到剧情钩子：{dangling}")
    unused_hooks = sorted(hooks_in_beats - hint_hooks - {str(a.get("unlockHook")) for a in activity_by_id.values() if a.get("unlockHook")})
    if unused_hooks:
        errors.append(f"这些 beats 挂了 hook 却没人接（既没有提示也没有讲解卡监听）：{unused_hooks}")

    # 防剧透：提示、目标卡、月历卡都不许提前报出主线标题（4 字以上才查，免得误伤“带巡”这类短词）
    spoilers = [str(node.get("title", "")) for node in nodes if str(node.get("nodeType")) == "main_story"]
    spoilers = sorted({title for title in spoilers if visible_length(title) >= 4})
    for hint in (hints or {}).get("hints", []):
        for field in ("title", "sub", "text"):
            copy = str(hint.get(field, ""))
            for plot in spoilers:
                if plot in copy:
                    errors.append(f"提示 {hint.get('id')} 的 {field} 提前泄露主线标题「{plot}」：{copy}")
    for node in nodes:
        for field in ("whenText",):
            copy = str(node.get(field, ""))
            for plot in spoilers:
                if plot in copy:
                    errors.append(f"{node['id']} 的 {field} 提前泄露主线标题「{plot}」：{copy}")
        phase = node.get("duePhase")
        if phase and str(phase) not in {"early", "mid", "late"}:
            errors.append(f"{node['id']} 的 duePhase 非法：{phase}")
    # 第 28 条：地点讲解卡与“今天”卡同样不许出现事件标题
    for activity in (activities or {}).get("activities", []):
        for line in ((activity.get("card") or {}).get("lines") or []):
            for plot in spoilers:
                if plot in str(line):
                    errors.append(f"活动 {activity.get('id')} 的讲解卡提前泄露主线标题「{plot}」：{line}")
    for node in nodes:
        today = node.get("todayCard") or {}
        lines = today.get("lines") or []
        if today and (not today.get("title") or not lines or not today.get("shots")):
            errors.append(f"{node['id']} 的“今天”卡缺 title、lines 或 shots")
        if len(lines) > 3:
            errors.append(f"{node['id']} 的“今天”卡有 {len(lines)} 行，上限 3 行")
        for line in lines:
            if visible_length(str(line)) > 22:
                errors.append(f"{node['id']} 的“今天”卡某行超过 22 字：{line}")
            for plot in spoilers:
                if plot in str(line):
                    errors.append(f"{node['id']} 的“今天”卡提前泄露主线标题「{plot}」：{line}")

    for node in nodes:
        if str(node.get("nodeType")) != "phone_batch":
            continue
        replies = node.get("replyOptions") or []
        if len(replies) > 3:
            errors.append(f"{node['id']} 的外层回复键有 {len(replies)} 个，上限 3 个")
        for reply in replies:
            if len(reply.get("subOptions") or []) > 2:
                errors.append(f"{node['id']} 的 {reply.get('id')} 展开后超过 2 条短回复")
        if not node.get("messages"):
            errors.append(f"{node['id']} 没有消息正文")

    if int(manifest.get("months", 0)) != 12:
        errors.append("manifest.months 必须是 12")
    for checkpoint in manifest.get("checkpoints", []):
        if str(checkpoint.get("type")) not in {"probation", "recheck", "promotion"}:
            errors.append(f"检查点 {checkpoint.get('id')} 类型非法：{checkpoint.get('type')}")
    cap_by_month = {int(k): int(v) for k, v in manifest.get("phoneBatchCapByMonth", {}).items()}
    batches: dict[int, int] = {}
    for node in nodes:
        if str(node.get("nodeType")) == "phone_batch":
            batches[int(node["month"])] = batches.get(int(node["month"]), 0) + 1
    for month, count in batches.items():
        if count > cap_by_month.get(month, 0):
            errors.append(f"第 {month} 月有 {count} 批真消息，超过上限 {cap_by_month.get(month, 0)}")

    # 第 24、25 条：时段字段与过场一致性
    bands = {"morning", "afternoon", "night"}
    phases = {"early": 0, "mid": 1, "late": 2}
    for node in nodes:
        band = node.get("timeBand")
        if band is None or str(band) not in bands:
            errors.append(f"{node['id']} 的 timeBand 缺失或非法：{band}")
        phase = node.get("phase")
        if phase is None or str(phase) not in phases:
            errors.append(f"{node['id']} 的 phase 缺失或非法：{phase}")
        cut = node.get("zoneCut")
        if cut and str(cut) not in ZONE_IDS:
            errors.append(f"{node['id']} 的 zoneCut 不是 A–H：{cut}")
    order_rank = {"morning": 0, "afternoon": 1, "night": 2}
    for month in sorted(scope):
        chain = sorted((n for n in nodes if int(n.get("month", 0)) == month), key=lambda n: int(n.get("order", 0)))
        for prev, cur in zip(chain, chain[1:]):
            if str(prev.get("phase", "")) not in phases or str(cur.get("phase", "")) not in phases:
                continue
            if phases[str(cur["phase"])] < phases[str(prev["phase"])]:
                errors.append(f"第 {month} 月时间倒流：{prev['id']}（{prev['phase']}）之后是 {cur['id']}（{cur['phase']}）")
            # 上一屏写着 sleepHome：玩家走回宿舍睡了一觉，天亮回到工位——
            # 同一旬里「夜里→上午」是过了一天，不是时间倒流。
            slept = bool(prev.get("sleepHome", False))
            if str(cur.get("timeBand", "")) in order_rank and str(prev.get("timeBand", "")) in order_rank:
                if order_rank[str(cur["timeBand"])] < order_rank[str(prev["timeBand"])] and cur.get("phase") == prev.get("phase") and not slept:
                    errors.append(
                        f"第 {month} 月 {prev['id']}→{cur['id']} 时段回退（{prev['timeBand']}→{cur['timeBand']}）"
                        f"但还在同一旬：要么改 phase，要么过场会把这次跨日藏起来"
                    )

    # 第 36 条：跨旬必须交代（2026-10-30）。旬卡只在到达那一刻翻页，如果后一屏
    # 首拍不报时，玩家看到的就是"突然就中旬了"。交代三选一：首拍/ note / walkNote
    # / departNote 里带旬名或时间词；或节点写 xunOpen 显式声明已有交代。
    xun_words = ("上旬", "中旬", "下旬", "两周", "这一旬", "第二天", "第三天", "几天", "隔了", "上周", "当天", "昨天")
    phase_name = {"early": "上旬", "mid": "中旬", "late": "下旬"}
    for month in sorted(scope):
        chain = sorted((n for n in nodes if int(n.get("month", 0)) == month), key=lambda n: int(n.get("order", 0)))
        for prev, cur in zip(chain, chain[1:]):
            if str(cur.get("nodeType", "")) != "main_story":
                continue
            if str(cur.get("phase", "")) == str(prev.get("phase", "")):
                continue
            if cur.get("xunOpen"):
                continue
            beats0 = (cur.get("beats") or [{}])[0].get("text", "") if cur.get("beats") else ""
            haystack = " ".join([
                str(beats0),
                str(cur.get("note", "")),
                str(cur.get("walkNote", "")),
                str(cur.get("departNote", "")),
            ])
            if not any(w in haystack for w in xun_words):
                warnings.append(
                    f"第 {month} 月 {prev['id']}→{cur['id']} 跨旬（{phase_name.get(prev.get('phase'), '?')}→{phase_name.get(cur.get('phase'), '?')}）"
                    f"但首屏没有旬首交代：补一句报时，或给节点写 xunOpen"
                )

    # 第 37 条：天黑到天白必须回宿舍睡觉（2026-10-30）。同月相邻两屏里，前一屏是夜里、
    # 后一屏是白天，玩家不该站在原地看天亮。前一屏写 sleepHome：读完走回宿舍、进门熄灯、
    # 天亮再回来；通宵那类（第 5 月深夜改到凌晨、人没走）写 allNighter 放行。
    for month in sorted(scope):
        chain = sorted((n for n in nodes if int(n.get("month", 0)) == month), key=lambda n: int(n.get("order", 0)))
        for prev, cur in zip(chain, chain[1:]):
            if str(prev.get("timeBand", "")) != "night" or str(cur.get("timeBand", "")) != "morning":
                continue
            if bool(prev.get("sleepHome", False)) or bool(prev.get("allNighter", False)):
                continue
            errors.append(
                f"第 {month} 月 {prev['id']}→{cur['id']} 从夜里直接到白天，没有回宿舍睡觉："
                f"给 {prev['id']} 写 sleepHome（走回宿舍、熄灯、天亮），通宵没走就写 allNighter"
            )

    # 第 38 条（WARN）：进夜那一屏要说清"这段时间在干什么"（2026-10-30）。
    # 天不是自己黑的：玩家得先读到「忙到收工 / 改到几点 / 天已经暗了」，才接受画面转夜。
    night_words = ("收工", "加班", "天黑", "暗了", "暗下来", "傍晚", "今晚", "点了", "点钟",
                   "点零", "灯", "通宵", "熬夜", "忙到", "等到", "睡", "夜里", "半夜")
    for month in sorted(scope):
        chain = sorted((n for n in nodes if int(n.get("month", 0)) == month), key=lambda n: int(n.get("order", 0)))
        for prev, cur in zip(chain, chain[1:]):
            if str(cur.get("nodeType", "")) != "main_story":
                continue
            if str(cur.get("timeBand", "")) != "night" or str(prev.get("timeBand", "")) == "night":
                continue
            haystack = " ".join(
                [str(b.get("text", "")) for b in (cur.get("beats") or [])]
                + [str(cur.get("note", "")), str(cur.get("walkNote", "")), str(cur.get("departNote", ""))]
            )
            if any(w in haystack for w in night_words):
                continue
            warnings.append(
                f"第 {month} 月 {cur['id']} 从白天进夜里，但这一屏没有交代这段时间在干什么："
                f"补一句「忙到收工 / 改到几点 / 天已经暗了」"
            )

    # 第 34 条：这一月要办成什么，必须由剧情里的一句话交代——
    # 上月末那条消息、或本月开场某个人当面说的。屏幕上不常驻目标文字：
    # 玩家不该提前知道还没发生的事（2026-10-29 定）。
    all_carriers: dict[int, list[str]] = {}
    for node in nodes:
        node_month = int(node.get("month", 0))
        for beat in all_beats(node) + (node.get("messages", []) or []):
            if not beat.get("goalLine"):
                continue
            # 上月末发的那条消息说的是下一个月的任务：按它指向的月份算。
            target = int(beat.get("goalForMonth", node_month))
            all_carriers.setdefault(target, []).append(str(node.get("id")))
    for month in sorted(scope):
        if month == 1:
            continue  # 新手月由入职通知和带巡交代，另有一套
        carriers = all_carriers.get(month, [])
        if not carriers:
            errors.append(f"第 {month} 月没人说清这个月要办成什么：给那条消息或那句台词打上 goalLine")
        if len(carriers) > 1:
            errors.append(f"第 {month} 月有 {len(carriers)} 处 goalLine（{carriers}）：一个月只需要一句")

    if FIXTURES.exists():
        for fixture in FIXTURES.glob("*.json"):
            payload = json.dumps(strict_load(fixture, errors), ensure_ascii=False)
            hit = sorted(key for key in FORBIDDEN_IN_RESPONSE if f'"{key}"' in payload)
            if hit:
                errors.append(f"{fixture.name} 泄露了服务端字段：{hit}")

    # 第 23 条：每条证据的 (维度, 锚点) 都要在 rubrics.json 里有对应文案
    if isinstance(rubrics, dict):
        dims = rubrics.get("dimensions") or {}
        if set(dims) != DIMENSIONS:
            errors.append(f"rubrics.dimensions 必须恰好是 S/O/N/D，当前 {sorted(dims)}")
        for dim, spec in dims.items():
            anchors = (spec or {}).get("anchors") or {}
            if sorted(str(i) for i in anchors) != ["0", "1", "2", "3", "4"]:
                errors.append(f"rubrics 的 {dim} 必须给满 0–4 五档锚点文案")
            if not (spec or {}).get("name"):
                errors.append(f"rubrics 的 {dim} 缺 name")
        for dim, anchor, where in competency_refs:
            copy = ((dims.get(dim) or {}).get("anchors") or {}).get(str(anchor))
            if not copy:
                errors.append(f"{where} 用了 rubrics 里没有的锚点文案：{dim}={anchor}")
        report_cfg = rubrics.get("report") or {}
        if int(report_cfg.get("maxSuggestions", 0)) > 2:
            errors.append("rubrics.report.maxSuggestions 不得超过 2（算法册：最多 2 条发展建议）")
        if not (rubrics.get("bt") or {}).get("provisional"):
            errors.append("rubrics.bt 必须标 provisional: true，B_t 系数未校准前不得当成定稿")
    templates_path = DATA / "report_templates.json"
    if not templates_path.exists():
        warnings.append("report_templates.json 还没建，规则 9 的校验到 P0 后半段才会真正生效")

    print(f"v12m_validate：范围 {sorted(scope)}，节点 {len([n for n in nodes if int(n.get('month', 0)) in scope])} 个，提示 {len([h for h in (hints or {}).get('hints', []) if int(h.get('month', 0)) in scope])} 条")
    for line in warnings:
        print(f"WARN  {line}")
    for line in errors:
        print(f"ERROR {line}")
    if errors:
        print(f"失败：{len(errors)} 个错误，{len(warnings)} 个警告")
        return 1
    print(f"通过：0 个错误，{len(warnings)} 个警告")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
