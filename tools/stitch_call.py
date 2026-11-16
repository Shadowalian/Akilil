"""Call Google Stitch MCP tools via HTTP JSON-RPC."""
from __future__ import annotations

import json
import os
import sys
import urllib.request

API_KEY = os.environ.get("STITCH_API_KEY", "")
if not API_KEY:
    raise SystemExit("Set STITCH_API_KEY in the environment")
URL = "https://stitch.googleapis.com/mcp"


def call(method: str, params: dict | None = None, rpc_id: int = 1) -> dict:
    payload = {
        "jsonrpc": "2.0",
        "id": rpc_id,
        "method": method,
        "params": params or {},
    }
    req = urllib.request.Request(
        URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "X-Goog-Api-Key": API_KEY,
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
        },
        method="POST",
    )
    # Windows may fail revocation checks offline.
    ctx = None
    try:
        import ssl

        ctx = ssl.create_default_context()
        # Keep verification; only disable revocation if needed via env.
        if os.environ.get("STITCH_SSL_NO_REVOKE") == "1":
            ctx.check_hostname = True
            ctx.verify_mode = ssl.CERT_REQUIRED
    except Exception:
        ctx = None
    with urllib.request.urlopen(req, context=ctx, timeout=180) as resp:
        return json.loads(resp.read().decode("utf-8"))


def tool(name: str, arguments: dict | None = None) -> dict:
    return call("tools/call", {"name": name, "arguments": arguments or {}})


def unwrap_text(result: dict) -> str:
    content = result.get("result", {}).get("content", [])
    texts = []
    for item in content:
        if isinstance(item, dict) and "text" in item:
            texts.append(item["text"])
    return "\n".join(texts)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: stitch_call.py <tool> [json-args]")
        sys.exit(1)
    name = sys.argv[1]
    args = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
    out = tool(name, args)
    print(json.dumps(out, indent=2)[:20000])
