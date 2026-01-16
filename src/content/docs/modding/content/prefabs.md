---
author: UnlimitedBytes
title: Prefab System
description: Create, load, save, and place prefab structures in Hytale.
sidebar:
  order: 4
---

The Prefab System allows you to create, save, and place pre-built structures containing blocks, fluids, entities, and nested child prefabs with rotation support.

## Architecture

```
PrefabStore (Singleton)
├── PREFAB_CACHE         - ConcurrentHashMap of cached BlockSelection objects
├── PREFABS_PATH         - Default path: "prefabs"
├── getPrefab()          - Load prefabs from disk (with caching)
├── savePrefab()         - Save prefabs to disk
└── Path resolution      - Server, Asset, WorldGen prefabs

BlockSelection
├── Block/Fluid/Entity data (thread-safe with ReentrantReadWriteLock)
├── Position and Anchor point
├── Selection bounds (min/max)
└── place()/placeNoReturn() methods
```

## PrefabStore

The `PrefabStore` singleton manages loading, saving, and caching prefabs:

```java
import com.hypixel.hytale.server.core.prefab.PrefabStore;
import com.hypixel.hytale.server.core.prefab.selection.standard.BlockSelection;
import java.nio.file.Path;
import java.util.Map;

PrefabStore store = PrefabStore.get();

// Load from different locations (relative to respective base paths)
BlockSelection serverPrefab = store.getServerPrefab("structures/house.prefab.json");
BlockSelection assetPrefab = store.getAssetPrefab("buildings/tower.prefab.json");
BlockSelection worldGenPrefab = store.getWorldGenPrefab("dungeons/cave.prefab.json");

// Load from any asset pack (returns null if not found)
BlockSelection anyPrefab = store.getAssetPrefabFromAnyPack("trees/oak.prefab.json");

// Load all prefabs from a directory
Map<Path, BlockSelection> prefabs = store.getServerPrefabDir("structures/houses");
Map<Path, BlockSelection> assetPrefabs = store.getAssetPrefabDir("buildings");
Map<Path, BlockSelection> worldGenPrefabs = store.getWorldGenPrefabDir("dungeons");

// Load from absolute path (with caching)
BlockSelection customPrefab = store.getPrefab(Path.of("/absolute/path/to/prefab.prefab.json"));
```

:::note
`getAssetPrefabFromAnyPack()` returns `@Nullable BlockSelection` - always check for null when using this method.
`getServerPrefab(...)`, `getAssetPrefab(...)`, and `getWorldGenPrefab(...)` are `@Nonnull` and throw `PrefabLoadException` if the file is missing.
:::

### Saving Prefabs

```java
BlockSelection selection = /* ... */;

// Save to server prefabs directory
store.saveServerPrefab("mystructure.prefab.json", selection, true);

// Save to asset prefabs directory
store.saveAssetPrefab("mystructure.prefab.json", selection, true);

// Save to world generation prefabs directory
store.saveWorldGenPrefab("mystructure.prefab.json", selection);
store.saveWorldGenPrefab("mystructure.prefab.json", selection, true);

// Save to custom absolute path
store.savePrefab(Path.of("/custom/path/structure.prefab.json"), selection, true);
```

:::caution
Saving a prefab will invalidate its cache entry. The `PrefabSaveException` is thrown with type `ALREADY_EXISTS` if the file exists and overwrite is false, or type `ERROR` for other I/O failures.
:::

:::caution
In the decompiled code, `saveServerPrefab(key, prefab)` and `saveAssetPrefab(key, prefab)` delegate to `saveWorldGenPrefab(...)`. Use the overloads with the `overwrite` flag if you need server or asset paths.
:::

## BlockSelection

The `BlockSelection` class represents a prefab's content. It is thread-safe, using `ReentrantReadWriteLock` for concurrent access to blocks and entities.

### Creating Selections

```java
import com.hypixel.hytale.server.core.prefab.selection.standard.BlockSelection;
import com.hypixel.hytale.math.vector.Vector3i;

// Create empty selection
BlockSelection selection = new BlockSelection();

// Create with initial capacity hints
BlockSelection optimized = new BlockSelection(1000, 10); // 1000 blocks, 10 entities

// Clone an existing selection
BlockSelection copy = new BlockSelection(existingSelection);

// Set world position (used as origin for local coordinates)
selection.setPosition(100, 64, 200);

// Set anchor point (offset applied when placing)
selection.setAnchor(0, 0, 0);

// Set anchor at world position (converts to local coordinates)
selection.setAnchorAtWorldPos(105, 64, 205);

// Set selection bounds
selection.setSelectionArea(
    new Vector3i(-5, 0, -5),  // min
    new Vector3i(5, 10, 5)    // max
);

// Copy properties from another selection
selection.copyPropertiesFrom(otherSelection);
```

### Adding Content

```java
import com.hypixel.hytale.server.core.asset.type.blocktype.config.BlockType;
import com.hypixel.hytale.server.core.asset.type.fluid.Fluid;
import com.hypixel.hytale.component.Holder;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;
import com.hypixel.hytale.server.core.universe.world.storage.ChunkStore;

// Add blocks at world position
int blockId = BlockType.getAssetMap().getAsset("hytale:stone").getBlockId();
selection.addBlockAtWorldPos(x, y, z, blockId, rotation, filler, supportValue);

// Add blocks with block state holder
Holder<ChunkStore> stateHolder = /* block entity data */;
selection.addBlockAtWorldPos(x, y, z, blockId, rotation, filler, supportValue, stateHolder);

// Add blocks at local position (relative to selection's position)
selection.addBlockAtLocalPos(localX, localY, localZ, blockId, rotation, filler, supportValue);

// Add empty block (air) at position
selection.addEmptyAtWorldPos(x, y, z);

// Add fluids
int fluidId = Fluid.getAssetMap().getAsset("hytale:water").getAssetIndex();
selection.addFluidAtWorldPos(x, y, z, fluidId, (byte) 8);
selection.addFluidAtLocalPos(localX, localY, localZ, fluidId, (byte) 8);

// Add entities (adjusts position relative to selection origin)
Holder<EntityStore> entityHolder = /* entity data */;
selection.addEntityFromWorld(entityHolder);

// Add entity without position adjustment
selection.addEntityHolderRaw(entityHolder);

// Copy block and fluid from world chunk
selection.copyFromAtWorld(x, y, z, worldChunk, blockPhysics);
```

### Querying Content

```java
// Check if block exists at position
boolean hasBlock = selection.hasBlockAtWorldPos(x, y, z);
boolean hasLocalBlock = selection.hasBlockAtLocalPos(localX, localY, localZ);

// Get block ID (returns Integer.MIN_VALUE if not found)
int blockId = selection.getBlockAtWorldPos(x, y, z);

// Get fluid ID and level
int fluidId = selection.getFluidAtWorldPos(x, y, z);     // Integer.MIN_VALUE if not found
byte fluidLevel = selection.getFluidLevelAtWorldPos(x, y, z); // 0 if not found

// Get support value (for physics)
int supportValue = selection.getSupportValueAtWorldPos(x, y, z);

// Get block state holder (for block entities)
Holder<ChunkStore> state = selection.getStateAtWorldPos(x, y, z); // nullable

// Get counts
int blockCount = selection.getBlockCount();
int fluidCount = selection.getFluidCount();
int entityCount = selection.getEntityCount();
int volume = selection.getSelectionVolume(); // xLength * yLength & zLength (bitwise AND)
```

### Iterating Content

```java
import com.hypixel.hytale.server.core.prefab.selection.standard.BlockSelection.BlockHolder;

// Iterate blocks (receives local coordinates and BlockHolder record)
selection.forEachBlock((x, y, z, block) -> {
    int blockId = block.blockId();
    int rotation = block.rotation();
    int filler = block.filler();
    int supportValue = block.supportValue();
    Holder<ChunkStore> holder = block.holder();
    // Process block...
});

// Iterate fluids
selection.forEachFluid((x, y, z, fluidId, fluidLevel) -> {
    // Process fluid...
});

// Iterate entities
selection.forEachEntity(entityHolder -> {
    // Process entity holder...
});

// Compare blocks (returns false to stop iteration)
boolean allMatch = selection.compare((x, y, z, block) -> {
    return block.blockId() != 0; // Check condition
});
```

## Placing Prefabs

### Basic Placement

```java
import com.hypixel.hytale.server.core.universe.world.World;
import com.hypixel.hytale.server.core.command.system.CommandSender;
import com.hypixel.hytale.component.ComponentAccessor;
import com.hypixel.hytale.component.Ref;
import com.hypixel.hytale.server.core.prefab.selection.mask.BlockMask;
import com.hypixel.hytale.server.core.prefab.selection.standard.FeedbackConsumer;

// Place at position (no undo support, no return value)
selection.placeNoReturn(world, new Vector3i(100, 64, 200), componentAccessor);

// Place with feedback sender (for progress reporting)
selection.placeNoReturn("feedbackKey", commandSender, world, componentAccessor);

// Place with custom feedback consumer
selection.placeNoReturn("feedbackKey", commandSender, FeedbackConsumer.DEFAULT, world, componentAccessor);

// Place with full options (position and block mask)
selection.placeNoReturn("feedbackKey", commandSender, FeedbackConsumer.DEFAULT, world,
    new Vector3i(100, 64, 200), blockMask, componentAccessor);

// Place with undo support (returns BlockSelection with previous state)
BlockSelection previousState = selection.place(commandSender, world);

// Place with block mask (exclude certain blocks from replacement)
BlockSelection previousState = selection.place(commandSender, world, blockMask);

// Place at specific position with mask
BlockSelection previousState = selection.place(commandSender, world,
    new Vector3i(100, 64, 200), blockMask);

// Undo the placement by placing the previous state
previousState.place(commandSender, world);
```

### Entity Callback

```java
import java.util.function.Consumer;

// Place with entity callback (called for each entity spawned)
Consumer<Ref<EntityStore>> entityCallback = entityRef -> {
    // Called for each entity placed in the world
    // entityRef is a reference to the spawned entity
    System.out.println("Entity spawned: " + entityRef);
};

BlockSelection previousState = selection.place(
    commandSender,
    world,
    new Vector3i(100, 64, 200),  // position (nullable)
    blockMask,                    // block mask (nullable)
    entityCallback
);
```

### World Matching

```java
// Check if selection can be placed (all target positions are air or in mask)
boolean canPlace = selection.canPlace(world, position, blockIdMask);

// Check if selection matches the world exactly at position
boolean matches = selection.matches(world, position);
```

## PrefabRotation

The `PrefabRotation` enum handles Y-axis rotation transformations for prefab placement:

```java
import com.hypixel.hytale.server.core.prefab.PrefabRotation;
import com.hypixel.hytale.math.vector.Vector3i;
import com.hypixel.hytale.math.vector.Vector3d;
import com.hypixel.hytale.math.vector.Vector3l;
import com.hypixel.hytale.server.core.asset.type.blocktype.config.Rotation;

// Available rotation values
PrefabRotation rot0 = PrefabRotation.ROTATION_0;
PrefabRotation rot90 = PrefabRotation.ROTATION_90;
PrefabRotation rot180 = PrefabRotation.ROTATION_180;
PrefabRotation rot270 = PrefabRotation.ROTATION_270;

// Access all values
PrefabRotation[] allRotations = PrefabRotation.VALUES;

// Parse from string (supports "90" or "ROTATION_90")
PrefabRotation parsed = PrefabRotation.valueOfExtended("90");

// Convert from Rotation enum
PrefabRotation fromRotation = PrefabRotation.fromRotation(Rotation.Ninety);

// Rotate vectors in-place (around Y axis)
Vector3i vec = new Vector3i(5, 0, 3);
rot90.rotate(vec);  // Modifies vec

Vector3d vecD = new Vector3d(5.0, 0.0, 3.0);
rot90.rotate(vecD);

Vector3l vecL = new Vector3l(5L, 0L, 3L);
rot90.rotate(vecL);

// Get rotated coordinates without modifying input
int newX = rot90.getX(originalX, originalZ);
int newZ = rot90.getZ(originalX, originalZ);

// Get yaw angle in radians
float yaw = rot90.getYaw();  // Returns -PI/2 for 90 degrees

// Combine rotations (adds degrees, wraps at 360)
PrefabRotation combined = rot90.add(PrefabRotation.ROTATION_180);  // Returns ROTATION_270

// Get rotated block rotation index
int rotatedBlockRotation = rot90.getRotation(blockRotationIndex);

// Get rotated filler block offset
int rotatedFiller = rot90.getFiller(fillerPackedValue);
```

### Transforming Selections

```java
import com.hypixel.hytale.math.Axis;
import com.hypixel.hytale.math.vector.Vector3f;

// Rotate around any axis by angle (90 degree increments)
BlockSelection rotatedY = selection.rotate(Axis.Y, 90);
BlockSelection rotatedX = selection.rotate(Axis.X, 180);
BlockSelection rotatedZ = selection.rotate(Axis.Z, 270);

// Rotate around a custom origin point
Vector3f origin = new Vector3f(50.0f, 64.0f, 50.0f);
BlockSelection rotatedAroundOrigin = selection.rotate(Axis.Y, 90, origin);

// Arbitrary rotation (any angle, not limited to 90 degrees)
BlockSelection arbitraryRotation = selection.rotateArbitrary(45.0f, 0.0f, 0.0f);

// Flip (mirror) along axis
BlockSelection flippedX = selection.flip(Axis.X);
BlockSelection flippedY = selection.flip(Axis.Y);
BlockSelection flippedZ = selection.flip(Axis.Z);

// Clone the selection
BlockSelection clone = selection.cloneSelection();

// Relativize coordinates (shift to origin)
BlockSelection relativized = selection.relativize();
BlockSelection relativizedCustom = selection.relativize(originX, originY, originZ);

// Merge another selection into this one
selection.add(otherSelection);
```

## PrefabWeights

Handle weighted random selection for prefabs:

```java
import com.hypixel.hytale.server.core.prefab.PrefabWeights;
import java.util.Random;
import java.util.function.Function;

// Create new weights instance
PrefabWeights weights = new PrefabWeights();

// Set weights for specific prefabs
weights.setWeight("oak_tree", 3.0);
weights.setWeight("birch_tree", 2.0);

// Set default weight for unlisted prefabs (default is 1.0)
weights.setDefaultWeight(1.0);

// Get weight for a specific prefab (returns default if not set)
double weight = weights.getWeight("oak_tree");  // Returns 3.0
double defaulted = weights.getWeight("pine_tree");  // Returns 1.0 (default)

// Remove a specific weight
weights.removeWeight("birch_tree");

// Select weighted random element from array
Random random = new Random();
String[] names = {"oak_tree", "birch_tree", "pine_tree"};
Function<String, String> nameExtractor = name -> name;  // Identity function
String selected = weights.get(names, nameExtractor, random);

// Select with specific random value (0.0 to 1.0)
String selectedWithValue = weights.get(names, nameExtractor, 0.5);

// Parse from string format "name=weight, name2=weight2"
PrefabWeights parsed = PrefabWeights.parse("oak=3.0, birch=2.0");

// Get mapping as string
String mappingString = weights.getMappingString();  // "oak_tree=3.0, birch_tree=2.0"

// Get number of explicitly set weights
int size = weights.size();

// Empty weights singleton (always returns null from get())
PrefabWeights none = PrefabWeights.NONE;

// Iterate over entries
for (var entry : weights.entrySet()) {
    String name = entry.getKey();
    double w = entry.getDoubleValue();
}
```

:::note
`PrefabWeights.NONE` is an immutable singleton that ignores all setWeight calls and always returns null from `get()`.
:::

## PrefabCopyableComponent

Mark entities as copyable when saving prefabs:

```java
import com.hypixel.hytale.server.core.prefab.PrefabCopyableComponent;
import com.hypixel.hytale.component.ComponentType;
import com.hypixel.hytale.component.Holder;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;

// Get the component type (registered via EntityModule)
ComponentType<EntityStore, PrefabCopyableComponent> componentType =
    PrefabCopyableComponent.getComponentType();

// Get the singleton instance
PrefabCopyableComponent instance = PrefabCopyableComponent.get();

// Add to entity to include in prefab copies
Holder<EntityStore> entityHolder = /* your entity */;
entityHolder.addComponent(componentType, instance);
```

:::note
Entities without the `PrefabCopyableComponent` may not be included when copying regions to prefabs. This component uses a singleton pattern - `PrefabCopyableComponent.INSTANCE` - so all entities share the same component instance.
:::

## Related Classes

### PrefabLoadException

Thrown when a prefab fails to load:

```java
import com.hypixel.hytale.server.core.prefab.PrefabLoadException;

try {
    BlockSelection prefab = store.getServerPrefab("nonexistent.prefab.json");
} catch (PrefabLoadException e) {
    if (e.getType() == PrefabLoadException.Type.NOT_FOUND) {
        // Prefab file does not exist
    }
}
```

### PrefabSaveException

Thrown when a prefab fails to save:

```java
import com.hypixel.hytale.server.core.prefab.PrefabSaveException;

try {
    store.saveServerPrefab("existing.prefab.json", selection);
} catch (PrefabSaveException e) {
    switch (e.getType()) {
        case ALREADY_EXISTS -> { /* File exists and overwrite=false */ }
        case ERROR -> { /* I/O error occurred */ }
    }
}
```

### BlockMask

Filter which blocks are affected during placement:

```java
import com.hypixel.hytale.server.core.prefab.selection.mask.BlockMask;
import com.hypixel.hytale.server.core.prefab.selection.mask.BlockFilter;

// Empty mask (allows all blocks)
BlockMask empty = BlockMask.EMPTY;

// Parse from string (comma or semicolon separated filter expressions)
BlockMask parsed = BlockMask.parse("hytale:stone,hytale:dirt");
BlockMask parsedAlt = BlockMask.parse("hytale:stone;hytale:dirt");

// Parse from array of filter strings
BlockMask fromArray = BlockMask.parse(new String[]{"hytale:stone", "hytale:dirt"});

// Combine multiple masks
BlockMask combined = BlockMask.combine(mask1, mask2, mask3);

// Configure filter options
BlockMask configured = mask.withOptions(BlockFilter.FilterType.BLOCK, true);

// Invert the mask
mask.setInverted(true);
boolean inverted = mask.isInverted();

// Check if position should be excluded
boolean excluded = mask.isExcluded(accessor, x, y, z, min, max, blockId);
boolean excludedWithFluid = mask.isExcluded(accessor, x, y, z, min, max, blockId, fluidId);

// Get filters
BlockFilter[] filters = mask.getFilters();

// Convert to string representation
String maskString = mask.toString();  // e.g., "hytale:stone,hytale:dirt"
String verbose = mask.informativeToString();  // Human-readable format

// Use during placement
selection.place(feedback, world, position, mask);
```

### FeedbackConsumer

Progress callback during placement operations:

```java
import com.hypixel.hytale.server.core.prefab.selection.standard.FeedbackConsumer;

// Default implementation (no-op)
FeedbackConsumer defaultConsumer = FeedbackConsumer.DEFAULT;

// Custom progress tracking
FeedbackConsumer progressConsumer = (feedbackKey, total, current, sender, accessor) -> {
    double percent = (current * 100.0) / total;
    System.out.printf("Placing blocks: %.1f%%\n", percent);
};

selection.placeNoReturn("myKey", commandSender, progressConsumer, world, componentAccessor);
```
