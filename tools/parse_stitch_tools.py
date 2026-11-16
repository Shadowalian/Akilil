import json
import os

path = os.path.join(os.environ["TEMP"], "stitch_tools.txt")
with open(path, encoding="utf-8") as f:
    data = json.load(f)
tools = data["result"]["tools"]
print(f"count={len(tools)}")
for t in tools:
    desc = (t.get("description") or "").replace("\n", " ")[:140]
    print(f"{t['name']}: {desc}")
