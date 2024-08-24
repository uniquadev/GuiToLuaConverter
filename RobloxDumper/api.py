"""Locate roblox studio binary and perform an api execution"""
import subprocess
import json
from pathlib import Path
import os

def FindExecuteable(base_dir: str, executable_name: str) -> Path:
    """Search for the executable recursively in all subdirectories"""
    for path in Path(base_dir).rglob(executable_name):
        return path  # Return the path of the first found executable
    return None  # Return None if the executable is not found

class RobloxStudioApi:
    VersionsDir: str = os.path.join(os.getenv('LOCALAPPDATA'), 'Roblox', 'Versions')
    ExecutableName = 'RobloxStudioBeta.exe'

    def __init__(self) -> None:
        pass
    
    def DumpJSON(self) -> dict:
        binary_path = FindExecuteable(self.VersionsDir, self.ExecutableName) or Path(os.path.join(os.getenv('LOCALAPPDATA'), 'Roblox Studio', self.ExecutableName))
        
        if binary_path is None:
            raise FileNotFoundError(f"Executable {self.ExecutableName} not found.")
        
        # Ensure the path is resolved
        binary_path = binary_path.resolve()

        # Use subprocess to execute the binary with arguments
        subprocess.run([str(binary_path), '-API', 'api_dump.json'], check=True)

        # Check if the file was created
        api_dump_path = Path('api_dump.json')
        if not api_dump_path.exists():
            raise FileNotFoundError("api_dump.json not found")
        
        # Load JSON data
        with open(api_dump_path) as f:
            api_dump = json.load(f)
        
        # Optionally delete the file after use
        api_dump_path.unlink()

        return api_dump
