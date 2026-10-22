"""Conservative, explainable supplementary evidence for the final Big Five portrait."""

from __future__ import annotations

import copy

from ..core import constants as C
from ..engine.state import GameState


ACTIVITY_TRAITS = {
    "D_STUDY": ("O", 1),
    "E_SPORT": ("E", 1),
    "E_ESCAPE": ("A", 1),
    "F_STAGE": ("E", 1),
    "G_NIGHT": ("C", 1),
    "G_KTV": ("E", 1),
    "C_COFFEE": ("E", 1),
    "H_BBQ": ("E", 1),
    "H_BOARD": ("O", 1),
}

CHAT_PHRASES = {
    "O": ("我想尝试新", "我想探索", "我想学习新"),
    "C": ("我会按计划", "我会先核对", "我会负责到底"),
    "E": ("我会主动沟通", "我想主动表达", "我会去争取"),
    "A": ("我会帮助", "我想理解", "我会支持"),
    "N": ("我会冷静处理", "我会先冷静", "我能稳定应对"),
}


def with_interaction_evidence(state: GameState, tracking: list[dict]) -> GameState:
    enriched = copy.copy(state)
    enriched.bigfive_evidence = copy.deepcopy(state.bigfive_evidence)
    added = {trait: 0 for trait in C.BIGFIVE_KEYS}
    for item in tracking:
        trait = None
        direction = 1
        if item.get("tap") == "action_spent" and item.get("activityKind") == "area_activity":
            trait, direction = ACTIVITY_TRAITS.get(str(item.get("activityId")), (None, 1))
        elif item.get("tap") == "npc_dialogue":
            message = str(item.get("message") or "")[:500]
            hits = [key for key, phrases in CHAT_PHRASES.items()
                    if any(phrase in message for phrase in phrases)]
            if len(hits) == 1:
                trait = hits[0]
        if trait is None or added[trait] >= 3:
            continue
        added[trait] += 1
        coef = 1.0
        strength = 0.25
        enriched.bigfive_evidence.setdefault(trait, []).append({
            "trait": trait, "dir": direction, "coef": coef,
            "strength": strength, "weighted": direction * coef * strength,
            "month": item.get("month"), "node": item.get("activityId") or "npc_dialogue",
        })
    return enriched


def style_tags(rows: list[dict]) -> list[str]:
    labels = {
        "O": ("探索新路", "稳妥务实"),
        "C": ("计划周密", "灵活应变"),
        "E": ("主动表达", "安静倾听"),
        "A": ("协作体贴", "坚持立场"),
        "N": ("沉着应对", "感受敏锐"),
    }
    ranked = sorted((row for row in rows if row["portrait_evidence"] != "none"),
                    key=lambda row: abs(row["portrait_score"] - 50), reverse=True)
    tags = []
    for row in ranked:
        score = row["portrait_score"]
        if abs(score - 50) >= 2:
            tags.append(labels[row["trait"]][0 if score >= 50 else 1])
        if len(tags) == 2:
            break
    if not ranked:
        return ["待积累经历"]
    return tags or ["平衡探索"]
