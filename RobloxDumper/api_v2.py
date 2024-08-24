"""Perform multiple http request and extract the latest API dump"""
import urllib3
import json
import re

class RobloxStudioApi:
    def __init__(self) -> None:
        pass
    
    http = urllib3.PoolManager()

    deploy_history_url = "https://setup.rbxcdn.com/DeployHistory.txt"
    
    def DumpJSON(self) -> dict:
        response = self.http.request('GET', self.deploy_history_url)
        
        if response.status == 200:
            deploy_history_text = response.data.decode('utf-8')

            pattern = r"New Studio64 (version-[\w\d]+) at"
            matches = re.findall(pattern, deploy_history_text)

            if matches:
                latest_studio64_version = matches[-1]
                print(f"Latest Studio64 version: {latest_studio64_version}")

                api_dump_url = f"https://setup.rbxcdn.com/{latest_studio64_version}-API-Dump.json"
                api_dump_response = self.http.request('GET', api_dump_url)

                if api_dump_response.status == 200:
                    api_dump = json.loads(api_dump_response.data.decode('utf-8'))
                    print("Successfully fetched the latest API dump.")
                    return api_dump
                else:
                    print(f"Failed to fetch the latest API dump. Status code: {api_dump_response.status}")
            else:
                print("Could not find any Studio64 versions in DeployHistory.txt.")
        else:
            print(f"Failed to fetch DeployHistory.txt. Status code: {response.status}")
