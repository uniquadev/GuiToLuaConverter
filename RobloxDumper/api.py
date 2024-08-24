"""Locate roblox studio binary and perform an api execution"""
import os
import json

class RobloxStudioApi:
    BinaryPath : None | str = r"C:\Users\%username%\AppData\Local\Roblox\Versions\version-e60bca3482fe488a\RobloxStudioBeta.exe"
    def __init__(self) -> None:
        pass
    
    def DumpJSON(self) -> dict:
        os.system(f"{self.BinaryPath} -API api_dump.json")
        if not os.path.exists("api_dump.json"):
            raise FileNotFoundError("api_dump.json not found")
        return json.load(open("api_dump.json"))
