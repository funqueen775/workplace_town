"""Exercise anonymous session ownership at the HTTP boundary."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import threading
from http.client import HTTPConnection
from pathlib import Path
from unittest.mock import patch

import npc_chat
import server


def request(port: int, method: str, path: str, body: dict | None = None,
            token: str = "") -> tuple[int, dict]:
    connection = HTTPConnection("127.0.0.1", port, timeout=10)
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    connection.request(method, path, json.dumps(body).encode() if body is not None else None,
                       headers)
    response = connection.getresponse()
    result = response.status, json.loads(response.read())
    connection.close()
    return result


def main() -> None:
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as temp_dir:
        db_path = Path(temp_dir) / "old.db"
        with sqlite3.connect(db_path) as database:
            database.execute("CREATE TABLE sessions(session_id TEXT PRIMARY KEY,"
                             " created_at TEXT NOT NULL, content_version TEXT NOT NULL,"
                             " state_json TEXT NOT NULL)")
        service = server.build_service(db_path, story_version="v1.2")
        handler = type("PublicHandler", (server.Handler,),
                       {"service": service, "PUBLIC_MODE": True})
        httpd = server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
        worker = threading.Thread(target=httpd.serve_forever, daemon=True)
        worker.start()
        port = httpd.server_address[1]
        try:
            code, first = request(port, "POST", "/api/v1/sessions",
                                  {"contentVersion": "v1.2"})
            assert code == 201 and first["sessionToken"]
            session_id = first["sessionId"]
            token = first["sessionToken"]
            path = f"/api/v1/sessions/{session_id}"
            assert request(port, "GET", path)[0] == 403
            assert request(port, "GET", path, token="wrong")[0] == 403
            assert request(port, "GET", path, token=token)[0] == 200
            assert request(port, "POST", "/api/v1/sessions",
                           {"resumeSessionId": session_id})[0] == 403
            legacy_code, legacy = service.create_session({"contentVersion": "v1.2"})
            assert legacy_code == 201
            legacy_id = legacy["sessionId"]
            code, claimed = request(port, "POST", "/api/v1/sessions",
                                    {"resumeSessionId": legacy_id})
            assert code == 200 and claimed["sessionToken"]
            assert request(port, "POST", "/api/v1/sessions",
                           {"resumeSessionId": legacy_id})[0] == 403
            assert request(port, "GET", f"/api/v1/sessions/{legacy_id}",
                           token=claimed["sessionToken"])[0] == 200
            code, resumed = request(port, "POST", "/api/v1/sessions",
                                    {"resumeSessionId": session_id,
                                     "sessionToken": token})
            assert code == 200 and resumed["sessionId"] == session_id
            code, second = request(port, "POST", "/api/v1/sessions",
                                   {"contentVersion": "v1.2"})
            assert code == 201
            assert request(port, "GET", f"/api/v1/sessions/{second['sessionId']}",
                           token=token)[0] == 403
            assert request(port, "GET", "/api/v1/health")[0] == 200
            for index in range(40):
                service.store.insert_event(session_id, f"chat-{index}", None,
                                           "npc_dialogue_complete", server.now_iso(),
                                           '{"chatResponse":{"reply":"ok"}}', "{}")
            with patch.object(npc_chat, "reply", return_value=("hello", "llm")):
                code, chat = request(port, "POST", f"{path}/npcs/wang_ge/chat",
                                     {"eventId": "new-chat", "clientTime": server.now_iso(),
                                      "contentVersion": "v1.2", "text": "hello"}, token=token)
            assert code == 200 and chat["reply"] == "hello"
            for _ in range(61):
                assert request(port, "POST", "/api/v1/sessions",
                               {"contentVersion": "v1.2"})[0] == 201
        finally:
            httpd.shutdown()
            httpd.server_close()
            worker.join(timeout=5)
            service.store.conn.close()


if __name__ == "__main__":
    main()
    print("Public session isolation: OK")
