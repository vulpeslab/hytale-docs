---
title: Damage System
description: Understanding the damage system in Hytale, including damage causes, damage data, knockback, and hit detection
---

The damage system in Hytale handles all aspects of entity damage, from damage calculation to knockback and visual effects. The system is built on the Entity Component System (ECS) architecture and uses events for damage processing.

## Core Components

### DamageDataComponent

Located in `com.hypixel.hytale.server.core.entity.damage`, this component tracks damage-related data for entities.

```java
public class DamageDataComponent implements Component<EntityStore> {
    private Instant lastCombatAction;
    private Instant lastDamageTime;
    private WieldingInteraction currentWielding;
    private Instant lastChargeTime;
}
```

**Fields:**
- `lastCombatAction` - Timestamp of the last combat-related action
- `lastDamageTime` - Timestamp when the entity last took damage
- `currentWielding` - The current wielding interaction being used
- `lastChargeTime` - Timestamp of the last charge action

This component is automatically added to all living entities via the `DamageDataSetupSystem`.

### KnockbackComponent

Located in `com.hypixel.hytale.server.core.entity.knockback`, this component handles knockback effects applied to entities.

```java
public class KnockbackComponent implements Component<EntityStore> {
    private Vector3d velocity;
    private ChangeVelocityType velocityType;
    private VelocityConfig velocityConfig;
    private DoubleList modifiers;
    private float duration;
    private float timer;
}
```

**Fields:**
- `velocity` - The knockback velocity vector
- `velocityType` - How the velocity should be applied (Add or Set)
- `velocityConfig` - Configuration for velocity behavior
- `modifiers` - List of multipliers applied to the knockback
- `duration` - How long the knockback should be applied (0 for instant)
- `timer` - Internal timer for tracking knockback duration

**Methods:**
- `addModifier(double)` - Add a multiplier to the knockback
- `applyModifiers()` - Apply all modifiers to the velocity
- `incrementTimer(float)` - Update the knockback timer

## Damage Event System

### Damage Class

The `Damage` class (in `com.hypixel.hytale.server.core.modules.entity.damage`) represents a damage event and extends `CancellableEcsEvent`.

```java
public class Damage extends CancellableEcsEvent implements IMetaStore<Damage> {
    private final float initialAmount;
    private int damageCauseIndex;
    private Source source;
    private float amount;
}
```

**Fields:**
- `initialAmount` - The original damage amount before any modifications
- `damageCauseIndex` - Index of the damage cause in the asset registry
- `source` - The source of the damage (entity, environment, command, etc.)
- `amount` - The current damage amount (can be modified by systems)

**Meta Keys:**

The damage system uses metadata to attach additional information:

- `HIT_LOCATION` - `Vector4d` - The location where the hit occurred
- `HIT_ANGLE` - `Float` - The angle of the hit
- `IMPACT_PARTICLES` - `Particles` - Particle effects to play on impact
- `IMPACT_SOUND_EFFECT` - `SoundEffect` - Sound effect for the impact
- `PLAYER_IMPACT_SOUND_EFFECT` - `SoundEffect` - Player-specific impact sound
- `CAMERA_EFFECT` - `CameraEffect` - Camera shake/effect to apply
- `DEATH_ICON` - `String` - Icon to show in death messages
- `BLOCKED` - `Boolean` - Whether the damage was blocked
- `STAMINA_DRAIN_MULTIPLIER` - `Float` - Multiplier for stamina drain
- `CAN_BE_PREDICTED` - `Boolean` - Whether damage can be client-predicted
- `KNOCKBACK_COMPONENT` - `KnockbackComponent` - Knockback to apply

### Damage Sources

Damage can come from various sources, defined by the `Damage.Source` interface:

**EntitySource** - Damage from another entity
```java
public static class EntitySource implements Source {
    protected final Ref<EntityStore> sourceRef;
}
```

**ProjectileSource** - Damage from a projectile, extends EntitySource
```java
public static class ProjectileSource extends EntitySource {
    protected final Ref<EntityStore> projectile;
}
```

**EnvironmentSource** - Damage from environment (fall, drowning, etc.)
```java
public static class EnvironmentSource implements Source {
    private final String type;
}
```

**CommandSource** - Damage from server commands
```java
public static class CommandSource implements Source {
    private final CommandSender commandSender;
    private final String commandName;
}
```

## Damage Causes

Damage causes are defined as asset files and stored in the `DamageCause` asset registry.

### DamageCause Asset

```java
public class DamageCause implements JsonAssetWithMap<String, IndexedLookupTableAssetMap<String, DamageCause>> {
    protected String id;
    protected String inherits;
    protected boolean durabilityLoss;
    protected boolean staminaLoss;
    protected boolean bypassResistances;
    protected String damageTextColor;
    protected String animationId = "Hurt";
    protected String deathAnimationId = "Death";
}
```

**Properties:**
- `id` - Unique identifier for the damage cause
- `inherits` - Another damage cause to inherit properties from
- `durabilityLoss` - Whether this damage causes durability loss on armor/items
- `staminaLoss` - Whether this damage drains stamina
- `bypassResistances` - Whether this damage ignores resistance modifiers
- `damageTextColor` - Color for damage numbers in the UI
- `animationId` - Animation to play when hit
- `deathAnimationId` - Animation to play on death from this damage

**Built-in Damage Causes:**
- `PHYSICAL` - Melee/physical damage
- `PROJECTILE` - Projectile damage
- `FALL` - Fall damage
- `DROWNING` - Drowning damage
- `SUFFOCATION` - Suffocation damage
- `OUT_OF_WORLD` - Void damage
- `ENVIRONMENT` - Generic environmental damage
- `COMMAND` - Damage from commands

## Damage Processing Pipeline

The damage system uses a three-stage processing pipeline via system groups:

### 1. Gather Damage Group

Systems in this group create and gather damage events. This is where damage is initially applied to entities.

### 2. Filter Damage Group

Systems in this group modify or cancel damage events. This includes:

- **FilterPlayerWorldConfig** - Applies world config settings for players
- **FilterNPCWorldConfig** - Applies world config settings for NPCs
- **FilterUnkillable** - Prevents damage to unkillable entities
- **PlayerDamageFilterSystem** - Handles player-specific damage filtering
- **WieldingDamageReduction** - Reduces damage based on equipped items
- **ArmorDamageReduction** - Reduces damage based on armor

### 3. Inspect Damage Group

Systems in this group handle the effects of damage after it's been filtered. This includes:

- **RecordLastCombat** - Records combat statistics
- **ApplyParticles** - Spawns particle effects
- **ApplySoundEffects** - Plays sound effects
- **HitAnimation** - Triggers hit animations
- **TrackLastDamage** - Updates last damage time
- **DamageArmor** - Applies durability loss to armor
- **DamageStamina** - Drains stamina
- **DamageAttackerTool** - Applies durability loss to attacking tool
- **PlayerHitIndicators** - Shows hit indicators to players

## Knockback System

Knockback is processed after damage in the Inspect Damage Group.

### Knockback Types

There are several types of knockback defined in the `com.hypixel.hytale.server.core.modules.interaction.interaction.config.server.combat` package:

**PointKnockback** - Knockback away from a specific point
**DirectionalKnockback** - Knockback in a specific direction
**ForceKnockback** - Raw force-based knockback

### Knockback Base Class

```java
public abstract class Knockback {
    protected float force;
    protected float duration;
    protected ChangeVelocityType velocityType = ChangeVelocityType.Add;
    private VelocityConfig velocityConfig;
    
    public abstract Vector3d calculateVector(Vector3d attackerPos, float yaw, Vector3d targetPos);
}
```

**Properties:**
- `force` - The magnitude of the knockback
- `duration` - How long to apply knockback (0 for instant)
- `velocityType` - Whether to add to or set velocity (Add/Set)
- `velocityConfig` - Advanced velocity configuration

### Knockback Systems

**ApplyKnockback** - Applies knockback to non-player entities
- Reads the `KnockbackComponent`
- Applies modifiers
- Adds velocity instruction to the entity's `Velocity` component
- Removes the component when duration expires

**ApplyPlayerKnockback** - Applies knockback to players with prediction support
- Similar to ApplyKnockback but handles client-side prediction
- Uses `KnockbackSimulation` component for predicted knockback
- Controlled by `DO_SERVER_PREDICTION` flag

### Knockback Reduction

Knockback can be reduced through:

- **WieldingKnockbackReduction** - Reduces knockback based on wielded item
- **ArmorKnockbackReduction** - Reduces knockback based on worn armor

## Using the Damage System

### Creating a Damage Event

```java
// Create damage with an entity source
Damage.EntitySource source = new Damage.EntitySource(attackerRef);
DamageCause cause = DamageCause.getAssetMap().getAsset("Physical");
Damage damage = new Damage(source, cause, 10.0f);

// Add metadata
damage.putMeta(Damage.HIT_LOCATION, hitLocation);
damage.putMeta(Damage.HIT_ANGLE, hitAngle);

// Fire the damage event
store.getEventBus().fire(damage, targetRef);
```

### Listening to Damage Events

Create a system that extends `DamageEventSystem`:

```java
public class MyDamageListener extends DamageEventSystem {
    @Override
    public void onEvent(Damage damage, Ref<EntityStore> targetRef, 
                       Store<EntityStore> store, CommandBuffer<EntityStore> commandBuffer) {
        // Modify damage
        damage.setAmount(damage.getAmount() * 0.5f);
        
        // Or cancel it
        damage.setCancelled(true);
    }
}
```

### Adding Knockback to Damage

```java
Damage damage = new Damage(source, cause, 10.0f);

// Create knockback component
KnockbackComponent knockback = new KnockbackComponent();
knockback.setVelocity(new Vector3d(0, 1, 0)); // Upward knockback
knockback.setVelocityType(ChangeVelocityType.Add);
knockback.setDuration(0.2f); // Apply for 0.2 seconds

// Add to damage metadata
damage.putMeta(Damage.KNOCKBACK_COMPONENT, knockback);
```

## Death System

When an entity's health reaches zero, the `DeathComponent` is added, triggering the death processing pipeline.

### DeathComponent

```java
public class DeathComponent implements Component<EntityStore>
```

Death-related systems handle:
- **ClearHealth** - Resets health to zero
- **ClearInteractions** - Removes active interactions
- **ClearEntityEffects** - Removes status effects
- **PlayerKilledPlayer** - Awards kill credit
- **DropPlayerDeathItems** - Drops inventory on death
- **KillFeed** - Broadcasts death messages
- **PlayerDeathScreen** - Shows death screen to players
- **DeathAnimation** - Plays death animation
- **CorpseRemoval** - Removes the entity after a delay

## Best Practices

1. **Use the event system** - Always fire damage through the event bus to allow other plugins to modify it
2. **Check cancellation** - Respect the cancelled state of damage events
3. **Use appropriate sources** - Choose the correct source type for your damage
4. **Add metadata** - Include hit location, angle, and effects for better player feedback
5. **Consider knockback** - Most damage types should include some knockback
6. **Respect damage causes** - Use appropriate damage cause assets for different damage types
7. **Handle death gracefully** - Use the DeathComponent system rather than directly removing entities

## Related Systems

- **Entity Stats System** - Manages health, resistance, and other stats affected by damage
- **Physics System** - Handles velocity and knockback movement
- **Animation System** - Plays hit and death animations
- **Particle System** - Shows impact particles
- **Sound System** - Plays damage and death sounds
