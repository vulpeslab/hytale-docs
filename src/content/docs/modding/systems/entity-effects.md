---
author: UnlimitedBytes
title: Entity Effects
description: Status effects, buffs, debuffs, and temporary entity modifiers.
sidebar:
  order: 3
human-verified: false
---

The Entity Effects system manages temporary and permanent status effects applied to entities, including buffs, debuffs, damage over time, and stat modifiers.

## Core Components

### EffectControllerComponent

Manages all active effects on an entity.

**Location:** `com.hypixel.hytale.server.core.entity.effect.EffectControllerComponent`

```java
// Get component type
ComponentType<EntityStore, EffectControllerComponent> type = 
    EffectControllerComponent.getComponentType();

// Get controller from entity
EffectControllerComponent controller = store.getComponent(entityRef, type);
```

**Key Methods:**

```java
// Add an effect
boolean added = controller.addEffect(
    entityRef,           // Entity to apply to
    entityEffect,        // Effect configuration
    componentAccessor    // Component accessor
);

// Add with custom duration
controller.addEffect(
    entityRef,
    entityEffect,
    customDuration,      // Duration in seconds
    OverlapBehavior.EXTEND,
    componentAccessor
);

// Add infinite effect
controller.addInfiniteEffect(
    entityRef,
    entityEffectIndex,
    entityEffect,
    componentAccessor
);

// Remove an effect
controller.removeEffect(
    entityRef,
    entityEffectIndex,
    componentAccessor
);

// Clear all effects
controller.clearEffects(entityRef, componentAccessor);

// Get active effects
Int2ObjectMap<ActiveEntityEffect> activeEffects = controller.getActiveEffects();
int[] effectIndexes = controller.getActiveEffectIndexes();
```

### ActiveEntityEffect

Represents an active effect instance with remaining duration and state.

**Location:** `com.hypixel.hytale.server.core.entity.effect.ActiveEntityEffect`

```java
// Effect properties
int effectIndex = activeEffect.getEntityEffectIndex();
float initialDuration = activeEffect.getInitialDuration();
float remainingDuration = activeEffect.getRemainingDuration();
boolean isInfinite = activeEffect.isInfinite();
boolean isDebuff = activeEffect.isDebuff();
boolean isInvulnerable = activeEffect.isInvulnerable();
```

**Tick Processing:**
- Updates remaining duration
- Applies stat modifiers periodically
- Applies damage over time
- Handles effect expiration

## Entity Effect Configuration

Effects are configured through JSON assets.

### EntityEffect

**Location:** `com.hypixel.hytale.server.core.asset.type.entityeffect.config.EntityEffect`

**Asset Path:** `EntityEffect/{id}.json`

```json
{
  "Name": "effect.poison.name",
  "Duration": 10.0,
  "Infinite": false,
  "Debuff": true,
  "StatusEffectIcon": "hytale:icon/poison",
  "OverlapBehavior": "Extend",
  "RemovalBehavior": "Complete",
  "Invulnerable": false,
  "StatModifiers": {
    "hytale:health": -5.0,
    "hytale:movement_speed": -0.2
  },
  "ValueType": "Percent",
  "DamageCalculator": {
    "Type": "OverTime",
    "DamageCauses": {
      "Poison": 2.0
    }
  },
  "DamageCalculatorCooldown": 1.0,
  "DamageEffects": {
    "Particles": ["hytale:poison_bubble"],
    "Sounds": ["hytale:damage_poison"]
  },
  "StatModifierEffects": {
    "Particles": ["hytale:debuff_sparkle"]
  },
  "ApplicationEffects": {
    "Particles": ["hytale:poison_cloud"],
    "Sounds": ["hytale:poison_apply"]
  },
  "ModelChange": "hytale:poisoned_texture",
  "WorldRemovalSoundEventId": "hytale:poison_fade",
  "LocalRemovalSoundEventId": "hytale:poison_cure"
}
```

**Configuration Fields:**

**Basic Properties:**
- `Name` - Localization key for display name
- `Duration` - Default duration in seconds
- `Infinite` - Whether effect lasts forever by default
- `Debuff` - True if negative effect (shown as debuff)
- `StatusEffectIcon` - Icon asset ID for UI
- `Locale` - Optional death message locale key

**Behavior:**
- `OverlapBehavior` - How to handle applying same effect twice:
  - `Replace` - Replace existing effect
  - `Extend` - Add duration to existing
  - `Ignore` - Keep existing, ignore new
- `RemovalBehavior` - How effect is removed:
  - `Complete` - Remove immediately
  - `Infinite` - Stop infinite flag
  - `Duration` - Set duration to 0
- `Invulnerable` - Makes entity invulnerable while active

**Stat Modifiers:**
- `StatModifiers` - Map of stat IDs to values
- `ValueType` - How values are applied:
  - `Absolute` - Direct value change
  - `Percent` - Percentage of max value
- `StatModifierEffects` - Effects when stats update
- `RawStatModifiers` - Advanced stat modifiers with priorities

**Damage Over Time:**
- `DamageCalculator` - Damage configuration
- `DamageCalculatorCooldown` - Seconds between damage ticks
- `DamageEffects` - Effects when damage is applied
- `DamageResistance` - Resistance values by damage cause

**Visual Effects:**
- `ApplicationEffects` - Effects when first applied
- `ModelChange` - Change entity model while active
- `ModelOverride` - Advanced model override settings

**Audio:**
- `WorldRemovalSoundEventId` - 3D sound when removed
- `LocalRemovalSoundEventId` - Sound for affected entity

### Overlap Behavior

**Location:** `com.hypixel.hytale.server.core.asset.type.entityeffect.config.OverlapBehavior`

```java
public enum OverlapBehavior {
    Replace,  // Replace existing effect
    Extend,   // Add duration to existing
    Ignore    // Keep existing effect
}
```

### Removal Behavior

**Location:** `com.hypixel.hytale.server.core.asset.type.entityeffect.config.RemovalBehavior`

```java
public enum RemovalBehavior {
    Complete,  // Remove effect completely
    Infinite,  // Clear infinite flag
    Duration   // Set duration to 0
}
```

## Applying Effects

### Basic Application

```java
// Get effect from asset store
EntityEffect effect = EntityEffect.getAssetMap().getAsset("hytale:poison");

// Get entity's effect controller
EffectControllerComponent controller = componentAccessor.getComponent(
    entityRef,
    EffectControllerComponent.getComponentType()
);

// Apply effect
boolean applied = controller.addEffect(
    entityRef,
    effect,
    componentAccessor
);
```

### Custom Duration

```java
// Apply with custom duration (30 seconds)
controller.addEffect(
    entityRef,
    effect,
    30.0f,                    // Duration
    OverlapBehavior.Extend,   // Extend if already active
    componentAccessor
);
```

### Infinite Effects

```java
// Apply infinite effect
int effectIndex = EntityEffect.getAssetMap().getIndex("hytale:invulnerable");
EntityEffect effect = EntityEffect.getAssetMap().getAsset(effectIndex);

controller.addInfiniteEffect(
    entityRef,
    effectIndex,
    effect,
    componentAccessor
);
```

## Removing Effects

### Remove Specific Effect

```java
// Get effect index
int effectIndex = EntityEffect.getAssetMap().getIndex("hytale:poison");

// Remove effect
controller.removeEffect(
    entityRef,
    effectIndex,
    componentAccessor
);

// Remove with specific behavior
controller.removeEffect(
    entityRef,
    effectIndex,
    RemovalBehavior.Complete,
    componentAccessor
);
```

### Clear All Effects

```java
// Remove all effects from entity
controller.clearEffects(entityRef, componentAccessor);
```

## Checking Active Effects

### Check if Effect Active

```java
EffectControllerComponent controller = /* get controller */;
int poisonIndex = EntityEffect.getAssetMap().getIndex("hytale:poison");

// Get active effect
ActiveEntityEffect activeEffect = controller.getActiveEffects().get(poisonIndex);
if (activeEffect != null) {
    // Effect is active
    float remainingTime = activeEffect.getRemainingDuration();
}
```

### Iterate Active Effects

```java
Int2ObjectMap<ActiveEntityEffect> activeEffects = controller.getActiveEffects();

for (Int2ObjectMap.Entry<ActiveEntityEffect> entry : activeEffects.int2ObjectEntrySet()) {
    int effectIndex = entry.getIntKey();
    ActiveEntityEffect effect = entry.getValue();
    
    System.out.println("Effect: " + effectIndex + 
                      ", Remaining: " + effect.getRemainingDuration() + 
                      ", Infinite: " + effect.isInfinite());
}
```

## Stat Modifiers

Effects can modify entity stats while active.

### Absolute Value Modifiers

```json
{
  "StatModifiers": {
    "hytale:health": 20.0,
    "hytale:movement_speed": 2.0
  },
  "ValueType": "Absolute"
}
```

Adds fixed values to stats (e.g., +20 health, +2 speed).

### Percentage Modifiers

```json
{
  "StatModifiers": {
    "hytale:health": -50.0,
    "hytale:damage": 25.0
  },
  "ValueType": "Percent"
}
```

Modifies stats by percentage (e.g., -50% health, +25% damage).

### Advanced Modifiers

```json
{
  "RawStatModifiers": {
    "hytale:health": [
      {
        "Value": 10.0,
        "Priority": 100,
        "Type": "Add"
      }
    ]
  }
}
```

Provides fine-grained control over modifier application order and type.

## Damage Over Time

Effects can deal periodic damage.

### Damage Configuration

```json
{
  "DamageCalculator": {
    "Type": "OverTime",
    "DamageCauses": {
      "Poison": 1.0,
      "Magic": 0.5
    }
  },
  "DamageCalculatorCooldown": 1.0,
  "DamageEffects": {
    "Particles": ["hytale:damage_indicator"],
    "Sounds": ["hytale:hurt"]
  }
}
```

**Fields:**
- `DamageCalculator` - Damage calculation configuration
- `DamageCalculatorCooldown` - Seconds between damage ticks (0 = once on apply)
- `DamageEffects` - Visual/audio effects when damage is dealt

### Damage Calculation

Damage is calculated based on effect duration:

```java
// In ActiveEntityEffect.tick()
int cyclesToRun = calculateCyclesToRun(entityEffect, dt);
if (cyclesToRun > 0) {
    // Apply damage for each cycle
    DamageCalculator calculator = entityEffect.getDamageCalculator();
    Object2FloatMap<DamageCause> damages = calculator.calculateDamage(initialDuration);
    
    // Queue damage events
    for (Damage damageEvent : createDamageEvents(damages)) {
        commandBuffer.invoke(entityRef, damageEvent);
    }
}
```

## Model Changes

Effects can change an entity's appearance.

### Simple Model Change

```json
{
  "ModelChange": "hytale:model/poisoned"
}
```

Replaces entity model while effect is active.

### Original Model Restoration

The controller automatically stores and restores the original model:

```java
// In EffectControllerComponent
public void setModelChange(
    Ref<EntityStore> ownerRef,
    EntityEffect entityEffect,
    int entityEffectIndex,
    ComponentAccessor<EntityStore> componentAccessor
) {
    if (this.originalModel != null) return;
    
    // Store original
    ModelComponent modelComponent = componentAccessor.getComponent(
        ownerRef, 
        ModelComponent.getComponentType()
    );
    this.originalModel = modelComponent.getModel();
    
    // Apply new model
    ModelAsset newModel = ModelAsset.getAssetMap()
        .getAsset(entityEffect.getModelChange());
    componentAccessor.putComponent(
        ownerRef,
        ModelComponent.getComponentType(),
        new ModelComponent(Model.createRandomScaleModel(newModel))
    );
}
```

## Invulnerability

Effects can make entities invulnerable.

```json
{
  "Invulnerable": true
}
```

While any invulnerable effect is active, the entity cannot take damage.

```java
// Check if entity is invulnerable via effects
EffectControllerComponent controller = /* get controller */;
boolean isInvulnerable = controller.isInvulnerable();
```

## Application Effects

Visual and audio feedback when effect is applied.

### ApplicationEffects

**Location:** `com.hypixel.hytale.server.core.asset.type.entityeffect.config.ApplicationEffects`

```json
{
  "ApplicationEffects": {
    "Particles": [
      "hytale:magic_sparkle",
      "hytale:buff_glow"
    ],
    "Sounds": [
      "hytale:buff_apply"
    ],
    "Animation": "hytale:player/receive_buff"
  }
}
```

## Network Synchronization

Effect changes are tracked and synchronized to clients.

```java
// Controller tracks changes
boolean isOutdated = controller.consumeNetworkOutdated();
EntityEffectUpdate[] changes = controller.consumeChanges();
controller.clearChanges();

// Create initial updates for new clients
EntityEffectUpdate[] initUpdates = controller.createInitUpdates();
```

**EntityEffectUpdate** contains:
- Operation type (Add/Remove)
- Effect index
- Remaining duration
- Infinite flag
- Debuff flag
- Status icon

## Interaction Integration

Effects can be applied via interactions.

### ApplyEffectInteraction

```json
{
  "Type": "ApplyEffect",
  "EntityEffect": "hytale:poison",
  "Duration": 10.0,
  "OverlapBehavior": "Extend"
}
```

### ClearEntityEffectInteraction

```json
{
  "Type": "ClearEntityEffect",
  "EntityEffect": "hytale:poison"
}
```

### EffectConditionInteraction

Check if entity has specific effect:

```json
{
  "Type": "EffectCondition",
  "EntityEffect": "hytale:burning",
  "HasEffect": true,
  "Interactions": ["hytale:take_fire_damage"]
}
```

## Examples

### Poison Effect

```json
{
  "Name": "effect.poison.name",
  "Duration": 10.0,
  "Debuff": true,
  "StatusEffectIcon": "hytale:icon/poison",
  "OverlapBehavior": "Extend",
  "DamageCalculator": {
    "Type": "OverTime",
    "DamageCauses": {
      "Poison": 1.0
    }
  },
  "DamageCalculatorCooldown": 1.0,
  "DamageEffects": {
    "Particles": ["hytale:poison_bubble"]
  },
  "ApplicationEffects": {
    "Particles": ["hytale:poison_cloud"],
    "Sounds": ["hytale:poison_apply"]
  }
}
```

### Speed Boost

```json
{
  "Name": "effect.speed.name",
  "Duration": 30.0,
  "Debuff": false,
  "StatusEffectIcon": "hytale:icon/speed",
  "OverlapBehavior": "Extend",
  "StatModifiers": {
    "hytale:movement_speed": 50.0
  },
  "ValueType": "Percent",
  "ApplicationEffects": {
    "Particles": ["hytale:speed_lines"],
    "Sounds": ["hytale:buff_apply"]
  }
}
```

### Regeneration

```json
{
  "Name": "effect.regeneration.name",
  "Duration": 20.0,
  "Debuff": false,
  "StatusEffectIcon": "hytale:icon/regen",
  "OverlapBehavior": "Replace",
  "StatModifiers": {
    "hytale:health": 1.0
  },
  "ValueType": "Absolute",
  "DamageCalculatorCooldown": 0.5,
  "StatModifierEffects": {
    "Particles": ["hytale:heal_sparkle"]
  }
}
```

### Invulnerability

```json
{
  "Name": "effect.invulnerable.name",
  "Duration": 5.0,
  "Debuff": false,
  "StatusEffectIcon": "hytale:icon/shield",
  "OverlapBehavior": "Ignore",
  "Invulnerable": true,
  "ModelChange": "hytale:player_glowing",
  "ApplicationEffects": {
    "Particles": ["hytale:golden_shield"],
    "Sounds": ["hytale:shield_activate"]
  }
}
```

### Complete Example in Code

```java
public class EffectManager {
    
    // Apply poison to entity
    public void applyPoison(
        Ref<EntityStore> targetRef,
        ComponentAccessor<EntityStore> accessor,
        float duration
    ) {
        // Get effect config
        EntityEffect poison = EntityEffect.getAssetMap()
            .getAsset("hytale:poison");
        if (poison == null) return;
        
        // Get or add effect controller
        EffectControllerComponent controller = accessor.getComponent(
            targetRef,
            EffectControllerComponent.getComponentType()
        );
        if (controller == null) {
            controller = new EffectControllerComponent();
            accessor.putComponent(
                targetRef,
                EffectControllerComponent.getComponentType(),
                controller
            );
        }
        
        // Apply effect with custom duration
        controller.addEffect(
            targetRef,
            poison,
            duration,
            OverlapBehavior.Extend,
            accessor
        );
    }
    
    // Check if entity is poisoned
    public boolean isPoisoned(
        Ref<EntityStore> entityRef,
        ComponentAccessor<EntityStore> accessor
    ) {
        EffectControllerComponent controller = accessor.getComponent(
            entityRef,
            EffectControllerComponent.getComponentType()
        );
        if (controller == null) return false;
        
        int poisonIndex = EntityEffect.getAssetMap()
            .getIndex("hytale:poison");
        return controller.getActiveEffects().containsKey(poisonIndex);
    }
    
    // Cure all debuffs
    public void cureDebuffs(
        Ref<EntityStore> entityRef,
        ComponentAccessor<EntityStore> accessor
    ) {
        EffectControllerComponent controller = accessor.getComponent(
            entityRef,
            EffectControllerComponent.getComponentType()
        );
        if (controller == null) return;
        
        // Find all debuffs
        List<Integer> debuffsToRemove = new ArrayList<>();
        for (Int2ObjectMap.Entry<ActiveEntityEffect> entry : 
             controller.getActiveEffects().int2ObjectEntrySet()) {
            if (entry.getValue().isDebuff()) {
                debuffsToRemove.add(entry.getIntKey());
            }
        }
        
        // Remove them
        for (int effectIndex : debuffsToRemove) {
            controller.removeEffect(entityRef, effectIndex, accessor);
        }
    }
}
```

## Effect Systems

Effects are processed by the `LivingEntityEffectSystem` from the EntityModule, which:

- Ticks all active effects each frame
- Updates durations and removes expired effects
- Applies periodic damage
- Updates stat modifiers
- Triggers effect-related interactions

The system iterates through all entities with `EffectControllerComponent` and calls `ActiveEntityEffect.tick()` on each active effect.
