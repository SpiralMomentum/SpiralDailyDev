"""게시 원장 (중복 게시 방지, 채널 공통). JSON Lines 파일 한 줄 = 게시 1건."""
from __future__ import annotations

import hashlib
import json
from functools import reduce
from itertools import chain
from pathlib import Path
from typing import Any, Iterable, Mapping, Optional

from common.hosting import is_url

Row = Mapping[str, Any]


def parse_ledger(text: str) -> tuple:
    return tuple(json.loads(line) for line in text.splitlines() if line.strip())


def deleted_ids(rows: Iterable[Row]) -> frozenset:
    return frozenset(r.get("media_id") for r in rows if r.get("status") == "deleted")


def find_published(rows: Iterable[Row], key: str) -> Optional[Row]:
    """key로 게시된 행 중 이후 삭제 기록이 없는 것. 삭제된 게시물은 다시 게시할 수 있다."""
    rows = tuple(rows)
    gone = deleted_ids(rows)
    return next((r for r in rows if r.get("key") == key and r.get("status") == "published"
                 and r.get("media_id") not in gone), None)


def read_ledger(path: Path) -> tuple:
    return parse_ledger(path.read_text(encoding="utf-8")) if path.exists() else ()


def append_ledger(row: Row, path: Path) -> Row:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(dict(row), ensure_ascii=False) + "\n")
    return row


def content_key(job: Mapping[str, Any], text_field: str = "caption") -> str:
    """job의 type + 미디어 바이트(또는 URL) + 본문의 SHA-256 앞 24자. idempotency_key가 있으면 그 값."""
    if job.get("idempotency_key"):
        return str(job["idempotency_key"])
    parts = chain([str(job.get("type")).encode()],
                  (m.encode() if is_url(m) else Path(m).read_bytes() for m in job.get("media", [])),
                  [job.get(text_field, "").encode()])
    return reduce(lambda h, b: (h.update(b), h)[1], parts, hashlib.sha256()).hexdigest()[:24]
