---
author: UnlimitedBytes
title: GUI System
description: An overview of Hytale's three GUI subsystems - Windows, Pages, and HUD.
sidebar:
  order: 1
---

Hytale's server-side GUI system is composed of three distinct subsystems, each designed for different use cases. All three are managed per-player and accessed through the `Player` component.

## Architecture Overview

```
Player Component
├── WindowManager      - Inventory-based UIs (containers, crafting)
├── PageManager        - Custom dialogs and overlays
├── HudManager         - Persistent on-screen elements
├── HotbarManager      - Player hotbar slot management
└── WorldMapTracker    - World map UI state

Page Classes
├── CustomUIPage            - Base class for custom pages
├── BasicCustomUIPage       - Simple pages without event handling
└── InteractiveCustomUIPage - Pages with typed event data handling

HUD Classes
└── CustomUIHud             - Base class for custom HUD overlays

UI Building Tools
├── UICommandBuilder   - Build UI commands (set values, append elements)
├── UIEventBuilder     - Bind UI events to server callbacks
└── EventData          - Pass parameters with events

UI Assets
├── .ui files          - Text-based layout definitions
├── Common.ui          - Global styles and constants
└── Pages/*.ui         - Page-specific layouts and components
```

## The Three GUI Systems

<div class="card-grid">

### [Windows System](./windows/)
Inventory-based UIs for containers, crafting benches, and processing stations. Windows display item grids and handle player-item interactions.

### [Pages System](./pages/)
Custom dialogs, menus, and full-screen overlays. Build fully interactive UIs with event handling for shops, dialogs, and custom interfaces.

### [HUD System](./hud/)
Persistent on-screen elements like health bars, hotbar, compass, and custom overlays. Control what information players see during gameplay.

### [UI Building Tools](./builders/)
UICommandBuilder and UIEventBuilder for creating and updating UI elements dynamically from your plugin code.

</div>

## Accessing GUI Managers

All three primary managers are accessed through the `Player` component:

```java
// Get the Player component from an entity reference
Player playerComponent = store.getComponent(ref, Player.getComponentType());

// Access the managers
WindowManager windowManager = playerComponent.getWindowManager();
PageManager pageManager = playerComponent.getPageManager();
HudManager hudManager = playerComponent.getHudManager();

// Additional UI-related managers
HotbarManager hotbarManager = playerComponent.getHotbarManager();
WorldMapTracker worldMapTracker = playerComponent.getWorldMapTracker();

// Reset managers (HUD, windows, camera, movement, world map tracker)
playerComponent.resetManagers(holder);
```

## When to Use Each System

| System | Use Case | Examples |
|--------|----------|----------|
| **Windows** | Item-based interactions | Chests, crafting tables, furnaces |
| **Pages** | Full-screen UIs | Shops, dialogs, settings menus |
| **HUD** | Always-visible info | Health bars, compass, quest tracker |

## Quick Start Examples

### Opening a Custom Page

```java
public class MyCustomPage extends BasicCustomUIPage {
    public MyCustomPage(PlayerRef playerRef) {
        super(playerRef, CustomPageLifetime.CanDismiss);
    }

    @Override
    public void build(UICommandBuilder commands) {
        commands.append("Pages/MyPage.ui");
        commands.set("#title", "Welcome!");
    }
}

// Open the page
pageManager.openCustomPage(ref, store, new MyCustomPage(playerRef));
```

### Showing a Custom HUD

```java
public class BossHealthHud extends CustomUIHud {
    public BossHealthHud(PlayerRef playerRef) {
        super(playerRef);
    }

    @Override
    protected void build(UICommandBuilder builder) {
        builder.append("#hud-root", "ui/boss_health.ui");
        builder.set("#boss-name", "Dragon");
        builder.set("#health-bar", 1.0f);
    }
}

// Show the HUD
hudManager.setCustomHud(playerRef, new BossHealthHud(playerRef));
```

### Modifying HUD Components

```java
// Show only essential components
hudManager.setVisibleHudComponents(playerRef,
    HudComponent.Hotbar,
    HudComponent.Health,
    HudComponent.Reticle
);

// Hide specific components
hudManager.hideHudComponents(playerRef,
    HudComponent.Compass,
    HudComponent.ObjectivePanel
);
```

## UI File System

Hytale uses `.ui` files as the client-side layout format. These text-based assets define UI structure, styles, and components:

```
Server UI Assets (built-in)
├── Common.ui                   # Global styles and variables
├── Common/
│   └── TextButton.ui          # Reusable components
└── Pages/
    ├── DialogPage.ui          # NPC dialogs
    ├── ShopPage.ui            # Shop interfaces
    └── RespawnPage.ui         # Death/respawn screen

Plugin Asset Pack Structure (your plugin)
src/main/resources/
├── manifest.json              # Set "IncludesAssetPack": true
└── Common/
    └── UI/
        └── Custom/
            ├── MyPage.ui          # Custom .ui files
            └── MyBackground.png   # Textures
```

### Creating Custom .ui Files

To create custom UI layouts with images in your plugin:

1. Set `"IncludesAssetPack": true` in `manifest.json`
2. Place `.ui` files in `src/main/resources/Common/UI/Custom/`
3. Reference them in Java as `Custom/MyPage.ui`
4. Use `PatchStyle(TexturePath: "image.png")` for loading textures (paths are relative to the .ui file)

See [Custom Pages](./pages/#creating-custom-ui-files) and [UI Building Tools](./builders/#custom-ui-files) for detailed examples.

## Package References

| Class | Package |
|-------|---------|
| `WindowManager` | `com.hypixel.hytale.server.core.entity.entities.player.windows` |
| `PageManager` | `com.hypixel.hytale.server.core.entity.entities.player.pages` |
| `HudManager` | `com.hypixel.hytale.server.core.entity.entities.player.hud` |
| `HotbarManager` | `com.hypixel.hytale.server.core.entity.entities.player` |
| `WorldMapTracker` | `com.hypixel.hytale.server.core.universe.world` |
| `UICommandBuilder` | `com.hypixel.hytale.server.core.ui.builder` |
| `UIEventBuilder` | `com.hypixel.hytale.server.core.ui.builder` |
| `EventData` | `com.hypixel.hytale.server.core.ui.builder` |
| `Player` | `com.hypixel.hytale.server.core.entity.entities` |
| `BasicCustomUIPage` | `com.hypixel.hytale.server.core.entity.entities.player.pages` |
| `CustomUIPage` | `com.hypixel.hytale.server.core.entity.entities.player.pages` |
| `InteractiveCustomUIPage` | `com.hypixel.hytale.server.core.entity.entities.player.pages` |
| `CustomUIHud` | `com.hypixel.hytale.server.core.entity.entities.player.hud` |
| `HudComponent` | `com.hypixel.hytale.protocol.packets.interface_` |
| `CustomPageLifetime` | `com.hypixel.hytale.protocol.packets.interface_` |
