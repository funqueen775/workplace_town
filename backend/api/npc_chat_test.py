from __future__ import annotations

import tempfile
import uuid
import json
from io import BytesIO
from pathlib import Path
from unittest.mock import patch

import npc_chat
import server


def request(text: str, event_id: str | None = None) -> dict:
    return {
        "eventId": event_id or str(uuid.uuid4()), "contentVersion": "v1.2",
        "clientTime": "2026-09-25T12:00:00+08:00", "text": text,
    }


def main() -> None:
    service = server.build_service(Path(tempfile.mkdtemp()) / "chat.db", story_version="v1.2")
    status, session = service.create_session({"contentVersion": "v1.2"})
    assert status == 201
    sid = session["sessionId"]
    initial_state = service.get_session(sid)[1]["state"]
    with patch.object(npc_chat, "reply", side_effect=lambda npc, text, memories: (
            f"{npc['name']}回复：{text}", "llm")):
        first = request("预算和工期怎么安排？")
        code, answer = service.npc_chat(sid, "chen_gong", first)
        assert code == 200 and answer["generatedBy"] == "llm"
        assert answer["memoryRefs"] == []
        assert service.npc_chat(sid, "chen_gong", first) == (200, answer)
        second = request("上次说的预算有变化")
        code, next_answer = service.npc_chat(sid, "chen_gong", second)
        assert code == 200
        assert any(ref["eventId"] == first["eventId"] for ref in next_answer["memoryRefs"])

    code, memories = service.npc_memories(sid, "chen_gong", ["social"], 20)
    assert code == 200 and len(memories["items"]) == 4
    assert any(item["kind"] == "npc_reply" for item in memories["items"])
    assert len(service.store.event_stream(sid)) == 2
    state = service.get_session(sid)[1]["state"]
    assert state["scoreSummary"] == initial_state["scoreSummary"]
    assert state["level"] == initial_state["level"]
    assert service.npc_chat(sid, "wang_ge", first)[0] == 409
    assert service.npc_chat(sid, "unknown", request("你好"))[0] == 404
    assert service.npc_chat(sid, "chen_gong", request(" "))[0] == 400
    with patch.object(npc_chat, "_local_config", return_value={}), patch.dict(
            "os.environ", {"ARK_API_KEY": "", "NPC_LLM_PROVIDER": "ark"}):
        for npc in npc_chat.NPCS.values():
            fallback, source = npc_chat.reply(npc, "你好", [])
            assert fallback == npc["fallbackReply"] and source == "template"
    with patch.object(npc_chat, "_local_config", return_value={
            "provider": "deepseek", "apiKey": "local-test-token"}), patch.dict(
            "os.environ", {"NPC_LLM_PROVIDER": "deepseek"}, clear=True):
        fake_response = BytesIO(b'{"choices":[{"message":{"content":"local reply"}}]}')
        with patch.object(npc_chat, "urlopen", return_value=fake_response) as transport:
            text, source = npc_chat.reply(npc_chat.NPCS["chen_gong"], "你好", [])
            assert (text, source) == ("local reply", "llm")
            assert transport.call_args.args[0].get_header("Authorization") == "Bearer local-test-token"
    with patch.dict("os.environ", {"NPC_LLM_PROVIDER": "deepseek", "DEEPSEEK_API_KEY": "test-token"}):
        fake_response = BytesIO(b'{"choices":[{"message":{"content":"mocked reply"}}]}')
        with patch.object(npc_chat, "urlopen", return_value=fake_response) as transport:
            text, source = npc_chat.reply(npc_chat.NPCS["chen_gong"], "你好", [])
            assert (text, source) == ("mocked reply", "llm")
            outgoing = transport.call_args.args[0]
            assert outgoing.full_url == "https://api.deepseek.com/chat/completions"
            assert json.loads(outgoing.data)["model"] == "deepseek-chat"
            assert outgoing.get_header("Authorization") == "Bearer test-token"
    with patch.dict("os.environ", {"NPC_LLM_PROVIDER": "deepseek", "DEEPSEEK_API_KEY": ""}):
        text, source = npc_chat.reply(npc_chat.NPCS["chen_gong"], "你好", [])
        assert source == "template" and text == npc_chat.NPCS["chen_gong"]["fallbackReply"]
    print("NPC_CHAT_PASS: idempotency, memory, isolation, validation")


if __name__ == "__main__":
    main()
