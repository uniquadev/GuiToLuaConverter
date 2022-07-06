# ⚠ This is only for developers and contributers.

## What is this? 🤔
This is an utility script that allows us to dump all properties from the Roblox API. <br>
It stores that data in a filtered JSON file.

## How it works 🛠
It uses a build-in function of the Roblox Studio executable to get a list of all the properties and functions. <br>
Since we are only intressted in the properties the user can edit; we filter out the functions and read-only properties.

## How to use it 👷‍
1. Clone this repository by doing `git clone https://github.com/uniquadev/GuiToLuaConverter/`
1. Open the `RobloxDumper` folder using command promt
1. Run `python main.py`

The file should be saved in `PluginPlace/src/assets/dump.json`



