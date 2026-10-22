"""Print aggregate counts from a local Workplace Town database."""

from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", type=Path, default=Path("/var/lib/workplace-town/game.sqlite3"))
    args = parser.parse_args()
    if not args.db.is_file():
        parser.error(f"database not found: {args.db}")
    with sqlite3.connect(f"file:{args.db}?mode=ro", uri=True) as database:
        for table in ("sessions", "events", "reports"):
            count = database.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            print(f"{table}: {count}")
        print("\nsessions by day:")
        for day, count in database.execute(
                "SELECT substr(created_at, 1, 10), COUNT(*) FROM sessions "
                "GROUP BY 1 ORDER BY 1 DESC LIMIT 30"):
            print(f"{day}: {count}")
        print("\nevents by type:")
        for event_type, count in database.execute(
                "SELECT event_type, COUNT(*) FROM events GROUP BY 1 ORDER BY 2 DESC"):
            print(f"{event_type}: {count}")


if __name__ == "__main__":
    main()
