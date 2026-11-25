import json
import urllib3

class RobloxStudioApi:
    http = urllib3.PoolManager()
    client_version_url = "https://clientsettingscdn.roblox.com/v2/client-version/WindowsStudio64"
    github_backup_url = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json"

    def DumpJSON(self) -> dict:
        try:
            response = self.http.request("GET", self.client_version_url)
            if response.status == 200:
                payload = json.loads(response.data.decode("utf-8"))
                version_hash = payload.get("clientVersionUpload")
                if version_hash and version_hash != "version-hidden":
                    cdn_url = f"https://setup.rbxcdn.com/{version_hash}-API-Dump.json"
                    cdn_response = self.http.request("GET", cdn_url)
                    if cdn_response.status == 200:
                        return json.loads(cdn_response.data.decode("utf-8"))
        except Exception:
            pass

        backup_response = self.http.request("GET", self.github_backup_url)
        if backup_response.status == 200:
            return json.loads(backup_response.data.decode("utf-8"))

        raise RuntimeError("Failed to fetch Roblox API dump from CDN and backup sources.")
