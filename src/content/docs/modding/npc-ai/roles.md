---
title: Roles
description: High-level NPC behavior definitions and configuration
---

Roles define the complete behavior set for an NPC, including their instructions, stats, movement parameters, inventory, and all behavioral characteristics.

## Overview

Located at `com.hypixel.hytale.server.npc.role.Role`

A Role is the top-level container for an NPC's behavior. Each NPC has exactly one role at a time, but can change roles dynamically.

## Role Structure

```java
public class Role implements IAnnotatedComponentCollection {
    // Identity
    protected int roleIndex;
    protected String roleName;
    protected String appearance;
    
    // Support systems
    protected CombatSupport combatSupport;
    protected StateSupport stateSupport;
    protected MarkedEntitySupport markedEntitySupport;
    protected WorldSupport worldSupport;
    protected EntitySupport entitySupport;
    protected PositionCache positionCache;
    protected DebugSupport debugSupport;
    
    // Configuration
    protected Map<String, MotionController> motionControllers;
    protected RoleStats roleStats;
    // ... many more fields
}
```

## Support Systems

Roles contain several support objects that provide specialized functionality:

### CombatSupport

Located at `com.hypixel.hytale.server.npc.role.support.CombatSupport`

Manages combat-related functionality:

- Damage tracking
- Combat state
- Attack cooldowns
- Target selection
- Hostility management

### StateSupport

Located at `com.hypixel.hytale.server.npc.role.support.StateSupport`

Manages NPC state machine:

- Current state tracking
- State history
- State transitions
- State-specific data
- State change notifications

### EntitySupport

Located at `com.hypixel.hytale.server.npc.role.support.EntitySupport`

Manages entity tracking and targeting:

- Target entity tracking
- Entity queries
- Entity filtering
- Marked entities
- Entity relationship management

### MarkedEntitySupport

Located at `com.hypixel.hytale.server.npc.role.support.MarkedEntitySupport`

Tracks entities marked for special behavior:

- Memory of specific entities
- Marked entity types
- Marked entity priorities
- Entity memory duration

### WorldSupport

Located at `com.hypixel.hytale.server.npc.role.support.WorldSupport`

Provides world interaction capabilities:

- Block queries
- World state access
- Environmental checks
- Biome information

### PositionCache

Located at `com.hypixel.hytale.server.npc.role.support.PositionCache`

Caches position data for performance:

- Last known positions
- Position history
- Velocity cache
- Distance calculations

### DebugSupport

Located at `com.hypixel.hytale.server.npc.role.support.DebugSupport`

Debugging and diagnostic tools:

- Trace logging
- Sensor failure tracking
- Performance monitoring
- Visual debugging

## Combat Configuration

```java
class Role {
    protected int initialMaxHealth;
    protected boolean invulnerable;
    protected double knockbackScale;
}
```

- `initialMaxHealth` - Starting health value
- `invulnerable` - Whether NPC takes damage
- `knockbackScale` - Multiplier for knockback forces

## Movement Configuration

### Collision Avoidance

```java
class Role {
    protected double collisionProbeDistance;
    protected double collisionRadius;
    protected double collisionForceFalloff;
    protected float collisionViewAngle;
    protected float collisionViewHalfAngleCosine;
}
```

- `collisionProbeDistance` - How far ahead to check for collisions
- `collisionRadius` - Radius for collision detection
- `collisionForceFalloff` - How quickly avoidance force decreases
- `collisionViewAngle` - Field of view for collision detection

### Entity Avoidance

```java
class Role {
    protected double entityAvoidanceStrength;
    protected AvoidanceMode avoidanceMode;
    protected boolean isAvoidingEntities;
    protected Set<Ref<EntityStore>> ignoredEntitiesForAvoidance;
}
```

### Separation (Flocking)

```java
class Role {
    protected double separationDistance;
    protected double separationWeight;
    protected double separationDistanceTarget;
    protected double separationNearRadiusTarget;
    protected double separationFarRadiusTarget;
    protected boolean applySeparation;
}
```

### Physics

```java
class Role {
    protected double inertia;          // Movement inertia
    protected boolean breathesInAir;   // Can breathe in air
    protected boolean breathesInWater; // Can breathe in water
}
```

## Environment Constraints

```java
class Role {
    protected boolean stayInEnvironment;
    protected String allowedEnvironments;
}
```

- `stayInEnvironment` - Whether to stay within allowed environments
- `allowedEnvironments` - Comma-separated list of allowed environment IDs

## Flock Configuration

```java
class Role {
    protected String[] flockSpawnTypes;
    protected boolean flockSpawnTypesRandom;
    protected String[] flockAllowedRoles;
    protected boolean canLeadFlock;
    protected double flockWeightAlignment;
    protected double flockWeightSeparation;
    protected double flockWeightCohesion;
    protected double flockInfluenceRange;
    protected boolean corpseStaysInFlock;
}
```

See [Flock System](/modding/flock) for details on flock behaviors.

## Inventory Configuration

```java
class Role {
    protected int inventorySlots;
    protected String inventoryContentsDropList;
    protected int hotbarSlots;
    protected String[] hotbarItems;
    protected int offHandSlots;
    protected byte defaultOffHandSlot;
    protected String[] offHandItems;
}
```

- `inventorySlots` - Number of inventory slots
- `hotbarSlots` - Number of hotbar slots
- `hotbarItems` - Default items in hotbar
- `offHandSlots` - Number of off-hand slots
- `offHandItems` - Default items in off-hand

## Death Configuration

```java
class Role {
    protected boolean pickupDropOnDeath;
    protected double deathAnimationTime;
    protected float despawnAnimationTime;
    protected String dropListId;
    protected String deathInteraction;
}
```

- `pickupDropOnDeath` - Whether items can be picked up on death
- `deathAnimationTime` - Duration of death animation
- `despawnAnimationTime` - Duration of despawn animation
- `dropListId` - ID of loot table for drops
- `deathInteraction` - Interaction to trigger on death

## Steering

```java
class Role {
    protected Steering bodySteering;
    protected Steering headSteering;
    protected SteeringForceAvoidCollision steeringForceAvoidCollision;
    protected GroupSteeringAccumulator groupSteeringAccumulator;
    protected Vector3d separation;
}
```

The role maintains steering objects that are updated each tick to control movement.

## Motion Controllers

```java
class Role {
    protected Map<String, MotionController> motionControllers;
}
```

Named motion controllers for different movement behaviors:

```java
role.getMotionController("walk");
role.getMotionController("run");
role.getMotionController("fly");
```

## Role Stats

Located at `com.hypixel.hytale.server.npc.role.support.RoleStats`

Tracks runtime statistics:

- Total ticks alive
- Distance traveled
- Damage dealt/received
- Kills
- Custom stat tracking

## Balance Assets

```java
class Role {
    protected String balanceAsset;
}
```

References a balance asset for tweaking NPC parameters:

- Damage values
- Speed multipliers
- Health scaling
- Other tunable parameters

## Interaction Variables

```java
class Role {
    protected Map<String, String> interactionVars;
}
```

Variables available to the interaction system:

- Dialogue variables
- Quest state
- Custom interaction data

## Deferred Actions

```java
class Role {
    protected List<DeferredAction> deferredActions;
}
```

Actions that are scheduled to execute later:

- Delayed spawns
- Timed events
- State changes

## Role Lifecycle

### Creation

Roles are created from asset data through the builder system:

Located at `com.hypixel.hytale.server.npc.role.builders.BuilderRole`

```java
BuilderRole builder = new BuilderRole();
Role role = builder.build(assetData, support);
```

### Activation

When a role is activated on an NPC:

```java
role.activate(ref, npcEntity, componentAccessor);
```

### Updates

Roles are updated each tick:

```java
role.tick(ref, npcEntity, dt, store);
```

### State Changes

When state changes occur:

```java
role.stateChanged(ref, npcEntity, componentAccessor);
```

### Role Changes

NPCs can change roles at runtime:

```java
npcEntity.changeRole(newRoleIndex);
```

This triggers:
1. Deactivation of old role
2. Cleanup of old role state
3. Activation of new role
4. Initialization of new role state

### Removal

When an NPC is removed:

```java
role.deactivate(ref, npcEntity);
```

## Role Assets

Roles are defined in JSON asset files:

```json
{
  "id": "example_npc_role",
  "roleName": "Guard",
  "appearance": "guard_model",
  "health": 100,
  "movement": {
    "speed": 3.5,
    "inertia": 0.8
  },
  "combat": {
    "damage": 10,
    "attackRange": 2.0
  },
  "inventory": {
    "slots": 27,
    "hotbar": ["sword", "shield"]
  },
  "instructions": [
    // Instruction definitions
  ]
}
```

## Role Utils

Located at `com.hypixel.hytale.server.npc.role.RoleUtils`

Utility functions for role management:

- Role lookup by ID
- Role validation
- Role comparison
- Role cloning

## Performance Considerations

Roles contain many fields and objects, so:

1. **Reuse roles** - Don't create new role instances unnecessarily
2. **Pool motion controllers** - Reuse controller instances
3. **Cache lookups** - Use position cache and entity cache
4. **Lazy initialization** - Only create support objects when needed
5. **Clean up references** - Clear entity references when no longer needed

## Best Practices

1. **Organize by purpose** - Create distinct roles for different NPC types
2. **Share common behavior** - Use role inheritance or composition
3. **Balance complexity** - Too many instructions can hurt performance
4. **Test state transitions** - Ensure smooth role changes
5. **Document role behavior** - Describe expected behavior in comments
6. **Version roles** - Track role changes for compatibility

## Examples

### Combat NPC

```java
Role combatRole = new Role();
combatRole.setRoleName("Warrior");
combatRole.setInitialMaxHealth(150);
combatRole.setCombatSupport(new CombatSupport());
combatRole.setHotbarItems(new String[]{"sword", "shield"});
// Configure combat instructions...
```

### Passive NPC

```java
Role passiveRole = new Role();
passiveRole.setRoleName("Villager");
passiveRole.setInvulnerable(true);
passiveRole.setAvoidanceMode(AvoidanceMode.AVOID_ALL);
// Configure interaction instructions...
```

### Flying NPC

```java
Role flyingRole = new Role();
flyingRole.setRoleName("Bird");
flyingRole.setMotionController("fly", flyController);
flyingRole.setAllowedEnvironments("sky,mountain");
// Configure flying behavior...
```

## Related Systems

- [Instructions](/modding/npc-ai/instructions) - Role contains instruction trees
- [Decision Makers](/modding/npc-ai/decision-makers) - State evaluation for roles
- [Navigation](/modding/npc-ai/navigation) - Movement configuration in roles
- [Spawning System](/modding/spawning) - Spawns NPCs with roles
- [Flock System](/modding/flock) - Flock behavior configured in roles
