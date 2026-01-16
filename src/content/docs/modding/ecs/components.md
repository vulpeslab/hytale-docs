---
author: UnlimitedBytes
title: Component System
description: Learn about Hytale's component system and how to create custom components.
sidebar:
  order: 2
human-verified: false
---

Hytale uses an Entity-Component-System architecture for game objects. This provides efficient data access and flexible composition.

## Architecture Overview

```
Store<ECS_TYPE>
├── ComponentRegistry     - Type registration
├── Archetype[]           - Component combinations
│   └── ArchetypeChunk[]  - Entity storage
│       └── Component[][] - Component data
├── Resource[]            - Global resources
└── System[]              - Logic processors
```

## Core Concepts

### Entities (Ref)

Lightweight references to entity data. A `Ref` is a pointer to an entity within a `Store`:

```java
public class Ref<ECS_TYPE> {
    public static final Ref<?>[] EMPTY_ARRAY = new Ref[0];

    @Nonnull
    private final Store<ECS_TYPE> store;
    private volatile int index;
    private volatile transient int hashCode;
    private volatile Throwable invalidatedBy;

    public Ref(@Nonnull Store<ECS_TYPE> store) {
        this(store, Integer.MIN_VALUE);
    }

    public Ref(@Nonnull Store<ECS_TYPE> store, int index) {
        this.store = store;
        this.index = index;
        this.hashCode = this.hashCode0();
    }

    @Nonnull
    public Store<ECS_TYPE> getStore() {
        return this.store;
    }

    public int getIndex() {
        return this.index;
    }

    public boolean isValid() {
        return this.index != Integer.MIN_VALUE;
    }

    public void validate() {
        if (this.index == Integer.MIN_VALUE) {
            throw new IllegalStateException("Invalid entity reference!", this.invalidatedBy);
        }
    }
}
```

:::caution
Always check `isValid()` before using a `Ref`. Entity references can become invalid when entities are removed.
:::

### Components

Data containers attached to entities. Components must implement `Cloneable` for entity copying:

```java
public interface Component<ECS_TYPE> extends Cloneable {
    @Nonnull
    public static final Component[] EMPTY_ARRAY = new Component[0];

    @Nullable
    Component<ECS_TYPE> clone();

    @Nullable
    default Component<ECS_TYPE> cloneSerializable() {
        return this.clone();
    }
}
```

The `cloneSerializable()` method is used for persistence and can be overridden to exclude transient data.

### Systems

Logic processors that operate on components. Systems define processing logic and execution order:

```java
public interface ISystem<ECS_TYPE> {
    public static final ISystem[] EMPTY_ARRAY = new ISystem[0];

    default void onSystemRegistered() {}
    default void onSystemUnregistered() {}

    @Nullable
    default SystemGroup<ECS_TYPE> getGroup() {
        return null;
    }

    @Nonnull
    default Set<Dependency<ECS_TYPE>> getDependencies() {
        return Collections.emptySet();
    }
}
```

### Resources

Global shared state per store. Resources are singleton objects accessible from any system:

```java
public interface Resource<ECS_TYPE> extends Cloneable {
    public static final Resource[] EMPTY_ARRAY = new Resource[0];

    @Nullable
    Resource<ECS_TYPE> clone();
}
```

## Creating Components

### Simple Data Component

```java
public class HealthComponent implements Component<EntityStore> {

    public static final BuilderCodec<HealthComponent> CODEC =
        BuilderCodec.builder(HealthComponent.class, HealthComponent::new)
            .append(new KeyedCodec<>("MaxHealth", Codec.FLOAT),
                (c, v) -> c.maxHealth = v, c -> c.maxHealth)
            .add()
            .append(new KeyedCodec<>("CurrentHealth", Codec.FLOAT),
                (c, v) -> c.currentHealth = v, c -> c.currentHealth)
            .add()
            .build();

    private float maxHealth = 100f;
    private float currentHealth = 100f;

    public HealthComponent() {}

    public HealthComponent(float maxHealth) {
        this.maxHealth = maxHealth;
        this.currentHealth = maxHealth;
    }

    public float getMaxHealth() { return maxHealth; }
    public float getCurrentHealth() { return currentHealth; }

    public void setCurrentHealth(float health) {
        this.currentHealth = Math.min(health, maxHealth);
    }

    public void damage(float amount) {
        this.currentHealth = Math.max(0, currentHealth - amount);
    }

    @Override
    public Component<EntityStore> clone() {
        HealthComponent copy = new HealthComponent(maxHealth);
        copy.currentHealth = this.currentHealth;
        return copy;
    }
}
```

### Marker Component

For boolean flags (no data needed):

```java
public class FlyingMarker implements Component<EntityStore> {
    public static final FlyingMarker INSTANCE = new FlyingMarker();

    public static final BuilderCodec<FlyingMarker> CODEC =
        BuilderCodec.builder(FlyingMarker.class, () -> INSTANCE).build();

    private FlyingMarker() {}

    @Override
    public Component<EntityStore> clone() {
        return INSTANCE;
    }
}
```

## Registering Components

### In Plugin Setup

```java
public class MyPlugin extends JavaPlugin {
    private ComponentType<EntityStore, HealthComponent> healthComponentType;

    @Override
    protected void setup() {
        // With serialization (saved to disk)
        healthComponentType = getEntityStoreRegistry().registerComponent(
            HealthComponent.class,
            "Health",
            HealthComponent.CODEC
        );

        // Without serialization (runtime only)
        ComponentType<EntityStore, TempData> tempType =
            getEntityStoreRegistry().registerComponent(
                TempData.class,
                TempData::new
            );
    }

    public ComponentType<EntityStore, HealthComponent> getHealthComponentType() {
        return healthComponentType;
    }
}
```

## Accessing Components

### Get Component

```java
Ref<EntityStore> entityRef = /* ... */;
Store<EntityStore> store = entityRef.getStore();

// May return null if entity doesn't have component
HealthComponent health = store.getComponent(entityRef, healthComponentType);

if (health != null) {
    float current = health.getCurrentHealth();
}
```

### Ensure Component Exists

```java
// Creates the component if missing
HealthComponent health = store.ensureAndGetComponent(entityRef, healthComponentType);
```

### Add Component

```java
CommandBuffer<EntityStore> commandBuffer = /* ... */;

commandBuffer.addComponent(
    entityRef,
    healthComponentType,
    new HealthComponent(200f)
);
```

### Remove Component

```java
commandBuffer.removeComponent(entityRef, healthComponentType);
```

### Modify Component

```java
HealthComponent health = store.getComponent(entityRef, healthComponentType);
if (health != null) {
    health.damage(25f);
    // You're mutating the stored instance; no reinsert needed
}
```

## Creating Systems

### System Types

Hytale provides several base system classes:

| System Type | Description |
|-------------|-------------|
| `TickingSystem` | Base ticking system, receives `Store` reference |
| `EntityTickingSystem` | Iterates over entities matching a query |
| `ArchetypeTickingSystem` | Iterates over archetype chunks matching a query |

### Basic Ticking System

The `TickingSystem` is the simplest form, receiving the full store each tick:

```java
public class GlobalUpdateSystem extends TickingSystem<EntityStore> {

    @Override
    public void tick(float dt, int index, Store<EntityStore> store) {
        // Access resources, perform global updates
    }
}
```

### Entity Ticking System

The `EntityTickingSystem` iterates over individual entities matching a query:

```java
public class HealthRegenSystem extends EntityTickingSystem<EntityStore> {

    private final ComponentType<EntityStore, HealthComponent> healthType;

    public HealthRegenSystem(ComponentType<EntityStore, HealthComponent> healthType) {
        this.healthType = healthType;
    }

    @Override
    public Query<EntityStore> getQuery() {
        return healthType;  // Only process entities with HealthComponent
    }

    @Override
    public void tick(float dt, int index,
                     ArchetypeChunk<EntityStore> chunk,
                     Store<EntityStore> store,
                     CommandBuffer<EntityStore> commandBuffer) {

        HealthComponent health = chunk.getComponent(index, healthType);
        if (health.getCurrentHealth() < health.getMaxHealth()) {
            health.setCurrentHealth(health.getCurrentHealth() + dt * 5f);
        }
    }
}
```

### Register System

```java
@Override
protected void setup() {
    getEntityStoreRegistry().registerSystem(new HealthRegenSystem(healthComponentType));
}
```

## System Dependencies

Control execution order with dependencies using `SystemDependency`:

```java
import com.hypixel.hytale.component.dependency.SystemDependency;
import com.hypixel.hytale.component.dependency.Order;
import com.hypixel.hytale.component.dependency.OrderPriority;

public class MySystem extends TickingSystem<EntityStore> {

    @Override
    public Set<Dependency<EntityStore>> getDependencies() {
        return Set.of(
            // Run after OtherSystem
            new SystemDependency<>(Order.AFTER, OtherSystem.class),
            // Run before AnotherSystem with closer priority (executes closer to target)
            new SystemDependency<>(Order.BEFORE, AnotherSystem.class, OrderPriority.CLOSE)
        );
    }

    @Override
    public void tick(float dt, int index, Store<EntityStore> store) {
        // Process
    }
}
```

Available `OrderPriority` values:
- `CLOSEST` - Highest priority, executes closest to the target system
- `CLOSE` - High priority
- `NORMAL` - Default priority
- `FURTHER` - Lower priority
- `FURTHEST` - Lowest priority, executes furthest from the target system

## Resources (Global State)

### Define Resource

```java
public class GameStateResource implements Resource<EntityStore> {
    private int score = 0;
    private boolean gameOver = false;

    public int getScore() { return score; }
    public void addScore(int points) { score += points; }
    public boolean isGameOver() { return gameOver; }
    public void setGameOver(boolean over) { gameOver = over; }

    @Override
    public Resource<EntityStore> clone() {
        GameStateResource copy = new GameStateResource();
        copy.score = this.score;
        copy.gameOver = this.gameOver;
        return copy;
    }
}
```

### Register and Access Resource

```java
private ResourceType<EntityStore, GameStateResource> gameStateType;

@Override
protected void setup() {
    gameStateType = getEntityStoreRegistry().registerResource(
        GameStateResource.class,
        GameStateResource::new
    );
}

// Access in code
Store<EntityStore> store = /* ... */;
GameStateResource state = store.getResource(gameStateType);
state.addScore(100);
```

## Queries

Filter entities by component composition:

```java
import com.hypixel.hytale.component.query.Query;

// Entities with HealthComponent (ComponentType implements Query)
Query<EntityStore> query = healthComponentType;

// Entities with both Health AND Position
Query<EntityStore> both = Query.and(healthType, positionType);

// Entities with Health OR Armor
Query<EntityStore> either = Query.or(healthType, armorType);

// Entities with Health but NOT Dead marker
Query<EntityStore> alive = Query.and(healthType, Query.not(deadMarkerType));

// All entities
Query<EntityStore> all = Query.any();
```

## Command Buffer

When iterating or ticking systems, use the `CommandBuffer` provided by the store/system to queue entity mutations safely:

```java
public class CleanupSystem extends EntityTickingSystem<EntityStore> {

    @Override
    public Query<EntityStore> getQuery() {
        return healthType;
    }

    @Override
    public void tick(float dt, int index,
                     ArchetypeChunk<EntityStore> chunk,
                     Store<EntityStore> store,
                     CommandBuffer<EntityStore> buffer) {
        Ref<EntityStore> ref = chunk.getReferenceTo(index);
        HealthComponent health = chunk.getComponent(index, healthType);

        if (health != null && health.getCurrentHealth() <= 0f) {
            buffer.removeEntity(ref, RemoveReason.REMOVE);
        }

        buffer.run(storeRef -> {
            // Runs after queued commands are consumed
        });
    }
}
```

Available `AddReason` values:
- `SPAWN` - Entity is being spawned (e.g., player joins, mob spawns)
- `LOAD` - Entity is being loaded from storage

Available `RemoveReason` values:
- `REMOVE` - Entity is being permanently removed (e.g., death, despawn)
- `UNLOAD` - Entity is being unloaded to storage (e.g., chunk unload)

## Built-in Components

Hytale provides many built-in components for common functionality:

| Component | Package | Description |
|-----------|---------|-------------|
| `TransformComponent` | `modules.entity.component` | Entity position and rotation (uses `Vector3d` for position, `Vector3f` for rotation) |
| `ModelComponent` | `modules.entity.component` | Visual model reference |
| `EntityScaleComponent` | `modules.entity.component` | Entity scale modifier |
| `PositionDataComponent` | `modules.entity.component` | Additional position-related data |
| `BoundingBox` | `modules.entity.component` | Entity collision bounding box |
| `ItemComponent` | `modules.entity.item` | Item data for dropped items |
| `PlayerSkinComponent` | `modules.entity.player` | Player skin data |
| `DisplayNameComponent` | `modules.entity.component` | Entity display name |
| `AudioComponent` | `modules.entity.component` | Sound emission |
| `MovementAudioComponent` | `modules.entity.component` | Movement-related sounds |
| `CollisionResultComponent` | `modules.entity.component` | Collision detection results |
| `UUIDComponent` | `entity` | Unique entity identifier |
| `EffectControllerComponent` | `entity.effect` | Active effects on entity |

All built-in components are in the `com.hypixel.hytale.server.core` package hierarchy.

## Best Practices

1. **Use components for data** - Keep logic in systems
2. **Implement clone()** - Required for entity copying
3. **Use CommandBuffer** - Never modify directly during iteration
4. **Define codecs** - For persistence support
5. **Use marker components** - For boolean flags (no data needed)
6. **Query efficiently** - Combine queries to minimize iteration
7. **Respect system order** - Use dependencies correctly
8. **Cache ComponentTypes** - Store references for fast access
9. **Validate Refs before use** - Always check `isValid()` before accessing entity data
10. **Use Resources for global state** - Avoid storing shared state in components
