---
author: UnlimitedBytes
title: HUD System
description: Managing and customizing the player heads-up display (HUD) in Hytale servers.
sidebar:
  order: 4
human-verified: false
---

The Hytale HUD system provides comprehensive control over the player's heads-up display, including built-in components, custom overlays, notifications, and event titles.

## Architecture

```
HudManager (per-player)
├── visibleHudComponents               - Set of currently visible built-in components
├── unmodifiableVisibleHudComponents   - Read-only view of visible components
├── customHud                          - Optional custom HUD overlay (nullable)
└── Methods for visibility control

CustomUIHud (abstract)
├── playerRef                - Reference to the player
├── build()                  - Define HUD structure using UICommandBuilder
├── show()                   - Display the HUD to the player
└── update()                 - Send incremental updates
```

## HudManager

The `HudManager` class controls HUD visibility and custom overlays for individual players.

### Getting the HudManager

```java
import com.hypixel.hytale.server.core.entity.entities.Player;
import com.hypixel.hytale.server.core.entity.entities.player.hud.HudManager;

Player playerComponent = store.getComponent(entityRef, Player.getComponentType());
HudManager hudManager = playerComponent.getHudManager();
```

### Setting Visible Components

```java
import com.hypixel.hytale.protocol.packets.interface_.HudComponent;

// Show only specific components (replaces all)
hudManager.setVisibleHudComponents(playerRef,
    HudComponent.Hotbar,
    HudComponent.Health,
    HudComponent.Chat,
    HudComponent.Reticle
);

// Using a Set
Set<HudComponent> components = Set.of(
    HudComponent.Hotbar,
    HudComponent.Health,
    HudComponent.Stamina
);
hudManager.setVisibleHudComponents(playerRef, components);
```

### Showing and Hiding Components

```java
// Show additional components
hudManager.showHudComponents(playerRef,
    HudComponent.Compass,
    HudComponent.ObjectivePanel
);

// Hide specific components (varargs only, no Set overload)
hudManager.hideHudComponents(playerRef,
    HudComponent.KillFeed,
    HudComponent.Notifications
);
```

### Resetting HUD

```java
// Reset to default components and clear custom HUD
hudManager.resetHud(playerRef);

// Reset entire UI state (sends ResetUserInterfaceState packet)
hudManager.resetUserInterface(playerRef);
```

### Querying HUD State

```java
// Get the current custom HUD (may be null)
CustomUIHud customHud = hudManager.getCustomHud();

// Get the current set of visible components (returns unmodifiable Set)
Set<HudComponent> visible = hudManager.getVisibleHudComponents();
```

## HudComponent Enum

All built-in HUD components:

| Component | Value | Description |
|-----------|-------|-------------|
| `Hotbar` | 0 | Player hotbar/inventory bar |
| `StatusIcons` | 1 | Status effect icons |
| `Reticle` | 2 | Crosshair/targeting reticle |
| `Chat` | 3 | Chat window |
| `Requests` | 4 | Friend/party requests |
| `Notifications` | 5 | Toast notifications |
| `KillFeed` | 6 | Kill/death messages |
| `InputBindings` | 7 | Key binding hints |
| `PlayerList` | 8 | Tab player list |
| `EventTitle` | 9 | Event title display area |
| `Compass` | 10 | Navigation compass |
| `ObjectivePanel` | 11 | Quest/objective tracker |
| `PortalPanel` | 12 | Portal-related UI |
| `BuilderToolsLegend` | 13 | Builder tools legend |
| `Speedometer` | 14 | Speed indicator |
| `UtilitySlotSelector` | 15 | Utility slot selection |
| `BlockVariantSelector` | 16 | Block variant picker |
| `BuilderToolsMaterialSlotSelector` | 17 | Builder material slot |
| `Stamina` | 18 | Stamina bar |
| `AmmoIndicator` | 19 | Ammunition counter |
| `Health` | 20 | Health bar |
| `Mana` | 21 | Mana bar |
| `Oxygen` | 22 | Oxygen/breath bar |
| `Sleep` | 23 | Sleep indicator |

### Default Components

The following components are visible by default (stored in `DEFAULT_HUD_COMPONENTS`):

```java
Set.of(
    HudComponent.UtilitySlotSelector, HudComponent.BlockVariantSelector,
    HudComponent.StatusIcons, HudComponent.Hotbar, HudComponent.Chat,
    HudComponent.Notifications, HudComponent.KillFeed, HudComponent.InputBindings,
    HudComponent.Reticle, HudComponent.Compass, HudComponent.Speedometer,
    HudComponent.ObjectivePanel, HudComponent.PortalPanel, HudComponent.EventTitle,
    HudComponent.Stamina, HudComponent.AmmoIndicator, HudComponent.Health,
    HudComponent.Mana, HudComponent.Oxygen, HudComponent.BuilderToolsLegend,
    HudComponent.Sleep
)
```

:::note
Notably absent from defaults: `Requests`, `PlayerList`, `BuilderToolsMaterialSlotSelector`
:::

## CustomUIHud

Create custom HUD overlays that display alongside built-in components. The `CustomUIHud` class is abstract and requires implementing the `build()` method.

### Creating a Custom HUD

```java
import com.hypixel.hytale.server.core.entity.entities.player.hud.CustomUIHud;
import com.hypixel.hytale.server.core.ui.builder.UICommandBuilder;

public class BossHealthHud extends CustomUIHud {
    private String bossName;
    private float healthPercent = 1.0f;

    public BossHealthHud(PlayerRef playerRef, String bossName) {
        super(playerRef);
        this.bossName = bossName;
    }

    @Override
    protected void build(UICommandBuilder builder) {
        builder.append("#hud-root", "ui/custom/boss_health.ui");
        builder.set("#boss-name", bossName);
        builder.set("#health-bar-fill", healthPercent);
    }

    public void updateHealth(float percent) {
        this.healthPercent = percent;
        UICommandBuilder builder = new UICommandBuilder();
        builder.set("#health-bar-fill", healthPercent);
        update(false, builder);  // false = don't clear existing HUD
    }
}
```

:::note
The `getPlayerRef()` method is inherited from `CustomUIHud` - you can call it directly via `getPlayerRef()`.
:::

### Displaying the HUD

```java
// Create and show custom HUD
BossHealthHud bossHud = new BossHealthHud(playerRef, "Dragon Lord");
hudManager.setCustomHud(playerRef, bossHud);

// Update the HUD later
bossHud.updateHealth(0.5f);

// Remove custom HUD
hudManager.setCustomHud(playerRef, null);
```

## Event Titles

Display large announcement titles on screen.

### EventTitleUtil Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `DEFAULT_ZONE` | "Void" | Default zone name |
| `DEFAULT_DURATION` | 4.0f | Default display time in seconds |
| `DEFAULT_FADE_DURATION` | 1.5f | Default fade duration (used for both in/out) |

### EventTitleUtil

```java
import com.hypixel.hytale.server.core.util.EventTitleUtil;
import com.hypixel.hytale.server.core.Message;

// Show title to player (full parameters)
EventTitleUtil.showEventTitleToPlayer(
    playerRef,
    Message.raw("Zone Discovered"),           // Primary title
    Message.raw("Welcome to the Dark Forest"), // Secondary title
    true,                                      // isMajor (large display)
    "ui/icons/forest.png",                    // Optional icon (nullable)
    4.0f,                                      // Duration (seconds)
    1.5f,                                      // Fade in duration
    1.5f                                       // Fade out duration
);

// Simplified version (uses default duration and fade)
EventTitleUtil.showEventTitleToPlayer(
    playerRef,
    Message.translation("zone.name"),
    Message.translation("zone.desc"),
    true  // isMajor
);

// Hide title early
EventTitleUtil.hideEventTitleFromPlayer(playerRef, 0.5f);

// Show to all players in world
EventTitleUtil.showEventTitleToWorld(
    Message.raw("Wave 5"),
    Message.raw("Prepare!"),
    true, "ui/icons/warning.png",
    4.0f, 1.5f, 1.5f,
    store  // Store<EntityStore>
);

// Show to all players in the universe (uses Universe.get() internally)
EventTitleUtil.showEventTitleToUniverse(
    Message.raw("Server Event"),
    Message.raw("Global announcement!"),
    true,
    "ui/icons/announcement.png",
    4.0f, 1.5f, 1.5f
);

// Hide title from all players in world
EventTitleUtil.hideEventTitleFromWorld(0.5f, store);
```

## Notifications

Display toast notifications.

### NotificationUtil

```java
import com.hypixel.hytale.server.core.util.NotificationUtil;
import com.hypixel.hytale.protocol.packets.interface_.NotificationStyle;

// Simple notification (string)
NotificationUtil.sendNotification(
    playerRef.getPacketHandler(),
    "Quest completed!"
);

// With style
NotificationUtil.sendNotification(
    playerRef.getPacketHandler(),
    Message.raw("Achievement Unlocked"),
    NotificationStyle.Success
);

// With icon and style
NotificationUtil.sendNotification(
    playerRef.getPacketHandler(),
    Message.raw("New Item"),
    "ui/icons/sword.png",
    NotificationStyle.Success
);

// Full parameters with secondary message, icon, item, and style
NotificationUtil.sendNotification(
    playerRef.getPacketHandler(),
    Message.raw("New Item"),          // Primary message (FormattedMessage via Message)
    Message.raw("Diamond Sword"),      // Secondary message (nullable)
    "ui/icons/sword.png",              // Icon path (nullable)
    itemWithAllMetadata,               // ItemWithAllMetadata (nullable)
    NotificationStyle.Success          // Style (required, non-null)
);

// Broadcast to all players in a world
NotificationUtil.sendNotificationToWorld(
    Message.raw("Server Notice"),
    null,                              // Secondary message
    null,                              // Icon
    null,                              // Item
    NotificationStyle.Warning,
    store                              // Store<EntityStore>
);

// Broadcast to all players in the universe (uses Universe.get() internally)
NotificationUtil.sendNotificationToUniverse(
    Message.raw("Global Announcement"),
    NotificationStyle.Success
);

// Alternative universe broadcast overloads
NotificationUtil.sendNotificationToUniverse("Simple string message");
NotificationUtil.sendNotificationToUniverse("Primary", "Secondary");
NotificationUtil.sendNotificationToUniverse(Message.raw("With icon"), "icon.png", NotificationStyle.Default);
```

### NotificationStyle Enum

| Style | Description |
|-------|-------------|
| `Default` | Standard notification |
| `Danger` | Red/danger styling |
| `Warning` | Yellow/warning styling |
| `Success` | Green/success styling |

## Kill Feed

Display kill/death messages.

```java
import com.hypixel.hytale.protocol.packets.interface_.KillFeedMessage;
import com.hypixel.hytale.protocol.FormattedMessage;

// KillFeedMessage takes FormattedMessage objects directly
KillFeedMessage message = new KillFeedMessage(
    killerFormattedMessage,    // FormattedMessage (nullable) - killer info
    decedentFormattedMessage,  // FormattedMessage (nullable) - victim info
    "ui/icons/sword.png"       // String (nullable) - icon path
);
playerRef.getPacketHandler().writeNoCache(message);

// Using Message helper to create FormattedMessage
KillFeedMessage message = new KillFeedMessage(
    Message.raw("Player1").getFormattedMessage(),
    Message.raw("Player2").getFormattedMessage(),
    "ui/icons/sword.png"
);
```

## Practical Examples

### Minigame HUD

```java
public class MinigameHud extends CustomUIHud {
    private int score = 0;
    private int timeRemaining = 300;

    public MinigameHud(PlayerRef playerRef) {
        super(playerRef);
    }

    @Override
    protected void build(UICommandBuilder builder) {
        builder.append("ui/minigame/scoreboard.ui");
        builder.set("#score-value", score);
        builder.set("#time-value", formatTime(timeRemaining));
    }

    public void updateScore(int newScore) {
        this.score = newScore;
        UICommandBuilder builder = new UICommandBuilder();
        builder.set("#score-value", score);
        update(false, builder);
    }

    private String formatTime(int seconds) {
        return String.format("%d:%02d", seconds / 60, seconds % 60);
    }
}
```

### Cinematic Mode

```java
public void enterCinematicMode(PlayerRef playerRef, HudManager hudManager) {
    hudManager.setVisibleHudComponents(playerRef, HudComponent.Chat);
}

public void exitCinematicMode(PlayerRef playerRef, HudManager hudManager) {
    hudManager.resetHud(playerRef);
}
```

### Boss Fight Setup

```java
public void startBossFight(PlayerRef playerRef, HudManager hudManager, String bossName) {
    // Show boss health HUD
    BossHealthHud bossHud = new BossHealthHud(playerRef, bossName);
    hudManager.setCustomHud(playerRef, bossHud);

    // Show event title
    EventTitleUtil.showEventTitleToPlayer(playerRef,
        Message.raw("BOSS FIGHT"), Message.raw(bossName),
        true, "ui/icons/skull.png", 3.0f, 0.5f, 0.5f);

    // Show notification
    NotificationUtil.sendNotification(
        playerRef.getPacketHandler(),
        Message.raw("A powerful enemy approaches!"),
        NotificationStyle.Danger);
}
```

## Best Practices

1. **Minimize updates** - Batch HUD updates to reduce network traffic
2. **Use incremental updates** - Pass `clear=false` to `update()` for partial updates
3. **Cache HUD instances** - Reuse `CustomUIHud` rather than recreating
4. **Respect preferences** - Allow players to toggle optional elements
5. **Clean up on disconnect** - Clear custom HUDs explicitly (e.g., `setCustomHud(playerRef, null)` or `resetHud(playerRef)`) when the player leaves
