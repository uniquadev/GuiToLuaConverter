from api import *
from dump import SanitizeDump

def main():
    Api = RobloxStudioApi()
    DumpJSON = Api.DumpJSON()
    JSON = SanitizeDump(DumpJSON)
    
    # Writing JSON to file
    with open("PluginPlace/src/assets/dump.json", "w") as f:
        f.write(json.dumps(JSON, indent=4))
    

if __name__ == '__main__':
    main()