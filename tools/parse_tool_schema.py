import json
import os

path = os.path.join(os.environ["TEMP"], "stitch_tools.txt")
with open(path, encoding="utf-8") as f:
    data = json.load(f)
for t in data["result"]["tools"]:
    if t["name"] in {"list_screens", "get_screen", "download_file", "get_project"}:
        print("====", t["name"])
        print(json.dumps(t.get("inputSchema"), indent=2)[:4000])
