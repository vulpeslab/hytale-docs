---
author: UnlimitedBytes
title: Instructions
description: Behavioral building blocks for NPC AI including sensors, actions, and motions
human-verified: false
---

Instructions are the core behavioral building blocks of the NPC AI system. They combine sensors (conditions), actions (behaviors), and motions (movement) to create complete NPC behaviors.

## Overview

Located at `com.hypixel.hytale.server.npc.instructions`

An instruction consists of:

1. **Sensor** - Detects when the instruction should execute
2. **Body Motion** (optional) - Controls body/movement steering
3. **Head Motion** (optional) - Controls head orientation
4. **Actions** - Executes specific behaviors
5. **Child Instructions** (optional) - Nested instruction tree

## Instruction Class

The `Instruction` class provides the main instruction implementation:

```java
public class Instruction implements RoleStateChange, IAnnotatedComponent
```

### Key Properties

- `sensor` - The sensor that determines when to execute
- `bodyMotion` - Optional body steering controller
- `headMotion` - Optional head steering controller
- `actions` - List of actions to execute
- `instructionList` - Array of child instructions
- `treeMode` - Whether to use tree-based evaluation
- `continueAfter` - Whether to continue to next instruction after match

### Execution Flow

1. **Match**: `matches()` checks if the sensor conditions are met
2. **Execute**: `execute()` runs the instruction's actions and motions
3. **Complete**: Cleanup and state updates

## Sensors

Sensors determine when an instruction should execute by checking conditions.

### Sensor Interface

Located at `com.hypixel.hytale.server.npc.instructions.Sensor`

```java
public interface Sensor extends RoleStateChange, IAnnotatedComponent {
    boolean matches(Ref<EntityStore> ref, Role role, double dt, Store<EntityStore> store);
    void done();
    InfoProvider getSensorInfo();
}
```

### NullSensor

Default sensor that always returns false:

```java
public static final Sensor NULL = new NullSensor();
```

### Sensor Info

Sensors can provide information through `InfoProvider`:

Located at `com.hypixel.hytale.server.npc.sensorinfo.InfoProvider`

Provides access to:
- Detected entities
- Positions
- Paths
- Custom data

### Info Providers

Located at `com.hypixel.hytale.server.npc.sensorinfo`

#### PositionProvider

Provides position information:

- `EntityPositionProvider` - Position of an entity
- `CachedPositionProvider` - Cached position data
- `IPositionProvider` - Interface for custom position providers

#### PathProvider

Provides path information:

- `PathProvider` - Path data for navigation
- `IPathProvider` - Interface for custom path providers

#### Wrapped Providers

- `WrappedInfoProvider` - Wraps another provider
- `ValueWrappedInfoProvider` - Wraps a value
- `ExtraInfoProvider` - Additional custom data

### Core Component Sensors

NPCs use builder-based sensors registered through the core components system:

Located at `com.hypixel.hytale.server.npc.corecomponents`

Categories:
- **Entity sensors** - Detect entities
- **Combat sensors** - Combat-related detection
- **Interaction sensors** - Player interactions
- **World sensors** - World state
- **Timer sensors** - Time-based triggers
- **Debug sensors** - Debugging tools

## Actions

Actions define what happens when an instruction executes.

### Action Class

Located at `com.hypixel.hytale.server.npc.instructions.Action`

Actions can:
- Modify NPC state
- Trigger events
- Interact with the world
- Execute combat behaviors
- Manage inventory

### ActionList

Located at `com.hypixel.hytale.server.npc.instructions.ActionList`

Manages multiple actions that execute together:

```java
actionList.execute(ref, role, sensorInfo, dt, store);
```

Features:
- Sequential execution
- Conditional execution
- Action prioritization

### Core Component Actions

Action builders registered through the core components:

#### Entity Actions

Located at `com.hypixel.hytale.server.npc.corecomponents.entity`

- Set target entity
- Track entity
- Clear entity reference

#### Combat Actions

Located at `com.hypixel.hytale.server.npc.corecomponents.combat`

- Attack target
- Flee from enemy
- Use abilities

#### Interaction Actions

Located at `com.hypixel.hytale.server.npc.corecomponents.interaction`

- Trigger interactions
- Display dialogue
- Trade with player

#### Lifecycle Actions

Located at `com.hypixel.hytale.server.npc.corecomponents.lifecycle`

- Spawn entities
- Despawn self
- Change role

#### State Machine Actions

Located at `com.hypixel.hytale.server.npc.corecomponents.statemachine`

- Change state
- Set state variables
- Trigger state transitions

#### Timer Actions

Located at `com.hypixel.hytale.server.npc.corecomponents.timer`

- Start timers
- Stop timers
- Reset timers

#### Item Actions

Located at `com.hypixel.hytale.server.npc.corecomponents.items`

- Equip items
- Use items
- Drop items

#### Utility Actions

Located at `com.hypixel.hytale.server.npc.corecomponents.utility`

- Debug logging
- Play sounds
- Spawn particles

#### World Actions

Located at `com.hypixel.hytale.server.npc.corecomponents.world`

- Place blocks
- Break blocks
- Interact with world

## Motions

Motions control NPC movement and orientation.

### BodyMotion

Located at `com.hypixel.hytale.server.npc.instructions.BodyMotion`

Controls body movement steering:

```java
void preComputeSteering(Ref<EntityStore> ref, Role role, InfoProvider info, Store<EntityStore> store);
```

Features:
- Steering force calculation
- Pathfinding integration
- Collision avoidance
- Speed control

### HeadMotion

Located at `com.hypixel.hytale.server.npc.instructions.HeadMotion`

Controls head orientation:

```java
void preComputeSteering(Ref<EntityStore> ref, Role role, InfoProvider info, Store<EntityStore> store);
```

Features:
- Look at target
- Head tracking
- Independent of body rotation

### Motion Class

Base motion interface:

Located at `com.hypixel.hytale.server.npc.instructions.Motion`

Provides lifecycle methods and steering computation.

### Core Component Motions

Motion builders for common movement patterns:

Located at `com.hypixel.hytale.server.npc.corecomponents.movement`

Motion types:
- **Follow** - Follow an entity
- **Wander** - Random wandering
- **Patrol** - Follow a path
- **Flee** - Move away from threat
- **Approach** - Move toward target
- **Circle** - Circle around point
- **Flock** - Flock movement (see [Flock System](/modding/flock))

## Instruction Tree

Instructions can be organized in a tree structure for complex behaviors.

### Tree Mode

When `treeMode = true`:

- Instructions evaluate children sequentially
- Success/failure propagates up the tree
- Allows complex decision trees
- Similar to behavior trees in other engines

### Continue After

When `continueAfter = true`:

- Execution continues to next instruction after match
- Allows multiple instructions to execute per tick
- Useful for layered behaviors

### Root Instruction

Create a root instruction containing child instructions:

```java
Instruction root = Instruction.createRootInstruction(
    childInstructions,
    support
);
```

## Randomized Instructions

Located at `com.hypixel.hytale.server.npc.instructions.InstructionRandomized`

Randomly selects from a set of instructions:

```java
InstructionRandomized randomBehavior = new InstructionRandomized(
    possibleInstructions,
    weights
);
```

## Role State Change

Located at `com.hypixel.hytale.server.npc.instructions.RoleStateChange`

Interface for components that react to role changes:

```java
void stateChanged(Ref<EntityStore> ref, Role role, ComponentAccessor<EntityStore> accessor);
void roleChanged(Ref<EntityStore> ref, Role role, ComponentAccessor<EntityStore> accessor);
```

Implemented by:
- Instructions
- Sensors
- Actions
- Motions

## Lifecycle Methods

Instructions respond to NPC lifecycle events:

```java
void loaded(Role role);        // NPC asset loaded
void spawned(Role role);       // NPC spawned in world
void unloaded(Role role);      // NPC asset unloaded
void removed(Role role);       // NPC removed from world
void teleported(Role role, World from, World to); // NPC teleported
```

## Instruction Builders

Located at `com.hypixel.hytale.server.npc.instructions.builders`

Builder pattern for creating instructions from asset data:

```java
BuilderInstruction builder = new BuilderInstruction();
Instruction instruction = builder.build(assetData, support);
```

## Component Annotations

Instructions implement `IAnnotatedComponent` for debugging and inspection:

Located at `com.hypixel.hytale.server.npc.util.IAnnotatedComponent`

Provides:
- Component hierarchy
- Debug labels
- Component info
- Breadcrumb navigation

## Examples

### Simple Instruction

```java
// When enemy nearby, attack
Instruction attackInstruction = new Instruction(
    enemySensor,              // Sensor: detect enemy
    approachMotion,          // Motion: move toward enemy
    lookAtMotion,            // Head: look at enemy
    attackAction             // Action: perform attack
);
```

### Instruction Tree

```java
// Root behavior
Instruction root = new Instruction(
    alwaysSensor,
    null,
    null,
    new Instruction[] {
        combatInstruction,    // Priority 1: Combat
        fleeInstruction,      // Priority 2: Flee if low health
        wanderInstruction     // Priority 3: Default wander
    }
);
```

### Conditional Chain

```java
// Sequential behavior with continue
Instruction chain = new Instruction(
    triggerSensor,
    null,
    null,
    new Instruction[] {
        firstAction,          // Execute first
        secondAction,         // Then second
        thirdAction          // Then third
    }
);
// Set continueAfter = true on each child
```

## Best Practices

1. **Keep sensors lightweight** - They're evaluated frequently
2. **Use sensor info** - Pass data from sensors to actions efficiently
3. **Separate motion and actions** - Makes behaviors more reusable
4. **Use tree mode** - For complex decision logic
5. **Cache expensive operations** - In the role's support objects
6. **Profile instruction execution** - Monitor performance of complex behaviors

## Performance Tips

- Limit instruction tree depth
- Use early-exit conditions
- Cache sensor results when appropriate
- Avoid creating objects in hot paths
- Use object pools for temporary data

## Related Systems

- [Decision Makers](/modding/npc-ai/decision-makers) - Condition evaluation
- [Navigation](/modding/npc-ai/navigation) - Pathfinding and movement
- [Roles](/modding/npc-ai/roles) - Organize instructions into behaviors
- [Blackboard](/modding/npc-ai/blackboard) - Data source for sensors
