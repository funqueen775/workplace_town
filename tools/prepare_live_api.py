"""Archive local mock API state before starting a fresh live session."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import tempfile
from collections import Counter
from datetime import datetime
from pathlib import Path


QUEUE_NAME = "workplace_town_api_queue.json"
SESSION_NAME = "workplace_town_api_session.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def replace_json(path: Path, value: object) -> None:
    raw = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=path.parent, prefix=path.name + ".",
        suffix=".tmp", delete=False,
    ) as handle:
        temporary = Path(handle.name)
        handle.write(raw)
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, path)


def prepare(data_dir: Path) -> Path:
    queue_path = data_dir / QUEUE_NAME
    session_path = data_dir / SESSION_NAME
    queue = json.loads(queue_path.read_text(encoding="utf-8"))
    session = json.loads(session_path.read_text(encoding="utf-8"))
    if not isinstance(queue, list) or not isinstance(session, dict):
        raise ValueError("API queue or session has an unexpected JSON shape")

    versions = Counter(str(item.get("contentVersion", "")) for item in queue)
    archive = data_dir / "api_archive" / datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    archive.mkdir(parents=True, exist_ok=False)
    for source in (queue_path, session_path):
        destination = archive / source.name
        shutil.copy2(source, destination)
        if sha256(source) != sha256(destination):
            raise OSError(f"Backup verification failed: {source.name}")

    if any(sha256(source) != sha256(archive / source.name)
           for source in (queue_path, session_path)):
        raise OSError("API state changed while backing up; no active files were reset")

    replace_json(queue_path, [])
    replace_json(session_path, {"contentVersion": "v1.2", "confirmed": False, "sessionId": ""})
    print(f"Archived {len(queue)} events ({dict(versions)}) in {archive}")
    return archive


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--data-dir", type=Path,
        default=Path(os.environ["APPDATA"]) / "Godot" / "app_userdata" / "职场小镇",
    )
    args = parser.parse_args()
    prepare(args.data_dir)
