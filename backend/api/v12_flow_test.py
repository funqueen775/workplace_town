from __future__ import annotations

import json
import sys
import tempfile
import uuid
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import server as srv


def event(story_id: str, choice: str = "option_a") -> dict:
    return {
        "eventId": str(uuid.uuid4()),
        "eventType": "option_click",
        "contentVersion": "v1.2",
        "clientTime": "2026-09-24T12:00:00+08:00",
        "payload": {"regionId": "A", "storyId": story_id,
                    "choiceId": choice, "hesitationMs": 2000},
    }


def main() -> None:
    story = srv.load_story_json(srv.STORY_V12_PATH)["events"]
    service = srv.build_service(Path(tempfile.mkdtemp()) / "v12.db", story_version="v1.2")
    code, session = service.create_session({"contentVersion": "v1.2"})
    assert code == 201
    sid = session["sessionId"]
    months = (6, 12, 18, 24, 30, 36, 42)
    achievements = {"E08": "C1", "E12": "C2", "E22": "C3",
                    "E38": "C4", "E34": "C5"}
    settled = []
    for index, node in enumerate(story):
        story_id = node["id"]
        assert service.next_node(sid)[1]["nodeId"] == story_id
        choice = "option_c" if story_id == "E23" else ("option_a", "option_b", "option_c")[index % 3]
        code, response = service.post_event(sid, event(story_id, choice))
        assert code == 200, (story_id, response)
        assert response["state"]["currentMonth"] == node["month"]
        if story_id in achievements:
            achievement_id = achievements[story_id]
            achievement = event(achievement_id)
            achievement["eventType"] = "achievement_view"
            if achievement_id not in ("C4", "C5"):
                achievement["payload"].pop("choiceId")
            code, result = service.post_event(sid, achievement)
            assert code == 200, (achievement_id, result)
            assert service.next_node(sid)[1]["nodeId"] == (
                story[index + 1]["id"] if index + 1 < len(story) else "END")
        next_month = story[index + 1]["month"] if index + 1 < len(story) else 49
        for month in months:
            if month in settled or not (node["month"] <= month < next_month):
                continue
            code, assessment = service.settle_assessment(sid, month)
            assert code == 200, (month, assessment)
            assert all(isinstance(value, bool) for value in assessment["assessmentSummary"].values())
            assert service.settle_assessment(sid, month) == (code, assessment)
            settled.append(month)
    assert settled == list(months), settled
    action = event("")
    action["eventType"] = "action_spent"
    action["payload"] = {"regionId": "G", "activityKind": "area_activity",
                         "activityId": "G_NIGHT", "windowId": "FW_REPORT",
                         "month": 48, "remainingAfter": 2}
    assert service.post_event(sid, action)[0] == 200
    chat = event("")
    chat["eventType"] = "npc_dialogue_complete"
    chat["payload"] = {"regionId": "B", "npcId": "wang_ge",
                       "message": "我想尝试新方案", "month": 48}
    assert service.post_event(sid, chat)[0] == 200
    code, response = service.generate_report(sid)
    assert code == 202 and response["status"] == "ready", response
    code, report = service.get_report(sid)
    assert code == 200 and report["decisionCount"] == 39, (code, report.get("decisionCount"))
    assert len(report["layers"]["persona"]["promotionTrack"]["windows"]) == 7
    state = srv.Engine.state_from_json(service.store.get_session(sid)["state_json"])
    baseline = srv.build_report(srv.ReportInput(state, state.month_log, []),
                                service.engine.reg)["layers"]["persona"]
    actual = {row["trait"]: row for row in report["layers"]["persona"]["bigfive"]}
    original = {row["trait"]: row for row in baseline["bigfive"]}
    assert actual["O"]["evidenceCount"] == original["O"]["evidenceCount"] + 1
    assert actual["C"]["evidenceCount"] == original["C"]["evidenceCount"] + 1
    assert chat["payload"]["message"] not in json.dumps(report, ensure_ascii=False)
    interactions = [
        {"tap": "action_spent", "activityKind": "area_activity",
         "activityId": "G_NIGHT", "month": 12},
        {"tap": "npc_dialogue", "message": "我想尝试新方案", "month": 12},
        {"tap": "npc_dialogue", "message": "今天吃什么", "month": 12},
    ]
    portrait = srv.build_report(srv.ReportInput(state, state.month_log, interactions),
                                service.engine.reg)["layers"]["persona"]
    before = {row["trait"]: row for row in baseline["bigfive"]}
    after = {row["trait"]: row for row in portrait["bigfive"]}
    neutral = srv.build_report(srv.ReportInput(state, state.month_log, [
        {"tap": "npc_dialogue", "message": "今天吃什么", "month": 12},
    ]), service.engine.reg)["layers"]["persona"]
    assert neutral["bigfive"] == baseline["bigfive"]
    assert after["O"]["evidenceCount"] == before["O"]["evidenceCount"] + 1, (before["O"], after["O"])
    assert after["C"]["evidenceCount"] == before["C"]["evidenceCount"] + 1
    assert after["O"]["behavior"] >= before["O"]["behavior"]
    assert after["C"]["behavior"] >= before["C"]["behavior"]
    assert after["O"]["portraitScore"] >= before["O"]["portraitScore"]
    assert after["C"]["portraitScore"] >= before["C"]["portraitScore"]
    assert after["E"]["evidenceCount"] == before["E"]["evidenceCount"]
    assert len(portrait["styleTags"]) >= 1
    assert "我想尝试新方案" not in json.dumps(portrait, ensure_ascii=False)
    stale = json.loads(json.dumps(report, ensure_ascii=False))
    del stale["portraitVersion"]
    service.store.save_report(sid, "ready", "", json.dumps(stale, ensure_ascii=False), None)
    assert service.generate_report(sid)[0] == 202
    assert service.get_report(sid)[1]["portraitVersion"] == 2
    code, skipped_session = service.create_session({"contentVersion": "v1.2"})
    assert code == 201
    skipped_sid = skipped_session["sessionId"]
    first_jump = event("")
    first_jump["eventType"] = "month_jump"
    first_jump["payload"] = {"regionId": "A", "targetMonth": 7}
    code, jump_result = service.post_event(skipped_sid, first_jump)
    assert code == 200, jump_result
    assert jump_result["state"]["currentMonth"] == 7
    assert service.next_node(skipped_sid)[1]["nodeId"] == "E08"
    assert len(jump_result["state"]["skippedStoryIds"]) == 7
    assert len(jump_result["state"]["assessmentHistory"]) == 1
    assert service.post_event(skipped_sid, first_jump)[1]["duplicate"]
    assert service.post_event(skipped_sid, event("E08"))[0] == 200
    final_jump = event("")
    final_jump["eventType"] = "month_jump"
    final_jump["payload"] = {"regionId": "A", "targetMonth": 48}
    code, jump_result = service.post_event(skipped_sid, final_jump)
    assert code == 200, jump_result
    assert service.next_node(skipped_sid)[1]["nodeId"] == "E35"
    assert len(jump_result["state"]["skippedStoryIds"]) == 37
    assert len(jump_result["state"]["assessmentHistory"]) == 7
    assert service.generate_report(skipped_sid)[0] == 409
    assert service.post_event(skipped_sid, event("E35"))[0] == 200
    assert service.generate_report(skipped_sid)[0] == 202
    code, sparse_report = service.get_report(skipped_sid)
    assert code == 200 and sparse_report["decisionCount"] == 2
    assert len(sparse_report["skippedStoryIds"]) == 37
    sparse_persona = sparse_report["layers"]["persona"]
    assert sparse_persona["portraitStatus"] == "provisional"
    assert all(0 <= row["portraitScore"] <= 100 for row in sparse_persona["bigfive"])
    assert all(row["portraitScore"] == 50 for row in sparse_persona["bigfive"]
               if row["portraitEvidence"] == "none")
    assert sparse_persona["styleTags"] != ["证据不足"]
    print("V1.2 PASS: 39 choices, 5 achievements, 7 checkpoints, month 48, final report")


if __name__ == "__main__":
    main()
