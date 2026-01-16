---
author: UnlimitedBytes
title: Inventory and Items System
description: Manage player inventories, item stacks, and create custom items in your Hytale plugins.
sidebar:
  order: 3
---

The Hytale inventory system provides comprehensive APIs for managing player inventories, item containers, and item manipulation.

## Architecture

```
Inventory (Player inventory manager)
├── ItemContainer (Storage, Hotbar, Armor, Utility, Backpack, Tools)
│   └── ItemStack (Individual item instances - mutable; most with* methods return new stacks)
└── CombinedItemContainer (Combined views of multiple containers)

Item (Asset definition)
├── ItemWeapon (Weapon configuration)
├── ItemArmor (Armor configuration)
├── ItemTool (Tool configuration)
├── ItemUtility (Utility item configuration)
└── ItemCategory (Categorization for UI)
```

## Inventory Sections

| Section | ID Constant | Capacity | Description |
|---------|-------------|----------|-------------|
| Hotbar | `HOTBAR_SECTION_ID` (-1) | 9 | Quick-access slots |
| Storage | `STORAGE_SECTION_ID` (-2) | 36 | Main inventory (4x9 grid) |
| Armor | `ARMOR_SECTION_ID` (-3) | 4 | Equipment slots |
| Utility | `UTILITY_SECTION_ID` (-5) | 4 | Utility item slots |
| Tools | `TOOLS_SECTION_ID` (-8) | 23 | Tool item slots |
| Backpack | `BACKPACK_SECTION_ID` (-9) | Variable | Extra storage |

## Accessing Inventory

```java
import com.hypixel.hytale.server.core.inventory.Inventory;
import com.hypixel.hytale.server.core.inventory.ItemStack;
import com.hypixel.hytale.server.core.inventory.container.ItemContainer;
import com.hypixel.hytale.server.core.entity.LivingEntity;

// Get player's inventory (Player extends LivingEntity)
LivingEntity entity = // ... obtain entity reference
Inventory inventory = entity.getInventory();

// Access individual sections
ItemContainer hotbar = inventory.getHotbar();
ItemContainer storage = inventory.getStorage();
ItemContainer armor = inventory.getArmor();
ItemContainer utility = inventory.getUtility();
ItemContainer tools = inventory.getTools();
ItemContainer backpack = inventory.getBackpack();

// Get section by ID (returns null if not found)
ItemContainer section = inventory.getSectionById(Inventory.HOTBAR_SECTION_ID);
```

## Active Slot Management

```java
// Get/set active hotbar slot (0-8)
byte activeSlot = inventory.getActiveHotbarSlot();
inventory.setActiveHotbarSlot((byte) 3); // also sets usingToolsItem=false

// Get item currently in hand (returns active hotbar or tools item)
ItemStack itemInHand = inventory.getItemInHand();
ItemStack activeHotbarItem = inventory.getActiveHotbarItem();

// Utility slot management
byte utilitySlot = inventory.getActiveUtilitySlot();
inventory.setActiveUtilitySlot((byte) 1);
ItemStack utilityItem = inventory.getUtilityItem();

// Tools slot management
byte toolsSlot = inventory.getActiveToolsSlot();
inventory.setActiveToolsSlot((byte) 0);  // also sets usingToolsItem=true
ItemStack toolsItem = inventory.getToolsItem();

// Check if using tools item vs hotbar
boolean usingTools = inventory.usingToolsItem();
inventory.setUsingToolsItem(true);
```

## Moving Items

```java
import com.hypixel.hytale.protocol.SmartMoveType;

// Move item between sections
inventory.moveItem(
    Inventory.STORAGE_SECTION_ID,  // From section
    5,                              // From slot
    32,                             // Quantity
    Inventory.HOTBAR_SECTION_ID,   // To section
    0                               // To slot
);

// Smart move (auto-equip armor, merge stacks)
// SmartMoveType options: EquipOrMergeStack, PutInHotbarOrWindow, PutInHotbarOrBackpack
inventory.smartMoveItem(
    Inventory.STORAGE_SECTION_ID,
    10,
    1,
    SmartMoveType.EquipOrMergeStack
);

// Take all items from a window into inventory
inventory.takeAll(windowSectionId);

// Put all storage items into a window
inventory.putAll(windowSectionId);

// Quick stack to window (only matching items)
inventory.quickStack(windowSectionId);

// Drop all items from inventory
List<ItemStack> droppedItems = inventory.dropAllItemStacks();

// Clear entire inventory
inventory.clear();
```

## ItemStack

`ItemStack` represents a stack of items with quantity, durability, and metadata. Most `with*` methods return a new instance, but the class is not strictly immutable (for example, `setOverrideDroppedItemAnimation(...)` mutates the stack).

### Creating ItemStacks

```java
import com.hypixel.hytale.server.core.inventory.ItemStack;
import org.bson.BsonDocument;

// Basic creation
ItemStack stack = new ItemStack("Stone");
ItemStack stackWithQuantity = new ItemStack("Stone", 64);

// With metadata
BsonDocument metadata = new BsonDocument();
metadata.put("CustomData", new BsonString("value"));
ItemStack stackWithMeta = new ItemStack("Stone", 64, metadata);

// With full parameters (durability)
ItemStack fullStack = new ItemStack(
    "DiamondSword",   // Item ID
    1,                // Quantity
    100.0,            // Current durability
    100.0,            // Max durability
    metadata          // Metadata (nullable)
);

// Empty stack constant
ItemStack empty = ItemStack.EMPTY;
```

Note: `ItemStack` constructors throw if `itemId` is `"Empty"` or `quantity <= 0`.

### ItemStack Properties

```java
import com.hypixel.hytale.server.core.asset.type.item.config.Item;

// Basic properties
String itemId = stack.getItemId();
int quantity = stack.getQuantity();
Item item = stack.getItem();  // Returns Item.UNKNOWN if not found

// Durability
double durability = stack.getDurability();
double maxDurability = stack.getMaxDurability();
boolean isBroken = stack.isBroken();           // True if durability == 0 and has durability
boolean isUnbreakable = stack.isUnbreakable(); // True if maxDurability <= 0

// Validation
boolean isEmpty = stack.isEmpty();              // True if itemId equals "Empty"
boolean isValid = stack.isValid();              // True if empty or if getItem() is non-null (Item.UNKNOWN for missing)

// Block-related (for placeable items)
String blockKey = stack.getBlockKey();          // "Empty" if empty, otherwise block ID or null

// Metadata (deprecated, use getFromMetadataOrNull)
BsonDocument meta = stack.getMetadata();        // Returns cloned metadata or null
```

### Modifying ItemStacks

Most modification methods return a **new** ItemStack instance. `setOverrideDroppedItemAnimation(...)` mutates the existing stack.

```java
// Quantity (returns new ItemStack, or null if quantity is 0)
ItemStack modified = stack.withQuantity(32);

// Durability (clamped between 0 and maxDurability)
ItemStack withDur = stack.withDurability(50.0);
ItemStack damaged = stack.withIncreasedDurability(-10.0);  // Reduce by 10
ItemStack newMax = stack.withMaxDurability(200.0);
ItemStack restored = stack.withRestoredDurability(100.0);  // Sets both to 100

// Metadata modifications
ItemStack withMeta = stack.withMetadata(newMetadataDoc);
ItemStack withKey = stack.withMetadata("CustomKey", bsonValue);

// Mutating flag
stack.setOverrideDroppedItemAnimation(true);

// State changes (for items with states)
ItemStack withState = stack.withState("activated");

// Stacking checks
boolean canStack = stack.isStackableWith(otherStack);      // Same type + durability + metadata
boolean sameType = stack.isEquivalentType(otherStack);     // Same type + metadata (ignores durability)

// Static helpers
boolean isEmpty = ItemStack.isEmpty(stack);                 // null-safe
boolean stackable = ItemStack.isStackableWith(a, b);        // null-safe
boolean sameItem = ItemStack.isSameItemType(a, b);          // Just checks itemId
```

## ItemContainer

`ItemContainer` is an abstract class managing a collection of item slots. Note that slot indices use `short` type.

### Basic Operations

```java
import com.hypixel.hytale.server.core.inventory.container.ItemContainer;
import com.hypixel.hytale.server.core.inventory.transaction.*;

// Get item at slot (uses short for slot index)
ItemStack item = container.getItemStack((short) 0);

// Set item at slot (returns transaction with success/failure info)
ItemStackSlotTransaction setTx = container.setItemStackForSlot((short) 0, new ItemStack("Stone", 32));
if (setTx.succeeded()) {
    // Item was set successfully
}

// Add items to slot (stacks with existing or places in empty)
ItemStackSlotTransaction addTx = container.addItemStackToSlot((short) 0, new ItemStack("Stone", 64));

// Add items (finds available slots automatically)
ItemStackTransaction tx = container.addItemStack(new ItemStack("Stone", 64));
ItemStack remainder = tx.getRemainder();  // Items that couldn't fit

// Remove items from slot
SlotTransaction removeTx = container.removeItemStackFromSlot((short) 0);
ItemStackSlotTransaction removeQtyTx = container.removeItemStackFromSlot((short) 0, 16);  // Remove specific quantity

// Clear container
ClearTransaction clearTx = container.clear();
```

### Adding Multiple Items

```java
import java.util.List;
import java.util.Arrays;

List<ItemStack> items = Arrays.asList(
    new ItemStack("Stone", 64),
    new ItemStack("Wood", 32)
);

// Check if items can be added
boolean canAdd = container.canAddItemStacks(items);

// Add all items
ListTransaction<ItemStackTransaction> addAllTx = container.addItemStacks(items);

// Add items in order (fills slots sequentially)
ListTransaction<ItemStackSlotTransaction> orderedTx = container.addItemStacksOrdered(items);
```

### Searching and Querying

```java
// Get capacity
short capacity = container.getCapacity();

// Check if empty
boolean isEmpty = container.isEmpty();

// Count items matching predicate
int count = container.countItemStacks(itemStack ->
    itemStack.getItemId().equals("Stone"));

// Check for stackable items
boolean hasStackable = container.containsItemStacksStackableWith(new ItemStack("Stone"));

// Iterate over all items
container.forEach((slot, itemStack) -> {
    System.out.println("Slot " + slot + ": " + itemStack.getItemId());
});
```

### Moving Items Between Containers

```java
// Move item from one container to another
MoveTransaction<ItemStackTransaction> moveTx = sourceContainer.moveItemStackFromSlot(
    (short) 0,       // Source slot
    targetContainer  // Destination container
);

// Move specific quantity to specific slot
MoveTransaction<SlotTransaction> moveSlotTx = sourceContainer.moveItemStackFromSlotToSlot(
    (short) 0,       // Source slot
    32,              // Quantity
    targetContainer, // Destination container
    (short) 5        // Destination slot
);

// Move all items to another container(s)
ListTransaction<MoveTransaction<ItemStackTransaction>> moveAllTx =
    container.moveAllItemStacksTo(targetContainer1, targetContainer2);

// Quick stack (move only items that match existing items in target)
ListTransaction<MoveTransaction<ItemStackTransaction>> quickTx =
    container.quickStackTo(targetContainer);
```

### Removing Items

```java
// Check if item can be removed
boolean canRemove = container.canRemoveItemStack(new ItemStack("Stone", 32));

// Remove specific ItemStack (finds matching items)
ItemStackTransaction removeTx = container.removeItemStack(new ItemStack("Stone", 32));

// Remove all items
List<ItemStack> removed = container.removeAllItemStacks();

// Drop all items (for use with world drop)
List<ItemStack> dropped = container.dropAllItemStacks();
```

## Item Types

### Item and ItemCategory

`Item` is an asset class representing item definitions loaded from data files. `ItemCategory` is also an asset class (not an enum) used for UI categorization.

```java
import com.hypixel.hytale.server.core.asset.type.item.config.Item;
import com.hypixel.hytale.server.core.asset.type.item.config.ItemCategory;
import com.hypixel.hytale.server.core.asset.type.item.config.ItemWeapon;
import com.hypixel.hytale.server.core.asset.type.item.config.ItemArmor;
import com.hypixel.hytale.server.core.asset.type.item.config.ItemTool;
import com.hypixel.hytale.server.core.asset.type.item.config.ItemUtility;

// Get item from asset registry
Item item = (Item) Item.getAssetMap().getAsset("DiamondSword");

// Basic properties
String id = item.getId();                    // Item identifier
int maxStack = item.getMaxStack();           // Max stack size
double maxDurability = item.getMaxDurability();

// Item subtypes (return null if not applicable)
ItemWeapon weapon = item.getWeapon();        // Weapon configuration
ItemArmor armor = item.getArmor();           // Armor configuration
ItemTool tool = item.getTool();              // Tool configuration
ItemUtility utility = item.getUtility();     // Utility configuration

// Block-related
boolean hasBlock = item.hasBlockType();
String blockId = item.getBlockId();          // Associated block ID

// Quality and appearance
int qualityIndex = item.getQualityIndex();
String model = item.getModel();
float scale = item.getScale();
```

### ItemCategory

```java
// ItemCategory is an asset, not an enum
ItemCategory category = (ItemCategory) ItemCategory.getAssetMap().getAsset("Weapons");

String categoryId = category.getId();
String categoryName = category.getName();
String icon = category.getIcon();
int order = category.getOrder();
ItemCategory[] children = category.getChildren();  // Subcategories
```

## Giving Items to Players

```java
// Via inventory (using combined container for automatic slot finding)
CombinedItemContainer combined = inventory.getCombinedHotbarFirst();
ItemStackTransaction tx = combined.addItemStack(new ItemStack("Stone", 64));

// Or directly to storage/hotbar
inventory.getStorage().addItemStack(new ItemStack("Stone", 64));
inventory.getHotbar().addItemStack(new ItemStack("Stone", 64));

// Check for any broken items in inventory
boolean hasBroken = inventory.containsBrokenItem();
```

## Item Events

```java
import com.hypixel.hytale.server.core.event.events.ecs.DropItemEvent;
import com.hypixel.hytale.server.core.event.events.ecs.InteractivelyPickupItemEvent;
import com.hypixel.hytale.server.core.event.events.entity.LivingEntityInventoryChangeEvent;
import com.hypixel.hytale.server.core.inventory.container.ItemContainer;
import com.hypixel.hytale.server.core.inventory.transaction.Transaction;

// Item dropped (extends CancellableEcsEvent)
getEventRegistry().register(DropItemEvent.class, event -> {
    // DropItemEvent is cancellable
    event.setCancelled(true);  // Prevent drop
});

// Item picked up (extends CancellableEcsEvent)
getEventRegistry().register(InteractivelyPickupItemEvent.class, event -> {
    ItemStack pickedUp = event.getItemStack();
    event.setItemStack(modifiedStack);  // Modify the item being picked up
    event.setCancelled(true);           // Prevent pickup
});

// Inventory change
getEventRegistry().register(LivingEntityInventoryChangeEvent.class, event -> {
    LivingEntity entity = event.getEntity();
    ItemContainer container = event.getItemContainer();
    Transaction transaction = event.getTransaction();
    // Handle inventory modification
});
```

## Best Practices

1. **Use section constants** - Reference sections by ID for consistency
2. **Check slot bounds** - Validate slot indices before access
3. **Handle remainders** - `addItem` returns unfitted quantity
4. **Clone ItemStacks** - Copy before modification to avoid side effects
5. **Use smart moves** - `smartMoveItem` handles armor equipping automatically
6. **Listen to events** - Track inventory changes through events
7. **Validate ItemStacks** - Check `isEmpty()` before operations
