---
title: Interaction System
description: Player and entity interactions with blocks, entities, and items including cooldowns and interaction chains.
sidebar:
  order: 1
---

The Interaction System manages how players and entities interact with the game world through mouse clicks, block interactions, and entity interactions.

## Core Components

### InteractionModule

The main module class that registers interaction types and manages the interaction system.

**Location:** `com.hypixel.hytale.server.core.modules.interaction.InteractionModule`

```java
// Get the module instance
InteractionModule module = InteractionModule.get();

// Get component types
ComponentType<EntityStore, InteractionManager> managerType = 
    module.getInteractionManagerComponent();
ComponentType<EntityStore, Interactions> interactionsType = 
    module.getInteractionsComponentType();
```

### Interactions Component

Stores the mapping of interaction types to root interaction IDs for an entity.

**Location:** `com.hypixel.hytale.server.core.modules.interaction.Interactions`

```java
// Get interaction ID for a specific type
Interactions component = store.getComponent(entityRef, Interactions.getComponentType());
String interactionId = component.getInteractionId(InteractionType.Primary);

// Set interaction ID
component.setInteractionId(InteractionType.Primary, "hytale:basic_attack");
```

**Interaction Types:**
- `Primary` - Left click
- `Secondary` - Right click
- `Tertiary` - Middle click
- `Ability1-4` - Ability slots
- `ProjectileImpact` - Projectile hit
- `ProjectileSpawn` - After projectile spawned
- And more...

### InteractionManager Component

Manages active interaction chains and cooldowns for an entity. This is automatically added to entities by the `PlayerAddManagerSystem`.

**Location:** `com.hypixel.hytale.server.core.entity.InteractionManager`

## Root Interactions

Root interactions are entry points that define what happens when a specific interaction type is triggered.

### RootInteraction

**Location:** `com.hypixel.hytale.server.core.modules.interaction.interaction.config.RootInteraction`

**Asset Path:** `Item/RootInteractions/{id}.json`

```json
{
  "Interactions": ["hytale:damage_entity", "hytale:play_sound"],
  "Cooldown": {
    "Id": "attack_cooldown",
    "Cooldown": 0.5,
    "Charges": [0.5, 1.0]
  },
  "Rules": {
    "BlockingRoots": ["hytale:mining"],
    "AllowedGameModes": ["Adventure", "Survival"]
  }
}
```

**Key Fields:**
- `Interactions` - Array of interaction IDs to execute in sequence
- `Cooldown` - Optional cooldown configuration
- `Rules` - Restrictions on when this interaction can run
- `Settings` - Per-gamemode settings

### Cooldowns

Cooldowns prevent interactions from running too frequently.

**Location:** `com.hypixel.hytale.server.core.modules.interaction.interaction.CooldownHandler`

```java
// Check if on cooldown
CooldownHandler handler = /* get from manager */;
boolean onCooldown = handler.isOnCooldown(
    rootInteraction, 
    "my_cooldown_id", 
    maxTime, 
    chargeTimes,
    interruptRecharge
);

// Reset cooldown
handler.resetCooldown("my_cooldown_id", maxTime, chargeTimes, interruptRecharge);
```

**Charge System:**
- Cooldowns can have multiple charges
- Each charge has a recharge time
- Using an action consumes one charge
- `InterruptRecharge` determines if using resets the recharge timer

## Interaction Chains

Interactions can be chained together to create complex behaviors.

### Interaction Types

All interactions extend the base `Interaction` class.

**Location:** `com.hypixel.hytale.server.core.modules.interaction.interaction.config.Interaction`

**Common Interaction Types:**

#### Client-Side Interactions
Executed on client with server validation:

- `PlaceBlock` - Place a block in the world
- `BreakBlock` - Break a block
- `UseBlock` - Interact with a block (doors, chests)
- `UseEntity` - Interact with an entity
- `Charging` - Hold to charge (bow drawing)
- `Chaining` - Chain multiple clicks
- `ChangeBlock` - Modify block type
- `ChangeState` - Modify block state
- `FirstClick` - Only runs on first click
- `ApplyForce` - Apply physics force

#### Server-Side Interactions
Executed only on server:

- `DamageEntity` - Damage an entity with selectors
- `LaunchProjectile` - Spawn a projectile
- `SpawnPrefab` - Spawn an entity
- `ApplyEffect` - Apply entity effect
- `ClearEntityEffect` - Remove entity effect
- `ChangeStat` - Modify entity stats
- `OpenContainer` - Open inventory UI
- `OpenPage` - Open custom UI
- `EquipItem` - Equip armor/items
- `ModifyInventory` - Add/remove items
- `SendMessage` - Send chat message
- `Door` - Open/close doors
- `LaunchPad` - Launch entity with velocity

#### Control Flow Interactions
Control execution flow:

- `Condition` - Conditional execution
- `Serial` - Run interactions in sequence
- `Parallel` - Run interactions simultaneously
- `Repeat` - Repeat interactions
- `Select` - Choose based on selector
- `Replace` - Replace with different interaction
- `CancelChain` - Stop chain execution
- `Interrupt` - Interrupt active chains

#### Condition Interactions

- `BlockCondition` - Check block type/state
- `CooldownCondition` - Check cooldown state
- `EffectCondition` - Check entity effects
- `StatsCondition` - Check entity stats
- `MovementCondition` - Check movement state
- `DestroyCondition` - Check if can destroy
- `PlacementCountCondition` - Check placed block count

### Selectors

Selectors determine which entities are targeted by interactions.

**Location:** `com.hypixel.hytale.server.core.modules.interaction.interaction.config.selector.SelectorType`

**Selector Types:**
- `Raycast` - Ray cast from entity look direction
- `Horizontal` - Horizontal arc around entity
- `Stab` - Forward stab hitbox
- `AOECircle` - Circle area around point
- `AOECylinder` - Cylinder area around entity

```json
{
  "Type": "Selector",
  "Selector": {
    "Type": "AOECircle",
    "Radius": 5.0,
    "Angle": 90.0
  },
  "EntityMatchers": ["Vulnerable"],
  "Interactions": ["hytale:damage_entity"]
}
```

**Entity Matchers:**
- `Vulnerable` - Can be damaged
- `Player` - Players only

## Block Interactions

Special utilities for block-related interactions.

### BlockInteractionUtils

**Location:** `com.hypixel.hytale.server.core.modules.interaction.BlockInteractionUtils`

Handles block interaction logic like determining if a block can be interacted with.

### BlockPlaceUtils

**Location:** `com.hypixel.hytale.server.core.modules.interaction.BlockPlaceUtils`

Utilities for validating and executing block placement.

### BlockHarvestUtils

**Location:** `com.hypixel.hytale.server.core.modules.interaction.BlockHarvestUtils`

Handles block breaking and loot drops.

### PlacedByInteractionComponent

Tracks which player placed a block, useful for tracking structures.

**Location:** `com.hypixel.hytale.server.core.modules.interaction.components.PlacedByInteractionComponent`

```java
ComponentType<ChunkStore, PlacedByInteractionComponent> type = 
    InteractionModule.get().getPlacedByComponentType();

PlacedByInteractionComponent component = chunkStore.getComponent(blockRef, type);
if (component != null) {
    UUID placerUUID = component.getPlacedBy();
    // Use placer UUID
}
```

## Interaction Effects

Effects that play during interactions (particles, sounds, animations).

**Location:** `com.hypixel.hytale.server.core.modules.interaction.interaction.config.InteractionEffects`

```json
{
  "Effects": {
    "Particles": ["hytale:sparkle"],
    "Sounds": ["hytale:whoosh"],
    "Animation": "hytale:swing",
    "Trail": "hytale:sword_slash",
    "ModelOverlay": "hytale:glow"
  }
}
```

## Interaction Context

Provides context information when executing interactions.

**Location:** `com.hypixel.hytale.server.core.entity.InteractionContext`

```java
// Create context for entity
InteractionContext context = InteractionContext.forEntity(
    interactionManager,
    livingEntity,
    InteractionType.Primary
);

// Create context for proxy entity (projectiles)
InteractionContext proxyContext = InteractionContext.forProxyEntity(
    interactionManager,
    creatorEntity,
    projectileRef
);

// Access context data
Ref<EntityStore> entity = context.getEntity();
CommandBuffer<EntityStore> buffer = context.getCommandBuffer();
String rootInteractionId = context.getRootInteractionId(InteractionType.Primary);
```

## Systems

The interaction module registers several ECS systems:

### PlayerAddManagerSystem

Automatically adds `InteractionManager` component to entities when needed.

### TickInteractionManagerSystem

Updates active interaction chains each tick.

### CleanUpSystem

Removes completed interaction data.

### TrackerTickSystem

Updates interaction tracking for networked entities.

## Example: Custom Interaction

```java
// Create a custom damage interaction
public class CustomDamageInteraction extends Interaction {
    @Override
    protected void firstRun(
        InteractionType type,
        InteractionContext context,
        CooldownHandler cooldownHandler
    ) {
        // Get target from context
        Ref<EntityStore> target = context.getTarget();
        if (target == null) return;
        
        // Create damage
        CommandBuffer<EntityStore> buffer = context.getCommandBuffer();
        Damage damage = new Damage(10.0f);
        damage.setSource(context.getEntity());
        
        // Apply damage
        buffer.invoke(target, damage);
    }
}
```

## Example: Running an Interaction Chain

```java
// Get components
InteractionManager manager = store.getComponent(
    playerRef, 
    InteractionModule.get().getInteractionManagerComponent()
);
Player player = EntityUtils.getEntity(playerRef, store);

// Get root interaction
RootInteraction root = RootInteraction.getRootInteractionOrUnknown(
    "hytale:attack"
);

// Create context
InteractionContext context = InteractionContext.forEntity(
    manager,
    (LivingEntity) player,
    InteractionType.Primary
);

// Initialize and execute chain
InteractionChain chain = manager.initChain(
    InteractionType.Primary,
    context,
    root,
    true // sendToClient
);
manager.queueExecuteChain(chain);
```

## Block Tracking

Track player-placed blocks for limits or statistics.

### BlockCounter

**Location:** `com.hypixel.hytale.server.core.modules.interaction.blocktrack.BlockCounter`

Resource that counts blocks placed by category.

### TrackedPlacement

**Location:** `com.hypixel.hytale.server.core.modules.interaction.blocktrack.TrackedPlacement`

Component that tracks placement data for a specific block.

```java
// Get resource type
ResourceType<ChunkStore, BlockCounter> counterType = 
    InteractionModule.get().getBlockCounterResourceType();

// Get component type  
ComponentType<ChunkStore, TrackedPlacement> placementType =
    InteractionModule.get().getTrackedPlacementComponentType();
```
