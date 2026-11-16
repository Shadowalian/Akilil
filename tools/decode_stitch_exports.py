"""Decode Stitch download_file JSON wrappers into real PNG/HTML files."""
from __future__ import annotations

import base64
import json
import re
from pathlib import Path

ROOT = Path(r"c:\Users\user\Desktop\fd\designs\stitch-akilil")


def decode_html(path: Path) -> None:
    raw = path.read_text(encoding="utf-8")
    data = json.loads(raw)
    html = data.get("dataString") or data.get("content") or ""
    if not html:
        return
    # unescape if needed
    out = path.with_name("index.html")
    out.write_text(html, encoding="utf-8")
    print("html", out)


def decode_png(path: Path) -> None:
    raw = path.read_text(encoding="utf-8")
    data = json.loads(raw)
    # common shapes
    b64 = (
        data.get("imageData")
        or data.get("data")
        or data.get("content")
        or data.get("bytesBase64Encoded")
    )
    meta = data.get("imageMetadata") or {}
    if not b64 and "image" in data:
        b64 = data["image"]
    if isinstance(b64, dict):
        b64 = b64.get("data") or b64.get("content")
    if not b64:
        # search any long base64-looking string
        m = re.search(r'"([A-Za-z0-9+/]{200,}={0,2})"', raw)
        b64 = m.group(1) if m else None
    if not b64:
        print("NO B64", path, list(data.keys())[:20], meta)
        return
    if b64.startswith("data:"):
        b64 = b64.split(",", 1)[1]
    out = path.with_name("preview.png")
    out.write_bytes(base64.b64decode(b64))
    print("png", out, out.stat().st_size)


def main() -> None:
    for folder in sorted(ROOT.glob("*/")):
        html = folder / "screen.html"
        shot = folder / "screenshot.png"
        if html.exists():
            try:
                decode_html(html)
            except Exception as e:
                print("html fail", folder.name, e)
        if shot.exists():
            try:
                decode_png(shot)
            except Exception as e:
                print("png fail", folder.name, e)


if __name__ == "__main__":
    main()
