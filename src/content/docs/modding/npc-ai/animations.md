---
title: Animations
description: NPC animation state management
---

The animation system manages NPC animation states and transitions, allowing NPCs to display appropriate animations based on their current behavior and state.

## Overview

Located at `com.hypixel.hytale.server.npc.animations`

The animation system provides:

- Animation state management
- Animation transitions
- Animation synchronization with behavior
- Model-based animation control

## Animation Components

### Core Animation System

Animations are managed through the core component system:

Located at `com.hypixel.hytale.server.npc.corecomponents.audiovisual`

Provides builders for:
- Animation triggers
- Animation state machines
- Sound effects
- Visual effects

### Animation Builders

Located at `com.hypixel.hytale.server.npc.corecomponents.audiovisual.builders`

Builder pattern for creating animation components from asset data.

## Model Integration

Animations are tied to NPC models through the model system:

Located at `com.hypixel.hytale.server.core.modules.entity.component.ModelComponent`

The `ModelComponent` stores:
- Current model
- Animation state
- Model variants
- Visual properties

### Model Assets

Models are loaded from asset files:

Located at `com.hypixel.hytale.server.core.asset.type.model.config.ModelAsset`

Defines:
- Model geometry
- Available animations
- Animation metadata
- Skeleton structure

## Animation States

Animation states are controlled through several mechanisms:

### Movement States

Located at `com.hypixel.hytale.protocol.MovementStates`

Standard movement states that trigger animations:

- Idle
- Walking
- Running
- Jumping
- Falling
- Swimming
- Flying
- Climbing

### Combat States

Combat-related animation states:

- Attacking
- Defending/Blocking
- Taking Damage
- Death
- Respawn

### Interaction States

Interaction animation states:

- Interacting with objects
- Using items
- Trading
- Dialogue poses

### Custom States

Roles can define custom animation states through:

- State machine configurations
- Custom triggers
- Scripted sequences

## Animation Triggers

Animations can be triggered by:

### Instruction Actions

Actions within instructions can trigger animations:

```java
// Trigger attack animation
AnimationAction attackAnim = new AnimationAction("attack");
attackAnim.execute(ref, role, sensorInfo, dt, store);
```

### State Changes

State transitions automatically trigger animations:

```java
// Moving from idle to combat triggers combat stance animation
role.changeState("combat");
```

### Events

Specific events trigger animations:

- Damage events → hurt animation
- Death events → death animation
- Item use → use animation

### Manual Triggers

Code can manually trigger animations:

```java
modelComponent.setAnimation("custom_animation");
```

## Animation Synchronization

Animations are synchronized with:

### Body Motion

The `BodyMotion` instruction component controls body animations:

- Walk/run animations match movement speed
- Turn animations match rotation
- Slope animations match terrain angle

### Head Motion

The `HeadMotion` instruction component controls head animations:

- Look direction
- Head tracking
- Independent head rotation

### Actions

Actions trigger corresponding animations:

- Attack action → attack animation
- Item use → use animation
- Interaction → interaction animation

## Animation Priority

When multiple animations could play, priority determines which plays:

1. **Death/Critical** - Highest priority
2. **Combat** - High priority
3. **Interaction** - Medium priority
4. **Movement** - Low priority
5. **Idle** - Lowest priority

Higher priority animations interrupt lower priority ones.

## Animation Blending

The system supports animation blending:

- **Upper body** - Separate from lower body (e.g., attack while walking)
- **Additive animations** - Layer on top of base animations
- **Transition blending** - Smooth transitions between animations

## Animation Configuration

Animations are configured through:

### Role Assets

Role definitions specify animation behavior:

```json
{
  "animations": {
    "idle": "guard_idle",
    "walk": "guard_walk",
    "attack": "guard_attack",
    "death": "guard_death"
  }
}
```

### Model Assets

Model assets define available animations:

```json
{
  "animations": [
    {
      "name": "guard_idle",
      "duration": 2.0,
      "loop": true
    },
    {
      "name": "guard_attack",
      "duration": 0.5,
      "loop": false
    }
  ]
}
```

### Core Components

Core component builders configure animation triggers:

```json
{
  "type": "PlayAnimation",
  "animation": "attack",
  "priority": 5
}
```

## Animation Parameters

Animations can have parameters:

- **Speed** - Animation playback speed
- **Start time** - Where in animation to start
- **Loop** - Whether animation loops
- **Blend time** - Transition duration
- **Priority** - Animation priority level

## Animation Events

Animations can trigger events at specific frames:

- **Sound events** - Play sounds at keyframes
- **Particle events** - Spawn particles during animation
- **Damage events** - Deal damage at specific frames
- **Callback events** - Trigger code at keyframes

## Death Animations

Death has special animation handling:

```java
class Role {
    protected double deathAnimationTime;
    protected float despawnAnimationTime;
}
```

- `deathAnimationTime` - Duration of death animation
- `despawnAnimationTime` - Duration of fade-out/despawn

Death sequence:
1. Trigger death animation
2. Play for `deathAnimationTime` seconds
3. Start despawn animation
4. Fade out over `despawnAnimationTime` seconds
5. Remove entity

## Performance Considerations

### Animation Updates

Animations are updated:
- Every tick for visible NPCs
- Less frequently for distant NPCs
- Not at all for off-screen NPCs

### LOD (Level of Detail)

Animation complexity scales with distance:

- **Close** - Full animation with blending
- **Medium** - Simplified animation
- **Far** - Static pose or no animation

### Animation Caching

- Cache animation state to avoid recalculation
- Reuse animation data across similar NPCs
- Pool animation objects

## Debugging Animations

Tools for debugging animations:

- Visual animation state display
- Animation transition logging
- Frame-by-frame playback
- Animation timeline view

## Integration with Client

The server sends animation state to clients:

- Current animation name
- Animation time/progress
- Animation parameters
- Transition state

Clients interpolate and render animations locally.

## Best Practices

1. **Use standard states** - Leverage built-in movement/combat states
2. **Test transitions** - Ensure smooth animation transitions
3. **Set appropriate durations** - Match animation length to action duration
4. **Use priorities** - Prevent animation conflicts
5. **Optimize distant NPCs** - Reduce animation updates for far NPCs
6. **Avoid rapid changes** - Prevent animation flickering

## Common Patterns

### Walk Animation

```java
// Automatically triggered by movement
// Speed scales with movement speed
if (moving) {
    animation = isRunning ? "run" : "walk";
    animationSpeed = movementSpeed / baseSpeed;
}
```

### Attack Animation

```java
// Triggered by attack action
// Damage dealt at specific frame
attackAction.trigger();
// → plays "attack" animation
// → frame 15: deal damage
// → return to idle
```

### State-Based Animation

```java
// Animation changes with NPC state
switch (currentState) {
    case IDLE: animation = "idle"; break;
    case ALERT: animation = "alert"; break;
    case COMBAT: animation = "combat_stance"; break;
    case FLEE: animation = "flee"; break;
}
```

### Layered Animation

```java
// Upper body independent from lower body
lowerBody.setAnimation("walk");
upperBody.setAnimation("attack");
// Result: attacking while walking
```

## Related Systems

- [Roles](/modding/npc-ai/roles) - Configure animation behavior
- [Instructions](/modding/npc-ai/instructions) - Trigger animations
- Model System - Defines available animations
- Entity System - Stores animation state
