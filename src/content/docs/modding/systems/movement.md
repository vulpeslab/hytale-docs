---
title: Movement & Locomotion System
description: Understanding the movement states and locomotion system in Hytale, including walking, sprinting, crouching, sliding, mantling, and gliding
---

The movement and locomotion system in Hytale manages all entity movement states and behaviors. The system tracks various movement states that affect animations, physics, and gameplay mechanics.

## Core Components

### MovementStatesComponent

Located in `com.hypixel.hytale.server.core.entity.movement`, this component tracks the current movement states of an entity.

```java
public class MovementStatesComponent implements Component<EntityStore> {
    private MovementStates movementStates = new MovementStates();
    private MovementStates sentMovementStates = new MovementStates();
}
```

**Fields:**
- `movementStates` - The current movement states of the entity
- `sentMovementStates` - The last movement states sent to clients (for network optimization)

This component is automatically added to all living entities via the `MovementStatesSystems.AddSystem`.

### MovementStates

The `MovementStates` class (in `com.hypixel.hytale.protocol`) contains boolean flags for all possible movement states:

```java
public class MovementStates {
    public boolean idle;
    public boolean horizontalIdle;
    public boolean jumping;
    public boolean flying;
    public boolean walking;
    public boolean running;
    public boolean sprinting;
    public boolean crouching;
    public boolean forcedCrouching;
    public boolean falling;
    public boolean climbing;
    public boolean inFluid;
    public boolean swimming;
    public boolean swimJumping;
    public boolean onGround;
    public boolean mantling;
    public boolean sliding;
    public boolean mounting;
    public boolean rolling;
    public boolean sitting;
    public boolean gliding;
    public boolean sleeping;
}
```

## Movement States Reference

### Basic Movement States

**idle** - Entity is completely stationary
- No input being received
- Not moving horizontally or vertically

**horizontalIdle** - Entity is not moving horizontally
- May still be falling or jumping
- Used for animation blending

**onGround** - Entity is standing on a solid surface
- Affects fall damage calculation
- Required for jumping

### Walking & Running

**walking** - Entity is moving at normal speed
- Base movement speed
- Typically activated with movement input

**running** - Entity is moving faster than walking
- Intermediate speed between walking and sprinting
- May be the default movement state in some configurations

**sprinting** - Entity is moving at maximum speed
- Requires stamina in many configurations
- May have cooldown or stamina drain
- See `SprintStaminaRegenDelay` for stamina interaction

### Vertical Movement

**jumping** - Entity is performing a jump
- Applies upward velocity
- Typically one-time action

**falling** - Entity is falling through the air
- Used for fall damage calculation
- Affects movement control

**climbing** - Entity is climbing a ladder or wall
- Special movement rules apply
- May have different movement speed

**mantling** - Entity is climbing over an obstacle
- Automated climbing action
- Typically triggered when approaching ledges

### Crouching & Sliding

**crouching** - Entity is voluntarily crouching
- Reduces hitbox size
- Typically slower movement speed
- Player-controlled state

**forcedCrouching** - Entity is forced to crouch
- Occurs in low-ceiling areas
- Not player-controlled
- Prevents standing up

**sliding** - Entity is performing a crouch slide
- Occurs when crouching while moving at high speed
- Maintains momentum while crouched
- May have distance/time limitations

### Fluid Movement

**inFluid** - Entity is inside a fluid (water, lava, etc.)
- Changes physics behavior
- May affect breathing/drowning

**swimming** - Entity is actively swimming
- Directional movement in fluid
- Different from just being in fluid

**swimJumping** - Entity is performing a swim jump
- Jumping out of or through water
- Special animation state

### Special States

**flying** - Entity is flying
- Creative mode or special abilities
- Ignores gravity

**mounting** - Entity is mounting or riding something
- See the Mounts System for details
- Affects movement control

**sitting** - Entity is sitting
- Typically from sitting on blocks or furniture
- Restricted movement

**rolling** - Entity is performing a roll
- Combat/evasion maneuver
- Brief animation state

**gliding** - Entity is gliding (e.g., with elytra/glider)
- See `ItemGlider` configuration
- Special flight physics
- Controlled descent

**sleeping** - Entity is sleeping in a bed
- Restricted movement
- May affect time progression

## Movement State Systems

### AddSystem

Ensures all living entities have the `MovementStatesComponent`.

```java
public static class AddSystem extends HolderSystem<EntityStore> {
    @Override
    public Query<EntityStore> getQuery() {
        return AllLegacyLivingEntityTypesQuery.INSTANCE;
    }
}
```

### TickingSystem

Synchronizes movement states between server and clients.

```java
public static class TickingSystem extends EntityTickingSystem<EntityStore> {
    @Override
    public void tick(float dt, int index, ArchetypeChunk<EntityStore> archetypeChunk,
                     Store<EntityStore> store, CommandBuffer<EntityStore> commandBuffer) {
        MovementStatesComponent component = archetypeChunk.getComponent(index, type);
        MovementStates current = component.getMovementStates();
        MovementStates sent = component.getSentMovementStates();
        
        // Only send updates if states changed
        if (!current.equals(sent)) {
            copyMovementStatesFrom(current, sent);
            queueUpdatesFor(ref, visibleComponent.visibleTo, component);
        }
    }
}
```

**Network Optimization:**
- Only sends updates when states change
- Sends to newly visible entities
- Uses efficient component updates

### PlayerInitSystem

Restores saved movement states when a player joins.

```java
public static class PlayerInitSystem extends RefSystem<EntityStore> {
    @Override
    public void onEntityAdded(Ref<EntityStore> ref, AddReason reason,
                             Store<EntityStore> store, CommandBuffer<EntityStore> commandBuffer) {
        PlayerWorldData perWorldData = playerComponent.getPlayerConfigData()
            .getPerWorldData(world.getName());
        SavedMovementStates savedStates = perWorldData.getLastMovementStates();
        playerComponent.applyMovementStates(ref, savedStates, currentStates, store);
    }
}
```

## Sprint System

Sprinting is controlled through movement states and interacts with the stamina system.

### Stamina Integration

**SprintStaminaRegenDelay** - Delays stamina regeneration after sprinting
- Located in `com.hypixel.hytale.server.core.modules.entity.stamina`
- Prevents instant stamina recovery
- Configurable delay duration

### Sprint Condition

**SprintingCondition** - Entity stat condition based on sprinting state
- Located in `com.hypixel.hytale.server.core.modules.entitystats.asset.condition`
- Can be used in entity stat modifiers
- Allows stats to change when sprinting (e.g., increased damage, reduced defense)

## Crouch & Slide Mechanics

### Crouch Sliding

Crouch sliding occurs when:
1. Entity is moving at high speed
2. Crouch input is activated
3. Entity is on the ground

The `sliding` state is set and the entity maintains horizontal momentum while in a crouched position.

**Implementation Notes:**
- Slides have physics-based deceleration
- Can be cancelled by standing up
- May have configuration for minimum speed or maximum duration

### Forced Crouching

When an entity enters a space with low ceiling:
1. `forcedCrouching` state is set to `true`
2. Entity cannot stand up while in confined space
3. Normal crouching becomes disabled
4. Automatically cleared when space is available

## Mantling System

Mantling allows entities to climb over obstacles automatically.

### Triggering Mantling

Mantling typically occurs when:
1. Entity is moving toward a ledge
2. Ledge height is within mantling range
3. Enough space exists on top of the ledge
4. `mantling` state is activated

### Mantle Behavior

During mantling:
- Entity position is smoothly interpolated upward
- Forward movement continues
- May play special animations
- Other movement inputs may be restricted

## Gliding System

Gliding allows entities to descend slowly through the air.

### Glider Items

Gliders are configured through the `ItemGlider` asset:

```java
public class ItemGlider {
    // Configuration for glider items
}
```

Located in `com.hypixel.hytale.server.core.asset.type.item.config`.

### Toggle Glider Interaction

**ToggleGliderInteraction** - Activates/deactivates glider
- Located in `com.hypixel.hytale.server.core.modules.interaction.interaction.config.client`
- Client interaction to toggle gliding state
- Requires glider item equipped

### Gliding Physics

When `gliding` is true:
- Gravity is reduced
- Forward momentum is maintained
- Directional control is available
- Special flight physics apply

## Using Movement States

### Reading Movement States

```java
// Get component
MovementStatesComponent component = store.getComponent(entityRef, 
    MovementStatesComponent.getComponentType());

// Check states
MovementStates states = component.getMovementStates();
if (states.sprinting) {
    // Entity is sprinting
}
if (states.onGround && !states.jumping) {
    // Entity is standing still on ground
}
```

### Modifying Movement States

```java
// Get component
MovementStatesComponent component = commandBuffer.getComponent(entityRef,
    MovementStatesComponent.getComponentType());

// Modify states
MovementStates states = component.getMovementStates();
states.gliding = true;
states.falling = false;

// States will be synchronized to clients by TickingSystem
```

### Creating State-Dependent Systems

```java
public class SprintDamageBonus extends DamageEventSystem {
    @Override
    public void onEvent(Damage damage, Ref<EntityStore> targetRef,
                       Store<EntityStore> store, CommandBuffer<EntityStore> commandBuffer) {
        // Get attacker if it's an entity source
        if (!(damage.getSource() instanceof Damage.EntitySource entitySource)) {
            return;
        }
        
        // Check if attacker is sprinting
        MovementStatesComponent component = store.getComponent(
            entitySource.getRef(), MovementStatesComponent.getComponentType());
        
        if (component != null && component.getMovementStates().sprinting) {
            // Increase damage by 50%
            damage.setAmount(damage.getAmount() * 1.5f);
        }
    }
}
```

### Detecting State Transitions

```java
public class SlideStartDetector extends EntityTickingSystem<EntityStore> {
    @Override
    public void tick(float dt, int index, ArchetypeChunk<EntityStore> archetypeChunk,
                     Store<EntityStore> store, CommandBuffer<EntityStore> commandBuffer) {
        MovementStatesComponent component = archetypeChunk.getComponent(index, type);
        MovementStates current = component.getMovementStates();
        MovementStates previous = component.getSentMovementStates();
        
        // Detect slide start
        if (current.sliding && !previous.sliding) {
            // Slide just started
            Ref<EntityStore> ref = archetypeChunk.getReferenceTo(index);
            handleSlideStart(ref, store, commandBuffer);
        }
    }
}
```

## Movement State Combinations

Common state combinations and their meanings:

**Idle on Ground**
```java
idle && horizontalIdle && onGround && !jumping && !falling
```
- Entity is standing completely still

**Walking**
```java
walking && onGround && !idle && !sprinting
```
- Normal walking movement

**Sprint Jumping**
```java
sprinting && jumping && !onGround
```
- Jumping while sprinting (often farthest jump)

**Crouch Sliding**
```java
crouching && sliding && onGround && !idle
```
- Active slide maneuver

**Swimming on Surface**
```java
swimming && inFluid && !swimJumping
```
- Swimming in water

**Climbing Ladder**
```java
climbing && !onGround && !falling
```
- On a ladder or climbable surface

**Forced Crouch in Tunnel**
```java
forcedCrouching && !crouching && onGround
```
- Auto-crouching due to low ceiling

**Gliding Descent**
```java
gliding && !onGround && !flying
```
- Controlled descent with glider

## Best Practices

1. **Check onGround for ground-based states** - Many actions require the entity to be on ground
2. **Use appropriate state combinations** - Don't set conflicting states (e.g., idle and sprinting)
3. **Let systems manage states** - Many states are automatically managed by core systems
4. **Network optimization** - States are only sent when changed, avoid unnecessary updates
5. **State persistence** - Player states are saved and restored across sessions
6. **Animation integration** - States directly drive animation state machines
7. **Physics interaction** - Movement states affect physics calculations
8. **Use conditions** - Leverage entity stat conditions based on movement states

## Related Systems

- **Physics System** - Applies movement forces based on states
- **Stamina System** - Drains stamina during sprinting
- **Animation System** - Plays animations based on movement states
- **Input System** - Translates player input into movement states
- **Mounts System** - Overrides movement when mounting entities or blocks
- **Entity Stats** - Can modify stats based on movement states
