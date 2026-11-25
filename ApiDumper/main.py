import json
from pathlib import Path
from sys import argv
from api import RobloxStudioApi as RobloxStudioApiLegacy
from api_v2 import RobloxStudioApi as RobloxStudioApiV2
from dump import SanitizeDump

DUMP_PATH = Path(__file__).parent.parent.joinpath("PluginPlace/src/assets/dump.json").absolute()

def main():
    if len(argv) < 2:
        print("Please specify an index for the API to use.\nUsage: python main.py <index[0,1]>")
        return

    try:
        index = int(argv[1])
    except ValueError:
        index = -1

    match index:
        case 0:
            api = RobloxStudioApiLegacy()
        case 1:
            api = RobloxStudioApiV2()
        case _:
            print("Invalid index.")
            return

    dump_json = api.DumpJSON()
    sanitized = SanitizeDump(dump_json)

    with open(DUMP_PATH, "w+", encoding="utf-8") as f:
        f.write(json.dumps(sanitized, indent=4))

if __name__ == "__main__":
    main()
