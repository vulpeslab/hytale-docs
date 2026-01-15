---
author: UnlimitedBytes
title: Projectile System
description: Projectile spawning, physics simulation, trajectory calculation, and collision detection.
sidebar:
  order: 2
---

The Projectile System handles spawning and simulating projectiles like arrows, spells, and thrown items with configurable physics.

## Core Components

### ProjectileModule

The main module class for the projectile system.

**Location:** `com.hypixel.hytale.server.core.modules.projectile.ProjectileModule`

**Dependencies:** `EntityModule`, `CollisionModule`

```java
// Get the module instance
ProjectileModule module = ProjectileModule.get();

// Spawn a projectile
Ref<EntityStore> projectileRef = module.spawnProjectile(
    creatorRef,
    commandBuffer,
    config,
    position,
    direction
);
```

### Projectile Component

Marker component that identifies an entity as a projectile.

**Location:** `com.hypixel.hytale.server.core.modules.projectile.component.Projectile`

```java
// Get component type
ComponentType<EntityStore, Projectile> type = Projectile.getComponentType();

// Check if entity is a projectile
boolean isProjectile = store.hasComponent(entityRef, type);

// Add projectile component
holder.ensureComponent(Projectile.getComponentType());
```

### PredictedProjectile Component

Component for client-predicted projectiles to sync with server.

**Location:** `com.hypixel.hytale.server.core.modules.projectile.component.PredictedProjectile`

```java
ComponentType<EntityStore, PredictedProjectile> type = 
    ProjectileModule.get().getPredictedProjectileComponentType();
```

## Projectile Configuration

Projectiles are configured through JSON assets.

### ProjectileConfig

**Location:** `com.hypixel.hytale.server.core.modules.projectile.config.ProjectileConfig`

**Asset Path:** `Projectile/{id}.json`

```json
{
  "Physics": {
    "Type": "Standard",
    "Density": 700.0,
    "Gravity": 9.8,
    "Bounciness": 0.3,
    "BounceCount": 3,
    "TerminalVelocityAir": 50.0,
    "DensityAir": 1.2,
    "TerminalVelocityWater": 10.0,
    "DensityWater": 998.0
  },
  "Model": "hytale:projectile/arrow",
  "LaunchForce": 30.0,
  "SpawnOffset": {
    "x": 0.0,
    "y": 1.6,
    "z": 0.0
  },
  "SpawnRotationOffset": {
    "pitch": 0.0,
    "yaw": 0.0,
    "roll": 0.0
  },
  "Interactions": {
    "ProjectileImpact": "hytale:arrow_impact"
  },
  "LaunchLocalSoundEventId": "hytale:bow_shoot",
  "LaunchWorldSoundEventId": "hytale:bow_shoot_world",
  "ProjectileSoundEventId": "hytale:arrow_flight"
}
```

**Key Configuration Fields:**

- `Physics` - Physics configuration (see Physics Config below)
- `Model` - Model asset ID for the projectile
- `LaunchForce` - Initial velocity multiplier
- `SpawnOffset` - Offset from spawner position
- `SpawnRotationOffset` - Rotation offset in degrees
- `Interactions` - Map of InteractionType to RootInteraction IDs
- `LaunchLocalSoundEventId` - Sound played to shooter
- `LaunchWorldSoundEventId` - 3D positioned sound for nearby players
- `ProjectileSoundEventId` - Looping sound attached to projectile

```java
// Get projectile config from asset store
ProjectileConfig config = ProjectileConfig.getAssetMap().getAsset("hytale:arrow");

// Access config properties
PhysicsConfig physics = config.getPhysicsConfig();
Model model = config.getModel();
double launchForce = config.getLaunchForce();
Map<InteractionType, String> interactions = config.getInteractions();
```

## Physics System

### PhysicsConfig

Base interface for projectile physics configurations.

**Location:** `com.hypixel.hytale.server.core.modules.projectile.config.PhysicsConfig`

```java
public interface PhysicsConfig {
    double getGravity();
    
    void apply(
        Holder<EntityStore> holder,
        Ref<EntityStore> creatorRef,
        Vector3d velocity,
        ComponentAccessor<EntityStore> componentAccessor,
        boolean predicted
    );
    
    com.hypixel.hytale.protocol.PhysicsConfig toPacket();
}
```

### StandardPhysicsConfig

Standard ballistic physics implementation with air resistance, gravity, and bouncing.

**Location:** `com.hypixel.hytale.server.core.modules.projectile.config.StandardPhysicsConfig`

**Physics Properties:**

**Basic Physics:**
- `Density` (default: 700.0) - Projectile density in kg/m³
- `Gravity` (default: 0.0) - Gravity acceleration
- `Bounciness` (0.0-1.0) - Energy retained on bounce
- `BounceCount` (default: -1) - Max bounces (-1 = unlimited)
- `BounceLimit` (default: 0.4) - Minimum velocity to bounce
- `SticksVertically` (default: false) - Stick to walls when vertical

**Rotation:**
- `ComputeYaw` (default: true) - Auto-calculate yaw from velocity
- `ComputePitch` (default: true) - Auto-calculate pitch from velocity
- `RotationMode` - How rotation is calculated:
  - `VelocityDamped` - Smooth rotation following velocity
  - `Velocity` - Instant rotation to velocity direction
  - `None` - No automatic rotation
- `RotationForce` (default: 3.0) - Rotation smoothing factor
- `SpeedRotationFactor` (default: 2.0) - Speed influence on rotation

**Air Physics:**
- `TerminalVelocityAir` (default: 1.0) - Max speed in air
- `DensityAir` (default: 1.2) - Air density for drag calculation

**Water Physics:**
- `TerminalVelocityWater` (default: 1.0) - Max speed in water
- `DensityWater` (default: 998.0) - Water density
- `HitWaterImpulseLoss` (default: 0.2) - Energy lost entering water
- `SwimmingDampingFactor` (default: 1.0) - Additional water drag

**Rolling Physics:**
- `AllowRolling` (default: false) - Can projectile roll on ground
- `RollingFrictionFactor` (default: 0.99) - Friction when rolling
- `RollingSpeed` (default: 0.1) - Angular velocity when rolling

**Other:**
- `MoveOutOfSolidSpeed` (default: 0.0) - Speed to escape stuck in blocks

### StandardPhysicsProvider

Component added to projectiles using StandardPhysicsConfig that stores physics state.

**Location:** `com.hypixel.hytale.server.core.modules.projectile.config.StandardPhysicsProvider`

```java
ComponentType<EntityStore, StandardPhysicsProvider> type = 
    ProjectileModule.get().getStandardPhysicsProviderComponentType();
```

## Ballistic Data

### BallisticData Interface

Provides trajectory calculation data for client prediction.

**Location:** `com.hypixel.hytale.server.core.modules.projectile.config.BallisticData`

```java
public interface BallisticData {
    double getGravity();
}
```

### BallisticDataProvider

Component that provides BallisticData for an interaction.

**Location:** `com.hypixel.hytale.server.core.modules.projectile.config.BallisticDataProvider`

## Spawning Projectiles

### Basic Spawning

```java
// Get projectile config
ProjectileConfig config = ProjectileConfig.getAssetMap()
    .getAsset("hytale:fireball");

// Define spawn position and direction
Vector3d position = new Vector3d(100, 64, 100);
Vector3d direction = new Vector3d(1, 0, 0); // East direction

// Spawn projectile
Ref<EntityStore> projectileRef = ProjectileModule.get().spawnProjectile(
    shooterRef,      // Creator entity reference
    commandBuffer,   // Command buffer for adding entity
    config,          // Projectile configuration
    position,        // Spawn position
    direction        // Launch direction (normalized)
);
```

### Predicted Spawning

For client-side prediction synchronization:

```java
// Client generates UUID for prediction
UUID predictionId = UUID.randomUUID();

// Server spawns with same UUID
Ref<EntityStore> projectileRef = ProjectileModule.get().spawnProjectile(
    predictionId,    // Prediction UUID (null for server-only)
    shooterRef,
    commandBuffer,
    config,
    position,
    direction
);
```

### Projectile Spawning Details

When a projectile is spawned, the following happens:

1. **Transform Setup:**
   - Position is offset by `SpawnOffset` from config
   - Direction is adjusted by `SpawnRotationOffset`
   - Initial rotation is calculated from direction

2. **Components Added:**
   - `TransformComponent` - Position and rotation
   - `HeadRotation` - Rotation tracking
   - `ModelComponent` - Visual model
   - `BoundingBox` - Collision bounds from model
   - `NetworkId` - Network sync ID
   - `Projectile` - Projectile marker
   - `Velocity` - Initial velocity vector
   - `DespawnComponent` - Auto-despawn after 5 minutes
   - `AudioComponent` - Optional looping sound
   - Physics provider (e.g., `StandardPhysicsProvider`)

3. **Interactions:**
   - Interactions from config are added to `Interactions` component
   - `ProjectileSpawn` interaction runs if creator has InteractionManager

4. **Sounds:**
   - `LaunchWorldSoundEvent` plays at spawn position
   - `LaunchLocalSoundEvent` plays for shooter
   - `ProjectileSoundEvent` loops with projectile

## Collision Handling

### Impact Events

When a projectile collides, the `ProjectileImpact` interaction runs:

```json
{
  "Interactions": {
    "ProjectileImpact": "hytale:arrow_stick"
  }
}
```

The impact interaction receives context about the collision:
- Hit entity (if any)
- Hit block position (if any)
- Impact point
- Impact normal

### Bounce Behavior

Configure bouncing with physics properties:

```json
{
  "Physics": {
    "Type": "Standard",
    "Bounciness": 0.6,
    "BounceCount": 5,
    "BounceLimit": 0.5
  }
}
```

- Projectile bounces when hitting surfaces
- Each bounce consumes one count (if limited)
- Velocity is multiplied by `Bounciness`
- Stops bouncing when speed < `BounceLimit`

### Sticking Behavior

Make projectiles stick to walls:

```json
{
  "Physics": {
    "Type": "Standard",
    "SticksVertically": true,
    "Bounciness": 0.0
  }
}
```

## Projectile Interactions

### ProjectileInteraction

Interaction type that spawns a projectile.

**Location:** `com.hypixel.hytale.server.core.modules.projectile.interaction.ProjectileInteraction`

```json
{
  "Type": "Projectile",
  "Config": "hytale:arrow"
}
```

Can be used in any interaction chain to launch a projectile.

## Systems

### StandardPhysicsTickSystem

Updates projectile physics each tick for entities with `StandardPhysicsProvider`.

**Location:** `com.hypixel.hytale.server.core.modules.projectile.system.StandardPhysicsTickSystem`

Handles:
- Gravity application
- Velocity updates
- Drag/air resistance
- Water physics
- Collision detection
- Rotation updates
- Bouncing
- Rolling

### PredictedProjectileSystems

Systems for handling client-predicted projectiles.

**Location:** `com.hypixel.hytale.server.core.modules.projectile.system.PredictedProjectileSystems`

**EntityTrackerUpdate:** Updates entity tracker for predicted projectiles.

## Example: Arrow Projectile

```json
{
  "Physics": {
    "Type": "Standard",
    "Density": 700.0,
    "Gravity": 20.0,
    "Bounciness": 0.0,
    "SticksVertically": true,
    "TerminalVelocityAir": 80.0,
    "ComputeYaw": true,
    "ComputePitch": true,
    "RotationMode": "VelocityDamped"
  },
  "Model": "hytale:projectile/arrow",
  "LaunchForce": 40.0,
  "SpawnOffset": {"x": 0.0, "y": 1.5, "z": 0.5},
  "Interactions": {
    "ProjectileImpact": "hytale:arrow_impact"
  },
  "LaunchWorldSoundEventId": "hytale:bow_shoot"
}
```

## Example: Bouncing Grenade

```json
{
  "Physics": {
    "Type": "Standard",
    "Density": 1200.0,
    "Gravity": 20.0,
    "Bounciness": 0.7,
    "BounceCount": 10,
    "BounceLimit": 1.0,
    "AllowRolling": true,
    "RollingFrictionFactor": 0.95
  },
  "Model": "hytale:projectile/grenade",
  "LaunchForce": 25.0,
  "Interactions": {
    "ProjectileImpact": "hytale:grenade_bounce"
  }
}
```

## Example: Magic Missile

```json
{
  "Physics": {
    "Type": "Standard",
    "Density": 100.0,
    "Gravity": 0.0,
    "TerminalVelocityAir": 60.0,
    "DensityAir": 0.5,
    "ComputeYaw": true,
    "ComputePitch": true,
    "RotationMode": "Velocity"
  },
  "Model": "hytale:projectile/magic_missile",
  "LaunchForce": 50.0,
  "SpawnOffset": {"x": 0.0, "y": 1.6, "z": 0.0},
  "Interactions": {
    "ProjectileImpact": "hytale:magic_explosion"
  },
  "ProjectileSoundEventId": "hytale:magic_whoosh"
}
```

## Example: Spawning from Code

```java
public class FireballLauncher {
    public void launchFireball(
        Ref<EntityStore> shooterRef,
        CommandBuffer<EntityStore> commandBuffer
    ) {
        // Get config
        ProjectileConfig config = ProjectileConfig.getAssetMap()
            .getAsset("mymod:fireball");
        if (config == null) return;
        
        // Get shooter transform
        TransformComponent transform = commandBuffer.getComponent(
            shooterRef, 
            TransformComponent.getComponentType()
        );
        if (transform == null) return;
        
        // Calculate launch position and direction
        Vector3d position = transform.getPosition().clone();
        position.y += 1.6; // Eye height
        
        Vector3d direction = new Vector3d(
            transform.getRotation().getYaw(),
            transform.getRotation().getPitch()
        );
        
        // Spawn projectile
        Ref<EntityStore> projectile = ProjectileModule.get().spawnProjectile(
            shooterRef,
            commandBuffer,
            config,
            position,
            direction
        );
        
        // Projectile now exists and will be simulated by StandardPhysicsTickSystem
    }
}
```

## Collision and Impact Consumers

### ImpactConsumer

Handler for when projectiles impact surfaces.

**Location:** `com.hypixel.hytale.server.core.modules.projectile.config.ImpactConsumer`

### BounceConsumer

Handler for when projectiles bounce off surfaces.

**Location:** `com.hypixel.hytale.server.core.modules.projectile.config.BounceConsumer`

These are internal interfaces used by physics systems for handling collision events.
