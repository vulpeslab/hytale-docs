---
title: Decision Makers
description: State evaluation and condition-based AI logic
---

The Decision Maker system provides condition evaluation and state-based logic for NPCs. It allows NPCs to make intelligent decisions based on their current state and environment.

## Overview

Decision makers are located in the `com.hypixel.hytale.server.npc.decisionmaker` package and provide two main approaches to decision-making:

1. **Condition-based evaluation** - Using the core conditions system
2. **State evaluation** - Using state evaluators for complex state machines

## Core Conditions

Located at `com.hypixel.hytale.server.npc.decisionmaker.core.conditions`

### Condition Interface

The base `Condition` interface provides:

```java
boolean evaluate(Ref<EntityStore> ref, Role role, ComponentAccessor<EntityStore> accessor);
```

Conditions are registered with a codec system for serialization:

```java
Condition.CODEC.register("ConditionName", ConditionClass.class, ConditionClass.CODEC);
```

### Base Conditions

Located at `com.hypixel.hytale.server.npc.decisionmaker.core.conditions.base`

These provide fundamental condition types that can be composed together:

#### Logical Operators

- **AND Condition** - All child conditions must be true
- **OR Condition** - At least one child condition must be true
- **NOT Condition** - Inverts the result of a child condition

#### Comparison Conditions

- Value comparisons (equals, greater than, less than, etc.)
- Numeric range checks
- String matching

#### Compound Conditions

Conditions can be nested and combined to create complex decision trees:

```java
AND(
    condition1,
    OR(
        condition2,
        condition3
    ),
    NOT(condition4)
)
```

## State Evaluator

Located at `com.hypixel.hytale.server.npc.decisionmaker.stateevaluator`

State evaluators provide a higher-level abstraction for managing NPC state machines. They evaluate conditions to determine state transitions.

### Key Concepts

**State Evaluation**: Determines which state an NPC should be in based on current conditions

**State Transitions**: Managed through the `StateTransitionController` system

**Priority**: States can have priorities to determine which state takes precedence when multiple conditions are met

## Integration with Instructions

Decision makers work closely with the instruction system:

1. **Sensors** query conditions to determine if they match
2. **Instructions** execute when their sensor conditions evaluate to true
3. **State changes** trigger new instruction evaluations

## Condition Types

Common condition types available in the system:

### Entity Conditions

- Entity distance checks
- Line of sight checks
- Entity type matching
- Entity state checks

### Combat Conditions

- Health thresholds
- Damage received
- Combat state (in combat, fleeing, etc.)
- Target availability

### World Conditions

- Time of day
- Weather conditions
- Biome checks
- Block presence

### Timer Conditions

- Elapsed time checks
- Cooldown completion
- Scheduled events

### Flock Conditions

- Flock size (`FlockSizeCondition`)
- Flock state
- Flock membership

### Custom Conditions

Plugins can register custom conditions:

```java
Condition.CODEC.register("CustomCondition", CustomCondition.class, CustomCondition.CODEC);
```

## State Support

The `StateSupport` class (part of Role) manages NPC state:

Located at `com.hypixel.hytale.server.npc.role.support.StateSupport`

Provides:
- Current state tracking
- State transition handling
- State history
- State-specific data

## Decision Making Flow

1. **Evaluation**: Conditions are evaluated each tick or on specific events
2. **Matching**: The first instruction with matching sensor conditions is selected
3. **Execution**: The selected instruction's actions are executed
4. **State Update**: State changes may trigger new evaluations

## State Machines

NPCs can have complex state machines defined through:

### State Transition Controller

Located at `com.hypixel.hytale.server.npc.statetransition.StateTransitionController`

Manages transitions between states:

- **Entry conditions**: Conditions that must be met to enter a state
- **Exit conditions**: Conditions that cause leaving a state
- **Transition priorities**: Which transitions take precedence
- **State duration**: Minimum/maximum time in a state

### Builder Pattern

State transitions are configured using builders:

Located at `com.hypixel.hytale.server.npc.statetransition.builders`

Provides a fluent API for defining state machines in asset files.

## Role States

The `RoleStateChange` interface defines lifecycle callbacks:

```java
void stateChanged(Ref<EntityStore> ref, Role role, ComponentAccessor<EntityStore> accessor);
void roleChanged(Ref<EntityStore> ref, Role role, ComponentAccessor<EntityStore> accessor);
```

Components implementing this interface are notified when:
- NPC state changes
- NPC role changes

## Examples

### Simple Condition Check

```java
// Check if target is within range
DistanceCondition condition = new DistanceCondition(10.0);
boolean inRange = condition.evaluate(ref, role, accessor);
```

### Complex Condition

```java
// Attack if: (enemy nearby AND health > 50%) OR (being attacked)
AND(
    OR(
        AND(
            EnemyNearbyCondition(),
            HealthAboveCondition(0.5)
        ),
        BeingAttackedCondition()
    ),
    NOT(FleeingCondition())
)
```

### State Machine

```java
// Passive -> Alert -> Combat -> Fleeing
States:
  Passive: default state, wander behavior
  Alert: enemy detected, prepare for combat
  Combat: actively fighting
  Fleeing: health low, retreat

Transitions:
  Passive -> Alert: enemy within detection range
  Alert -> Combat: enemy within attack range
  Combat -> Fleeing: health < 20%
  Fleeing -> Passive: safe for 10 seconds
  * -> Passive: no threats for 30 seconds
```

## Best Practices

1. **Keep conditions simple**: Complex logic should be broken into smaller, reusable conditions
2. **Use priorities**: Ensure critical states (like fleeing) have higher priority
3. **Avoid rapid state changes**: Add cooldowns or minimum durations to prevent flickering
4. **Cache expensive checks**: Use the blackboard to cache computation results
5. **Test edge cases**: Ensure conditions handle edge cases like null entities

## Performance Considerations

- Conditions are evaluated frequently, keep them lightweight
- Use early exits in AND conditions
- Cache condition results when appropriate
- Avoid expensive world queries in conditions
- Use spatial indexing for distance checks

## Related Systems

- [Instructions](/modding/npc-ai/instructions) - Execute based on condition results
- [Blackboard](/modding/npc-ai/blackboard) - Provides data for condition evaluation
- [Roles](/modding/npc-ai/roles) - Define state machines and behaviors
- [Sensors](/modding/npc-ai/instructions#sensors) - Use conditions to match
