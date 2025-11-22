# 📦 **WAU – World Auto Upgrade**  
*A lightweight auto-equip addon for World of Warcraft.*

![Version](https://img.shields.io/github/v/release/Colvar91/wau?label=Version&color=4caf50)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Downloads](https://img.shields.io/github/downloads/USER/REPO/total?color=ff9800)
![WoW Addon](https://img.shields.io/badge/WoW-Addon-7952B3.svg)

> **Replace `USER/REPO` above with your GitHub username & repository name.**

---

## ✨ Features

- **Automatically equips** higher item level gear  
- **Smart Ring logic** → upgrades only the weaker ring  
- **Smart Trinket logic** → no duplicate swapping or loops  
- **Slot Blocking UI**  
- **Upgrade cap:** only equips items up to **ilvl 739**  
- Manual scan available  
- Lightweight, Remix-friendly design  
- Clean configuration window  

---

## 🕹️ Commands

/wau → open settings
/wau on → enable auto-upgrade
/wau off → disable auto-upgrade
/wau scan → manually scan bags

---

## 🎯 Designed For

- **Legion Remix progression**  
- Fast leveling / alt runs  
- Efficient dungeon or event farming  
- Players who prefer automatic gear management  
- Clean and simple UI setups  

---

## 🔧 How It Works

WAU scans your bags for new items and compares them against your current equipment.  
If the new item is:

- higher item level  
- below **739**  
- not slot-blocked  
- not a duplicate ring or trinket  
- actually an upgrade  

…it is automatically equipped.

Ring & trinket slots follow special logic to avoid endless swapping.

---

## 🧩 Installation

1. Download the latest release ZIP  
2. Extract it into: World of Warcraft/retail/Interface/AddOns/
3. Reload your UI with `/reload`

---

## 📁 Project Structure
WAU/
├── Core.lua
├── Config.lua
├── WAU.toc
├── Libs/
│ ├── LibStub.lua
│ └── AceLocale-3.0.lua
└── locales/
├── enUS.lua
└── deDE.lua

---

## 🧪 Development

Contributions are welcome!  
Feel free to open an Issue or submit a Pull Request.

---

## 📝 License

This project is released under the **MIT License**.

---

## ⭐ Support

If you enjoy using WAU, please ⭐ star the repo —  
it helps support development and increases visibility.
