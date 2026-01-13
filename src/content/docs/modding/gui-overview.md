---
title: GUI System Overview
description: An overview of Hytale's three GUI subsystems - Windows, Pages, and HUD.
sidebar:
  order: 16
---

Hytale's server-side GUI system is composed of three distinct subsystems, each designed for different use cases. All three are managed per-player and accessed through the `Player` component.

## Architecture Overview

```
Player Component
├── WindowManager      - Inventory-based UIs (containers, crafting)
├── PageManager        - Custom dialogs and overlays
└── HudManager         - Persistent on-screen elements

UI Building Tools
├── UICommandBuilder   - Build UI commands (set values, append elements)
├── UIEventBuilder     - Bind UI events to server callbacks
└── EventData          - Pass parameters with events

UI Assets
├── .ui files          - Text-based layout definitions
├── Common.ui          - Global styles and constants
└── Pages/*.ui         - Page-specific layouts and components
```

## Accessing GUI Managers

All three managers are accessed through the `Player` component:

```java
// Get the Player component from an entity reference
Player playerComponent = store.getComponent(ref, Player.getComponentType());

// Access the managers
WindowManager windowManager = playerComponent.getWindowManager();
PageManager pageManager = playerComponent.getPageManager();
HudManager hudManager = playerComponent.getHudManager();
```

---

## Window System

The Window System handles inventory-based UIs such as containers, crafting benches, and processing stations. Windows can display item grids, crafting interfaces, and material containers.

### WindowManager

`WindowManager` manages the lifecycle of all open windows for a player:

```java
// com.hypixel.hytale.server.core.entity.entities.player.windows.WindowManager

// Open a new window
OpenWindow packet = windowManager.openWindow(window);

// Open multiple windows atomically (all succeed or all fail)
List<OpenWindow> packets = windowManager.openWindows(window1, window2);

// Get a window by ID
Window window = windowManager.getWindow(id);

// Close a specific window
windowManager.closeWindow(id);

// Close all windows
windowManager.closeAllWindows();

// Update window contents
windowManager.updateWindow(window);
```

### Window Types

Windows are categorized by `WindowType`, an enum defining the client-side rendering:

| WindowType | Value | Description |
|------------|-------|-------------|
| `Container` | 0 | Generic item container (chests, storage) |
| `PocketCrafting` | 1 | Quick crafting from inventory |
| `BasicCrafting` | 2 | Standard crafting bench interface |
| `DiagramCrafting` | 3 | Pattern-based crafting (diagrams) |
| `StructuralCrafting` | 4 | Building/structural crafting |
| `Processing` | 5 | Processing stations (furnaces, etc.) |
| `Memories` | 6 | Memory/collection interface |

### Window Base Class

All windows extend the abstract `Window` class:

```java
// com.hypixel.hytale.server.core.entity.entities.player.windows.Window

public abstract class Window {
    // Get window data as JSON for client
    public abstract JsonObject getData();

    // Called when window opens (return false to cancel)
    protected abstract boolean onOpen0();

    // Called when window closes
    protected abstract void onClose0();

    // Handle client actions
    public void handleAction(Ref<EntityStore> ref, Store<EntityStore> store, WindowAction action);

    // Get the window type
    public WindowType getType();

    // Close this window
    public void close();

    // Register close event listener
    public EventRegistration registerCloseEvent(Consumer<WindowCloseEvent> consumer);
}
```

### WindowAction Types

Client interactions are sent as `WindowAction` subtypes:

| Action | Description |
|--------|-------------|
| `CraftRecipeAction` | Craft using a specific recipe |
| `CraftItemAction` | Craft a specific item |
| `TierUpgradeAction` | Upgrade crafting tier |
| `SelectSlotAction` | Select a slot in the window |
| `ChangeBlockAction` | Change block in structural crafting |
| `SetActiveAction` | Set active state |
| `UpdateCategoryAction` | Change category filter |
| `CancelCraftingAction` | Cancel ongoing craft |
| `SortItemsAction` | Sort items in container |

---

## Page System

The Page System handles custom dialogs, menus, and full-screen overlays. Pages can be built-in types or fully custom UIs.

### PageManager

`PageManager` controls which page is displayed and handles custom page events:

```java
// com.hypixel.hytale.server.core.entity.entities.player.pages.PageManager

// Set a built-in page
pageManager.setPage(ref, store, Page.Inventory);

// Open a custom page
pageManager.openCustomPage(ref, store, customPage);

// Set page with associated windows
pageManager.setPageWithWindows(ref, store, Page.Bench, true, craftingWindow);

// Open custom page with windows
pageManager.openCustomPageWithWindows(ref, store, customPage, window1, window2);

// Get current custom page
CustomUIPage currentPage = pageManager.getCustomPage();
```

### Built-in Page Types

The `Page` enum defines standard page types:

| Page | Value | Description |
|------|-------|-------------|
| `None` | 0 | No page open (gameplay view) |
| `Bench` | 1 | Crafting bench page |
| `Inventory` | 2 | Player inventory |
| `ToolsSettings` | 3 | Tool configuration |
| `Map` | 4 | World map view |
| `MachinimaEditor` | 5 | Machinima/cinematic editor |
| `ContentCreation` | 6 | Content creation tools |
| `Custom` | 7 | Plugin-defined custom page |

### CustomUIPage

Create custom pages by extending `CustomUIPage`:

```java
// com.hypixel.hytale.server.core.entity.entities.player.pages.CustomUIPage

public abstract class CustomUIPage {
    protected final PlayerRef playerRef;
    protected CustomPageLifetime lifetime;

    // Build the page UI
    public abstract void build(Ref<EntityStore> ref, UICommandBuilder commandBuilder,
                               UIEventBuilder eventBuilder, Store<EntityStore> store);

    // Handle data events from client
    public void handleDataEvent(Ref<EntityStore> ref, Store<EntityStore> store, String rawData);

    // Called when page is dismissed
    public void onDismiss(Ref<EntityStore> ref, Store<EntityStore> store);

    // Rebuild entire page
    protected void rebuild();

    // Send incremental update
    protected void sendUpdate(UICommandBuilder commandBuilder);

    // Close the page
    protected void close();
}
```

### InteractiveCustomUIPage

For pages with typed event handling, extend `InteractiveCustomUIPage<T>`:

```java
// com.hypixel.hytale.server.core.entity.entities.player.pages.InteractiveCustomUIPage

public abstract class InteractiveCustomUIPage<T> extends CustomUIPage {
    protected final BuilderCodec<T> eventDataCodec;

    // Handle typed data events
    public void handleDataEvent(Ref<EntityStore> ref, Store<EntityStore> store, T data);

    // Send update with event bindings
    protected void sendUpdate(UICommandBuilder commandBuilder, UIEventBuilder eventBuilder, boolean clear);
}
```

---

## HUD System

The HUD System manages persistent on-screen elements like health bars, hotbar, and compass. Components can be shown/hidden individually, and custom HUD overlays can be added.

### HudManager

`HudManager` controls which HUD components are visible:

```java
// com.hypixel.hytale.server.core.entity.entities.player.hud.HudManager

// Get currently visible components
Set<HudComponent> visible = hudManager.getVisibleHudComponents();

// Set exactly which components are visible
hudManager.setVisibleHudComponents(playerRef, HudComponent.Hotbar, HudComponent.Health);

// Show additional components
hudManager.showHudComponents(playerRef, HudComponent.Compass, HudComponent.Stamina);

// Hide specific components
hudManager.hideHudComponents(playerRef, HudComponent.Speedometer);

// Set custom HUD overlay
hudManager.setCustomHud(playerRef, customHud);

// Reset to default HUD
hudManager.resetHud(playerRef);

// Reset entire UI state
hudManager.resetUserInterface(playerRef);
```

### HUD Components

Built-in HUD components defined in `HudComponent` enum:

| Component | Description |
|-----------|-------------|
| `Hotbar` | Action bar / item slots |
| `StatusIcons` | Status effect icons |
| `Reticle` | Crosshair / aim indicator |
| `Chat` | Chat window |
| `Requests` | Friend/party requests |
| `Notifications` | Toast notifications |
| `KillFeed` | Combat kill feed |
| `InputBindings` | Current keybind hints |
| `PlayerList` | Online player list |
| `EventTitle` | Event title display |
| `Compass` | Directional compass |
| `ObjectivePanel` | Quest/objective tracker |
| `PortalPanel` | Portal information |
| `BuilderToolsLegend` | Builder mode legend |
| `Speedometer` | Speed indicator |
| `UtilitySlotSelector` | Utility slot UI |
| `BlockVariantSelector` | Block variant picker |
| `BuilderToolsMaterialSlotSelector` | Builder material selector |
| `Stamina` | Stamina bar |
| `AmmoIndicator` | Ammunition counter |
| `Health` | Health bar |
| `Mana` | Mana bar |
| `Oxygen` | Oxygen/breath bar |
| `Sleep` | Sleep indicator |

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
);
```

### CustomUIHud

Create custom HUD overlays by extending `CustomUIHud`:

```java
// com.hypixel.hytale.server.core.entity.entities.player.hud.CustomUIHud

public abstract class CustomUIHud {
    private final PlayerRef playerRef;

    // Build the HUD UI
    protected abstract void build(UICommandBuilder commandBuilder);

    // Show the HUD (calls build internally)
    public void show();

    // Send update to client
    public void update(boolean clear, UICommandBuilder commandBuilder);

    // Get player reference
    public PlayerRef getPlayerRef();
}
```

---

## UI Building Tools

### UICommandBuilder

Build UI manipulation commands to send to the client:

```java
// com.hypixel.hytale.server.core.ui.builder.UICommandBuilder

UICommandBuilder builder = new UICommandBuilder();

// Clear element contents
builder.clear("#my-container");

// Remove element from DOM
builder.remove("#old-element");

// Append document template
builder.append("#container", "path/to/template.ui");

// Append inline markup
builder.appendInline("#container", "<div>Inline content</div>");

// Insert before element
builder.insertBefore("#target", "path/to/template.ui");

// Set values on elements
builder.set("#health-text", "100 HP");
builder.set("#health-bar", 0.75f);
builder.set("#is-visible", true);
builder.set("#count", 42);
builder.setNull("#optional-field");

// Set complex objects
builder.setObject("#item-slot", itemGridSlot);
builder.set("#items", itemStackList);

// Get commands array
CustomUICommand[] commands = builder.getCommands();
```

### UIEventBuilder

Bind UI events to server-side handlers:

```java
// com.hypixel.hytale.server.core.ui.builder.UIEventBuilder

UIEventBuilder eventBuilder = new UIEventBuilder();

// Basic event binding
eventBuilder.addEventBinding(CustomUIEventBindingType.Click, "#my-button");

// With event data
EventData data = new EventData()
    .append("action", "submit")
    .append("itemId", "123");
eventBuilder.addEventBinding(CustomUIEventBindingType.Click, "#submit-btn", data);

// Non-locking event (doesn't block UI)
eventBuilder.addEventBinding(CustomUIEventBindingType.Change, "#slider", data, false);

// Get bindings array
CustomUIEventBinding[] bindings = eventBuilder.getEvents();
```

### EventData

Pass key-value parameters with events:

```java
// com.hypixel.hytale.server.core.ui.builder.EventData

// Create empty and append
EventData data = new EventData()
    .append("key1", "value1")
    .append("key2", "value2");

// Create with initial value
EventData data = EventData.of("action", "confirm");

// Append enum values
data.append("direction", Direction.NORTH);
```

---

## Complete Example

Here's a complete example showing how to create a custom page with event handling:

```java
public class MyCustomPage extends InteractiveCustomUIPage<MyEventData> {

    public MyCustomPage(PlayerRef playerRef) {
        super(playerRef, CustomPageLifetime.UntilDismissed, MyEventData.CODEC);
    }

    @Override
    public void build(Ref<EntityStore> ref, UICommandBuilder commands,
                      UIEventBuilder events, Store<EntityStore> store) {
        // Build the UI
        commands.append("path/to/my-page.ui");
        commands.set("#title", "My Custom Page");
        commands.set("#player-name", playerRef.getUsername());

        // Bind events
        events.addEventBinding(
            CustomUIEventBindingType.Click,
            "#confirm-button",
            EventData.of("action", "confirm")
        );
        events.addEventBinding(
            CustomUIEventBindingType.Click,
            "#cancel-button",
            EventData.of("action", "cancel")
        );
    }

    @Override
    public void handleDataEvent(Ref<EntityStore> ref, Store<EntityStore> store, MyEventData data) {
        if ("confirm".equals(data.action())) {
            // Handle confirm
            this.close();
        } else if ("cancel".equals(data.action())) {
            // Handle cancel
            this.close();
        }
    }

    @Override
    public void onDismiss(Ref<EntityStore> ref, Store<EntityStore> store) {
        // Cleanup when page is closed
    }
}

// Usage
Player playerComponent = store.getComponent(ref, Player.getComponentType());
PageManager pageManager = playerComponent.getPageManager();
pageManager.openCustomPage(ref, store, new MyCustomPage(playerRef));
```

---

## UI File System (.ui Files)

Hytale uses `.ui` files as the client-side layout format. These text-based assets define UI structure, styles, and components that are referenced by server-side code.

### Overview

UI files are registered as text assets in the engine:

```java
assetTypeRegistry.registerAssetType(
    new CommonAssetTypeHandler("UI", null, ".ui", AssetEditorEditorType.Text)
);
```

### Directory Structure

```
UI Assets
├── Common/
│   └── TextButton.ui          # Reusable components
├── Common.ui                   # Global styles
└── Pages/
    ├── [Feature]Page.ui       # Main layouts
    └── [Feature]Element.ui    # Sub-components
```

### Loading UI Files

```java
UICommandBuilder builder = new UICommandBuilder();

// Load main page layout
builder.append("Pages/MyPage.ui");

// Append child elements into containers
builder.append("#Container", "Pages/MyElement.ui");

// Reference styles from other UI files
builder.set("#Button.Style", Value.ref("Common.ui", "DefaultTextButtonStyle"));
```

### Known UI Files

The game includes numerous built-in UI files for pages like:

- `Pages/DialogPage.ui` - NPC conversation dialogs
- `Pages/ShopPage.ui` - Shop interfaces with `ShopItemButton.ui`
- `Pages/BarterPage.ui` - Trading with `BarterTradeRow.ui`
- `Pages/RespawnPage.ui` - Death/respawn with point selection
- `Pages/WarpListPage.ui` - Teleportation lists
- `Pages/CommandListPage.ui` - Command browser
- `Pages/PluginListPage.ui` - Plugin management
- `Pages/PrefabPage.ui` - Prefab browser and editor tools
- `Pages/MemoriesPanel.ui` - Collection/memories display

See the [Custom Pages System](/modding/gui-pages#ui-file-system-ui-files) documentation for a complete list and detailed usage.

## Package References

| Class | Package |
|-------|---------|
| `WindowManager` | `com.hypixel.hytale.server.core.entity.entities.player.windows` |
| `Window` | `com.hypixel.hytale.server.core.entity.entities.player.windows` |
| `WindowType` | `com.hypixel.hytale.protocol.packets.window` |
| `WindowAction` | `com.hypixel.hytale.protocol.packets.window` |
| `PageManager` | `com.hypixel.hytale.server.core.entity.entities.player.pages` |
| `CustomUIPage` | `com.hypixel.hytale.server.core.entity.entities.player.pages` |
| `InteractiveCustomUIPage` | `com.hypixel.hytale.server.core.entity.entities.player.pages` |
| `Page` | `com.hypixel.hytale.protocol.packets.interface_` |
| `HudManager` | `com.hypixel.hytale.server.core.entity.entities.player.hud` |
| `CustomUIHud` | `com.hypixel.hytale.server.core.entity.entities.player.hud` |
| `HudComponent` | `com.hypixel.hytale.protocol.packets.interface_` |
| `UICommandBuilder` | `com.hypixel.hytale.server.core.ui.builder` |
| `UIEventBuilder` | `com.hypixel.hytale.server.core.ui.builder` |
| `EventData` | `com.hypixel.hytale.server.core.ui.builder` |
| `Player` | `com.hypixel.hytale.server.core.entity.entities` |
