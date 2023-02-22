"""Locate roblox studio binary and perform an api execution"""
import os
import json

class RobloxStudioApi:
    BinaryPath : None | str = r"C:\Users\%username%\AppData\Local\Roblox\Versions\version-161ebe8a914a48fa\RobloxStudioBeta.exe"
    def __init__(self) -> None:
        pass
    
    def DumpJSON(self) -> dict:
        os.system(f"{self.BinaryPath} -API api_dump.json")
        return json.load(open("api_dump.json"))
