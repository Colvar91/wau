# WAU – World Auto Upgrade
A lightweight, multilingual auto-equip addon for World of Warcraft.

![Version](https://img.shields.io/github/v/release/Colvar91/wau?label=Version&color=4caf50)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Downloads](https://img.shields.io/github/downloads/Colvar91/wau/total?color=ff9800)
![WoW Addon](https://img.shields.io/badge/WoW-Addon-7952B3.svg)

## Features
- Automatically equips higher item level gear
- Smart Ring logic (upgrades weakest ring)
- Smart Trinket logic (prevents duplicate-effect swapping)
- Equip cap: up to ilvl 739
- Slot Blocking UI
- Manual scan (/wau scan)
- DF/11.x Settings Integration
- Lightweight and Remix-friendly
- Multilingual support (11 languages)

## Commands
```
/wau          → open WAU settings
/wau help     → shows all commands
/wau scan     → manually scan bags
/wau on       → enable auto mode
/wau off      → disable auto mode
/wau max      → set maximum item level
```

## Designed For
- Legion Remix
- Fast leveling / alts
- Auto-upgrade convenience
- Minimalistic UI setups

## How It Works
WAU scans your bags and equips better items if:
- higher item level
- below 739 ilvl
- not slot-blocked
- not duplicate ring/trinket
- not in combat
- actual upgrade

## Installation
1. Download latest release ZIP
2. Extract to: World of Warcraft/_retail_/Interface/AddOns/WAU/
3. Reload UI

## Project Structure
```
WAU/
├── Core.lua
├── UI.lua
├── WAU.toc
├── Libs/
│   ├── LibStub.lua
│   └── AceLocale-3.0.lua
└── locales/
    ├── enUS.lua
    ├── deDE.lua
    ├── ruRU.lua
    ├── frFR.lua
    ├── esES.lua
    ├── esMX.lua
    ├── itIT.lua
    ├── ptBR.lua
    ├── koKR.lua
    ├── zhCN.lua
    └── zhTW.lua
```

## Development
Issues and PRs welcome!

## License
MIT

## Support
If you like WAU, please ⭐ the repository!
