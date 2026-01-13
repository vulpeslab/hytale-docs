---
title: Entity System (ECS)
description: Learn about Hytale's Entity-Component-System architecture for game objects.
sidebar:
  order: 1
---

This section covers Hytale's Entity-Component-System (ECS) architecture, which provides efficient data access and flexible composition for game objects.

## What is ECS?

The Entity-Component-System architecture separates game objects into three core concepts:

- **Entities** - Lightweight references (IDs) to game objects
- **Components** - Data containers attached to entities
- **Systems** - Logic processors that operate on components

This separation provides:
- Efficient memory layout and cache-friendly data access
- Flexible composition without deep inheritance hierarchies
- Clean separation between data and logic

## Architecture Overview

```
Store<ECS_TYPE>
├── ComponentRegistry<ECS_TYPE>    - Type registration and system management
├── Archetype[]                    - Component type combinations
│   └── ArchetypeChunk[]           - Entity storage per archetype
│       ├── Ref<ECS_TYPE>[]        - Entity references
│       └── Component<ECS_TYPE>[][] - Component data arrays
├── Resource<ECS_TYPE>[]           - Global resources (via ResourceType)
└── ISystem<ECS_TYPE>[]            - Logic processors
```

## Getting Started

1. **[Component System](./components)** - Learn about creating and using components
2. **[Entity Stats](./entity-stats)** - Health, stamina, mana, and custom attributes
3. **[Physics System](./physics)** - Physics simulation and collision
4. **[Player Management](./player-persistence)** - Player data and persistence

## Quick Example

```java
// Get the EntityStore from a world, then get the underlying Store
EntityStore entityStore = world.getEntityStore();
Store<EntityStore> store = entityStore.getStore();

// Create an entity using a Holder with an Archetype
Holder<EntityStore> holder = EntityStore.REGISTRY.newHolder(
    Archetype.of(positionType, velocityType, healthType),
    new Component[] {
        new PositionComponent(0, 64, 0),
        new VelocityComponent(),
        new HealthComponent(100)
    }
);
Ref<EntityStore> entity = store.addEntity(holder, AddReason.SPAWNED);

// Get a component from an entity using ComponentType (not Class)
PositionComponent pos = store.getComponent(entity, positionType);

// Iterate over entities with specific components using forEachChunk
store.forEachChunk(positionType, (archetypeChunk, commandBuffer) -> {
    for (int i = 0; i < archetypeChunk.size(); i++) {
        Ref<EntityStore> ref = archetypeChunk.getReferenceTo(i);
        PositionComponent position = archetypeChunk.getComponent(i, positionType);
        VelocityComponent velocity = archetypeChunk.getComponent(i, velocityType);
        if (position != null && velocity != null) {
            // Process entities with both components
            position.add(velocity);
        }
    }
});
```

## Core Concepts

### Entity References (Ref)

Entities are referenced through lightweight `Ref` objects that track validity:

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

    public void validate() {
        if (this.index == Integer.MIN_VALUE) {
            throw new IllegalStateException("Invalid entity reference!", this.invalidatedBy);
        }
    }

    public boolean isValid() {
        return this.index != Integer.MIN_VALUE;
    }
}
```

:::caution
Always check `isValid()` before using a `Ref`. Entity references become invalid when entities are removed. You can also call `validate()` which throws an `IllegalStateException` with the stack trace of when the entity was invalidated.
:::

### Component Types

Components must implement the `Component` interface which extends `Cloneable`:

```java
public interface Component<ECS_TYPE> extends Cloneable {
    @Nonnull
    public static final Component[] EMPTY_ARRAY = new Component[0];

    @Nullable
    public Component<ECS_TYPE> clone();

    @Nullable
    default public Component<ECS_TYPE> cloneSerializable() {
        return this.clone();
    }
}
```

Components are accessed through `ComponentType<ECS_TYPE, T>` objects registered with the `ComponentRegistry`, not by their Class directly.

### Systems

Systems process entities with specific component combinations. The base interface is `ISystem`:

```java
public interface ISystem<ECS_TYPE> {
    public static final ISystem[] EMPTY_ARRAY = new ISystem[0];

    default public void onSystemRegistered() {}

    default public void onSystemUnregistered() {}

    @Nullable
    default public SystemGroup<ECS_TYPE> getGroup() {
        return null;
    }

    @Nonnull
    default public Set<Dependency<ECS_TYPE>> getDependencies() {
        return Collections.emptySet();
    }
}
```

### Resources

Resources are global data accessible across the store, implementing the `Resource` interface:

```java
public interface Resource<ECS_TYPE> extends Cloneable {
    public static final Resource[] EMPTY_ARRAY = new Resource[0];

    @Nullable
    public Resource<ECS_TYPE> clone();
}
```

Resources are accessed via `ResourceType` and retrieved using `store.getResource(resourceType)`.

### Archetypes

An `Archetype` represents a specific combination of component types. Entities with the same archetype are stored together in `ArchetypeChunk` for cache-efficient iteration:

```java
// Create an archetype with specific component types
Archetype<EntityStore> archetype = Archetype.of(positionType, velocityType);

// Add or remove component types from archetypes
Archetype<EntityStore> withHealth = Archetype.add(archetype, healthType);
Archetype<EntityStore> withoutVelocity = Archetype.remove(archetype, velocityType);
```

## Next Steps

- Read the [Component System](./components) guide for detailed documentation
- Learn about [Entity Stats](./entity-stats) for health and attributes
- Understand the [Physics System](./physics) for movement and collision
