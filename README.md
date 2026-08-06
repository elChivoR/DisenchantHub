# <img src="https://img.shields.io/badge/WoW-3.3.5a-blueviolet" alt="WoW 3.3.5a" /> DisenchantHub

**Bulk disenchanting addon for WoW 3.3.5a** — filter, queue, and shatter your gear with precision.
Built for [Project Ascension](https://ascension.gg/) and WotLK private servers.

---

## Screenshots

| Items Tab | Config Tab |
|:-:|:-:|
| ![Items Tab](https://i.gyazo.com/ea150b535bf909fcc74991196e3d2317.png) | ![Config Tab](https://i.gyazo.com/287e80cffc294e9aca5ba0061b2c0a43.png) |

---

## Features

| | |
|---|---|
| **Smart Filtering** | Filter items by rarity (Poor → Legendary) and item level range. Only shows disenchantable Armor and Weapons. |
| **Checkbox Selection** | Select individual items with checkboxes or use Select All. Bulk disenchant your selection in one queue. |
| **Whitelist / Blacklist** | Protect items you want to keep, or mark specific IDs to always disenchant. Right-click any item to manage. |
| **Queue System** | Select items and queue them for disenchant. One click per item — safe, no taint errors. |
| **Enchanting Detection** | Displays your Enchanting skill level. Warns you if the profession isn't learned. |
| **Configurable Hotkey** | Default `F5` to toggle the UI. Rebind to any key from the Config tab. |
| **Multi-language** | Full localization: English, Spanish (Spain), Spanish (LATAM). Switch languages from the Config tab. |
| **Activity Log** | Timestamped history of every disenchant (success/fail), with stats. Persists across sessions. |
| **Secure Execution** | Uses `SecureActionButtonTemplate` with macro attributes — no protected API calls, no Blizzard taint. |

## Installation

1. Download or clone this repo
2. Copy the `DisenchantHub` folder into your WoW client:
   ```
   WoW/Interface/AddOns/DisenchantHub/
   ```
3. Restart WoW or type `/reload`

## Usage

### Slash Commands

```
/dh              Toggle the main window
/dh config       Open configuration panel
/dh log          View disenchant history
/dh reset        Reset all settings to defaults
/dh help         Show available commands
```

### Workflow

1. Open the addon with `/dh` or your hotkey (`F5`)
2. The **Items** tab scans your bags and shows all disenchantable equipment
3. Use **checkboxes** to select items, or click the header checkbox to select all
4. Click **DE Selection** to queue the selected items
5. Click the `[DE: ItemName]` button once per item to disenchant
6. Loot is auto-collected. The button updates to the next item automatically.

### Managing Lists

- **Right-click** any item in the Items tab → Add to Whitelist / Blacklist
- Switch to the **Lists** tab to view and remove entries
- If the whitelist has entries, **only** whitelisted items will be disenchantable
- Blacklisted items are always blocked regardless of filter settings

## Configuration

| Setting | Default | Description |
|---|---|---|
| Min Rarity | Uncommon | Lowest rarity to disenchant |
| Max Rarity | Epic | Highest rarity to disenchant |
| Min ilvl | 0 | Minimum item level |
| Max ilvl | 999 | Maximum item level |
| Auto-loot | On | Automatically loot disenchant results |
| Confirm bulk DE | On | Show confirmation popup before mass disenchant |
| Sound | On | Play sound on each disenchant |
| Hotkey | F5 | Key to toggle the UI |
| Language | English | English, Espanol (ES), Espanol (LATAM) |

## Project Structure

```
DisenchantHub/
├── DisenchantHub.toc    # Addon manifest (Interface: 30300)
├── Core.lua             # Init, events, slash commands
├── Config.lua           # SavedVariables, defaults, hotkey binding
├── Locale.lua           # i18n: enUS, esES, esMX
├── Filter.lua           # Rarity/ilvl filtering, item type validation
├── Lists.lua            # Whitelist/blacklist persistence
├── Disenchant.lua       # SecureActionButton queue engine
├── Log.lua              # Activity log with timestamps and stats
├── UI.lua               # Tabbed interface (Items, Lists, Config, Log)
├── screenshots/         # UI screenshots
└── Libs/
    └── LibStub.lua      # Library versioning
```

## Technical Notes

- **No taint**: All spell casting goes through a `SecureActionButtonTemplate` with `/cast` + `/use` macro attributes. The user's physical click triggers the protected action — the addon never calls `CastSpellByName()` or `UseContainerItem()` directly.
- **SavedVariables**: All config, lists, and logs persist in `DisenchantHubDB` across sessions.
- **Real-time sync**: The item list refreshes automatically via `BAG_UPDATE` when your inventory changes.
- **Ascension compatible**: Handles classless server quirks — profession detection falls back to `IsUsableSpell` if the standard API doesn't apply.

## License

MIT
