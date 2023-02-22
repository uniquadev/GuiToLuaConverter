from api import *
from dump import SanitizeDump
from pathlib import Path

DUMP_JSON = Path(__file__).parent.parent.joinpath("PluginPlace/src/assets/dump.json").absolute()

def main():
    Api = RobloxStudioApi()
    DumpJSON = Api.DumpJSON()
    JSON = SanitizeDump(DumpJSON)
    
    # Writing JSON to file
    with open(DUMP_JSON, "w+") as f:
        f.write(json.dumps(JSON, indent=4))
    

if __name__ == '__main__':
    main()