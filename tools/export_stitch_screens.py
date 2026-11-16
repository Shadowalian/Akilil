"""Export all Stitch screens (metadata, screenshots, HTML) for Akilil."""
from __future__ import annotations

import base64
import json
import os
import re
import ssl
import urllib.request
from pathlib import Path

API_KEY = os.environ.get("STITCH_API_KEY", "")
if not API_KEY:
    raise SystemExit("Set STITCH_API_KEY in the environment")
URL = "https://stitch.googleapis.com/mcp"
PROJECT = "7529641220560354026"
OUT = Path(r"c:\Users\user\Desktop\fd\designs\stitch-akilil")


def rpc(method: str, params: dict, rpc_id: int = 1) -> dict:
    payload = {"jsonrpc": "2.0", "id": rpc_id, "method": method, "params": params}
    ctx = ssl.create_default_context()
    req = urllib.request.Request(
        URL,
        data=json.dumps(payload).encode(),
        headers={
            "X-Goog-Api-Key": API_KEY,
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, context=ctx, timeout=180) as resp:
        return json.loads(resp.read().decode())


def tool(name: str, arguments: dict) -> dict:
    return rpc("tools/call", {"name": name, "arguments": arguments})


def unwrap_json(result: dict):
    content = result.get("result", {}).get("content", [])
    for item in content:
        if isinstance(item, dict) and "text" in item:
            text = item["text"]
            try:
                return json.loads(text)
            except json.JSONDecodeError:
                return {"raw": text}
    return result


def slug(title: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9]+", "-", title).strip("-").lower()
    return s[:80] or "screen"


def download_bytes(url: str) -> bytes:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "akilil-export/1.0",
            "X-Goog-Api-Key": API_KEY,
        },
    )
    ctx = ssl.create_default_context()
    with urllib.request.urlopen(req, context=ctx, timeout=180) as resp:
        return resp.read()


def save_download_file(file_name: str, dest: Path) -> None:
    """download_file may return base64, URL, or inline text."""
    res = unwrap_json(tool("download_file", {"name": file_name}))
    dest.parent.mkdir(parents=True, exist_ok=True)
    # Common shapes
    if isinstance(res, dict):
        if "downloadUrl" in res:
            dest.write_bytes(download_bytes(res["downloadUrl"]))
            return
        if "url" in res:
            dest.write_bytes(download_bytes(res["url"]))
            return
        if "content" in res and isinstance(res["content"], str):
            raw = res["content"]
            # base64?
            try:
                dest.write_bytes(base64.b64decode(raw))
                return
            except Exception:
                dest.write_text(raw, encoding="utf-8")
                return
        if "data" in res and isinstance(res["data"], str):
            try:
                dest.write_bytes(base64.b64decode(res["data"]))
                return
            except Exception:
                dest.write_text(res["data"], encoding="utf-8")
                return
        if "raw" in res:
            dest.write_text(str(res["raw"]), encoding="utf-8")
            return
        dest.write_text(json.dumps(res, indent=2), encoding="utf-8")
        return
    dest.write_text(str(res), encoding="utf-8")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    screens = unwrap_json(tool("list_screens", {"projectId": PROJECT})).get("screens", [])
    index = []
    for i, s in enumerate(screens):
        name = s["name"]
        title = s.get("title") or name
        print(f"[{i+1}/{len(screens)}] {title}")
        detail = unwrap_json(tool("get_screen", {"name": name}))
        folder = OUT / f"{i+1:02d}-{slug(title)}"
        folder.mkdir(parents=True, exist_ok=True)
        (folder / "screen.json").write_text(json.dumps(detail, indent=2), encoding="utf-8")

        # screenshot + html from detail
        screen_obj = detail.get("screen") or detail
        shot = screen_obj.get("screenshot") or screen_obj.get("thumbnailScreenshot") or {}
        html = screen_obj.get("htmlCode") or screen_obj.get("html_code") or {}

        if isinstance(shot, dict):
            if shot.get("downloadUrl"):
                (folder / "screenshot.png").write_bytes(download_bytes(shot["downloadUrl"]))
            elif shot.get("name"):
                save_download_file(shot["name"], folder / "screenshot.bin")
        if isinstance(html, dict):
            if html.get("downloadUrl"):
                raw = download_bytes(html["downloadUrl"])
                try:
                    (folder / "screen.html").write_text(raw.decode("utf-8"), encoding="utf-8")
                except Exception:
                    (folder / "screen.html.bin").write_bytes(raw)
            elif html.get("name"):
                save_download_file(html["name"], folder / "screen.html")

        index.append(
            {
                "title": title,
                "name": name,
                "folder": str(folder.relative_to(OUT.parent.parent)),
                "deviceType": screen_obj.get("deviceType") or s.get("deviceType"),
            }
        )

    # project theme / design md
    project = unwrap_json(tool("get_project", {"name": f"projects/{PROJECT}"}))
    (OUT / "project.json").write_text(json.dumps(project, indent=2), encoding="utf-8")
    theme = (project.get("project") or project).get("designTheme") or {}
    design_md = theme.get("designMd") or theme.get("design_md")
    if design_md:
        (OUT / "DESIGN.md").write_text(design_md, encoding="utf-8")
    (OUT / "index.json").write_text(json.dumps(index, indent=2), encoding="utf-8")
    print("DONE", OUT)


if __name__ == "__main__":
    main()
