---
author: UnlimitedBytes
title: Windows System
description: Create and manage server-side GUI windows for player interactions in Hytale.
sidebar:
  order: 2
---

The Hytale window system provides a server-authoritative GUI framework for displaying inventory interfaces, crafting tables, containers, and custom interfaces to players.

## Architecture

```
WindowManager (Per-player window management)
├── Window (Base abstract class)
│   ├── ContainerWindow (Simple item container)
│   ├── ContainerBlockWindow (Block-bound container via BlockWindow)
│   ├── ItemStackContainerWindow (ItemStack-based container)
│   └── Custom window implementations
├── WindowType (Protocol-defined window types)
└── WindowAction (Client-to-server actions)

Window Hierarchy:
├── Window (abstract base)
│   └── BlockWindow (abstract, for block-bound windows)
│       └── ContainerBlockWindow

Window Interfaces:
├── ItemContainerWindow - Windows with item storage (getItemContainer())
├── MaterialContainerWindow - Windows with material/extra resources (getExtraResourcesSection(), invalidateExtraResources(), isValid())
└── ValidatedWindow - Windows requiring periodic validation (validate())
```

## WindowManager

The `WindowManager` handles all window operations for a specific player. It is accessed through the `Player` component's `getWindowManager()` method.

### Accessing WindowManager

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.WindowManager;
import com.hypixel.hytale.server.core.entity.entities.Player;

// Get WindowManager from Player
Player player = store.getComponent(ref, Player.getComponentType());
WindowManager windowManager = player.getWindowManager();

// WindowManager is initialized internally via init(PlayerRef playerRef)
// This is called automatically when the player is set up
```

### Opening Windows

```java
import com.hypixel.hytale.protocol.packets.window.OpenWindow;

// Open a window and get the packet to send
Window myWindow = new ContainerWindow(itemContainer);
OpenWindow packet = windowManager.openWindow(myWindow);

if (packet != null) {
    // Window opened successfully - packet returned for sending
    // The packet includes: id, windowType, windowData (JSON), inventory section, extra resources
    int windowId = myWindow.getId();
}

// Open multiple windows at once
Window[] windows = { window1, window2, window3 };
List<OpenWindow> packets = windowManager.openWindows(windows);

if (packets == null) {
    // One or more windows failed to open - all are closed
}
```

### Updating Windows

```java
// Manually update a window (sends UpdateWindow packet via playerRef.getPacketHandler().writeNoCache())
// Includes inventory section for ItemContainerWindow, and extraResources for MaterialContainerWindow when !isValid()
windowManager.updateWindow(window);

// Mark a window as changed (will be updated on next tick)
windowManager.markWindowChanged(windowId);

// Update all dirty windows (called automatically by server)
// Iterates through all windows and sends UpdateWindow packet for dirty ones
windowManager.updateWindows();

// Validate all windows implementing ValidatedWindow interface
// Closes windows that fail validation (e.g., player moved too far from block)
// Called automatically by the server each tick
windowManager.validateWindows();
```

### Closing Windows

```java
// Close a specific window by ID
// Sends CloseWindow packet, removes window, calls onClose()
// Throws IllegalArgumentException if id is -1
// Throws IllegalStateException if window doesn't exist
Window closedWindow = windowManager.closeWindow(windowId);

// Close all windows for the player
// Iterates through all windows and calls close() on each
windowManager.closeAllWindows();

// Close window from within the window instance
window.close();
```

### Window ID Management

| ID | Description |
|----|-------------|
| -1 | Invalid/unassigned |
| 0 | Reserved for client-initiated windows |
| 1+ | Server-assigned IDs (auto-incremented) |

```java
// Get a window by ID (throws IllegalArgumentException if id is -1)
Window window = windowManager.getWindow(windowId);

// Get all active windows (returns a new ObjectArrayList copy)
List<Window> allWindows = windowManager.getWindows();

// Static utility: Close and remove all windows from a UUID-keyed map
WindowManager.closeAndRemoveAll(Map<UUID, ? extends Window> windows);
```

## Window Types

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

## Creating Custom Windows

### Basic Window Implementation

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.Window;
import com.hypixel.hytale.protocol.packets.window.WindowType;
import com.hypixel.hytale.protocol.packets.window.WindowAction;
import com.hypixel.hytale.component.Ref;
import com.hypixel.hytale.component.Store;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;
import com.google.gson.JsonObject;
import javax.annotation.Nonnull;

public class CustomWindow extends Window {
    @Nonnull
    private final JsonObject windowData = new JsonObject();

    public CustomWindow() {
        super(WindowType.Container);
        windowData.addProperty("customProperty", "value");
    }

    @Override
    @Nonnull
    public JsonObject getData() {
        return windowData;
    }

    @Override
    protected boolean onOpen0() {
        // Called when window opens
        // Return false to cancel opening
        return true;
    }

    @Override
    protected void onClose0() {
        // Called when window closes
        // Clean up resources here
    }

    // Optional: Override to handle client actions
    @Override
    public void handleAction(@Nonnull Ref<EntityStore> ref, @Nonnull Store<EntityStore> store, @Nonnull WindowAction action) {
        // Handle window-specific actions
    }
}
```

### Key Window Methods

```java
// Get the window type
WindowType type = window.getType();

// Get the window ID (assigned by WindowManager)
int id = window.getId();

// Get the player reference (available after init)
PlayerRef playerRef = window.getPlayerRef();

// Close this window
window.close();

// Mark the window as needing an update (calls invalidate internally)
// Use protected invalidate() method inside Window subclasses
protected void invalidate() {
    this.isDirty.set(true);
}

// Mark window as needing a full rebuild
protected void setNeedRebuild() {
    this.needRebuild.set(true);
    this.getData().addProperty("needRebuild", Boolean.TRUE);
}
```

### Window Lifecycle

```
1. Window constructed with WindowType
2. WindowManager.openWindow(window) called
3. Window ID auto-incremented and assigned via window.setId(id)
   - IDs wrap from MAX_INT back to 1 (never 0 or -1)
4. Window.init(PlayerRef, WindowManager) called
5. If window is ItemContainerWindow, change event registered automatically (EventPriority.LAST)
6. Window.onOpen() -> onOpen0()
   - Return true to complete opening
   - Return false to cancel (window is closed, ID set to -1)
7. window.consumeIsDirty() called
8. OpenWindow packet created and returned (includes inventory section and extra resources if applicable)
9. Window active - handles actions via handleAction(), updates via invalidate()
10. WindowManager.validateWindows() called each tick
    - Windows implementing ValidatedWindow are validated
    - Invalid windows are closed automatically
11. WindowManager.updateWindows() called each tick
    - Dirty windows send UpdateWindow packets automatically
12. Window.close() or WindowManager.closeWindow(id) called
13. CloseWindow packet sent to client via playerRef.getPacketHandler().writeNoCache()
14. Window removed from WindowManager's Int2ObjectConcurrentHashMap
15. If ItemContainerWindow, change event unregistered
16. Window.onClose() -> onClose0() called
17. WindowCloseEvent dispatched via closeEventRegistry
```

### Window Data

Window data is sent to the client as JSON via the `getData()` method. The returned `JsonObject` is serialized and included in the `OpenWindow` and `UpdateWindow` packets:

```java
@Override
@Nonnull
public JsonObject getData() {
    JsonObject data = new JsonObject();
    data.addProperty("title", "My Window");
    data.addProperty("capacity", 27);
    data.addProperty("customFlag", true);
    return data;
}
```

The window data string is serialized via `window.getData().toString()` and has a maximum size of 4,096,000 bytes (UTF-8 length).

## WindowAction Types

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
| `SortItemsAction` | Sort items in container (sortType: Name=0, Type=1, Rarity=2) |

### Handling Actions

```java
@Override
public void handleAction(@Nonnull Ref<EntityStore> ref, @Nonnull Store<EntityStore> store, @Nonnull WindowAction action) {
    if (action instanceof SelectSlotAction selectSlot) {
        int slot = selectSlot.slot; // Direct field access, not getter
        // Handle slot selection
    } else if (action instanceof SortItemsAction sortAction) {
        // sortAction.sortType is a com.hypixel.hytale.protocol.SortType enum (Name=0, Type=1, Rarity=2)
        // Convert to server SortType using SortType.fromPacket(sortAction.sortType)
        com.hypixel.hytale.server.core.inventory.container.SortType sortType = 
            com.hypixel.hytale.server.core.inventory.container.SortType.fromPacket(sortAction.sortType);
        // Sort the container contents
    }
}
```

## Window Events

### Close Event

The `WindowCloseEvent` is dispatched when a window closes. It implements `IEvent<Void>`.

```java
import com.hypixel.hytale.event.EventRegistration;
import com.hypixel.hytale.event.EventPriority;

// Register for window close events (default priority)
EventRegistration registration = window.registerCloseEvent(event -> {
    // Handle window close
    // Note: WindowCloseEvent is a simple event with no additional data
});

// Register with short priority value
EventRegistration registration = window.registerCloseEvent((short) 0, event -> {
    // Handle window close
});

// Register with EventPriority enum
EventRegistration registration = window.registerCloseEvent(EventPriority.LAST, event -> {
    // Handle window close
});

// Unregister when done
registration.unregister();
```

## Built-in Window Classes

### ContainerWindow

Basic item container window implementing `ItemContainerWindow`. Uses `WindowType.Container` and has minimal implementation (empty `onOpen0()` returns true, empty `onClose0()`):

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.ContainerWindow;
import com.hypixel.hytale.server.core.inventory.container.SimpleItemContainer;
import com.hypixel.hytale.protocol.packets.window.OpenWindow;

SimpleItemContainer container = new SimpleItemContainer((short) 27);
ContainerWindow window = new ContainerWindow(container);

// openWindow returns the OpenWindow packet (or null if opening failed)
OpenWindow packet = windowManager.openWindow(window);
if (packet != null) {
    // Window opened successfully, send the packet to the client
    playerRef.getPacketHandler().write(packet);
}
```

### BlockWindow

Abstract base class for windows bound to a block position. Implements `ValidatedWindow` to automatically close when the player moves too far from the block or the block changes.

```java
// BlockWindow constructor (abstract class, used by subclasses)
// BlockWindow(WindowType windowType, int x, int y, int z, int rotationIndex, BlockType blockType)

// Static constant (used as default):
// private static final float MAX_DISTANCE = 7.0f;

// Key methods:
blockWindow.getX();           // Block X coordinate
blockWindow.getY();           // Block Y coordinate
blockWindow.getZ();           // Block Z coordinate
blockWindow.getRotationIndex();
blockWindow.getBlockType();
blockWindow.setMaxDistance(double maxDistance);  // Default: 7.0 blocks
blockWindow.getMaxDistance();

// validate() checks:
// 1. PlayerRef is not null
// 2. Player reference and store are valid
// 3. Player distance to block <= maxDistanceSqr
// 4. Chunk containing block is loaded
// 5. Block at position has same Item as original blockType
blockWindow.validate();       // Returns false if any check fails
```

### ContainerBlockWindow

Window bound to a block in the world. Extends `BlockWindow` and implements `ItemContainerWindow`. Includes built-in handling for `SortItemsAction`:

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.ContainerBlockWindow;
import com.hypixel.hytale.server.core.asset.type.blocktype.config.BlockType;

// Constructor takes block coordinates, rotation, block type, and item container
ContainerBlockWindow window = new ContainerBlockWindow(
    x,              // int - block X position
    y,              // int - block Y position
    z,              // int - block Z position
    rotationIndex,  // int - block rotation
    blockType,      // BlockType - the block type
    itemContainer   // ItemContainer - the container for items
);

// Window data automatically includes blockItemId from blockType.getItem().getId()
// handleAction() automatically handles SortItemsAction:
//   - Converts protocol SortType to server SortType via SortType.fromPacket()
//   - Saves the sort type to player's inventory via playerComponent.getInventory().setSortType()
//   - Sorts the container items via itemContainer.sortItems()
//   - Invalidates the window to trigger an update
```

### ItemStackContainerWindow

Window for containers that are stored within an ItemStack. Implements `ItemContainerWindow`:

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.ItemStackContainerWindow;
import com.hypixel.hytale.server.core.inventory.container.ItemStackItemContainer;

// ItemStackItemContainer wraps an ItemStack's container
ItemStackContainerWindow window = new ItemStackContainerWindow(itemStackItemContainer);

// On open, registers a change event on the parent container
// Automatically closes if the parent ItemStack becomes invalid (checked via isItemStackValid())
// On close, unregisters the change event
```

## Client-Requestable Windows

Some windows can be opened by client request. These must be registered in the static `Window.CLIENT_REQUESTABLE_WINDOW_TYPES` map:

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.Window;
import com.hypixel.hytale.protocol.packets.window.WindowType;
import java.util.function.Supplier;

// CLIENT_REQUESTABLE_WINDOW_TYPES is a ConcurrentHashMap<WindowType, Supplier<? extends Window>>
// Register a window type that clients can request to open
Window.CLIENT_REQUESTABLE_WINDOW_TYPES.put(WindowType.Container, MyContainerWindow::new);

// Client-opened windows use ID 0 and are handled via clientOpenWindow()
// Returns UpdateWindow packet instead of OpenWindow packet
// Throws IllegalArgumentException if window type is not registered
```

Client-requested windows always use window ID 0 and replace any existing window at that ID. If a window already exists at ID 0, it is closed before the new window opens.

## Best Practices

1. **Validate window state** - Check if window is still valid before operations
2. **Handle close gracefully** - Clean up resources in `onClose0()`
3. **Use invalidate() for updates** - Call `invalidate()` to mark window dirty, then `WindowManager.updateWindows()` sends updates
4. **Use appropriate types** - Choose the right `WindowType` for rendering
5. **Limit open windows** - Close old windows before opening new ones
6. **Register ItemContainer change events** - WindowManager automatically registers change events for `ItemContainerWindow` implementations
7. **Implement ValidatedWindow** - For windows that should close based on conditions (e.g., distance from block)
