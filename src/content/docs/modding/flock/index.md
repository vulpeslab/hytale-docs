---
title: Flock System
description: Group behavior management for NPCs including flock membership and coordination
---

The Flock System manages group behaviors for NPCs, allowing them to move and act together as coordinated units. Flocks provide emergent group behaviors like alignment, cohesion, and separation.

## Overview

Located at `com.hypixel.hytale.server.flock`

The `FlockPlugin` manages all flock functionality and provides:

- **Flock entities** - Core flock management
- **Flock membership** - NPC membership in flocks
- **Persistent flock data** - Saved flock state
- **Flock behaviors** - Group movement and coordination
- **Flock decision-making** - Group-based AI decisions

## FlockPlugin

The `FlockPlugin` class (`com.hypixel.hytale.server.flock.FlockPlugin`) serves as the central management point:

```java
public class FlockPlugin extends JavaPlugin {
    private ComponentType<EntityStore, Flock> flockComponentType;
    private ComponentType<EntityStore, FlockMembership> flockMembershipComponentType;
    private ComponentType<EntityStore, PersistentFlockData> persistentFlockDataComponentType;
}
```

Features:
- Registers flock components
- Manages flock lifecycle
- Coordinates with NPC and spawning systems
- Handles prefab flock remapping

## Flock Entity

Located at `com.hypixel.hytale.server.flock.Flock`

### Flock Component

The `Flock` component represents a group of NPCs:

```java
public class Flock implements Component<EntityStore> {
    private boolean trace;
    private PersistentFlockData flockData;
    private DamageData nextDamageData;
    private DamageData currentDamageData;
    private DamageData nextLeaderDamageData;
    private DamageData currentLeaderDamageData;
    private FlockRemovedStatus removedStatus;
}
```

### Flock Properties

#### Trace Mode

Debug tracing for flock behavior:

```java
flock.setTrace(true); // Enable debug logging
```

#### Damage Tracking

Flocks track damage dealt by the group:

- `currentDamageData` - Damage this tick
- `nextDamageData` - Damage next tick (double buffered)
- `currentLeaderDamageData` - Leader damage this tick
- `nextLeaderDamageData` - Leader damage next tick

Damage data is double-buffered for thread safety:

```java
flock.swapDamageDataBuffers();
```

#### Flock Status

```java
public enum FlockRemovedStatus {
    NOT_REMOVED,
    DISSOLVED,
    UNLOADED
}
```

- `NOT_REMOVED` - Active flock
- `DISSOLVED` - Flock disbanded
- `UNLOADED` - Flock unloaded from world

### Getting Flock Component

```java
ComponentType<EntityStore, Flock> flockType = Flock.getComponentType();
Flock flock = componentAccessor.getComponent(flockRef, flockType);
```

## Flock Membership

Located at `com.hypixel.hytale.server.flock.FlockMembership`

### FlockMembership Component

NPCs have a `FlockMembership` component when part of a flock:

```java
public class FlockMembership implements Component<EntityStore> {
    private Ref<EntityStore> flockRef;
    private boolean isLeader;
    private UUID flockId;
}
```

### Membership Properties

- `flockRef` - Reference to flock entity
- `isLeader` - Whether this NPC is the flock leader
- `flockId` - Unique identifier for the flock

### Joining a Flock

NPCs join flocks through the join action:

```java
// From core components
BuilderActionFlockJoin joinAction = new BuilderActionFlockJoin();
```

### Leaving a Flock

NPCs leave flocks through:

```java
// From core components
BuilderActionFlockLeave leaveAction = new BuilderActionFlockLeave();
```

Or automatically when:
- NPC dies (unless `corpseStaysInFlock` is true)
- NPC is removed
- Flock is dissolved

### Getting Membership

```java
ComponentType<EntityStore, FlockMembership> membershipType = FlockMembership.getComponentType();
FlockMembership membership = componentAccessor.getComponent(npcRef, membershipType);
```

## Persistent Flock Data

Located at `com.hypixel.hytale.server.flock.PersistentFlockData`

### PersistentFlockData Component

Stores flock data that persists across saves:

```java
public class PersistentFlockData implements Component<EntityStore> {
    private FlockAsset flockDefinition;
    private String[] allowedRoles;
    private int currentSize;
    private int maxSize;
}
```

### Flock Configuration

- `flockDefinition` - Reference to flock asset
- `allowedRoles` - Roles allowed to join
- `currentSize` - Current member count
- `maxSize` - Maximum member count

### Stored Flock

Located at `com.hypixel.hytale.server.flock.StoredFlock`

Used for storing flock data in spawn markers:

```java
public class StoredFlock {
    private String flockAssetId;
    private UUID flockId;
    private int memberCount;
}
```

## Flock Assets

Located at `com.hypixel.hytale.server.flock.config.FlockAsset`

### FlockAsset

Defines flock behavior configuration:

```json
{
  "id": "wolf_pack",
  "minSize": 3,
  "maxSize": 8,
  "alignment": 0.5,
  "cohesion": 0.3,
  "separation": 0.2,
  "influenceRange": 10.0
}
```

### RangeSizeFlockAsset

Located at `com.hypixel.hytale.server.flock.config.RangeSizeFlockAsset`

Flock asset with size range configuration.

## Flock Behaviors

Flocks exhibit three core behaviors (boids algorithm):

### Alignment

Flocks align their velocity with nearby flock members:

```java
class Role {
    protected double flockWeightAlignment;
}
```

Higher weight = stronger alignment tendency.

### Cohesion

Flocks move toward the center of nearby flock members:

```java
class Role {
    protected double flockWeightCohesion;
}
```

Higher weight = tighter grouping.

### Separation

Flocks maintain distance from nearby flock members:

```java
class Role {
    protected double flockWeightSeparation;
}
```

Higher weight = more personal space.

### Influence Range

How far flock members influence each other:

```java
class Role {
    protected double flockInfluenceRange;
}
```

Members beyond this distance don't affect flock behavior.

## Flock Leadership

### Leader Selection

One flock member is designated as the leader:

```java
class Role {
    protected boolean canLeadFlock;
}
```

Only NPCs with `canLeadFlock = true` can be leaders.

### Leader Behavior

The leader:
- Makes decisions for the flock
- Other members follow the leader
- Can have different AI instructions than followers

### Leader Damage Tracking

Flock tracks damage dealt by the leader separately:

```java
DamageData leaderDamage = flock.getLeaderDamageData();
```

## Flock Core Components

Located at `com.hypixel.hytale.server.flock.corecomponents.builders`

Core components for flock behaviors:

### Motion Components

#### BuilderBodyMotionFlock

Flock movement behavior:

```java
BuilderBodyMotionFlock flockMotion = new BuilderBodyMotionFlock();
```

Implements alignment, cohesion, and separation.

### Action Components

#### BuilderActionFlockJoin

Join a flock:

```json
{
  "type": "JoinFlock",
  "flockId": "wolf_pack"
}
```

#### BuilderActionFlockLeave

Leave current flock:

```json
{
  "type": "LeaveFlock"
}
```

#### BuilderActionFlockState

Change flock state:

```json
{
  "type": "FlockState",
  "state": "aggressive"
}
```

#### BuilderActionFlockSetTarget

Set flock target:

```json
{
  "type": "FlockTarget",
  "target": "nearest_enemy"
}
```

#### BuilderActionFlockBeacon

Create a flock beacon:

```json
{
  "type": "FlockBeacon",
  "duration": 30.0
}
```

### Filter Components

#### BuilderEntityFilterFlock

Filter for flock members:

```json
{
  "type": "Flock",
  "sameFlock": true
}
```

### Sensor Components

#### BuilderSensorFlockCombatDamage

Senses flock combat damage:

```json
{
  "type": "FlockCombatDamage",
  "threshold": 50.0
}
```

#### BuilderSensorInflictedDamage

Senses damage dealt by flock:

```json
{
  "type": "InflictedDamage",
  "threshold": 100.0
}
```

#### BuilderSensorFlockLeader

Senses flock leader:

```json
{
  "type": "FlockLeader",
  "mustBeAlive": true
}
```

## Flock Decision Making

Located at `com.hypixel.hytale.server.flock.decisionmaker`

### Conditions

#### FlockSizeCondition

Located at `com.hypixel.hytale.server.flock.decisionmaker.conditions.FlockSizeCondition`

Condition based on flock size:

```json
{
  "type": "FlockSize",
  "min": 3,
  "max": 8
}
```

Returns true if flock size is within range.

## Flock Systems

Located at `com.hypixel.hytale.server.flock`

### FlockSystems

Various systems that manage flock behavior:

#### FlockSystems.EntityRemoved

Handles entity removal from flocks.

#### FlockSystems.Ticking

Updates flock state each tick:
- Swaps damage buffers
- Updates flock behavior
- Checks flock validity

#### FlockSystems.PlayerChangeGameModeEventSystem

Handles player game mode changes affecting flocks.

### FlockMembershipSystems

Systems managing flock membership:

#### FlockMembershipSystems.EntityRef

Manages entity references in flocks.

#### FlockMembershipSystems.RefChange

Handles membership reference changes.

### FlockDeathSystems

Located at `com.hypixel.hytale.server.flock.FlockDeathSystems`

Handles NPC death in flocks:

```java
class Role {
    protected boolean corpseStaysInFlock;
}
```

If `false`, dead NPCs leave the flock.

## Spawning Integration

### Flock Spawning

Spawn markers can spawn entire flocks:

```java
class Role {
    protected String[] flockSpawnTypes;
    protected boolean flockSpawnTypesRandom;
    protected String[] flockAllowedRoles;
}
```

- `flockSpawnTypes` - NPC types to spawn in flock
- `flockSpawnTypesRandom` - Random selection from types
- `flockAllowedRoles` - Roles allowed in this flock

### Spawn Sequence

1. Create flock entity
2. Spawn leader
3. Spawn flock members
4. Assign all to flock
5. Initialize flock behavior

## Prefab Integration

Flocks in prefabs are handled specially:

```java
class FlockPlugin {
    private Int2ObjectConcurrentHashMap<Map<UUID, UUID>> prefabFlockRemappings;
}
```

### PrefabPasteEventSystem

Located in `FlockPlugin`

Handles flock remapping when prefabs are pasted:

```java
class PrefabPasteEventSystem extends WorldEventSystem<PrefabPasteEvent>
```

Ensures flock UUIDs are unique when prefabs are duplicated.

## Flock Lifecycle

### Creation

1. Create flock entity
2. Add Flock component
3. Set flock data
4. Add initial members

### Update

Each tick:
1. Swap damage buffers
2. Update member positions
3. Compute flock behaviors
4. Update leader state
5. Check for dissolution

### Dissolution

Flocks dissolve when:
- All members die/despawn
- Manually disbanded
- World unloads

```java
flock.setRemovedStatus(FlockRemovedStatus.DISSOLVED);
```

## Examples

### Simple Flock

```json
{
  "id": "bird_flock",
  "minSize": 5,
  "maxSize": 15,
  "alignment": 0.6,
  "cohesion": 0.3,
  "separation": 0.1,
  "influenceRange": 8.0
}
```

### Combat Flock

```json
{
  "id": "wolf_pack",
  "minSize": 3,
  "maxSize": 6,
  "alignment": 0.4,
  "cohesion": 0.5,
  "separation": 0.1,
  "influenceRange": 12.0
}
```

With NPC role:
```json
{
  "canLeadFlock": true,
  "flockWeightAlignment": 0.4,
  "flockWeightCohesion": 0.5,
  "flockWeightSeparation": 0.1,
  "corpseStaysInFlock": false
}
```

## Best Practices

1. **Balance flock weights** - Sum of weights should be reasonable
2. **Set appropriate influence range** - Based on flock spacing
3. **Limit flock size** - Large flocks impact performance
4. **Use leader AI** - Give leaders smarter behavior
5. **Handle death properly** - Decide if corpses stay or leave
6. **Test coordination** - Ensure flocks behave naturally

## Performance Considerations

- Flock updates are distributed across ticks
- Member queries use spatial indexing
- Influence range limits computation
- Smaller flocks perform better
- Cached position data reduces lookups

## Debugging

Enable flock tracing:

```java
flock.setTrace(true);
```

This logs:
- Member additions/removals
- Leadership changes
- Damage events
- Behavior decisions

## Related Systems

- [NPC & AI System](/modding/npc-ai) - NPCs that join flocks
- [Spawning System](/modding/spawning) - Spawns flocks
- [Navigation](/modding/npc-ai/navigation) - Flock movement
- [Instructions](/modding/npc-ai/instructions) - Flock behaviors
