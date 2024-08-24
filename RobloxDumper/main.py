from pick import pick
from dump import SanitizeDump
from pathlib import Path
import json

# Import necessary classes/functions from api_v2 and api
from api_v2 import RobloxStudioApi as RobloxStudioApiV2
from api import RobloxStudioApi as RobloxStudioApiLegacy

DUMP_JSON = Path(__file__).parent.parent.joinpath("PluginPlace/src/assets/dump.json").absolute()

def main():
    version, index = pick(["V2", "V1"], 'Please choose what API Dumper you want to use:')
    
    if index == 0:
        Api = RobloxStudioApiV2()
    elif index == 1:
        Api = RobloxStudioApiLegacy()
    
    DumpJSON = Api.DumpJSON()
    JSON = SanitizeDump(DumpJSON)
    
    # Writing JSON to file
    with open(DUMP_JSON, "w+") as f:
        f.write(json.dumps(JSON, indent=4))
    
if __name__ == '__main__':
    main()