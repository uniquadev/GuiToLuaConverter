from api import *
from dump import SanitizeDump

def main():
    Api = RobloxStudioApi()
    DumpJSON = Api.DumpJSON()
    JSON = SanitizeDump(DumpJSON)
    # TODO store the JSON inside PluginPlace/src/plugin/dump.json
    

if __name__ == '__main__':
    main()