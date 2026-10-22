from __future__ import annotations

import difflib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
STORY = ROOT / "data/story/main_story_v12.json"
CARDS = ROOT / "data/story/scoring_cards.json"
OUTPUT = ROOT / "data/story/story_key_map_v12.json"


def normalized(value: str) -> str:
    return "".join(char.lower() for char in value if char.isalnum())


def build() -> dict:
    story = json.loads(STORY.read_text(encoding="utf-8"))
    cards = json.loads(CARDS.read_text(encoding="utf-8"))
    events = {}
    order = []
    for event in story["events"]:
        story_id = event["id"]
        card = cards.get(event["scoringKey"])
        if not isinstance(card, dict):
            raise ValueError(f"{story_id}: missing scoring card")
        if normalized(event["title"]) != normalized(card["title"]):
            similarity = difflib.SequenceMatcher(
                None, normalized(event["title"]), normalized(card["title"])).ratio()
            if similarity < 0.55:
                raise ValueError(f"{story_id}: title mismatch")
        options = {}
        for index, choice in enumerate(event["choices"]):
            key = chr(ord("A") + index)
            card_choice = card["options"].get(key)
            if not card_choice:
                raise ValueError(f"{story_id}: missing card option {key}")
            options[choice["id"]] = key
        events[story_id] = {
            "scoringKey": event["scoringKey"],
            "align": "ok",
            "title": event["title"],
            "month": event["month"],
            "options": options,
        }
        order.append(story_id)
    if len(order) != 39 or len(set(order)) != 39:
        raise ValueError("V1.2 must contain 39 unique story events")
    return {"version": "v1.2", "source": STORY.name, "events": events,
            "playableOrder": {"list": order}}


if __name__ == "__main__":
    OUTPUT.write_text(json.dumps(build(), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"mapped {len(build()['events'])} V1.2 story events")
