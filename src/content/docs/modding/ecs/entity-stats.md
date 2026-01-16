---
author: UnlimitedBytes
title: Entity Stats System
description: Learn about Hytale's Entity Stats System for managing Health, Stamina, Mana, and custom character attributes.
sidebar:
  order: 3
human-verified: false
---

Hytale's Entity Stats System provides a flexible framework for managing entity attributes like Health, Stamina, Mana, and Oxygen. The system supports dynamic modifiers, conditional regeneration, and custom stat types.

## Architecture Overview

```
EntityStatMap (Component)
├── EntityStatValue[]           - Individual stat instances
│   ├── value, min, max         - Current and bounds
│   ├── RegeneratingValue[]     - Regeneration handlers
│   └── Map<String, Modifier>   - Active modifiers
├── StatModifiersManager        - Recalculates modifiers from equipment/effects
└── EntityStatType (Asset)      - Stat definition from JSON
```

## Core Classes

### EntityStatValue

Represents a single stat instance on an entity:

```java
import com.hypixel.hytale.server.core.modules.entitystats.EntityStatValue;

public class EntityStatValue {
    // Get the current value
    public float get();

    // Get as percentage between min and max (0.0 to 1.0)
    public float asPercentage();

    // Bounds
    public float getMin();
    public float getMax();

    // Modifiers
    @Nullable
    public Modifier getModifier(String key);

    @Nullable
    public Map<String, Modifier> getModifiers();
}
```

### EntityStatMap

A component that holds all stat values for an entity:

```java
import com.hypixel.hytale.server.core.modules.entitystats.EntityStatMap;
import com.hypixel.hytale.server.core.modules.entitystats.EntityStatsModule;

// Get the component type
ComponentType<EntityStore, EntityStatMap> statMapType =
    EntityStatsModule.get().getEntityStatMapComponentType();

// Get from entity
EntityStatMap stats = store.getComponent(entityRef, statMapType);

// Get stat by index
EntityStatValue health = stats.get(DefaultEntityStatTypes.getHealth());
```

### Modifying Stats

```java
EntityStatMap stats = /* get from entity */;
int healthIndex = DefaultEntityStatTypes.getHealth();

// Set to specific value (clamped to min/max)
stats.setStatValue(healthIndex, 50.0f);

// Add to current value
stats.addStatValue(healthIndex, 10.0f);

// Subtract from current value
stats.subtractStatValue(healthIndex, 5.0f);

// Set to minimum
stats.minimizeStatValue(healthIndex);

// Set to maximum
stats.maximizeStatValue(healthIndex);
```

### Predictable Updates

For client prediction, use the `Predictable` enum to control network synchronization:

```java
import com.hypixel.hytale.server.core.modules.entitystats.EntityStatMap.Predictable;

// NONE - Normal server update (default)
stats.setStatValue(Predictable.NONE, healthIndex, 50.0f);

// SELF - Client can predict this change locally
stats.addStatValue(Predictable.SELF, staminaIndex, -10.0f);

// ALL - All viewers can predict this change
stats.subtractStatValue(Predictable.ALL, healthIndex, 25.0f);
```

## Default Stat Types

Hytale provides several built-in stat types:

```java
import com.hypixel.hytale.server.core.modules.entitystats.asset.DefaultEntityStatTypes;

int health = DefaultEntityStatTypes.getHealth();
int oxygen = DefaultEntityStatTypes.getOxygen();
int stamina = DefaultEntityStatTypes.getStamina();
int mana = DefaultEntityStatTypes.getMana();
int signatureEnergy = DefaultEntityStatTypes.getSignatureEnergy();
int ammo = DefaultEntityStatTypes.getAmmo();
```

| Stat Type | Description |
|-----------|-------------|
| `Health` | Entity health points |
| `Oxygen` | Breath underwater |
| `Stamina` | Used for sprinting and actions |
| `Mana` | Magic resource |
| `SignatureEnergy` | Special ability resource |
| `Ammo` | Ranged weapon ammunition |

## Stat Modifiers

Modifiers adjust stat bounds (min/max) dynamically. They're used by armor, effects, and items.

### StaticModifier

The most common modifier type:

```java
import com.hypixel.hytale.server.core.modules.entitystats.modifier.StaticModifier;
import com.hypixel.hytale.server.core.modules.entitystats.modifier.Modifier.ModifierTarget;

// Additive: value + amount
StaticModifier armorBonus = new StaticModifier(
    ModifierTarget.MAX,
    StaticModifier.CalculationType.ADDITIVE,
    20.0f  // +20 max health
);

// Multiplicative: value * amount
StaticModifier percentBoost = new StaticModifier(
    ModifierTarget.MAX,
    StaticModifier.CalculationType.MULTIPLICATIVE,
    1.5f   // 1.5x max health
);
```

### Applying Modifiers

```java
EntityStatMap stats = /* ... */;
int healthIndex = DefaultEntityStatTypes.getHealth();

// Add a modifier with a unique key
StaticModifier modifier = new StaticModifier(
    ModifierTarget.MAX,
    StaticModifier.CalculationType.ADDITIVE,
    50.0f
);
stats.putModifier(healthIndex, "my_plugin_bonus", modifier);

// Get existing modifier
Modifier existing = stats.getModifier(healthIndex, "my_plugin_bonus");

// Remove modifier
stats.removeModifier(healthIndex, "my_plugin_bonus");
```

### Built-in Modifier Keys

| Key Pattern | Source |
|-------------|--------|
| `Effect_ADDITIVE` | Entity effects |
| `Effect_MULTIPLICATIVE` | Entity effects |
| `Armor_ADDITIVE` | Equipped armor |
| `Armor_MULTIPLICATIVE` | Equipped armor |

## Creating Custom Stat Types

Custom stat types are defined in JSON asset files.

### JSON Structure

Create a file at `Entity/Stats/MyCustomStat.json`:

```json
{
    "Id": "MyCustomStat",
    "InitialValue": 100.0,
    "Min": 0.0,
    "Max": 100.0,
    "Shared": true,
    "IgnoreInvulnerability": false,
    "ResetType": "InitialValue",
    "Regenerating": [
        {
            "Interval": 1.0,
            "Amount": 5.0,
            "RegenType": "ADDITIVE",
            "ClampAtZero": true,
            "Conditions": [
                {
                    "Type": "OutOfCombat",
                    "DelaySeconds": 3.0
                }
            ]
        }
    ],
    "MinValueEffects": {
        "TriggerAtZero": false,
        "SoundEventId": "MyMod:StatEmpty"
    }
}
```

### Configuration Options

| Field | Type | Description |
|-------|------|-------------|
| `Id` | String | Unique identifier |
| `InitialValue` | Float | Starting value |
| `Min` | Float | Minimum bound |
| `Max` | Float | Maximum bound |
| `Shared` | Boolean | Visible to other players |
| `IgnoreInvulnerability` | Boolean | Can decrease when invulnerable |
| `MinValueEffects` | Object | Effects triggered at min value (sound, particles, interactions) |
| `MaxValueEffects` | Object | Effects triggered at max value (sound, particles, interactions) |
| `ResetType` | Enum | `InitialValue` or `MaxValue` |
| `Regenerating` | Array | Regeneration rules |

### Accessing Custom Stats

:::caution[Asset Loading Timing]
Entity stat assets are only guaranteed after the `LoadedAssetsEvent` for `EntityStatType` (initial load or reload). If you resolve custom stat indices during plugin `setup()`/`start()`, they may not be available yet. Prefer:
1. Registering a `LoadedAssetsEvent` listener for `EntityStatType` in `setup()` (recommended)
2. Lazy-resolving indices when first needed
:::

```java
import com.hypixel.hytale.server.core.modules.entitystats.asset.EntityStatType;

// Get stat index by ID
int customStatIndex = EntityStatType.getAssetMap().getIndex("MyCustomStat");

// Use with EntityStatMap
EntityStatMap stats = /* ... */;
EntityStatValue customStat = stats.get(customStatIndex);
float current = customStat.get();
float percent = customStat.asPercentage();
```

## Built-in Conditions

Conditions control when regeneration occurs:

| Condition | Description |
|-----------|-------------|
| `OutOfCombat` | True after delay since last combat action |
| `Gliding` | True when entity is gliding |
| `Charging` | True when entity is charging an attack |
| `Environment` | True when in specific environments |
| `LogicCondition` | Combine conditions with AND/OR |
| `Stat` | Compare stat value against threshold |
| `Alive` | True when entity is alive |
| `NoDamageTaken` | True after delay since taking damage |
| `Suffocating` | True when entity cannot breathe at its current position |
| `Sprinting` | True when entity is sprinting |
| `Player` | Check player game mode |
| `RegenHealth` | Always true (reserved for health regen rules) |
| `Wielding` | True when entity is wielding an item |

## Example: Custom Resource System

```java
import com.hypixel.hytale.assetstore.event.LoadedAssetsEvent;
import com.hypixel.hytale.server.core.modules.entitystats.asset.EntityStatType;

public class MyResourcePlugin extends JavaPlugin {
    private int focusStatIndex = Integer.MIN_VALUE;

    @Override
    protected void setup() {
        // Register listener to cache stat index when assets are loaded
        getEventRegistry().register(
            LoadedAssetsEvent.class,
            EntityStatType.class,
            this::onEntityStatTypesLoaded
        );
    }

    private void onEntityStatTypesLoaded(LoadedAssetsEvent<?, ?, ?> event) {
        // Called when EntityStatType assets are loaded or reloaded
        focusStatIndex = EntityStatType.getAssetMap().getIndex("Focus");
    }

    public void consumeFocus(Ref<EntityStore> ref, Store<EntityStore> store, float amount) {
        if (focusStatIndex == Integer.MIN_VALUE) return; // Assets not loaded yet

        EntityStatMap stats = store.getComponent(ref, EntityStatMap.getComponentType());
        if (stats == null) return;

        EntityStatValue focus = stats.get(focusStatIndex);
        if (focus == null || focus.get() < amount) {
            return; // Not enough focus
        }

        stats.subtractStatValue(Predictable.SELF, focusStatIndex, amount);
    }

    public void addFocusModifier(Ref<EntityStore> ref, Store<EntityStore> store) {
        if (focusStatIndex == Integer.MIN_VALUE) return; // Assets not loaded yet

        EntityStatMap stats = store.getComponent(ref, EntityStatMap.getComponentType());
        if (stats == null) return;

        StaticModifier bonus = new StaticModifier(
            Modifier.ModifierTarget.MAX,
            StaticModifier.CalculationType.ADDITIVE,
            25.0f
        );
        stats.putModifier(focusStatIndex, "focus_mastery", bonus);
    }
}
```

:::tip[Alternative: Lazy Initialization]
If your custom stat is only used occasionally, you can use lazy initialization instead:

```java
public class MyResourcePlugin extends JavaPlugin {
    private int focusStatIndex = Integer.MIN_VALUE;

    private int getFocusStatIndex() {
        if (focusStatIndex == Integer.MIN_VALUE) {
            focusStatIndex = EntityStatType.getAssetMap().getIndex("Focus");
        }
        return focusStatIndex;
    }

    public void consumeFocus(/* ... */) {
        int index = getFocusStatIndex();
        if (index == Integer.MIN_VALUE) return; // Stat not found
        // ... use index
    }
}
```
:::

## Best Practices

1. **Use stat indices** - Cache indices from `EntityStatType.getAssetMap().getIndex()` for performance
2. **Unique modifier keys** - Use plugin-prefixed keys like `"myplugin_bonus"` to avoid conflicts
3. **Respect invulnerability** - Check `IgnoreInvulnerability` when dealing damage
4. **Use Predictable wisely** - Only use `SELF` or `ALL` for changes the client can accurately predict
5. **Clean up modifiers** - Remove modifiers when effects expire or equipment is removed
6. **Consider network traffic** - `Shared: false` stats don't sync to other players
7. **Handle missing stats** - Always null-check when getting `EntityStatValue`
