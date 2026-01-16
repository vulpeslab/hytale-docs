---
author: UnlimitedBytes
title: Spawning System
description: NPC spawning, spawn beacons, markers, and spawn control
human-verified: false
---

The Spawning System controls how and when NPCs spawn in the world through spawn beacons, spawn markers, spawn controllers, and spawning rules.

## Overview

Located at `com.hypixel.hytale.server.spawning`

The `SpawningPlugin` manages all spawning functionality and consists of:

- **Spawn Beacons** - Persistent spawn points that manage NPC populations
- **Spawn Markers** - Block-placed spawn points for specific NPCs
- **Spawn Controllers** - Control spawn timing and conditions
- **Spawn Suppression** - Prevent spawning in specific areas
- **Spawning Rules** - Conditions that must be met for spawning

## SpawningPlugin

The `SpawningPlugin` class (`com.hypixel.hytale.server.spawning.SpawningPlugin`) serves as the central management point for spawning:

- Registers spawning components
- Manages spawn configurations
- Coordinates with NPC and Flock systems
- Handles spawn lifecycle

## Spawn Beacons

Located at `com.hypixel.hytale.server.spawning.beacons`

### SpawnBeacon

The `SpawnBeacon` class is an entity that manages spawning in an area:

```java
public class SpawnBeacon extends Entity {
    private BeaconSpawnWrapper spawnWrapper;
    private String spawnConfigId;
    private IntSet unspawnableRoles;
    private SpawningContext spawningContext;
}
```

Key features:
- Manages population of NPCs in an area
- Respawns NPCs when they die
- Tracks which NPCs belong to it
- Handles flock spawning
- Controls spawn timing

### SpawnBeacon Visibility

Spawn beacons are hidden from players except in Creative mode:

```java
@Override
public boolean isHiddenFromLivingEntity(Ref<EntityStore> ref, Ref<EntityStore> targetRef, ComponentAccessor<EntityStore> componentAccessor) {
    Player targetPlayerComponent = componentAccessor.getComponent(targetRef, Player.getComponentType());
    return targetPlayerComponent == null || targetPlayerComponent.getGameMode() != GameMode.Creative;
}
```

### Initial Beacon Delay

Located at `com.hypixel.hytale.server.spawning.beacons.InitialBeaconDelay`

Beacons can have a delay before first spawn:

```java
public class InitialBeaconDelay implements Component<EntityStore> {
    private double delay;
}
```

### Legacy Spawn Beacon

Located at `com.hypixel.hytale.server.spawning.beacons.LegacySpawnBeaconEntity`

Supports legacy beacon formats for compatibility.

### Beacon Systems

Located at `com.hypixel.hytale.server.spawning.beacons.SpawnBeaconSystems`

Systems that manage beacon behavior:

- **Position calculation** - Determine valid spawn positions
- **Population management** - Track and maintain NPC count
- **Respawn timing** - Control when NPCs respawn
- **Flock coordination** - Spawn flock members together

## Spawn Markers

Located at `com.hypixel.hytale.server.spawning.spawnmarkers`

### SpawnMarkerEntity

The `SpawnMarkerEntity` component is attached to entities placed as spawn markers:

```java
public class SpawnMarkerEntity implements Component<EntityStore> {
    private String spawnMarkerId;
    private SpawnMarker cachedMarker;
    private double respawnCounter;
    private Duration gameTimeRespawn;
    private Instant spawnAfter;
    private int spawnCount;
    private Set<UUID> suppressedBy;
    private InvalidatablePersistentRef[] npcReferences;
    private StoredFlock storedFlock;
}
```

Features:
- Placed in world as blocks
- Spawn specific NPC types
- Support respawn timers
- Can spawn flocks
- Track spawned NPCs

### Spawn Marker Configuration

Spawn markers are defined in assets:

Located at `com.hypixel.hytale.server.spawning.assets.spawnmarker.config.SpawnMarker`

Configuration includes:
- NPC type to spawn
- Respawn timing
- Spawn conditions
- Flock settings
- Maximum spawn count

### Spawn Marker Block States

Located at `com.hypixel.hytale.server.spawning.blockstates`

Spawn markers integrate with the block system:

- `SpawnMarkerBlockState` - Block state for spawn marker blocks
- `SpawnMarkerBlockReference` - Reference from block to spawn marker
- `SpawnMarkerBlockStateSystems` - Systems managing block integration

### Spawn Marker Systems

Located at `com.hypixel.hytale.server.spawning.spawnmarkers.SpawnMarkerSystems`

Systems managing spawn marker behavior:

- Spawn timing
- NPC tracking
- Respawn logic
- Deactivation when NPCs despawn

## Spawn Controllers

Located at `com.hypixel.hytale.server.spawning.controllers`

### SpawnController

Base interface for spawn controllers:

```java
public interface SpawnController {
    boolean canSpawn(SpawningContext context);
    void onSpawn(SpawningContext context);
    void onDeath(SpawningContext context);
}
```

### BeaconSpawnController

Located at `com.hypixel.hytale.server.spawning.controllers.BeaconSpawnController`

Controls spawning for spawn beacons:

- Population limits
- Spawn cooldowns
- Distance requirements
- Player proximity checks

### Spawn Controller Systems

Located at `com.hypixel.hytale.server.spawning.controllers.SpawnControllerSystem`

System that executes spawn controller logic each tick.

### Spawn Job System

Located at `com.hypixel.hytale.server.spawning.controllers.SpawnJobSystem`

Manages asynchronous spawn jobs:

- Queues spawn requests
- Executes spawns off main thread
- Handles spawn failures
- Retries failed spawns

## Spawning Context

Located at `com.hypixel.hytale.server.spawning.SpawningContext`

The `SpawningContext` class provides context for spawn operations:

```java
public class SpawningContext {
    private World world;
    private Vector3d position;
    private Random random;
    private ComponentAccessor accessor;
    // ... spawn-specific data
}
```

Used to pass information during spawn evaluation and execution.

## Spawn Configurations

### NPCSpawn

Located at `com.hypixel.hytale.server.spawning.assets.spawns.config.NPCSpawn`

Base class for NPC spawn configurations.

### BeaconNPCSpawn

Located at `com.hypixel.hytale.server.spawning.assets.spawns.config.BeaconNPCSpawn`

Configuration for beacon-based spawning:

```json
{
  "id": "forest_wolf_spawn",
  "npcType": "wolf",
  "minCount": 2,
  "maxCount": 5,
  "spawnRadius": 20.0,
  "respawnTime": 300.0
}
```

### WorldNPCSpawn

Located at `com.hypixel.hytale.server.spawning.assets.spawns.config.WorldNPCSpawn`

Configuration for world-based spawning (natural spawns).

### RoleSpawnParameters

Located at `com.hypixel.hytale.server.spawning.assets.spawns.config.RoleSpawnParameters`

Parameters for spawning NPCs with specific roles:

- Role selection
- Role weights
- Role-specific conditions

## Spawn Suppression

Located at `com.hypixel.hytale.server.spawning.suppression`

Spawn suppression prevents spawning in specific areas.

### SpawnSuppressionComponent

Located at `com.hypixel.hytale.server.spawning.suppression.component.SpawnSuppressionComponent`

Component that marks an area as suppressed:

```java
public class SpawnSuppressionComponent implements Component<EntityStore> {
    private Set<String> suppressedSpawnTypes;
    private double radius;
}
```

### ChunkSuppressionQueue

Located at `com.hypixel.hytale.server.spawning.suppression.component.ChunkSuppressionQueue`

Manages suppression on a per-chunk basis:

```java
public class ChunkSuppressionQueue implements Component<ChunkStore> {
    private Queue<SuppressionEntry> entries;
}
```

### ChunkSuppressionEntry

Located at `com.hypixel.hytale.server.spawning.suppression.component.ChunkSuppressionEntry`

Individual suppression entry:

```java
public class ChunkSuppressionEntry implements Component<ChunkStore> {
    private UUID suppressorId;
    private Set<String> suppressedTypes;
}
```

### SpawnSuppressorEntry

Located at `com.hypixel.hytale.server.spawning.suppression.SpawnSuppressorEntry`

Tracks an entity that suppresses spawning.

### Suppression Systems

Located at `com.hypixel.hytale.server.spawning.suppression.system`

Systems that manage suppression:

- Apply suppression when entities enter area
- Remove suppression when entities leave
- Check suppression during spawn attempts

### Spawn Suppression Assets

Located at `com.hypixel.hytale.server.spawning.assets.spawnsuppression.SpawnSuppression`

Asset configuration for spawn suppression:

```json
{
  "id": "town_suppression",
  "suppressedTypes": ["monster", "hostile"],
  "radius": 50.0
}
```

## Spawn Testing

### SpawnTestResult

Located at `com.hypixel.hytale.server.spawning.SpawnTestResult`

Result of testing if a spawn can occur:

```java
public enum SpawnTestResult {
    SUCCESS,
    FAILED,
    RETRY
}
```

### SpawnRejection

Located at `com.hypixel.hytale.server.spawning.SpawnRejection`

Reason why a spawn was rejected:

```java
public class SpawnRejection {
    private String reason;
    private SpawnTestResult result;
}
```

## Local Spawning

Located at `com.hypixel.hytale.server.spawning.local`

Local spawning handles player-specific or temporary spawns.

### LocalSpawnBeacon

Component for temporary spawn beacons:

```java
public class LocalSpawnBeacon implements Component<EntityStore> {
    private UUID ownerId;
    private double lifetime;
}
```

### LocalSpawnController

Controller for local spawn beacons:

- Manages temporary spawns
- Player-specific spawning
- Event-triggered spawns

### Local Spawn Systems

- `LocalSpawnBeaconSystem` - Manages local beacon lifecycle
- `LocalSpawnControllerSystem` - Controls local spawning
- `LocalSpawnForceTriggerSystem` - Force-triggers local spawns
- `LocalSpawnSetupSystem` - Sets up local spawn configurations
- `LocalSpawnState` - Tracks local spawn state

## Spawn Managers

Located at `com.hypixel.hytale.server.spawning.managers`

### SpawnManager

Base spawn manager interface:

```java
public interface SpawnManager {
    void update(double dt);
    void cleanup();
}
```

### BeaconSpawnManager

Located at `com.hypixel.hytale.server.spawning.managers.BeaconSpawnManager`

Manages all spawn beacons in the world:

- Tracks active beacons
- Updates beacon population
- Handles beacon lifecycle

## Spawn Wrappers

Located at `com.hypixel.hytale.server.spawning.wrappers`

### BeaconSpawnWrapper

Wraps spawn configuration for beacons:

```java
public class BeaconSpawnWrapper {
    private BeaconNPCSpawn spawn;
    private IWeightedMap<RoleSpawnParameters> roleWeights;
}
```

Provides:
- Role selection based on weights
- Spawn parameter access
- Spawn validation

## World Spawning

Located at `com.hypixel.hytale.server.spawning.world`

World-level spawning systems:

### World Components

Located at `com.hypixel.hytale.server.spawning.world.component`

Components for world-level spawn management.

### World Managers

Located at `com.hypixel.hytale.server.spawning.world.manager`

Managers for world spawning logic.

### World Systems

Located at `com.hypixel.hytale.server.spawning.world.system`

Systems for world spawn processing.

## Spawning Integration

### With NPC System

Spawning creates NPCs:

```java
NPCEntity npc = spawner.spawn(spawnConfig, position);
```

NPCs track their spawn source:

- `SpawnBeaconReference` - Reference to spawn beacon
- `SpawnMarkerReference` - Reference to spawn marker

### With Flock System

Spawning can create flocks:

```java
spawnMarker.storedFlock = new StoredFlock(flockConfig);
```

When spawning:
1. Create flock entity
2. Spawn flock members
3. Assign members to flock

## Spawn Interactions

Located at `com.hypixel.hytale.server.spawning.interactions`

### TriggerSpawnMarkersInteraction

Interaction to manually trigger spawn markers:

```java
public class TriggerSpawnMarkersInteraction extends Interaction {
    // Triggers nearby spawn markers
}
```

## Spawning Utilities

Located at `com.hypixel.hytale.server.spawning.util`

### FloodFillPositionSelector

Finds valid spawn positions using flood fill:

```java
public class FloodFillPositionSelector {
    public Vector3d selectPosition(Vector3d center, double radius);
}
```

Features:
- Finds reachable positions
- Avoids obstacles
- Respects terrain
- Caches results

## Core Component Integration

Located at `com.hypixel.hytale.server.spawning.corecomponents.builders`

### BuilderActionTriggerSpawnBeacon

Action builder for triggering spawn beacons from instructions.

## Spawn Assets

Located at `com.hypixel.hytale.server.spawning.assets`

Asset types:
- `spawns` - Spawn configurations
- `spawnmarker` - Spawn marker definitions
- `spawnsuppression` - Suppression configurations

## Events

### LoadedNPCEvent

Located at `com.hypixel.hytale.server.spawning.LoadedNPCEvent`

Fired when an NPC is loaded from spawn:

```java
public class LoadedNPCEvent {
    private Ref<EntityStore> npcRef;
    private String spawnId;
}
```

## ISpawnable Interface

Located at `com.hypixel.hytale.server.spawning.ISpawnable`

Interface for entities that can be spawned:

```java
public interface ISpawnable {
    void onSpawned(SpawningContext context);
}
```

### ISpawnableWithModel

Located at `com.hypixel.hytale.server.spawning.ISpawnableWithModel`

For spawnable entities with models:

```java
public interface ISpawnableWithModel extends ISpawnable {
    Model getModel();
    void setModel(Model model);
}
```

## Best Practices

1. **Use beacons for persistent spawns** - Villages, dungeons, etc.
2. **Use markers for specific placements** - Bosses, quest NPCs
3. **Configure suppression** - Prevent spawns in towns/safe areas
4. **Set appropriate respawn times** - Balance gameplay
5. **Limit spawn counts** - Prevent performance issues
6. **Test spawn conditions** - Ensure spawns work as expected

## Performance Considerations

- Beacon updates are distributed across ticks
- Spawn position calculation is cached
- Failed spawns have retry limits
- Suppression uses spatial indexing
- Inactive beacons are not updated

## Related Systems

- [NPC & AI System](/modding/npc-ai) - NPCs that are spawned
- [Flock System](/modding/flock) - Group spawning
- World Generation - Initial spawn placement
- Event System - Spawn events
