---
title: Custom Pages System
description: Create and manage custom GUI pages for player interactions in your Hytale server plugins.
sidebar:
  order: 3
---

The Custom Pages System allows you to create fully customizable GUI interfaces for players. This includes interactive dialogs, settings pages, choice menus, shop interfaces, and more.

## Architecture

```
PageManager (Per-Player)
├── Standard Pages (Page enum)
│   └── None, Bench, Inventory, ToolsSettings, Map, etc.
└── Custom Pages (CustomUIPage hierarchy)
    ├── BasicCustomUIPage     - Simple display-only pages
    ├── InteractiveCustomUIPage<T> - Pages with event handling
    └── ChoiceBasePage        - Choice/dialog pages
```

## PageManager

The `PageManager` handles opening, closing, and updating pages for each player. Access it through the `Player` component.

### Key Methods

| Method | Description |
|--------|-------------|
| `setPage(ref, store, page)` | Set a standard page (from Page enum) |
| `setPage(ref, store, page, canCloseThroughInteraction)` | Set page with close-through-interaction option |
| `setPageWithWindows(ref, store, page, canCloseThroughInteraction, windows...)` | Set page with inventory windows |
| `openCustomPage(ref, store, customPage)` | Open a custom UI page |
| `openCustomPageWithWindows(ref, store, page, windows...)` | Open custom page with inventory windows |
| `getCustomPage()` | Get the currently open custom page |
| `init(playerRef, windowManager)` | Initialize the PageManager (called automatically) |

### Standard Page Enum

| Value | Description |
|-------|-------------|
| `None` | No page open (closes current page) |
| `Bench` | Crafting bench interface |
| `Inventory` | Player inventory |
| `ToolsSettings` | Tool settings interface |
| `Map` | World map |
| `MachinimaEditor` | Machinima editing tools |
| `ContentCreation` | Content creation tools |
| `Custom` | Custom page (used internally) |

### Opening Pages

```java
Player playerComponent = store.getComponent(ref, Player.getComponentType());
PageManager pageManager = playerComponent.getPageManager();

// Open standard page
pageManager.setPage(ref, store, Page.Inventory);

// Open page that can be closed by clicking elsewhere
pageManager.setPage(ref, store, Page.Bench, true);

// Close any open page
pageManager.setPage(ref, store, Page.None);
```

## CustomUIPage Hierarchy

### CustomUIPage (Base Class)

```java
public abstract class CustomUIPage {
    protected final PlayerRef playerRef;
    protected CustomPageLifetime lifetime;

    // Must implement - builds the initial page UI
    public abstract void build(
        Ref<EntityStore> ref,
        UICommandBuilder commandBuilder,
        UIEventBuilder eventBuilder,
        Store<EntityStore> store
    );

    // Override for cleanup when page is dismissed
    public void onDismiss(Ref<EntityStore> ref, Store<EntityStore> store);

    // Rebuild the entire page UI
    protected void rebuild();

    // Send partial updates to the page (multiple overloads)
    protected void sendUpdate();  // Rebuild without arguments
    protected void sendUpdate(@Nullable UICommandBuilder commandBuilder);
    protected void sendUpdate(@Nullable UICommandBuilder commandBuilder, boolean clear);

    // Get/set the page lifetime
    public CustomPageLifetime getLifetime();
    public void setLifetime(CustomPageLifetime lifetime);

    // Close this page
    protected void close();
}
```

### CustomPageLifetime Enum

| Value | Description |
|-------|-------------|
| `CantClose` | Player cannot close the page (e.g., death screen) |
| `CanDismiss` | Player can dismiss with escape key |
| `CanDismissOrCloseThroughInteraction` | Can dismiss or close by clicking outside |

### BasicCustomUIPage

For simple pages that don't need event handling:

```java
public class WelcomePage extends BasicCustomUIPage {
    
    public WelcomePage(PlayerRef playerRef) {
        super(playerRef, CustomPageLifetime.CanDismiss);
    }

    @Override
    public void build(UICommandBuilder commandBuilder) {
        commandBuilder.append("Pages/WelcomePage.ui");
        commandBuilder.set("#Title.Text", "Welcome!");
        commandBuilder.set("#PlayerName.Text", playerRef.getUsername());
    }
}
```

### InteractiveCustomUIPage<T>

For pages that handle user interactions. This class extends `CustomUIPage` with typed event handling and has an additional `sendUpdate` signature:

```java
// Additional sendUpdate signature for interactive pages
protected void sendUpdate(@Nullable UICommandBuilder commandBuilder, 
                          @Nullable UIEventBuilder eventBuilder, 
                          boolean clear);
```

```java
public class SettingsPage extends InteractiveCustomUIPage<SettingsEventData> {
    
    public SettingsPage(PlayerRef playerRef) {
        super(playerRef, CustomPageLifetime.CanDismiss, SettingsEventData.CODEC);
    }

    @Override
    public void build(Ref<EntityStore> ref, UICommandBuilder commands,
                      UIEventBuilder events, Store<EntityStore> store) {
        commands.append("Pages/SettingsPage.ui");
        
        // Bind save button
        events.addEventBinding(
            CustomUIEventBindingType.Activating,
            "#SaveButton",
            EventData.of("action", "save")
        );
    }

    @Override
    public void handleDataEvent(Ref<EntityStore> ref, Store<EntityStore> store,
                                SettingsEventData data) {
        if ("save".equals(data.action)) {
            // Handle save
            close();
        }
    }
}
```

## Event Data Class

Create a data class with codec for receiving events:

```java
public static class SettingsEventData {
    public static final BuilderCodec<SettingsEventData> CODEC = 
        BuilderCodec.builder(SettingsEventData.class, SettingsEventData::new)
            .append(new KeyedCodec<>("action", Codec.STRING),
                (d, v) -> d.action = v, d -> d.action)
            .add()
            .append(new KeyedCodec<>("@value", Codec.INTEGER),
                (d, v) -> d.value = v, d -> d.value)
            .add()
            .build();

    public String action;
    public Integer value;
}
```

### Event Data Keys

- **Static keys** (e.g., `"action"`) - Sent as literal values
- **Reference keys** (prefixed with `@`, e.g., `"@value"`) - Reference UI element values at event time

### EventData Methods

`EventData` only supports `String` and `Enum` values. Numbers must be converted to strings:

```java
// Static factory method
EventData.of("key", "value")

// Append methods (returns self for chaining)
.append("stringKey", "stringValue")
.append("enumKey", MyEnum.VALUE)

// For integers, convert to string
EventData.of("action", "buy").append("index", Integer.toString(i))
```

## UIEventBuilder

The `UIEventBuilder` creates event bindings for UI elements:

```java
// Basic event binding
events.addEventBinding(CustomUIEventBindingType.Activating, "#Button");

// With event data
events.addEventBinding(CustomUIEventBindingType.Activating, "#Button", EventData.of("action", "click"));

// With locksInterface parameter (default is true)
events.addEventBinding(CustomUIEventBindingType.Activating, "#Button", EventData.of("action", "click"), false);
```

### CustomUIEventBindingType

| Type | Description |
|------|-------------|
| `Activating` | Element clicked/activated |
| `RightClicking` | Right mouse button click |
| `DoubleClicking` | Double click |
| `MouseEntered` | Mouse enters element |
| `MouseExited` | Mouse exits element |
| `ValueChanged` | Input value changed |
| `ElementReordered` | Element reordered in list |
| `Validating` | Input validation |
| `Dismissing` | Page being dismissed |
| `FocusGained` | Element gained focus |
| `FocusLost` | Element lost focus |
| `KeyDown` | Key pressed |
| `MouseButtonReleased` | Mouse button released |
| `SlotClicking` | Inventory slot clicked |
| `SlotDoubleClicking` | Inventory slot double-clicked |
| `SlotMouseEntered` | Mouse enters slot |
| `SlotMouseExited` | Mouse exits slot |
| `DragCancelled` | Drag operation cancelled |
| `Dropped` | Element dropped |
| `SlotMouseDragCompleted` | Slot drag completed |
| `SlotMouseDragExited` | Drag exited slot |
| `SlotClickReleaseWhileDragging` | Click released while dragging |
| `SlotClickPressWhileDragging` | Click pressed while dragging |
| `SelectedTabChanged` | Tab selection changed |

## UICommandBuilder

The `UICommandBuilder` creates UI update commands:

### Layout Commands

| Method | Description |
|--------|-------------|
| `append(documentPath)` | Append UI document at root |
| `append(selector, documentPath)` | Append UI document to element |
| `appendInline(selector, document)` | Append inline UI definition |
| `insertBefore(selector, documentPath)` | Insert UI document before element |
| `insertBeforeInline(selector, document)` | Insert inline UI before element |
| `clear(selector)` | Clear element's children |
| `remove(selector)` | Remove element from DOM |

### Value Setting Commands

| Method | Description |
|--------|-------------|
| `set(selector, String)` | Set string value |
| `set(selector, boolean)` | Set boolean value |
| `set(selector, int)` | Set integer value |
| `set(selector, float)` | Set float value |
| `set(selector, double)` | Set double value |
| `set(selector, Message)` | Set localized message |
| `set(selector, Value<T>)` | Set reference value |
| `set(selector, T[])` | Set array of values |
| `set(selector, List<T>)` | Set list of values |
| `setNull(selector)` | Set null value |
| `setObject(selector, Object)` | Set compatible object (Area, ItemGridSlot, ItemStack, etc.) |

## Complete Interactive Example

```java
public class ShopPage extends InteractiveCustomUIPage<ShopPage.ShopEventData> {

    private final List<ShopItem> items;
    private int playerCoins;

    public ShopPage(PlayerRef playerRef, List<ShopItem> items, int coins) {
        super(playerRef, CustomPageLifetime.CanDismiss, ShopEventData.CODEC);
        this.items = items;
        this.playerCoins = coins;
    }

    @Override
    public void build(Ref<EntityStore> ref, UICommandBuilder commands,
                      UIEventBuilder events, Store<EntityStore> store) {
        commands.append("Pages/ShopPage.ui");
        commands.set("#CoinsLabel.Text", playerCoins + " coins");

        for (int i = 0; i < items.size(); i++) {
            ShopItem item = items.get(i);
            commands.append("#ItemList", "Components/ShopItem.ui");
            commands.set("#Item" + i + ".Name", item.getName());
            commands.set("#Item" + i + ".Price", item.getPrice() + "c");

            events.addEventBinding(
                CustomUIEventBindingType.Activating,
                "#BuyBtn" + i,
                EventData.of("action", "buy").append("index", Integer.toString(i))
            );
        }

        events.addEventBinding(
            CustomUIEventBindingType.Activating,
            "#CloseBtn",
            EventData.of("action", "close")
        );
    }

    @Override
    public void handleDataEvent(Ref<EntityStore> ref, Store<EntityStore> store,
                                ShopEventData data) {
        switch (data.action) {
            case "buy":
                ShopItem item = items.get(data.index);
                if (playerCoins >= item.getPrice()) {
                    playerCoins -= item.getPrice();
                    // Give item to player...
                    
                    // Update UI
                    UICommandBuilder update = new UICommandBuilder();
                    update.set("#CoinsLabel.Text", playerCoins + " coins");
                    sendUpdate(update);
                }
                break;
            case "close":
                close();
                break;
        }
    }

    public static class ShopEventData {
        public static final BuilderCodec<ShopEventData> CODEC = 
            BuilderCodec.builder(ShopEventData.class, ShopEventData::new)
                .append(new KeyedCodec<>("action", Codec.STRING),
                    (d, v) -> d.action = v, d -> d.action).add()
                .append(new KeyedCodec<>("index", Codec.INTEGER),
                    (d, v) -> d.index = v, d -> d.index).add()
                .build();

        public String action;
        public Integer index;
    }
}
```

## Updating Pages Dynamically

### Partial Updates

```java
private void updateScore(int newScore) {
    UICommandBuilder builder = new UICommandBuilder();
    builder.set("#ScoreLabel.Text", String.valueOf(newScore));
    sendUpdate(builder);
}
```

### Full Rebuild

```java
// Completely rebuild the page
rebuild();
```

## ChoiceBasePage

A specialized page for presenting choices/dialogs to players. Extends `InteractiveCustomUIPage<ChoicePageEventData>`:

```java
public abstract class ChoiceBasePage extends InteractiveCustomUIPage<ChoicePageEventData> {
    
    public ChoiceBasePage(PlayerRef playerRef, ChoiceElement[] elements, String pageLayout) {
        super(playerRef, CustomPageLifetime.CanDismiss, ChoicePageEventData.CODEC);
        // ...
    }
    
    protected ChoiceElement[] getElements();
    protected String getPageLayout();
}
```

The page automatically:
- Appends the page layout
- Clears `#ElementList`
- Adds buttons for each `ChoiceElement` with `Activating` event bindings
- Handles element selection and runs associated `ChoiceInteraction`s

## Built-in UI Files

The game includes built-in UI files for common pages:

| File | Purpose |
|------|---------|
| `Pages/DialogPage.ui` | NPC conversation dialogs |
| `Pages/ShopPage.ui` | Shop interfaces |
| `Pages/BarterPage.ui` | Trading interfaces |
| `Pages/RespawnPage.ui` | Death/respawn screen |
| `Pages/WarpListPage.ui` | Teleportation lists |
| `Pages/CommandListPage.ui` | Command browser |
| `Pages/PluginListPage.ui` | Plugin management |

## Best Practices

1. **Use appropriate lifetime** - `CantClose` for important dialogs, `CanDismiss` for menus
2. **Handle all events** - Always have a way to close the page
3. **Validate event data** - Clients can send unexpected values
4. **Batch updates** - Combine multiple changes in one `sendUpdate()` call
5. **Clean up in onDismiss** - Release resources when page closes
