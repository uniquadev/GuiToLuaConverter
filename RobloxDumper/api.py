"""Locate roblox studio binary and perform an api execution"""
import os
import json

class RobloxStudioApi:
    BinaryPath : None | str = r"C:\Users\%username%\AppData\Local\Roblox\Versions\version-cab881b8584d4028\RobloxStudioBeta.exe"
    def __init__(self) -> None:
        pass
    
    def DumpJSON(self) -> dict:
        os.system(f"{self.BinaryPath} -API api_dump.json")
        return json.load(open("api_dump.json"))
