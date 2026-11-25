# ⚠ This is only for developers and contributors.

## What is this? 🤔
This is an utility script that allows us to dump all properties from the Roblox API. <br>
It stores that data in a filtered JSON file.

## How it works 🛠
It queries the official Roblox Studio API dump and extracts all scriptable, writable properties for every instance, filtering out read-only, hidden, internal, and deprecated properties.

## How to use it 👷‍
1. Clone this repository by doing `git clone https://github.com/uniquadev/GuiToLuaConverter/`
2. Open the `GuiToLuaConverter` folder in your terminal
3. Run `python ./ApiDumper/main.py 1` to fetch and dump the latest API from the Roblox CDN directly, or `python ./ApiDumper/main.py 0` to use your local Roblox Studio installation.

The file will be saved in `PluginPlace/src/assets/dump.json`
