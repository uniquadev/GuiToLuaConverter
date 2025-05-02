from sys import argv
from dump import SanitizeDump
from pathlib import Path
import json

# from api_v2 import RobloxStudioApi as RobloxStudioApiV2
from api import RobloxStudioApi as RobloxStudioApiLegacy

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
            Api = RobloxStudioApiLegacy()
        case 1:
            # Api = RobloxStudioApiV2()
            pass
        case _:
            print("Invalid index.")
            return
    
    DumpJSON = Api.DumpJSON()
    JSON = SanitizeDump(DumpJSON)
    
    # Writing JSON to file
    with open(DUMP_PATH, "w+") as f:
        f.write(json.dumps(JSON, indent=4))
    
if __name__ == '__main__':
    main()