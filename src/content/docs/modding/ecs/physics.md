---
author: UnlimitedBytes
title: Physics System
description: Learn about Hytale's physics simulation system for entities and projectiles.
sidebar:
  order: 4
---

Hytale uses a sophisticated physics system for simulating entity movement, projectile trajectories, and physical interactions. The physics system supports multiple numerical integrators, force accumulation, and collision detection.

## Architecture Overview

```
Physics System
├── PhysicsBodyState         - Position and velocity state
├── ForceAccumulator         - Accumulates forces per tick
├── ForceProvider            - Interface for force sources
│   ├── ForceProviderStandard    - Gravity, drag, friction
│   └── ForceProviderEntity      - Entity-specific forces
├── PhysicsBodyStateUpdater  - Numerical integration
│   ├── SymplecticEuler          - Fast, energy-preserving
│   ├── Midpoint                 - Second-order accuracy
│   └── RK4                      - Fourth-order accuracy
└── CollisionModule          - Block and entity collisions
```

## Core Concepts

### Physics Body State

The `PhysicsBodyState` class holds the kinematic state of a physics body:

```java
import com.hypixel.hytale.server.core.modules.physics.util.PhysicsBodyState;
import com.hypixel.hytale.math.vector.Vector3d;

public class PhysicsBodyState {
    public final Vector3d position = new Vector3d();
    public final Vector3d velocity = new Vector3d();
}
```

### Physics Constants

```java
import com.hypixel.hytale.server.core.modules.physics.util.PhysicsConstants;

public class PhysicsConstants {
    public static final double GRAVITY_ACCELERATION = 32.0;  // blocks/sec^2
}
```

### Physics Values Component

Entities can have physics properties through the `PhysicsValues` component:

```java
import com.hypixel.hytale.server.core.modules.physics.component.PhysicsValues;

public class PhysicsValues implements Component<EntityStore> {
    protected double mass = 1.0;              // Default mass
    protected double dragCoefficient = 0.5;   // Air resistance
    protected boolean invertedGravity = false; // Gravity direction

    public double getMass() { return mass; }
    public double getDragCoefficient() { return dragCoefficient; }
    public boolean isInvertedGravity() { return invertedGravity; }
}
```

## Force System

### Force Provider Interface

Forces are contributed by implementing `ForceProvider`:

```java
import com.hypixel.hytale.server.core.modules.physics.util.ForceProvider;
import com.hypixel.hytale.server.core.modules.physics.util.ForceAccumulator;
import com.hypixel.hytale.server.core.modules.physics.util.PhysicsBodyState;

public interface ForceProvider {
    void update(PhysicsBodyState state, ForceAccumulator accumulator, boolean onGround);
}
```

### Force Accumulator

The `ForceAccumulator` collects all forces applied during a physics tick:

```java
import com.hypixel.hytale.server.core.modules.physics.util.ForceAccumulator;
import com.hypixel.hytale.math.vector.Vector3d;

public class ForceAccumulator {
    public double speed;                              // Current speed
    public final Vector3d force = new Vector3d();     // Accumulated force
    public final Vector3d resistanceForceLimit = new Vector3d();  // Max resistance

    public void initialize(PhysicsBodyState state, double mass, double timeStep) {
        this.force.assign(Vector3d.ZERO);
        this.speed = state.velocity.length();
        this.resistanceForceLimit.assign(state.velocity).scale(-mass / timeStep);
    }
}
```

### Standard Force Provider

The `ForceProviderStandard` implements common physical forces:

```java
import com.hypixel.hytale.math.vector.Vector3d;
import com.hypixel.hytale.server.core.modules.physics.util.ForceAccumulator;
import com.hypixel.hytale.server.core.modules.physics.util.ForceProviderStandard;
import com.hypixel.hytale.server.core.modules.physics.util.ForceProviderStandardState;
import com.hypixel.hytale.server.core.modules.physics.util.PhysicsBodyState;

public abstract class ForceProviderStandard implements ForceProvider {
    protected final Vector3d dragForce = new Vector3d();

    @Override
    public void update(PhysicsBodyState bodyState, ForceAccumulator accumulator, boolean onGround) {
        ForceProviderStandardState standardState = getForceProviderStandardState();
        Vector3d extForce = standardState.externalForce;
        double extForceY = extForce.y;

        // External forces
        accumulator.force.add(extForce);

        // Drag force (air resistance)
        double speed = accumulator.speed;
        double dragForceDivSpeed = standardState.dragCoefficient *
            getProjectedArea(bodyState, speed) * speed;
        dragForce.assign(bodyState.velocity).scale(-dragForceDivSpeed);
        clipForce(dragForce, accumulator.resistanceForceLimit);
        accumulator.force.add(dragForce);

        // Gravity and friction
        double gravityForce = -standardState.gravity * getMass(getVolume());
        if (onGround) {
            double frictionForce = (gravityForce + extForceY) * getFrictionCoefficient();
            if (speed > 0.0 && frictionForce > 0.0) {
                accumulator.force.x -= bodyState.velocity.x * (frictionForce / speed);
                accumulator.force.z -= bodyState.velocity.z * (frictionForce / speed);
            }
        } else {
            accumulator.force.y += gravityForce;
        }

        if (standardState.displacedMass != 0.0) {
            accumulator.force.y += standardState.displacedMass * standardState.gravity;
        }
    }
}
```

## Numerical Integration

### Integrator Types

| Integrator | Description |
|------------|-------------|
| `SymplecticEuler` | Fast, energy-preserving (used by `SimplePhysicsProvider`) |
| `Midpoint` | Second-order accuracy |
| `RK4` | Fourth-order accuracy for complex trajectories |

### Symplectic Euler Integrator

`SimplePhysicsProvider` uses Symplectic Euler for energy conservation:

```java
public class PhysicsBodyStateUpdaterSymplecticEuler extends PhysicsBodyStateUpdater {
    @Override
    public void update(PhysicsBodyState before, PhysicsBodyState after,
                       double mass, double dt, boolean onGround,
                       ForceProvider[] forceProviders) {
        computeAcceleration(before, onGround, forceProviders, mass, dt);
        updateAndClampVelocity(before, after, dt);        // v' = v + a*dt
        updatePositionAfterVelocity(before, after, dt);   // x' = x + v'*dt
    }
}
```

:::note
Symplectic Euler updates velocity first, then uses the new velocity for position. This preserves energy in oscillating systems better than standard Euler.
:::

## Velocity Component

The `Velocity` component manages entity velocities:

```java
import com.hypixel.hytale.server.core.modules.physics.component.Velocity;

public class Velocity implements Component<EntityStore> {
    protected final Vector3d velocity = new Vector3d();

    public void setZero() {
        set(0.0, 0.0, 0.0);
    }

    public void addForce(Vector3d force) {
        velocity.add(force);
    }

    public void set(Vector3d newVelocity) {
        velocity.assign(newVelocity);
    }

    public double getSpeed() {
        return velocity.length();
    }
}
```

## Collision Detection

### Physics Flags

The `PhysicsFlags` class defines collision categories:

```java
import com.hypixel.hytale.server.core.modules.physics.util.PhysicsFlags;

public class PhysicsFlags {
    public static final int NO_COLLISIONS = 0;
    public static final int ENTITY_COLLISIONS = 1;
    public static final int BLOCK_COLLISIONS = 2;
    public static final int ALL_COLLISIONS = 3;
}
```

### Collision Module

```java
import com.hypixel.hytale.server.core.modules.collision.CollisionModule;
import com.hypixel.hytale.server.core.modules.collision.CollisionResult;

// Check if movement is below threshold
boolean isStationary = CollisionModule.isBelowMovementThreshold(velocity);

// Find collisions along a movement path
CollisionResult result = new CollisionResult();
boolean isFarDistance = CollisionModule.findCollisions(
    collider,           // Bounding box
    position,           // Current position
    velocity,           // Movement vector
    stopOnCollision,    // Stop searching on first collision
    result,             // Output results
    componentAccessor   // ECS accessor
);
```

### Block Collision Consumer

Implement `IBlockCollisionConsumer` to handle collision events:

```java
public class MyCollisionHandler implements IBlockCollisionConsumer {
    @Override
    public Result onCollision(int blockX, int blockY, int blockZ,
                              Vector3d direction, BlockContactData contactData,
                              BlockData blockData, Box collider) {
        // Handle solid block collision
        if (blockData.getBlockType().getMaterial() == BlockMaterial.Solid) {
            Vector3d normal = contactData.getCollisionNormal();
            double alignment = direction.dot(normal);

            if (alignment < 0.0) {
                return Result.STOP; // Moving into surface
            }
        }
        return Result.CONTINUE;
    }

    @Override
    public Result probeCollisionDamage(int blockX, int blockY, int blockZ,
                                       Vector3d direction, BlockContactData contactData,
                                       BlockData blockData) {
        return Result.CONTINUE;
    }

    @Override
    public void onCollisionDamage(int blockX, int blockY, int blockZ,
                                  Vector3d direction, BlockContactData contactData,
                                  BlockData blockData) {
        // Optional: handle damage
    }

    @Override
    public Result onCollisionSliceFinished() {
        return Result.CONTINUE;
    }

    @Override
    public void onCollisionFinished() {
        // Optional cleanup
    }
}
```

## Physics Math Utilities

```java
import com.hypixel.hytale.server.core.modules.physics.util.PhysicsMath;

public class PhysicsMath {
    public static final double DENSITY_AIR = 1.2;
    public static final double DENSITY_WATER = 998.0;

    // Calculate terminal velocity
    public static double getTerminalVelocity(double mass, double density,
                                              double areaMillimetersSquared, double dragCoefficient) {
        double massGrams = mass * 1000.0;
        double areaMeters = areaMillimetersSquared * 1000000.0;
        return Math.sqrt(64.0 * massGrams / (density * areaMeters * dragCoefficient));
    }

    // Calculate projected area of box in velocity direction
    public static double computeProjectedArea(Vector3d direction, Box box) {
        double area = 0.0;
        if (direction.x != 0.0) area += Math.abs(direction.x) * box.depth() * box.height();
        if (direction.y != 0.0) area += Math.abs(direction.y) * box.depth() * box.width();
        if (direction.z != 0.0) area += Math.abs(direction.z) * box.width() * box.height();
        return area;
    }
}
```

## Implementing Custom Physics

### Custom Force Provider

```java
public class WindForceProvider implements ForceProvider {
    private final Vector3d windDirection;
    private final double windStrength;

    public WindForceProvider(Vector3d direction, double strength) {
        this.windDirection = direction.clone().normalize();
        this.windStrength = strength;
    }

    @Override
    public void update(PhysicsBodyState state, ForceAccumulator accumulator, boolean onGround) {
        // Wind only affects airborne entities
        if (!onGround) {
            accumulator.force.addScaled(windDirection, windStrength);
        }
    }
}
```

### Custom Physics System

```java
public class CustomPhysicsSystem extends EntityTickingSystem<EntityStore> {
    private final PhysicsBodyStateUpdater updater = new PhysicsBodyStateUpdaterSymplecticEuler();
    private final PhysicsBodyState stateBefore = new PhysicsBodyState();
    private final PhysicsBodyState stateAfter = new PhysicsBodyState();

    @Override
    public void tick(float dt, int index, ArchetypeChunk<EntityStore> chunk,
                     Store<EntityStore> store, CommandBuffer<EntityStore> buffer) {
        TransformComponent transform = chunk.getComponent(index, transformType);
        Velocity velocity = chunk.getComponent(index, velocityType);
        PhysicsValues physics = chunk.getComponent(index, physicsType);

        // Setup state
        stateBefore.position.assign(transform.getPosition());
        velocity.assignVelocityTo(stateBefore.velocity);

        // Run physics simulation
        updater.update(stateBefore, stateAfter, physics.getMass(), dt, onGround, forceProviders);

        // Apply results
        transform.setPosition(stateAfter.position);
        velocity.set(stateAfter.velocity);
    }
}
```

## Best Practices

1. **Choose the right integrator** - Use Symplectic Euler for most cases, RK4 for precise trajectories
2. **Clamp velocities** - Prevent numerical instability with velocity thresholds
3. **Use force accumulation** - Let `ForceAccumulator` handle force clipping
4. **Handle ground state** - Switch between gravity and friction based on `onGround`
5. **Consider buoyancy** - Track displaced mass for fluid interactions
6. **Cache physics objects** - Reuse `PhysicsBodyState` instances to avoid allocation
7. **Use collision iterators** - For long-distance movement, use iterative collision detection
8. **Separate physics from rendering** - Physics runs at fixed timestep, interpolate for display
