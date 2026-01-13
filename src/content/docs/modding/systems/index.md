---
title: Gameplay Systems
description: Core gameplay systems including damage, movement, interactions, projectiles, and entity effects.
sidebar:
  order: 5
---

This section covers Hytale's gameplay systems—the game mechanics that operate on entities using the ECS architecture.

## Available Systems

- **[Damage System](./damage)** - Health, damage types, damage sources, and death handling
- **[Movement & Locomotion](./movement)** - Entity movement, velocity, and locomotion states
- **[Mounts System](./mounts)** - Mounting entities, riders, and mount controls
- **[Interaction System](./interactions)** - Player and entity interactions with blocks, entities, and items
- **[Projectile System](./projectiles)** - Projectile spawning, physics, and collision detection
- **[Entity Effects](./entity-effects)** - Status effects, buffs, debuffs, and entity modifiers

## System Overview

These systems are built on top of Hytale's ECS architecture and provide high-level functionality for common gameplay patterns:

- **Damage** handles health components, damage calculation, resistances, and death events
- **Movement** controls entity velocity, locomotion states (walking, running, swimming), and physics integration
- **Mounts** manages rider-mount relationships and mount control delegation
- **Interactions** handle player input and convert it into game actions (attacking, mining, using items)
- **Projectiles** simulate arrows, spells, and other thrown objects with configurable physics
- **Entity Effects** apply temporary or permanent status changes to entities (poison, speed boost, etc.)

All systems use asset-based configuration stored in JSON files, allowing server mods to customize behavior without code changes.

## Quick Examples

### Launching a Projectile

```java
// Get projectile config from asset store
ProjectileConfig config = ProjectileConfig.getAssetMap().getAsset("hytale:arrow");

// Spawn projectile from player position
Vector3d position = player.getPosition();
Vector3d direction = player.getLookDirection();
Ref<EntityStore> projectileRef = ProjectileModule.get()
    .spawnProjectile(playerRef, commandBuffer, config, position, direction);
```

### Applying an Entity Effect

```java
// Get effect from asset store
EntityEffect effect = EntityEffect.getAssetMap().getAsset("hytale:poison");

// Apply to entity
EffectControllerComponent controller = componentAccessor.getComponent(
    entityRef, 
    EffectControllerComponent.getComponentType()
);
controller.addEffect(entityRef, effect, componentAccessor);
```

### Running an Interaction

```java
// Get root interaction
RootInteraction root = RootInteraction.getRootInteractionOrUnknown("hytale:mine_block");

// Initialize interaction chain
InteractionContext context = InteractionContext.forEntity(
    interactionManager, 
    livingEntity, 
    InteractionType.Primary
);
InteractionChain chain = interactionManager.initChain(
    InteractionType.Primary, 
    context, 
    root, 
    true
);

// Execute the chain
interactionManager.queueExecuteChain(chain);
```

## Module Dependencies

All three systems require the **EntityModule** which provides the base ECS functionality. The projectile system additionally depends on the **CollisionModule** for physics simulation.

```
InteractionModule
├── Depends on: EntityModule
└── Used by: Items, Blocks, Entities

ProjectileModule  
├── Depends on: EntityModule, CollisionModule
└── Used by: Weapons, Throwable items

Entity Effects
├── Part of: EntityModule
└── Used by: Status effects, Buffs, Debuffs
```
