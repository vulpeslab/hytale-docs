---
title: HUD System
description: Managing and customizing the player heads-up display (HUD) in Hytale servers.
sidebar:
  order: 19
---

The Hytale HUD system provides comprehensive control over the player's heads-up display, including built-in components, custom overlays, notifications, and event titles.

## Architecture

```
HudManager (per-player)
├── visibleHudComponents     - Set of currently visible built-in HUD components
├── customHud                - Optional custom HUD overlay
└── Methods for visibility control and custom HUD management

CustomUIHud (abstract)
├── build()                  - Define HUD structure using UICommandBuilder
├── show()                   - Display the HUD to the player
└── update()                 - Send incremental updates
```

## HudManager

The `HudManager` class controls HUD visibility and custom overlays for individual players. Each player has their own `HudManager` instance accessible via the `Player` component.

### Getting the HudManager

```java
import com.hypixel.hytale.server.core.entity.entities.Player;
import com.hypixel.hytale.server.core.entity.entities.player.hud.HudManager;

// From a Player component
Player playerComponent = store.getComponent(entityRef, Player.getComponentType());
HudManager hudManager = playerComponent.getHudManager();
```

### Setting Visible HUD Components

Replace the entire set of visible HUD components:

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

Add or remove components without replacing the entire set:

```java
// Show additional components
hudManager.showHudComponents(playerRef,
    HudComponent.Compass,
    HudComponent.ObjectivePanel
);

// Hide specific components
hudManager.hideHudComponents(playerRef,
    HudComponent.KillFeed,
    HudComponent.Notifications
);
```

### Resetting HUD State

```java
// Reset to default components and clear custom HUD
hudManager.resetHud(playerRef);

// Reset entire UI state (closes menus, etc.)
hudManager.resetUserInterface(playerRef);
```

### Getting Current Visible Components

```java
Set<HudComponent> visible = hudManager.getVisibleHudComponents();
// Returns an unmodifiable view of the current components
```

## HudComponent Enum

All built-in HUD components available in the game:

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

### Default HUD Components

The following components are visible by default:

```java
Set.of(
    HudComponent.UtilitySlotSelector,
    HudComponent.BlockVariantSelector,
    HudComponent.StatusIcons,
    HudComponent.Hotbar,
    HudComponent.Chat,
    HudComponent.Notifications,
    HudComponent.KillFeed,
    HudComponent.InputBindings,
    HudComponent.Reticle,
    HudComponent.Compass,
    HudComponent.Speedometer,
    HudComponent.ObjectivePanel,
    HudComponent.PortalPanel,
    HudComponent.EventTitle,
    HudComponent.Stamina,
    HudComponent.AmmoIndicator,
    HudComponent.Health,
    HudComponent.Mana,
    HudComponent.Oxygen,
    HudComponent.BuilderToolsLegend,
    HudComponent.Sleep
)
```

:::note
`PlayerList` and `Requests` are not included in the default set but can be added as needed.
:::

## CustomUIHud

Create custom HUD overlays that display alongside or replace built-in components.

### Creating a Custom HUD

```java
import com.hypixel.hytale.server.core.entity.entities.player.hud.CustomUIHud;
import com.hypixel.hytale.server.core.ui.builder.UICommandBuilder;
import com.hypixel.hytale.server.core.universe.PlayerRef;

public class BossHealthHud extends CustomUIHud {
    private String bossName;
    private float healthPercent;

    public BossHealthHud(PlayerRef playerRef, String bossName) {
        super(playerRef);
        this.bossName = bossName;
        this.healthPercent = 1.0f;
    }

    @Override
    protected void build(UICommandBuilder builder) {
        // Append a UI document from assets
        builder.append("#hud-root", "ui/custom/boss_health.ui");

        // Set initial values
        builder.set("#boss-name", bossName);
        builder.set("#health-bar-fill", healthPercent);
    }

    public void updateHealth(float percent) {
        this.healthPercent = percent;

        UICommandBuilder builder = new UICommandBuilder();
        builder.set("#health-bar-fill", healthPercent);

        // Send incremental update (clear=false)
        update(false, builder);
    }

    public void setBossDefeated() {
        UICommandBuilder builder = new UICommandBuilder();
        builder.set("#boss-name", bossName + " (Defeated)");
        builder.set("#health-bar-fill", 0.0f);
        update(false, builder);
    }
}
```

### Displaying a Custom HUD

```java
// Create and show custom HUD
BossHealthHud bossHud = new BossHealthHud(playerRef, "Dragon Lord");
hudManager.setCustomHud(playerRef, bossHud);

// Later, update the HUD
bossHud.updateHealth(0.5f);

// Remove custom HUD
hudManager.setCustomHud(playerRef, null);
```

### UICommandBuilder Methods

The `UICommandBuilder` class provides methods for manipulating UI elements:

| Method | Description |
|--------|-------------|
| `append(selector, documentPath)` | Append UI document as child |
| `append(documentPath)` | Append UI document to root |
| `appendInline(selector, document)` | Append inline UI definition |
| `insertBefore(selector, documentPath)` | Insert UI document before element |
| `insertBeforeInline(selector, document)` | Insert inline UI before element |
| `remove(selector)` | Remove element from DOM |
| `clear(selector)` | Clear element's children |
| `set(selector, value)` | Set element property (string, number, boolean, Message) |
| `setNull(selector)` | Set property to null |
| `setObject(selector, data)` | Set complex object (Area, ItemStack, etc.) |

### Supported Data Types for set()

```java
// Strings
builder.set("#label", "Hello World");

// Numbers
builder.set("#progress", 0.75f);
builder.set("#count", 42);
builder.set("#value", 3.14159);

// Booleans
builder.set("#visible", true);

// Messages (with formatting)
builder.set("#title", Message.translation("game.boss.name"));

// Complex objects
builder.setObject("#item-slot", itemStack);
builder.setObject("#area", new Area(0, 0, 100, 50));
```

## Event Titles

Display large announcement titles on the player's screen.

### EventTitleUtil

```java
import com.hypixel.hytale.server.core.util.EventTitleUtil;
import com.hypixel.hytale.server.core.Message;

// Show title to a single player
EventTitleUtil.showEventTitleToPlayer(
    playerRef,
    Message.raw("Zone Discovered"),           // Primary title
    Message.raw("Welcome to the Dark Forest"), // Secondary title
    true,                                      // isMajor (large display)
    "ui/icons/forest.png",                    // Optional icon
    4.0f,                                      // Duration (seconds)
    1.5f,                                      // Fade in duration
    1.5f                                       // Fade out duration
);

// Simplified version with defaults
EventTitleUtil.showEventTitleToPlayer(
    playerRef,
    Message.translation("zone.darkforest.name"),
    Message.translation("zone.darkforest.desc"),
    true  // isMajor
);

// Hide title early
EventTitleUtil.hideEventTitleFromPlayer(playerRef, 0.5f);
```

### Broadcasting to World or Universe

```java
// Show to all players in a world
EventTitleUtil.showEventTitleToWorld(
    Message.raw("Wave 5"),
    Message.raw("Prepare for battle!"),
    true,                    // isMajor
    "ui/icons/warning.png", // icon
    4.0f,                    // duration
    1.5f,                    // fadeIn
    1.5f,                    // fadeOut
    store                    // EntityStore
);

// Show to all players in the universe
EventTitleUtil.showEventTitleToUniverse(
    Message.raw("Server Event"),
    Message.raw("Double XP Weekend!"),
    true,
    null,
    10.0f,
    2.0f,
    2.0f
);

// Hide from all players in a world
EventTitleUtil.hideEventTitleFromWorld(1.0f, store);
```

### ShowEventTitle Packet Fields

| Field | Type | Description |
|-------|------|-------------|
| `fadeInDuration` | float | Seconds to fade in |
| `fadeOutDuration` | float | Seconds to fade out |
| `duration` | float | Seconds to display |
| `icon` | String | Optional icon path |
| `isMajor` | boolean | Large vs small display |
| `primaryTitle` | FormattedMessage | Main title text |
| `secondaryTitle` | FormattedMessage | Subtitle text |

## Notifications

Display toast notifications in the notification area.

### NotificationUtil

```java
import com.hypixel.hytale.server.core.util.NotificationUtil;
import com.hypixel.hytale.protocol.packets.interface_.NotificationStyle;

// Simple notification
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

// With icon
NotificationUtil.sendNotification(
    playerRef.getPacketHandler(),
    Message.translation("item.received"),
    "ui/icons/chest.png",
    NotificationStyle.Default
);

// Full notification with all options
NotificationUtil.sendNotification(
    playerRef.getPacketHandler(),
    Message.raw("New Item"),              // Primary message
    Message.raw("Diamond Sword"),          // Secondary message
    "ui/icons/sword.png",                 // Icon
    itemWithMetadata,                      // Item to display
    NotificationStyle.Success
);
```

### NotificationStyle Enum

| Style | Value | Description |
|-------|-------|-------------|
| `Default` | 0 | Standard notification |
| `Danger` | 1 | Red/danger styling |
| `Warning` | 2 | Yellow/warning styling |
| `Success` | 3 | Green/success styling |

### Broadcasting Notifications

```java
// To entire world
NotificationUtil.sendNotificationToWorld(
    Message.raw("Server message"),
    null,                      // Secondary message
    "ui/icons/server.png",    // Icon
    null,                      // Item
    NotificationStyle.Default,
    store
);

// To entire universe
NotificationUtil.sendNotificationToUniverse(
    Message.raw("Server restarting in 5 minutes"),
    NotificationStyle.Warning
);
```

## Kill Feed Messages

Display kill/death messages in the kill feed.

### KillFeedMessage Packet

```java
import com.hypixel.hytale.protocol.packets.interface_.KillFeedMessage;
import com.hypixel.hytale.protocol.FormattedMessage;

// Create kill feed message
KillFeedMessage message = new KillFeedMessage(
    killerMessage.getFormattedMessage(),   // Killer name/info
    decedentMessage.getFormattedMessage(), // Victim name/info
    "ui/icons/sword.png"                   // Kill icon
);

// Send to player
playerRef.getPacketHandler().writeNoCache(message);
```

### KillFeedEvent

The kill feed system fires events that can be intercepted:

```java
import com.hypixel.hytale.server.core.modules.entity.damage.event.KillFeedEvent;

// Customize kill feed display
getEventRegistry().register(KillFeedEvent.Display.class, event -> {
    // Modify broadcast targets
    event.getBroadcastTargets().clear();
    event.getBroadcastTargets().addAll(nearbyPlayers);

    // Change icon
    event.setIcon("ui/icons/custom_kill.png");

    // Or cancel entirely
    // event.setCancelled(true);
});

// Customize decedent message
getEventRegistry().register(KillFeedEvent.DecedentMessage.class, event -> {
    event.setMessage(Message.raw("was eliminated"));
});

// Customize killer message
getEventRegistry().register(KillFeedEvent.KillerMessage.class, event -> {
    event.setMessage(Message.raw("eliminated"));
});
```

## HUD-Related Packets

### CustomHud (ID 217)

Sends custom HUD commands to the client:

| Field | Type | Description |
|-------|------|-------------|
| `clear` | boolean | Clear existing custom HUD first |
| `commands` | CustomUICommand[] | Array of UI commands |

### UpdateVisibleHudComponents (ID 230)

Updates which built-in HUD components are visible:

| Field | Type | Description |
|-------|------|-------------|
| `visibleComponents` | HudComponent[] | Array of visible components |

### ResetUserInterfaceState (ID 231)

Resets the entire UI state (closes menus, resets HUD). This packet has no fields.

### ShowEventTitle (ID 214)

Displays an event title:

| Field | Type | Description |
|-------|------|-------------|
| `fadeInDuration` | float | Fade in time |
| `fadeOutDuration` | float | Fade out time |
| `duration` | float | Display duration |
| `icon` | String | Optional icon |
| `isMajor` | boolean | Major/minor display |
| `primaryTitle` | FormattedMessage | Main title |
| `secondaryTitle` | FormattedMessage | Subtitle |

### HideEventTitle (ID 215)

Hides the current event title:

| Field | Type | Description |
|-------|------|-------------|
| `fadeOutDuration` | float | Fade out time |

### Notification (ID 212)

Sends a toast notification:

| Field | Type | Description |
|-------|------|-------------|
| `message` | FormattedMessage | Primary message |
| `secondaryMessage` | FormattedMessage | Secondary message |
| `icon` | String | Optional icon |
| `item` | ItemWithAllMetadata | Optional item display |
| `style` | NotificationStyle | Visual style |

### KillFeedMessage (ID 213)

Sends a kill feed entry:

| Field | Type | Description |
|-------|------|-------------|
| `killer` | FormattedMessage | Killer info |
| `decedent` | FormattedMessage | Victim info |
| `icon` | String | Kill method icon |

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

    public void updateTime(int seconds) {
        this.timeRemaining = seconds;
        UICommandBuilder builder = new UICommandBuilder();
        builder.set("#time-value", formatTime(seconds));
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
    // Hide most HUD elements
    hudManager.setVisibleHudComponents(playerRef,
        HudComponent.Chat  // Keep chat visible
    );
}

public void exitCinematicMode(PlayerRef playerRef, HudManager hudManager) {
    // Restore default HUD
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
    EventTitleUtil.showEventTitleToPlayer(
        playerRef,
        Message.raw("BOSS FIGHT"),
        Message.raw(bossName),
        true,
        "ui/icons/skull.png",
        3.0f,
        0.5f,
        0.5f
    );

    // Show danger notification
    NotificationUtil.sendNotification(
        playerRef.getPacketHandler(),
        Message.raw("A powerful enemy approaches!"),
        NotificationStyle.Danger
    );
}

public void endBossFight(PlayerRef playerRef, HudManager hudManager, boolean victory) {
    // Remove boss HUD
    hudManager.setCustomHud(playerRef, null);

    if (victory) {
        EventTitleUtil.showEventTitleToPlayer(
            playerRef,
            Message.raw("VICTORY"),
            Message.raw("The boss has been defeated!"),
            true
        );

        NotificationUtil.sendNotification(
            playerRef.getPacketHandler(),
            Message.raw("Boss defeated!"),
            NotificationStyle.Success
        );
    }
}
```

## Best Practices

1. **Minimize updates** - Batch HUD updates when possible to reduce network traffic
2. **Use incremental updates** - Pass `clear=false` to `update()` for partial updates
3. **Cache HUD instances** - Reuse `CustomUIHud` instances rather than recreating them
4. **Respect player preferences** - Consider allowing players to toggle optional HUD elements
5. **Clean up on disconnect** - Custom HUDs are automatically cleared when players disconnect
6. **Use appropriate notification styles** - Match the style to the message importance
7. **Keep event titles brief** - They should be scannable at a glance
8. **Test different screen sizes** - HUD elements should work across resolutions
