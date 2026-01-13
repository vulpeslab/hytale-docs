---
title: GUI Windows System
description: Create and manage server-side GUI windows for player interactions in Hytale.
sidebar:
  order: 17
---

> **Note:** This is unofficial community documentation created through decompilation and analysis. Some details may change in future versions.

The Hytale window system provides a server-authoritative GUI framework for displaying inventory interfaces, crafting tables, containers, and custom interfaces to players.

## Architecture

```
WindowManager (Per-player window management)
├── Window (Base abstract class)
│   ├── ContainerWindow (Simple item container)
│   ├── ContainerBlockWindow (Block-bound container)
│   ├── ItemStackContainerWindow (ItemStack-based container)
│   └── Custom window implementations
├── WindowType (Protocol-defined window types)
└── WindowAction (Client-to-server actions)

Window Interfaces:
├── ItemContainerWindow - Windows with item storage
├── MaterialContainerWindow - Windows with extra resources
└── ValidatedWindow - Windows requiring periodic validation
```

## WindowManager

The `WindowManager` handles all window operations for a specific player. It is accessed through the player's component system.

### Accessing WindowManager

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.WindowManager;
import com.hypixel.hytale.server.core.entity.entities.Player;

// Get WindowManager from player component
Player playerComponent = store.getComponent(ref, Player.getComponentType());
WindowManager windowManager = playerComponent.getWindowManager();
```

### Opening Windows

```java
import com.hypixel.hytale.protocol.packets.window.OpenWindow;

// Open a window and get the packet to send
Window myWindow = new ContainerWindow(itemContainer);
OpenWindow packet = windowManager.openWindow(myWindow);

if (packet != null) {
    // Window opened successfully - packet is automatically sent
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
// Manually update a window (sends UpdateWindow packet)
windowManager.updateWindow(window);

// Mark a window as changed (will be updated on next tick)
windowManager.markWindowChanged(windowId);

// Update all dirty windows (called automatically by server)
windowManager.updateWindows();
```

### Closing Windows

```java
// Close a specific window by ID
Window closedWindow = windowManager.closeWindow(windowId);

// Close all windows for the player
windowManager.closeAllWindows();

// Close window from within the window instance
window.close();
```

### Window ID Management

Window IDs are managed automatically by the `WindowManager`:

| ID | Description |
|----|-------------|
| -1 | Invalid/unassigned |
| 0 | Reserved for client-initiated windows |
| 1+ | Server-assigned IDs (auto-incremented) |

```java
// Get a window by ID
Window window = windowManager.getWindow(windowId);

// Get all active windows
List<Window> allWindows = windowManager.getWindows();
```

### Validating Windows

Windows implementing `ValidatedWindow` are automatically validated each tick:

```java
// Called automatically by the server
windowManager.validateWindows();
```

## Window Base Class

All windows extend the abstract `Window` class.

### Creating a Custom Window

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.Window;
import com.hypixel.hytale.protocol.packets.window.WindowType;
import com.google.gson.JsonObject;

public class CustomWindow extends Window {
    private final JsonObject windowData = new JsonObject();

    public CustomWindow() {
        super(WindowType.Container);
        // Initialize window data
        windowData.addProperty("customProperty", "value");
    }

    @Override
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
}
```

### Window Lifecycle

```
1. Window constructed
2. WindowManager.openWindow() called
3. Window.init() - receives PlayerRef and WindowManager
4. Window.onOpen() -> onOpen0()
   - Return true to complete opening
   - Return false to cancel (window is closed)
5. OpenWindow packet sent to client
6. Window active - handles actions, updates
7. Window.close() or WindowManager.closeWindow()
8. Window.onClose() -> onClose0()
9. WindowCloseEvent dispatched
10. CloseWindow packet sent to client
```

### Window Data

Window data is sent to the client as JSON:

```java
@Override
public JsonObject getData() {
    JsonObject data = new JsonObject();
    data.addProperty("title", "My Window");
    data.addProperty("capacity", 27);
    data.addProperty("customFlag", true);
    return data;
}

// Mark window as needing a full rebuild
protected void setNeedRebuild() {
    this.needRebuild.set(true);
    this.getData().addProperty("needRebuild", Boolean.TRUE);
}
```

### Window State Management

```java
// Mark window as dirty (will send update)
protected void invalidate() {
    this.isDirty.set(true);
}

// Check and consume dirty state
protected boolean consumeIsDirty() {
    return this.isDirty.getAndSet(false);
}

// Access window properties
public int getId() { return this.id; }
public WindowType getType() { return this.windowType; }
public PlayerRef getPlayerRef() { return this.playerRef; }
```

### WindowCloseEvent

Register handlers for when a window closes:

```java
import com.hypixel.hytale.event.EventPriority;
import com.hypixel.hytale.event.EventRegistration;
import com.hypixel.hytale.server.core.entity.entities.player.windows.Window.WindowCloseEvent;

// Register close handler
EventRegistration registration = window.registerCloseEvent(event -> {
    // Handle window closure
    System.out.println("Window closed!");
});

// With priority
EventRegistration reg = window.registerCloseEvent(
    EventPriority.EARLY,
    event -> handleClose(event)
);

// Unregister when done
registration.unregister();
```

### Client-Requestable Windows

Some windows can be opened by client request (like pocket crafting):

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.Window;

// Register a client-requestable window type
Window.CLIENT_REQUESTABLE_WINDOW_TYPES.put(
    WindowType.PocketCrafting,
    () -> new PocketCraftingWindow()
);

// In WindowManager - handles client request
UpdateWindow packet = windowManager.clientOpenWindow(window);
```

## WindowType Enum

Defines the types of windows recognized by the protocol.

| Type | ID | Description |
|------|-----|-------------|
| `Container` | 0 | Generic item container |
| `PocketCrafting` | 1 | Portable/pocket crafting interface |
| `BasicCrafting` | 2 | Basic crafting table |
| `DiagramCrafting` | 3 | Diagram-based crafting (schematics) |
| `StructuralCrafting` | 4 | Structural/building crafting |
| `Processing` | 5 | Processing bench (furnace, etc.) |
| `Memories` | 6 | Memories/journal interface |

```java
import com.hypixel.hytale.protocol.packets.window.WindowType;

// Get type from value
WindowType type = WindowType.fromValue(0); // Container

// Get value from type
int value = WindowType.Container.getValue(); // 0

// All types
WindowType[] allTypes = WindowType.VALUES;
```

## Window Interfaces

### ItemContainerWindow

Windows that contain an `ItemContainer` for item storage.

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.ItemContainerWindow;
import com.hypixel.hytale.server.core.inventory.container.ItemContainer;

public class MyContainerWindow extends Window implements ItemContainerWindow {
    private final ItemContainer itemContainer;

    public MyContainerWindow(ItemContainer container) {
        super(WindowType.Container);
        this.itemContainer = container;
    }

    @Override
    public ItemContainer getItemContainer() {
        return itemContainer;
    }

    // ... other methods
}
```

When a window implements `ItemContainerWindow`, the `WindowManager` automatically:
- Registers change events on the container
- Sends inventory updates to the client
- Unregisters events when the window closes

### MaterialContainerWindow

Windows that display extra resources/materials (used by crafting benches).

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.MaterialContainerWindow;
import com.hypixel.hytale.server.core.entity.entities.player.windows.MaterialExtraResourcesSection;

public class CraftingWindow extends Window implements MaterialContainerWindow {
    private final MaterialExtraResourcesSection extraResources;

    public CraftingWindow() {
        super(WindowType.BasicCrafting);
        this.extraResources = new MaterialExtraResourcesSection();
    }

    @Override
    public MaterialExtraResourcesSection getExtraResourcesSection() {
        return extraResources;
    }

    @Override
    public void invalidateExtraResources() {
        extraResources.setValid(false);
        invalidate();
    }

    @Override
    public boolean isValid() {
        return extraResources.isValid();
    }
}
```

### MaterialExtraResourcesSection

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.MaterialExtraResourcesSection;
import com.hypixel.hytale.protocol.ItemQuantity;

MaterialExtraResourcesSection section = new MaterialExtraResourcesSection();

// Set extra materials to display
ItemQuantity[] materials = new ItemQuantity[] { /* ... */ };
section.setExtraMaterials(materials);

// Track validity
section.setValid(true);
boolean valid = section.isValid();

// Associated item container
section.setItemContainer(container);
ItemContainer container = section.getItemContainer();
```

### ValidatedWindow

Windows that need periodic validation (e.g., distance checks, block existence).

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.ValidatedWindow;

public class MyValidatedWindow extends Window implements ValidatedWindow {

    @Override
    public boolean validate() {
        // Return true if window should remain open
        // Return false to close the window

        PlayerRef playerRef = getPlayerRef();
        if (playerRef == null) return false;

        // Custom validation logic
        return isPlayerInRange();
    }
}
```

## Built-in Window Types

### ContainerWindow

Simple container window for displaying item storage.

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.ContainerWindow;
import com.hypixel.hytale.server.core.inventory.container.SimpleItemContainer;

// Create a container
ItemContainer container = new SimpleItemContainer((short) 27);

// Create and open the window
ContainerWindow window = new ContainerWindow(container);
windowManager.openWindow(window);
```

### BlockWindow

Abstract base for windows tied to world blocks. Implements `ValidatedWindow` to automatically close when player moves too far or block changes.

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.BlockWindow;
import com.hypixel.hytale.server.core.asset.type.blocktype.config.BlockType;

public class CustomBlockWindow extends BlockWindow {
    private static final float MAX_DISTANCE = 7.0f;

    public CustomBlockWindow(int x, int y, int z, int rotationIndex, BlockType blockType) {
        super(WindowType.Container, x, y, z, rotationIndex, blockType);
    }

    // Access block position
    public int getX() { return x; }
    public int getY() { return y; }
    public int getZ() { return z; }
    public int getRotationIndex() { return rotationIndex; }
    public BlockType getBlockType() { return blockType; }

    // Configure max interaction distance (default 7.0)
    public void setMaxDistance(double distance) {
        // Updates internal distance check
    }
}
```

The `BlockWindow.validate()` method checks:
1. Player reference exists
2. Player is within max distance
3. Chunk is loaded
4. Block at position matches original block type

### ContainerBlockWindow

Block-based container (chests, storage blocks, etc.).

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.ContainerBlockWindow;

// Create window for a block at position
ContainerBlockWindow window = new ContainerBlockWindow(
    x, y, z,           // Block position
    rotationIndex,     // Block rotation
    blockType,         // BlockType asset
    itemContainer      // ItemContainer for storage
);

// Window data includes blockItemId automatically
windowManager.openWindow(window);
```

### ItemStackContainerWindow

Window for an `ItemStackItemContainer` (items stored within other items, like backpacks).

```java
import com.hypixel.hytale.server.core.entity.entities.player.windows.ItemStackContainerWindow;
import com.hypixel.hytale.server.core.inventory.container.ItemStackItemContainer;

ItemStackItemContainer backpackContainer = // ... from item metadata
ItemStackContainerWindow window = new ItemStackContainerWindow(backpackContainer);
windowManager.openWindow(window);
```

Automatically closes when the parent item stack becomes invalid.

### Crafting Window Hierarchy

Crafting uses specialized bench configurations:

```
Bench (Base configuration)
├── CraftingBench
│   ├── DiagramCraftingBench (WindowType.DiagramCrafting)
│   └── (Basic crafting - WindowType.BasicCrafting)
├── StructuralCraftingBench (WindowType.StructuralCrafting)
└── ProcessingBench (WindowType.Processing)
```

**CraftingBench Categories:**

```java
// Access bench categories
CraftingBench bench = // ... from block config
BenchCategory[] categories = bench.getCategories();

for (BenchCategory category : categories) {
    String id = category.getId();
    String name = category.getName();
    String icon = category.getIcon();
    BenchItemCategory[] itemCategories = category.getItemCategories();
}
```

**StructuralCraftingBench:**

```java
StructuralCraftingBench bench = // ... from block config

// Check if category is a header
boolean isHeader = bench.isHeaderCategory("building");

// Get category sort order
int index = bench.getCategoryIndex("walls");

// Configuration flags
boolean allowCycling = bench.shouldAllowBlockGroupCycling();
boolean showHints = bench.shouldAlwaysShowInventoryHints();
```

## WindowAction System

Window actions are client-to-server messages for interacting with windows.

### Base WindowAction Class

```java
import com.hypixel.hytale.protocol.packets.window.WindowAction;

// Actions are deserialized from network packets
// Type ID determines the specific action class
```

### Action Types

| ID | Action Class | Description |
|----|--------------|-------------|
| 0 | `CraftRecipeAction` | Craft a specific recipe |
| 1 | `TierUpgradeAction` | Upgrade crafting tier |
| 2 | `SelectSlotAction` | Select a slot in the window |
| 3 | `ChangeBlockAction` | Cycle block variant |
| 4 | `SetActiveAction` | Set active state |
| 5 | `CraftItemAction` | Generic craft action |
| 6 | `UpdateCategoryAction` | Change crafting category |
| 7 | `CancelCraftingAction` | Cancel current craft |
| 8 | `SortItemsAction` | Sort container items |

### Built-in Actions

**CraftRecipeAction:**

```java
import com.hypixel.hytale.protocol.packets.window.CraftRecipeAction;

// Fields
String recipeId;   // Recipe identifier (nullable)
int quantity;      // Number to craft

// Example handling
public void handleAction(Ref<EntityStore> ref, Store<EntityStore> store, WindowAction action) {
    if (action instanceof CraftRecipeAction craftAction) {
        String recipe = craftAction.recipeId;
        int qty = craftAction.quantity;
        // Process crafting...
    }
}
```

**SelectSlotAction:**

```java
import com.hypixel.hytale.protocol.packets.window.SelectSlotAction;

// Fields
int slot;  // Selected slot index

// Creating an action
SelectSlotAction action = new SelectSlotAction(5);
```

**SortItemsAction:**

```java
import com.hypixel.hytale.protocol.packets.window.SortItemsAction;
import com.hypixel.hytale.protocol.SortType;

// Fields
SortType sortType;  // Name, Category, etc.

// Example from ContainerBlockWindow
@Override
public void handleAction(Ref<EntityStore> ref, Store<EntityStore> store, WindowAction action) {
    if (action instanceof SortItemsAction sortAction) {
        SortType sortType = SortType.fromPacket(sortAction.sortType);
        itemContainer.sortItems(sortType);
        invalidate();
    }
}
```

**UpdateCategoryAction:**

```java
import com.hypixel.hytale.protocol.packets.window.UpdateCategoryAction;

// Fields
String category;       // Main category
String itemCategory;   // Sub-category
```

**ChangeBlockAction:**

```java
import com.hypixel.hytale.protocol.packets.window.ChangeBlockAction;

// Fields
boolean down;  // Direction of change
```

**SetActiveAction:**

```java
import com.hypixel.hytale.protocol.packets.window.SetActiveAction;

// Fields
boolean state;  // New active state
```

### Handling Actions in Custom Windows

```java
import com.hypixel.hytale.protocol.packets.window.WindowAction;
import com.hypixel.hytale.component.Ref;
import com.hypixel.hytale.component.Store;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;

public class CustomWindow extends Window {

    @Override
    public void handleAction(
        @Nonnull Ref<EntityStore> ref,
        @Nonnull Store<EntityStore> store,
        @Nonnull WindowAction action
    ) {
        if (action instanceof SelectSlotAction selectAction) {
            int slot = selectAction.slot;
            handleSlotSelection(slot);
        } else if (action instanceof SortItemsAction sortAction) {
            handleSort(sortAction.sortType);
        }
        // Handle other action types...
    }
}
```

## Network Packets

### OpenWindow (Server -> Client)

Sent when opening a new window.

| Field | Type | Description |
|-------|------|-------------|
| `id` | int | Window ID (unique per player) |
| `windowType` | WindowType | Type of window |
| `windowData` | String | JSON data (nullable) |
| `inventory` | InventorySection | Item container data (nullable) |
| `extraResources` | ExtraResources | Extra resource data (nullable) |

**Packet ID:** 200

### UpdateWindow (Server -> Client)

Sent when window data/contents change.

| Field | Type | Description |
|-------|------|-------------|
| `id` | int | Window ID |
| `windowData` | String | Updated JSON data (nullable) |
| `inventory` | InventorySection | Updated inventory (nullable) |
| `extraResources` | ExtraResources | Updated resources (nullable) |

**Packet ID:** 201

### CloseWindow (Server -> Client)

Sent when closing a window.

| Field | Type | Description |
|-------|------|-------------|
| `id` | int | Window ID to close |

**Packet ID:** 202

### SendWindowAction (Client -> Server)

Sent when player performs an action in a window.

| Field | Type | Description |
|-------|------|-------------|
| `id` | int | Window ID |
| `action` | WindowAction | The action performed |

**Packet ID:** 203

### ClientOpenWindow (Client -> Server)

Sent when client requests to open a client-initiated window.

| Field | Type | Description |
|-------|------|-------------|
| `type` | WindowType | Requested window type |

**Packet ID:** 204

Only window types registered in `Window.CLIENT_REQUESTABLE_WINDOW_TYPES` can be opened this way.

## Complete Example: Custom Shop Window

```java
import com.google.gson.JsonObject;
import com.hypixel.hytale.component.Ref;
import com.hypixel.hytale.component.Store;
import com.hypixel.hytale.protocol.packets.window.SelectSlotAction;
import com.hypixel.hytale.protocol.packets.window.WindowAction;
import com.hypixel.hytale.protocol.packets.window.WindowType;
import com.hypixel.hytale.server.core.entity.entities.player.windows.ItemContainerWindow;
import com.hypixel.hytale.server.core.entity.entities.player.windows.Window;
import com.hypixel.hytale.server.core.inventory.container.ItemContainer;
import com.hypixel.hytale.server.core.inventory.container.SimpleItemContainer;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;

import javax.annotation.Nonnull;

public class ShopWindow extends Window implements ItemContainerWindow {
    private final JsonObject windowData = new JsonObject();
    private final ItemContainer shopInventory;
    private final String shopName;
    private int selectedSlot = -1;

    public ShopWindow(String shopName, int size) {
        super(WindowType.Container);
        this.shopName = shopName;
        this.shopInventory = new SimpleItemContainer((short) size);

        // Initialize window data
        windowData.addProperty("shopName", shopName);
        windowData.addProperty("selectedSlot", selectedSlot);
    }

    @Override
    @Nonnull
    public JsonObject getData() {
        windowData.addProperty("selectedSlot", selectedSlot);
        return windowData;
    }

    @Override
    protected boolean onOpen0() {
        // Load shop items into inventory
        loadShopItems();
        return true;
    }

    @Override
    protected void onClose0() {
        // Save any changes if needed
        saveShopState();
    }

    @Override
    @Nonnull
    public ItemContainer getItemContainer() {
        return shopInventory;
    }

    @Override
    public void handleAction(
        @Nonnull Ref<EntityStore> ref,
        @Nonnull Store<EntityStore> store,
        @Nonnull WindowAction action
    ) {
        if (action instanceof SelectSlotAction selectAction) {
            handleSlotSelection(ref, store, selectAction.slot);
        }
    }

    private void handleSlotSelection(
        Ref<EntityStore> ref,
        Store<EntityStore> store,
        int slot
    ) {
        if (slot >= 0 && slot < shopInventory.getCapacity()) {
            selectedSlot = slot;
            invalidate(); // Mark window as dirty to send update

            // Process purchase logic
            processPurchase(ref, store, slot);
        }
    }

    private void loadShopItems() {
        // Load items into shopInventory
    }

    private void saveShopState() {
        // Persist shop state
    }

    private void processPurchase(
        Ref<EntityStore> ref,
        Store<EntityStore> store,
        int slot
    ) {
        // Handle purchase logic
    }
}
```

**Using the Shop Window:**

```java
// In your plugin or command handler
public void openShopForPlayer(PlayerRef playerRef) {
    Player player = // ... get player component
    WindowManager windowManager = player.getWindowManager();

    ShopWindow shop = new ShopWindow("General Store", 27);
    OpenWindow packet = windowManager.openWindow(shop);

    if (packet != null) {
        // Window opened successfully

        // Register close handler
        shop.registerCloseEvent(event -> {
            System.out.println("Player closed the shop");
        });
    }
}
```

## Best Practices

1. **Always check `openWindow()` return value** - Returns null if window failed to open
2. **Clean up in `onClose0()`** - Unregister event handlers and release resources
3. **Use `invalidate()` for updates** - Let the server batch updates efficiently
4. **Implement `ValidatedWindow` for distance-based windows** - Prevents exploit abuse
5. **Handle all expected action types** - Don't ignore client actions silently
6. **Use JSON window data sparingly** - Large data payloads affect network performance
7. **Register close events for cleanup** - Ensure resources are freed when windows close
8. **Consider thread safety** - Window operations may occur on different threads
