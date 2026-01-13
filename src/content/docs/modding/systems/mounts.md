---
title: Mounts System
description: Understanding the mounts system in Hytale, including block mounts, NPC mounts, mount controllers, and minecarts
---

The mounts system in Hytale allows entities to ride other entities or mount blocks. The system handles seats, beds, minecarts, and rideable NPCs with configurable mount points and controllers.

## Core Components

### MountedComponent

Located in `com.hypixel.hytale.builtin.mounts`, this component indicates that an entity is currently mounted on something.

```java
public class MountedComponent implements Component<EntityStore> {
    private Ref<EntityStore> mountedToEntity;
    private Ref<ChunkStore> mountedToBlock;
    private MountController controller;
    private BlockMountType blockMountType;
    private Vector3f attachmentOffset;
    private long mountStartMs;
    private boolean isNetworkOutdated;
}
```

**Fields:**
- `mountedToEntity` - Reference to the entity being mounted (for NPC/entity mounts)
- `mountedToBlock` - Reference to the block being mounted (for block mounts)
- `controller` - The type of mount controller (BlockMount, Minecart, etc.)
- `blockMountType` - Type of block mount (Seat, Bed)
- `attachmentOffset` - Offset from the mount point
- `mountStartMs` - Timestamp when mounting started
- `isNetworkOutdated` - Flag for network synchronization

**Methods:**
- `getMountedToEntity()` - Get the mounted entity reference
- `getMountedToBlock()` - Get the mounted block reference
- `getControllerType()` - Get the mount controller type
- `getBlockMountType()` - Get the block mount type (Seat/Bed)
- `getMountedDurationMs()` - Get how long the entity has been mounted

### MountedByComponent

This component indicates that an entity has passengers/riders.

```java
public class MountedByComponent implements Component<EntityStore> {
    private final List<Ref<EntityStore>> passengers;
}
```

**Methods:**
- `getPassengers()` - Get list of all passengers (auto-removes invalid refs)
- `addPassenger(Ref<EntityStore>)` - Add a passenger
- `removePassenger(Ref<EntityStore>)` - Remove a passenger
- `withPassenger(Ref<EntityStore>)` - Builder-style passenger addition

### BlockMountComponent

Located on block entities, this component manages mount points on blocks.

```java
public class BlockMountComponent implements Component<ChunkStore> {
    private BlockMountType type;
    private Vector3i blockPos;
    private BlockType expectedBlockType;
    private int expectedRotation;
    private Map<BlockMountPoint, Ref<EntityStore>> entitiesByMountPoint;
    private Map<Ref<EntityStore>, BlockMountPoint> mountPointByEntity;
}
```

**Fields:**
- `type` - Mount type (Seat or Bed)
- `blockPos` - World position of the block
- `expectedBlockType` - The block type that should be at this position
- `expectedRotation` - Expected rotation of the block
- `entitiesByMountPoint` - Maps mount points to seated entities
- `mountPointByEntity` - Reverse mapping for quick lookup

**Methods:**
- `putSeatedEntity(BlockMountPoint, Ref<EntityStore>)` - Seat an entity at a mount point
- `removeSeatedEntity(Ref<EntityStore>)` - Remove a seated entity
- `getSeatBlockBySeatedEntity(Ref<EntityStore>)` - Get the mount point an entity is using
- `getSeatedEntities()` - Get all seated entities
- `findAvailableSeat(Vector3i, BlockMountPoint[], Vector3f)` - Find the closest available seat
- `isDead()` - Check if component should be removed (no seated entities)

### NPCMountComponent

This component marks an NPC as a rideable mount.

```java
public class NPCMountComponent implements Component<EntityStore> {
    private int originalRoleIndex;
    private PlayerRef ownerPlayerRef;
    private float anchorX, anchorY, anchorZ;
}
```

**Fields:**
- `originalRoleIndex` - The NPC's original role before being mounted
- `ownerPlayerRef` - Reference to the player riding this mount
- `anchorX/Y/Z` - Anchor point for the rider

**Methods:**
- `getOriginalRoleIndex()` - Get the original NPC role
- `getOwnerPlayerRef()` - Get the riding player
- `setAnchor(float, float, float)` - Set the rider anchor position

### MinecartComponent

This component represents a minecart entity.

```java
public class MinecartComponent implements Component<EntityStore> {
    private int numberOfHits;
    private Instant lastHit;
    private String sourceItem = "Rail_Kart";
}
```

**Fields:**
- `numberOfHits` - Number of times the minecart has been hit
- `lastHit` - Timestamp of last hit
- `sourceItem` - Item ID used to create this minecart

## Mount Types

### Block Mounts

Block mounts allow entities to sit on or lie in blocks.

#### BlockMountType

```java
public enum BlockMountType {
    Seat,  // Sitting position
    Bed    // Lying position
}
```

#### Block Mount Points

Mount points are defined in block assets using `BlockMountPoint`:

```java
public class BlockMountPoint {
    // Position and rotation relative to block
    public Vector3f computeWorldSpacePosition(Vector3i blockPos);
    public Vector3f computeRotationEuler(int blockRotation);
}
```

Block types can define mount points in their asset configuration:
- **Seats** - Chair-like sitting positions
- **Beds** - Lying positions for sleeping

### Entity Mounts

Entity mounts allow entities to ride other entities (NPCs, vehicles, etc.).

#### MountController Types

```java
public enum MountController {
    BlockMount,  // Mounted on a block
    Minecart,    // Riding in a minecart
    // Additional controllers for different mount types
}
```

### Minecarts

Minecarts are special entities that can be mounted and move on rails.

**Features:**
- Created from items (default: "Rail_Kart")
- Track number of hits for destruction
- Custom mount controller behavior
- Rail-based movement system

## Mount Systems

### Block Mounting System

The `BlockMountAPI` provides utilities for mounting entities on blocks.

#### Mounting Process

```java
public static BlockMountResult mountOnBlock(
    Ref<EntityStore> entity,
    CommandBuffer<EntityStore> commandBuffer,
    Vector3i targetBlock,
    Vector3f interactPos
)
```

**Process:**
1. Check entity isn't already mounted
2. Validate chunk and block exist
3. Get or create block entity reference
4. Determine mount type (Seat or Bed)
5. Get mount points from block type
6. Find available mount point closest to interaction position
7. Create `BlockMountComponent` if needed
8. Position entity at mount point
9. Add `MountedComponent` to entity
10. Register entity in mount point map

**Return Types:**

```java
public sealed interface BlockMountResult {
    record Mounted(BlockType blockType, MountedComponent component);
    enum DidNotMount {
        CHUNK_NOT_FOUND,
        CHUNK_REF_NOT_FOUND,
        BLOCK_REF_NOT_FOUND,
        INVALID_BLOCK,
        ALREADY_MOUNTED,
        UNKNOWN_BLOCKMOUNT_TYPE,
        NO_MOUNT_POINT_FOUND
    }
}
```

### Mount System Events

#### MountedEntityDeath

Handles cleanup when a mounted entity dies:

```java
public static class MountedEntityDeath extends RefChangeSystem<EntityStore, DeathComponent> {
    @Override
    public Query<EntityStore> getQuery() {
        return MountedComponent.getComponentType();
    }
}
```

Removes the entity from mount point when death component is added.

#### Dismount Handling

When `MountedComponent` is removed, the system:
1. Removes passenger from `MountedByComponent` of mount
2. Removes entity from `BlockMountComponent` if block mount
3. Cleans up block component if no remaining passengers

### NPC Mount Systems

#### NPCMountSystems.OnAdd

Handles NPC mount setup when component is added:

```java
public static class OnAdd extends RefSystem<EntityStore> {
    @Override
    public void onEntityAdded(Ref<EntityStore> ref, AddReason reason,
                             Store<EntityStore> store, CommandBuffer<EntityStore> commandBuffer) {
        NPCMountComponent mountComponent = store.getComponent(ref, type);
        PlayerRef playerRef = mountComponent.getOwnerPlayerRef();
        
        if (playerRef != null) {
            // Send mount packet to player
            MountNPC packet = new MountNPC(anchorX, anchorY, anchorZ, networkId);
            playerComponent.setMountEntityId(networkId);
            playerRef.getPacketHandler().write(packet);
        } else {
            // Reset to original role if no owner
            resetOriginalRoleMount(ref, store, commandBuffer, mountComponent);
        }
    }
}
```

#### Death Handling

**DismountOnMountDeath** - When the mount dies
- Removes player from mount
- Resets player movement settings

**DismountOnPlayerDeath** - When the rider dies  
- Dismounts the player from any NPC mount
- Cleans up mount state

## Mount Interactions

### Seating Interaction

```java
public class SeatingInteraction {
    // Handles clicking on seats to sit
}
```

Located in `com.hypixel.hytale.builtin.mounts.interactions`.

### Mount Interaction

```java
public class MountInteraction {
    // Handles mounting entities
}
```

### Spawn Minecart Interaction

```java
public class SpawnMinecartInteraction {
    // Handles spawning minecarts from items
}
```

## Mount Commands

### MountCommand

Allows mounting entities via command.

```java
public class MountCommand {
    // Command: /mount <entity>
}
```

### DismountCommand

Forces dismounting.

```java
public class DismountCommand {
    // Command: /dismount
}
```

### MountCheckCommand

Checks mount state.

```java
public class MountCheckCommand {
    // Command: /mountcheck
}
```

## Using the Mounts System

### Mounting on a Block

```java
// Player clicks on a chair
Vector3i blockPos = new Vector3i(x, y, z);
Vector3f clickPos = new Vector3f(clickX, clickY, clickZ);

BlockMountAPI.BlockMountResult result = BlockMountAPI.mountOnBlock(
    playerRef,
    commandBuffer,
    blockPos,
    clickPos
);

if (result instanceof BlockMountAPI.Mounted mounted) {
    // Successfully mounted
    BlockType blockType = mounted.blockType();
    MountedComponent component = mounted.component();
} else if (result instanceof BlockMountAPI.DidNotMount error) {
    // Handle error
    switch (error) {
        case ALREADY_MOUNTED -> // Already sitting
        case NO_MOUNT_POINT_FOUND -> // No available seat
        // ... other cases
    }
}
```

### Dismounting

```java
// Remove the MountedComponent to dismount
commandBuffer.removeComponent(entityRef, MountedComponent.getComponentType());

// System automatically handles cleanup
```

### Creating a Rideable NPC

```java
// Add NPCMountComponent to an NPC
NPCMountComponent mountComponent = new NPCMountComponent();
mountComponent.setOriginalRoleIndex(npc.getRoleIndex());
mountComponent.setOwnerPlayerRef(playerRef);
mountComponent.setAnchor(0f, 1.5f, 0f);

commandBuffer.addComponent(npcRef, NPCMountComponent.getComponentType(), mountComponent);
```

### Spawning a Minecart

```java
// Create minecart entity
Holder<EntityStore> minecartHolder = EntityStore.REGISTRY.newHolder();

// Add MinecartComponent
MinecartComponent minecart = new MinecartComponent("Rail_Kart");
minecartHolder.putComponent(MinecartComponent.getComponentType(), minecart);

// Add other required components (Transform, NetworkId, etc.)
// ...

// Spawn the entity
Ref<EntityStore> minecartRef = store.addEntity(minecartHolder, AddReason.SPAWN);
```

### Checking Mount State

```java
// Check if entity is mounted
MountedComponent mounted = store.getComponent(entityRef, MountedComponent.getComponentType());
if (mounted != null) {
    if (mounted.getMountedToEntity() != null) {
        // Mounted on an entity
        Ref<EntityStore> mount = mounted.getMountedToEntity();
    } else if (mounted.getMountedToBlock() != null) {
        // Mounted on a block
        Ref<ChunkStore> block = mounted.getMountedToBlock();
        BlockMountType type = mounted.getBlockMountType(); // Seat or Bed
    }
}

// Check if entity has passengers
MountedByComponent mountedBy = store.getComponent(entityRef, MountedByComponent.getComponentType());
if (mountedBy != null) {
    List<Ref<EntityStore>> passengers = mountedBy.getPassengers();
    for (Ref<EntityStore> passenger : passengers) {
        // Process each passenger
    }
}
```

### Finding Available Seats

```java
// Get block type
BlockType blockType = world.getBlockType(blockPos);
if (blockType.getSeats() != null) {
    // Get seats for current rotation
    int rotation = world.getRotationIndex(blockPos);
    BlockMountPoint[] seats = blockType.getSeats().getRotated(rotation);
    
    // Get or create BlockMountComponent
    BlockMountComponent mountComponent = // ... get from block entity
    
    // Find available seat
    Vector3f interactionPoint = new Vector3f(x, y, z);
    BlockMountPoint availableSeat = mountComponent.findAvailableSeat(
        blockPos,
        seats,
        interactionPoint
    );
    
    if (availableSeat != null) {
        // Seat is available
        Vector3f seatWorldPos = availableSeat.computeWorldSpacePosition(blockPos);
    }
}
```

## Movement States Integration

When mounted, the `mounting` movement state is set:

```java
MovementStatesComponent movement = store.getComponent(entityRef, 
    MovementStatesComponent.getComponentType());
movement.getMovementStates().mounting = true;
```

This affects:
- Animation state (sitting/riding animations)
- Movement restrictions
- Physics behavior
- Input handling

## Network Synchronization

Mount state is synchronized to clients via:

1. **MountedUpdate** packet - Updates mount state
2. **BlockMount** protocol - Block mount information
3. **MountNPC** packet - NPC mounting
4. **ComponentUpdate** - General component sync

The `MountGamePacketHandler` handles client-server mount communication.

## Best Practices

1. **Always use the API** - Use `BlockMountAPI.mountOnBlock()` rather than manually creating components
2. **Handle errors** - Check the result type when mounting
3. **Clean up properly** - Systems handle cleanup, but ensure custom logic doesn't leave orphaned refs
4. **Validate before mounting** - Check if entity is already mounted
5. **Use mount points** - Define proper mount points in block assets for best positioning
6. **Network state** - The `isNetworkOutdated` flag helps optimize network traffic
7. **Death handling** - Ensure dismounting on death for both rider and mount
8. **Chunk loading** - Block mounts require chunks to be loaded

## Configuration

### Block Asset Configuration

Define mount points in block assets:

```json
{
  "Seats": [
    {
      "Offset": [0, 0.5, 0],
      "Rotation": [0, 0, 0]
    }
  ]
}
```

### NPC Mount Configuration

Configure NPC mounts in prefabs:

```json
{
  "Components": {
    "NPCMountComponent": {
      "OriginalRoleIndex": 0
    }
  }
}
```

## Related Systems

- **Movement System** - Sets `mounting` state when mounted
- **Transform System** - Positions mounted entities
- **Physics System** - Handles mount movement
- **Animation System** - Plays sitting/riding animations
- **Interaction System** - Triggers mounting via interactions
- **Death System** - Handles dismounting on death
- **Network System** - Synchronizes mount state to clients

## Advanced Features

### Custom Mount Controllers

Extend the mount system by creating custom controllers:
- Implement specific movement behaviors
- Add custom input handling
- Create specialized mount types

### Multi-seat Mounts

Blocks and entities can have multiple mount points:
- Each mount point tracked separately
- Independent passenger management
- Coordinate multiple riders

### Dynamic Mounts

Mounts can be created and destroyed dynamically:
- Minecarts spawned from items
- Temporary mount entities
- Mount point availability changes
