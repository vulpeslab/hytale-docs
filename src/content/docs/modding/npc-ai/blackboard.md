---
author: UnlimitedBytes
title: Blackboard System
description: Shared memory system for NPC AI decision-making
---

The Blackboard system provides a shared memory architecture for NPCs to store and access information about their environment, events, and interactions. It acts as a central knowledge base that sensors can query to make decisions.

## Overview

The `Blackboard` class (`com.hypixel.hytale.server.npc.blackboard.Blackboard`) is a resource attached to the `EntityStore` that manages different types of views into game state. Each view type provides specialized access to different kinds of information.

## Blackboard Views

The blackboard uses a view-based architecture where different view types provide access to specific categories of information:

### AttitudeView

Located at `com.hypixel.hytale.server.npc.blackboard.view.attitude.AttitudeView`

Manages NPC attitudes and relationships toward entities and items:

- `AttitudeMap` - Maps entities to attitude values
- `ItemAttitudeMap` - Maps items to attitude values
- Faction relationships
- Hostility tracking

### BlockTypeView

Located at `com.hypixel.hytale.server.npc.blackboard.view.blocktype.BlockTypeView`

Provides information about blocks in the world:

- Block type queries
- Block state information
- Material properties
- Managed by `BlockTypeViewManager`

### BlockEventView

Located at `com.hypixel.hytale.server.npc.blackboard.view.event.block.BlockEventView`

Tracks block-related events that NPCs observe:

- `onEntityDamageBlock()` - When an entity damages a block
- `onEntityBreakBlock()` - When an entity breaks a block
- Event memory and history

### EntityEventView

Located at `com.hypixel.hytale.server.npc.blackboard.view.event.entity.EntityEventView`

Tracks entity-related events:

- Entity spawn events
- Entity death events
- Entity state changes
- Combat events

### ResourceView

Located at `com.hypixel.hytale.server.npc.blackboard.view.resource.ResourceView`

Manages resource information:

- Resource locations
- Resource availability
- Managed by `ResourceViewManager`

### InteractionView

Located at `com.hypixel.hytale.server.npc.blackboard.view.interaction.InteractionView`

Tracks NPC interactions:

- Player interactions
- NPC-to-NPC interactions
- Interaction history

## View Managers

Each view type has an associated manager that controls view lifecycle and access:

### IBlackboardViewManager Interface

Base interface for all view managers with methods:

- `get(Ref, Blackboard, ComponentAccessor)` - Get view for an entity
- `get(chunkX, chunkZ, Blackboard)` - Get view for a chunk
- `get(index, Blackboard)` - Get view by index
- `getIfExists(index)` - Check if view exists
- `forEachView(Consumer)` - Iterate over all views
- `cleanup()` - Clean up unused views
- `clear()` - Clear all views
- `onWorldRemoved()` - Handle world removal

### SingletonBlackboardViewManager

Used for global views that apply to the entire world:

```java
new SingletonBlackboardViewManager<BlockEventView>(new BlockEventView(world))
```

Used by:
- BlockEventView
- EntityEventView  
- AttitudeView
- InteractionView

### Per-Entity/Per-Chunk Managers

Other managers provide per-entity or per-chunk views:

- `BlockTypeViewManager` - Per-chunk block information
- `ResourceViewManager` - Resource tracking

## Accessing the Blackboard

### Getting the Blackboard Resource

```java
ResourceType<EntityStore, Blackboard> blackboardType = Blackboard.getResourceType();
Blackboard blackboard = store.getResource(blackboardType);
```

### Querying Views

Get a view for a specific entity:

```java
AttitudeView attitudeView = blackboard.getView(
    AttitudeView.class, 
    entityRef, 
    componentAccessor
);
```

Get a view for a chunk:

```java
BlockTypeView blockTypeView = blackboard.getView(
    BlockTypeView.class,
    chunkX,
    chunkZ
);
```

Get a view by index:

```java
ResourceView resourceView = blackboard.getView(
    ResourceView.class,
    index
);
```

### Iterating Over Views

```java
blackboard.forEachView(AttitudeView.class, view -> {
    // Process each attitude view
});
```

## Blackboard Lifecycle

### Initialization

The blackboard is initialized when a world is loaded:

```java
blackboard.init(world);
```

This registers all view types and their managers.

### Event Handling

The blackboard receives events and propagates them to appropriate views:

```java
// Block damage event
blackboard.onEntityDamageBlock(entityRef, damageBlockEvent);

// Block break event
blackboard.onEntityBreakBlock(entityRef, breakBlockEvent);
```

### Cleanup

Views are cleaned up periodically:

```java
blackboard.cleanupViews(); // Cleanup unused views
blackboard.clear();        // Clear all views
blackboard.onWorldRemoved(); // World shutdown
```

## Integration with Sensors

Sensors use the blackboard to access world state information. The blackboard provides the data that sensors need to evaluate their conditions.

For example, a sensor checking if an entity is hostile might:

1. Get the AttitudeView from the blackboard
2. Query the attitude toward the target entity
3. Return whether the attitude indicates hostility

## View Access Patterns

### Spatial Queries

Views can be accessed by spatial location (chunk coordinates) for efficient spatial queries:

```java
// Get block information for a specific chunk
BlockTypeView view = blackboard.getView(BlockTypeView.class, chunkX, chunkZ);
```

### Entity-Based Queries

Views can be accessed per-entity for entity-specific information:

```java
// Get attitude information for a specific NPC
AttitudeView view = blackboard.getView(AttitudeView.class, npcRef, accessor);
```

### Global Queries

Some views are singletons that provide world-wide information:

```java
// Get global interaction view
InteractionView view = blackboard.getView(InteractionView.class, npcRef, accessor);
```

## Thread Safety

The blackboard uses `ConcurrentHashMap` for thread-safe view management, allowing concurrent access from multiple systems.

## Related Systems

- [Sensors](/modding/npc-ai/instructions#sensors) - Use blackboard for decision-making
- [Decision Makers](/modding/npc-ai/decision-makers) - Evaluate conditions using blackboard data
- Event System - Feeds events into the blackboard
