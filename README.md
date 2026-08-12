# <img src="https://img.shields.io/badge/WoW-3.3.5a-blueviolet" alt="WoW 3.3.5a" /> DisenchantHub

**Fast disenchanting addon for WoW 3.3.5a** — click an item, disenchant it instantly.
Built for [Project Ascension](https://ascension.gg/) and WotLK private servers.

---

## Screenshots

| Items Tab | Config Tab |
|:-:|:-:|
| ![Items Tab](https://i.gyazo.com/4920163254573a0f9c9320bb28f1444d.png) | ![Config Tab](https://i.gyazo.com/07662a2b89609e38e86f8943f3812d1e.png) |

---

## Features

| | |
|---|---|
| **One-Click Disenchant** | Left-click any item in the list to disenchant it directly. No queues, no extra steps. |
| **Smart Filtering** | Filter items by rarity (Poor → Legendary) and item level range. Only shows disenchantable Armor and Weapons. |
| **Skill Requirement Display** | Shows the required Enchanting skill per item. Items you can't disenchant yet appear dimmed and sorted to the bottom. |
| **Whitelist / Blacklist** | Protect items you want to keep, or mark specific IDs to always disenchant. Right-click any item to manage lists. |
| **Enchanting Detection** | Displays your current Enchanting skill level. Warns you if the profession isn't learned. |
| **Activity Log** | Timestamped history of every disenchant with success/fail status and loot obtained. Persists across sessions. |
| **Configurable Hotkey** | Default `F5` to toggle the UI. Rebind to any key from the Config tab. |
| **Multi-language** | Full localization: English, Español (España), Español (LATAM). Switch from the Config tab. |
| **Auto-loot** | Automatically loots disenchant results. Configurable. |
| **Secure Execution** | Uses `SecureActionButtonTemplate` with macro attributes — no protected API calls, no Blizzard taint. |
| **Real-time Sync** | Item list refreshes automatically via `BAG_UPDATE` when your inventory changes. |

## Installation

1. Download or clone this repo
2. Copy the `DisenchantHub` folder into your WoW client:
   ```
   WoW/Interface/AddOns/DisenchantHub/
   ```
3. Restart WoW

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
3. Each row shows: item name, rarity, item level, required Enchanting skill, and type
4. **Left-click** an item to disenchant it immediately
5. Items that require a higher Enchanting skill appear dimmed and cannot be clicked
6. Loot is collected automatically

### Managing Lists

- **Right-click** any item in the Items tab → Add to Whitelist / Blacklist
- Switch to the **Lists** tab to view and remove entries
- If the whitelist has entries, **only** whitelisted items will be shown
- Blacklisted items are always hidden regardless of filter settings

## Configuration

| Setting | Default | Description |
|---|---|---|
| Min Rarity | Uncommon | Lowest rarity to show |
| Max Rarity | Epic | Highest rarity to show |
| Min ilvl | 0 | Minimum item level |
| Max ilvl | 300 | Maximum item level (capped at 300) |
| Auto-loot | On | Automatically loot disenchant results |
| Sound | On | Play sound on each disenchant |
| Hotkey | F5 | Key to toggle the UI |
| Language | English | English, Español (ES), Español (LATAM) |

## Project Structure

```
DisenchantHub/
├── DisenchantHub.toc    # Addon manifest (Interface: 30300)
├── Core.lua             # Init, events, slash commands
├── Config.lua           # SavedVariables, defaults, hotkey binding
├── Locale.lua           # i18n: enUS, esES, esMX
├── Filter.lua           # Rarity/ilvl filtering, skill brackets
├── Lists.lua            # Whitelist/blacklist persistence
├── Disenchant.lua       # Event handling and macro generation
├── Log.lua              # Activity log with timestamps and loot tracking
├── UI.lua               # Tabbed interface (Items, Lists, Config, Log)
└── Libs/
    └── LibStub.lua      # Library versioning
```

## Technical Notes

- **No taint**: Each item row is a `SecureActionButtonTemplate` with `/cast Disenchant` + `/use bag slot` macro attributes. The user's physical click triggers the protected action — the addon never calls `CastSpellByName()` or `UseContainerItem()` directly.
- **Loot tracking**: `UNIT_SPELLCAST_SUCCEEDED` creates the log entry, `LOOT_OPENED` attaches the loot to it — handles the WoW event timing where spell success fires before the loot window opens.
- **Skill brackets**: Enchanting skill requirements follow WotLK brackets (capped at 300). Items requiring higher skill than the player has are dimmed and non-clickable.
- **SavedVariables**: All config, lists, and logs persist in `DisenchantHubDB` across sessions.
- **Real-time sync**: The item list refreshes automatically via `BAG_UPDATE` when your inventory changes.
- **Ascension compatible**: Handles classless server quirks — profession detection works with Ascension's skill system.

## License

MIT
