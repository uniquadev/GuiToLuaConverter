#"""Locate roblox studio binary and perform an api execution"""
"""perform a http request to max's latest api dump"""
#import os
import requests
import json

class RobloxStudioApi:
    BinaryPath : None | str = r"C:\Users\%username%\AppData\Local\Roblox\Versions\version-e2bc56a1e4374ca0\RobloxStudioBeta.exe" # new binary path should be r"%localappdata%\Roblox Studio\RobloxStudioBeta.exe"
    def __init__(self) -> None:
        pass
    
    def DumpJSON(self) -> dict:
        #os.system(f"{self.BinaryPath} -API api_dump.json")
        #if not os.path.exists("api_dump.json"):
        #    raise FileNotFoundError("api_dump.json not found")
        #return json.load(open("api_dump.json"))
        return json.loads(requests.get("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json").text)