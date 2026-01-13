---
title: Navigation & Pathfinding
description: A* pathfinding and movement systems for NPCs
---

The navigation system provides pathfinding and movement capabilities for NPCs using A* pathfinding algorithms and steering behaviors.

## Overview

Located at `com.hypixel.hytale.server.npc.navigation` and `com.hypixel.hytale.server.npc.movement`

The navigation system consists of:

1. **Pathfinding** - A* algorithm for finding optimal paths
2. **Path Following** - Following computed paths
3. **Steering** - Low-level movement control
4. **Motion Controllers** - High-level movement behaviors
5. **Collision Avoidance** - Avoiding obstacles and other entities

## Pathfinding

### A* Implementation

The core A* pathfinding is implemented through several classes:

#### AStarBase

Located at `com.hypixel.hytale.server.npc.navigation.AStarBase`

Base class for A* pathfinding:

- Node expansion
- Path cost calculation
- Heuristic evaluation
- Open/closed set management

#### AStarWithTarget

Located at `com.hypixel.hytale.server.npc.navigation.AStarWithTarget`

A* implementation for finding paths to a specific target:

```java
AStarWithTarget pathfinder = new AStarWithTarget();
Path path = pathfinder.findPath(startPos, targetPos, evaluator);
```

#### AStarEvaluator

Located at `com.hypixel.hytale.server.npc.navigation.AStarEvaluator`

Evaluates nodes during pathfinding:

- Determines if a position is walkable
- Calculates movement cost
- Applies penalties for different terrain
- Checks environmental constraints

### Node Management

#### AStarNode

Located at `com.hypixel.hytale.server.npc.navigation.AStarNode`

Represents a node in the pathfinding graph:

- Position (x, y, z)
- Cost values (g-cost, h-cost, f-cost)
- Parent node reference
- Node state

#### Node Pools

For performance, nodes are pooled and reused:

##### AStarNodePool

Located at `com.hypixel.hytale.server.npc.navigation.AStarNodePool`

Interface for node pool management.

##### AStarNodePoolSimple

Located at `com.hypixel.hytale.server.npc.navigation.AStarNodePoolSimple`

Simple node pool implementation:

```java
AStarNodePoolSimple pool = new AStarNodePoolSimple(maxNodes);
AStarNode node = pool.acquire();
// Use node...
pool.release(node);
```

##### AStarNodePoolProvider

Located at `com.hypixel.hytale.server.npc.navigation.AStarNodePoolProvider`

Provides access to node pools:

- Thread-safe pool management
- Pool size configuration
- Pool recycling

## Path System

### IWaypoint

Located at `com.hypixel.hytale.server.npc.navigation.IWaypoint`

Interface for waypoints in a path:

```java
Vector3d getPosition();
boolean isReached(Vector3d currentPos, double threshold);
```

### PathFollower

Located at `com.hypixel.hytale.server.npc.navigation.PathFollower`

Follows a computed path:

- Tracks current waypoint
- Determines when waypoints are reached
- Advances to next waypoint
- Handles path completion

Usage:

```java
PathFollower follower = new PathFollower(path);
follower.update(currentPosition, dt);
Vector3d targetWaypoint = follower.getCurrentWaypoint();
```

### Path Integration

Paths integrate with the broader path system:

Located at `com.hypixel.hytale.server.npc.path`

Provides:
- Path definitions
- Path builders
- Path persistence

Related to the global path system at:
`com.hypixel.hytale.builtin.path`

## Movement System

Located at `com.hypixel.hytale.server.npc.movement`

### Steering

Located at `com.hypixel.hytale.server.npc.movement.Steering`

Represents a steering force:

```java
class Steering {
    Vector3d force;      // Steering force direction/magnitude
    double desiredSpeed; // Desired movement speed
}
```

Used by motion controllers to influence NPC movement.

### Motion Controllers

Located at `com.hypixel.hytale.server.npc.movement.controllers`

Motion controllers provide high-level movement behaviors:

#### MotionController

Base interface for all motion controllers:

```java
void computeSteering(Role role, Steering steering, double dt);
void update(Role role, double dt);
```

#### Controller Builders

Located at `com.hypixel.hytale.server.npc.movement.controllers.builders`

Builder pattern for creating motion controllers from asset data.

### Steering Forces

Located at `com.hypixel.hytale.server.npc.movement.steeringforces`

Specific steering force implementations:

#### SteeringForceAvoidCollision

Avoids collisions with obstacles and other entities:

```java
SteeringForceAvoidCollision avoidance = new SteeringForceAvoidCollision();
avoidance.compute(role, steering, obstacles);
```

Features:
- Ray casting for obstacle detection
- Collision prediction
- Force calculation based on proximity
- View angle constraints

### Group Steering

#### GroupSteeringAccumulator

Located at `com.hypixel.hytale.server.npc.movement.GroupSteeringAccumulator`

Accumulates steering forces from multiple sources:

```java
GroupSteeringAccumulator accumulator = new GroupSteeringAccumulator();
accumulator.add(force1, weight1);
accumulator.add(force2, weight2);
Vector3d resultForce = accumulator.compute();
```

Used for:
- Combining multiple behaviors
- Weighted force blending
- Flock behaviors

## Collision Avoidance

The Role class contains collision avoidance parameters:

```java
class Role {
    double collisionProbeDistance;   // How far ahead to check
    double collisionRadius;           // Collision detection radius
    double collisionForceFalloff;     // Force reduction with distance
    float collisionViewAngle;         // Field of view for detection
    double entityAvoidanceStrength;   // Strength of avoidance force
    AvoidanceMode avoidanceMode;      // Avoidance behavior mode
}
```

### Avoidance Modes

Different strategies for avoiding entities:

- **Avoid All** - Avoid all entities
- **Avoid Enemies** - Only avoid hostile entities
- **Avoid Non-Flock** - Avoid entities not in the same flock
- **None** - No entity avoidance

### Separation

Flocking separation behavior:

```java
class Role {
    double separationDistance;        // Desired separation
    double separationWeight;          // Separation force weight
    double separationDistanceTarget;  // Target distance
    double separationNearRadiusTarget; // Near radius
    double separationFarRadiusTarget;  // Far radius
}
```

## Environmental Constraints

### Stay in Environment

NPCs can be constrained to specific environments:

```java
class Role {
    boolean stayInEnvironment;   // Whether to stay in allowed environments
    String allowedEnvironments;  // Comma-separated environment IDs
}
```

If enabled, the NPC will avoid leaving its allowed environment.

## Physics Integration

Located at `com.hypixel.hytale.server.npc.util.NPCPhysicsMath`

Provides physics calculations for NPC movement:

- Velocity integration
- Acceleration application
- Inertia calculations
- Knockback handling

```java
class Role {
    double inertia;        // Movement inertia (resistance to direction change)
    double knockbackScale; // Knockback force multiplier
}
```

## Debugging

### Debug Visualization

Located at `com.hypixel.hytale.server.npc.navigation.AStarDebugBase` and `AStarDebugWithTarget`

Provides debugging visualization for pathfinding:

- Visualize explored nodes
- Show final path
- Display cost values
- Render waypoints

## Integration with Instructions

Navigation integrates with the instruction system through:

1. **Body Motion** - Sets steering forces for movement
2. **Sensor Info** - Provides path and position data
3. **Path Providers** - Supply path information to sensors/actions

## Best Practices

1. **Limit path length** - Long paths are expensive to compute
2. **Reuse paths** - Cache paths when target doesn't move
3. **Update incrementally** - Recompute paths periodically, not every frame
4. **Use path smoothing** - Smooth jagged paths for natural movement
5. **Blend steering forces** - Combine multiple behaviors smoothly
6. **Set appropriate costs** - Configure terrain costs for desired behavior

## Performance Optimization

### Node Pool Sizing

Configure node pools based on expected path complexity:

```java
// For short paths
AStarNodePoolSimple pool = new AStarNodePoolSimple(256);

// For long paths
AStarNodePoolSimple pool = new AStarNodePoolSimple(2048);
```

### Path Update Frequency

Don't recompute paths every frame:

```java
// Recompute every N seconds or when target moves significantly
if (timeSinceLastUpdate > 1.0 || targetMovedDistance > 5.0) {
    recomputePath();
}
```

### Early Path Termination

Stop pathfinding if path becomes too long:

```java
if (pathLength > maxPathLength) {
    // Use simplified movement or give up
}
```

### Spatial Partitioning

Use spatial data structures for efficient obstacle queries:

- KD-trees for entity lookups
- Chunk-based world queries
- Cached terrain data

## Common Movement Patterns

### Follow Entity

```java
// Motion: Follow target entity
// - Get target position
// - Find path to target
// - Follow path with path follower
// - Update when target moves
```

### Patrol Path

```java
// Motion: Patrol waypoints
// - Define waypoint list
// - Follow current waypoint
// - Advance to next on reach
// - Loop back to start
```

### Wander

```java
// Motion: Random wandering
// - Pick random target in radius
// - Move to target
// - Pick new target on arrival
// - Stay within bounds
```

### Flee

```java
// Motion: Flee from threat
// - Get threat position
// - Calculate direction away
// - Move in opposite direction
// - Maintain minimum distance
```

## Related Systems

- [Instructions](/modding/npc-ai/instructions) - Uses navigation for motion
- [Roles](/modding/npc-ai/roles) - Configures navigation parameters
- [Flock System](/modding/flock) - Group movement behaviors
- Physics System - Applies movement forces to entities
