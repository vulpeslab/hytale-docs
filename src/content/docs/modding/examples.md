---
title: Examples & Patterns
description: Code examples and common patterns for Hytale plugin development.
sidebar:
  order: 8
---

This page provides complete code examples and common patterns for Hytale plugin development.

## Complete Plugin Example

### Basic Plugin Structure

```java
package com.example.myplugin;

import com.hypixel.hytale.server.core.plugin.JavaPlugin;
import com.hypixel.hytale.server.core.plugin.JavaPluginInit;
import javax.annotation.Nonnull;

public class MyPlugin extends JavaPlugin {

    private static MyPlugin instance;

    public MyPlugin(@Nonnull JavaPluginInit init) {
        super(init);
    }

    public static MyPlugin get() {
        return instance;
    }

    @Override
    protected void setup() {
        instance = this;

        // Register components
        registerComponents();

        // Register systems
        registerSystems();

        // Register commands
        registerCommands();

        // Register events
        registerEvents();

        getLogger().at(Level.INFO).log("MyPlugin setup complete!");
    }

    @Override
    protected void start() {
        getLogger().at(Level.INFO).log("MyPlugin started!");
    }

    @Override
    protected void shutdown() {
        getLogger().at(Level.INFO).log("MyPlugin shutting down!");
    }

    private void registerComponents() {
        // Component registration here
    }

    private void registerSystems() {
        // System registration here
    }

    private void registerCommands() {
        // Command registration here
    }

    private void registerEvents() {
        // Event registration here
    }
}
```

### manifest.json

```json
{
  "Group": "com.example",
  "Name": "MyPlugin",
  "Version": "1.0.0",
  "Main": "com.example.myplugin.MyPlugin",
  "Description": "A complete example plugin",
  "Authors": [
    {
      "Name": "Your Name"
    }
  ],
  "ServerVersion": ">=0.0.1",
  "Dependencies": {},
  "OptionalDependencies": {},
  "IncludesAssetPack": false
}
```

## Health System Example

This example demonstrates a complete feature implementation with component, system, and command.

### Component

```java
import com.hypixel.hytale.codec.Codec;
import com.hypixel.hytale.codec.KeyedCodec;
import com.hypixel.hytale.codec.builder.BuilderCodec;
import com.hypixel.hytale.component.Component;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;
import javax.annotation.Nullable;

public class HealthComponent implements Component<EntityStore> {

    public static final BuilderCodec<HealthComponent> CODEC =
        ((BuilderCodec.Builder) BuilderCodec.builder(HealthComponent.class, HealthComponent::new)
            .append(new KeyedCodec<>("MaxHealth", Codec.FLOAT),
                (c, v) -> c.maxHealth = v, c -> c.maxHealth)
            .add())
            .append(new KeyedCodec<>("CurrentHealth", Codec.FLOAT),
                (c, v) -> c.currentHealth = v, c -> c.currentHealth)
            .add()
            .append(new KeyedCodec<>("RegenRate", Codec.FLOAT),
                (c, v) -> c.regenRate = v, c -> c.regenRate)
            .add()
            .build();

    private float maxHealth = 100f;
    private float currentHealth = 100f;
    private float regenRate = 1f;

    public HealthComponent() {}

    public HealthComponent(float maxHealth, float regenRate) {
        this.maxHealth = maxHealth;
        this.currentHealth = maxHealth;
        this.regenRate = regenRate;
    }

    public float getMaxHealth() { return maxHealth; }
    public float getCurrentHealth() { return currentHealth; }
    public float getRegenRate() { return regenRate; }

    public void heal(float amount) {
        currentHealth = Math.min(maxHealth, currentHealth + amount);
    }

    public void damage(float amount) {
        currentHealth = Math.max(0, currentHealth - amount);
    }

    public boolean isDead() {
        return currentHealth <= 0;
    }

    public float getHealthPercent() {
        return currentHealth / maxHealth;
    }

    @Override
    @Nullable
    public Component<EntityStore> clone() {
        HealthComponent copy = new HealthComponent();
        copy.maxHealth = this.maxHealth;
        copy.currentHealth = this.currentHealth;
        copy.regenRate = this.regenRate;
        return copy;
    }
}
```

### System

Systems process entities with specific components each tick. The `EntityTickingSystem` is ideal for per-entity logic:

```java
import com.hypixel.hytale.component.ArchetypeChunk;
import com.hypixel.hytale.component.CommandBuffer;
import com.hypixel.hytale.component.ComponentType;
import com.hypixel.hytale.component.Store;
import com.hypixel.hytale.component.query.Query;
import com.hypixel.hytale.component.system.tick.EntityTickingSystem;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;

public class HealthRegenSystem extends EntityTickingSystem<EntityStore> {

    private final Query<EntityStore> query;
    private final ComponentType<EntityStore, HealthComponent> healthType;

    public HealthRegenSystem(ComponentType<EntityStore, HealthComponent> healthType) {
        this.healthType = healthType;
        this.query = healthType;  // Query for entities with HealthComponent
    }

    @Override
    @Nullable
    public Query<EntityStore> getQuery() {
        return query;
    }

    @Override
    public void tick(float dt, int index,
                     @Nonnull ArchetypeChunk<EntityStore> chunk,
                     @Nonnull Store<EntityStore> store,
                     @Nonnull CommandBuffer<EntityStore> commandBuffer) {

        HealthComponent health = chunk.getComponent(index, healthType);
        assert health != null;

        if (!health.isDead() && health.getCurrentHealth() < health.getMaxHealth()) {
            health.heal(health.getRegenRate() * dt);
        }
    }
}
```

### Command

Commands use `AbstractCommandCollection` for grouping and `CommandBase` for individual commands:

```java
import com.hypixel.hytale.component.ComponentType;
import com.hypixel.hytale.component.Ref;
import com.hypixel.hytale.component.Store;
import com.hypixel.hytale.server.core.Message;
import com.hypixel.hytale.server.core.command.system.CommandContext;
import com.hypixel.hytale.server.core.command.system.arguments.system.RequiredArg;
import com.hypixel.hytale.server.core.command.system.arguments.types.ArgTypes;
import com.hypixel.hytale.server.core.command.system.basecommands.AbstractCommandCollection;
import com.hypixel.hytale.server.core.command.system.basecommands.AbstractPlayerCommand;
import com.hypixel.hytale.server.core.command.system.basecommands.CommandBase;
import com.hypixel.hytale.server.core.universe.PlayerRef;
import com.hypixel.hytale.server.core.universe.world.World;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;
import javax.annotation.Nonnull;

public class HealthCommand extends AbstractCommandCollection {

    private final ComponentType<EntityStore, HealthComponent> healthType;

    public HealthCommand(ComponentType<EntityStore, HealthComponent> healthType) {
        super("health", "server.commands.health");  // name, description key
        this.healthType = healthType;

        this.addSubCommand(new HealCommand());
        this.addSubCommand(new CheckCommand());
    }

    // Command that requires player context
    class HealCommand extends AbstractPlayerCommand {
        @Nonnull
        private final RequiredArg<Double> amountArg =
            this.withRequiredArg("amount", "server.commands.health.heal.amount", ArgTypes.DOUBLE);

        HealCommand() {
            super("heal", "server.commands.health.heal.desc");
        }

        @Override
        protected void execute(@Nonnull CommandContext context,
                               @Nonnull Store<EntityStore> store,
                               @Nonnull Ref<EntityStore> ref,
                               @Nonnull PlayerRef playerRef,
                               @Nonnull World world) {
            double amount = amountArg.get(context);
            HealthComponent health = store.getComponent(ref, healthType);

            if (health != null) {
                health.heal((float) amount);
                context.sendMessage(Message.translation("server.commands.health.healed")
                    .param("amount", amount));
            } else {
                context.sendMessage(Message.translation("server.commands.health.noComponent"));
            }
        }
    }

    // Basic command variant
    class CheckCommand extends CommandBase {
        @Nonnull
        private final RequiredArg<PlayerRef> playerArg =
            this.withRequiredArg("player", "server.commands.health.check.player", ArgTypes.PLAYER_REF);

        CheckCommand() {
            super("server.commands.health.check.desc");
        }

        @Override
        protected void executeSync(@Nonnull CommandContext context) {
            PlayerRef playerRef = playerArg.get(context);
            Ref<EntityStore> ref = playerRef.getReference();

            if (ref == null || !ref.isValid()) {
                context.sendMessage(Message.translation("server.commands.errors.playerNotInWorld"));
                return;
            }

            Store<EntityStore> store = ref.getStore();
            World world = store.getExternalData().getWorld();

            world.execute(() -> {
                HealthComponent health = store.getComponent(ref, healthType);
                if (health != null) {
                    context.sendMessage(Message.translation("server.commands.health.status")
                        .param("username", playerRef.getUsername())
                        .param("current", health.getCurrentHealth())
                        .param("max", health.getMaxHealth()));
                }
            });
        }
    }
}
```

### Registration

All components, systems, and commands are registered in the plugin's `setup()` method:

```java
import com.hypixel.hytale.component.ComponentType;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;

@Override
protected void setup() {
    // Register component with name and codec for JSON serialization
    ComponentType<EntityStore, HealthComponent> healthType =
        getEntityStoreRegistry().registerComponent(
            HealthComponent.class,
            "Health",                    // Component name in JSON
            HealthComponent.CODEC        // Serialization codec
        );

    // Register system that processes entities with HealthComponent
    getEntityStoreRegistry().registerSystem(new HealthRegenSystem(healthType));

    // Register command collection
    getCommandRegistry().registerCommand(new HealthCommand(healthType));

    getLogger().at(Level.INFO).log("Health system registered!");
}
```

## Custom Event Example

### Event Definition

```java
public class PlayerLevelUpEvent implements IEvent<Void>, ICancellable {

    private final PlayerRef player;
    private final int oldLevel;
    private final int newLevel;
    private boolean cancelled = false;

    public PlayerLevelUpEvent(PlayerRef player, int oldLevel, int newLevel) {
        this.player = player;
        this.oldLevel = oldLevel;
        this.newLevel = newLevel;
    }

    public PlayerRef getPlayer() { return player; }
    public int getOldLevel() { return oldLevel; }
    public int getNewLevel() { return newLevel; }

    @Override
    public boolean isCancelled() { return cancelled; }

    @Override
    public void setCancelled(boolean cancelled) { this.cancelled = cancelled; }
}
```

### Dispatching

```java
public void levelUp(PlayerRef player, int newLevel) {
    int oldLevel = getCurrentLevel(player);

    IEventDispatcher<PlayerLevelUpEvent, PlayerLevelUpEvent> dispatcher =
        HytaleServer.get().getEventBus().dispatchFor(PlayerLevelUpEvent.class);

    if (dispatcher.hasListener()) {
        PlayerLevelUpEvent event = new PlayerLevelUpEvent(player, oldLevel, newLevel);
        dispatcher.dispatch(event);

        if (event.isCancelled()) {
            return;  // Level up was cancelled
        }
    }

    // Apply level up
    setLevel(player, newLevel);
}
```

### Listening

```java
@Override
protected void setup() {
    getEventRegistry().register(
        PlayerLevelUpEvent.class,
        event -> {
            getLogger().at(Level.INFO).log("Player leveled up: " +
                event.getOldLevel() + " -> " + event.getNewLevel());

            // Cancel if level too high
            if (event.getNewLevel() > 100) {
                event.setCancelled(true);
            }
        }
    );
}
```

## Custom Interaction Example

Interactions define game actions triggered by player input. This example shows a simple instant interaction:

### Interaction Class

```java
import com.hypixel.hytale.codec.KeyedCodec;
import com.hypixel.hytale.codec.builder.BuilderCodec;
import com.hypixel.hytale.component.CommandBuffer;
import com.hypixel.hytale.component.Ref;
import com.hypixel.hytale.protocol.InteractionState;
import com.hypixel.hytale.protocol.InteractionType;
import com.hypixel.hytale.protocol.Vector3f;
import com.hypixel.hytale.server.core.codec.ProtocolCodecs;
import com.hypixel.hytale.server.core.entity.InteractionContext;
import com.hypixel.hytale.server.core.modules.entity.component.TransformComponent;
import com.hypixel.hytale.server.core.modules.interaction.interaction.CooldownHandler;
import com.hypixel.hytale.server.core.modules.interaction.interaction.config.SimpleInstantInteraction;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;
import javax.annotation.Nonnull;

public class TeleportInteraction extends SimpleInstantInteraction {

    public static final BuilderCodec<TeleportInteraction> CODEC =
        ((BuilderCodec.Builder) BuilderCodec.builder(
            TeleportInteraction.class,
            TeleportInteraction::new,
            SimpleInstantInteraction.CODEC)  // Inherit parent codec
            .appendInherited(
                new KeyedCodec<>("Destination", ProtocolCodecs.VECTOR3F),
                (i, v) -> i.destination.assign(v.x, v.y, v.z),
                i -> new Vector3f(i.destination.x, i.destination.y, i.destination.z),
                (i, parent) -> i.destination = parent.destination)  // Inheritance handler
            .add())
        .build();

    private com.hypixel.hytale.math.vector.Vector3f destination =
        new com.hypixel.hytale.math.vector.Vector3f(0, 0, 0);

    @Override
    protected void firstRun(@Nonnull InteractionType type,
                            @Nonnull InteractionContext context,
                            @Nonnull CooldownHandler cooldownHandler) {

        Ref<EntityStore> entity = context.getEntity();
        CommandBuffer<EntityStore> buffer = context.getCommandBuffer();

        TransformComponent transform = buffer.getComponent(entity, TransformComponent.getComponentType());

        if (transform != null) {
            transform.setPosition(destination.x, destination.y, destination.z);
            context.getState().state = InteractionState.Finished;
        } else {
            context.getState().state = InteractionState.Failed;
        }
    }
}
```

### Registration

```java
import com.hypixel.hytale.server.core.modules.interaction.interaction.config.Interaction;

@Override
protected void setup() {
    // Register with the polymorphic Interaction codec
    getCodecRegistry(Interaction.CODEC)
        .register("Teleport", TeleportInteraction.class, TeleportInteraction.CODEC);
}
```

### Usage in JSON

Once registered, the interaction can be used in item definitions:

```json
{
  "Type": "Teleport",
  "Destination": [100.0, 64.0, 100.0]
}
```

## Common Patterns

### Singleton Access Pattern

```java
public class MyPlugin extends JavaPlugin {
    private static MyPlugin instance;

    public static MyPlugin get() {
        return instance;
    }

    @Override
    protected void setup() {
        instance = this;
    }
}
```

### Type-Safe Component Access

```java
private ComponentType<EntityStore, MyComponent> componentType;

public ComponentType<EntityStore, MyComponent> getComponentType() {
    return componentType;
}

// Usage elsewhere
MyComponent comp = store.getComponent(entityRef, MyPlugin.get().getComponentType());
```

### Event Handler Method Pattern

```java
private void onPlayerJoin(PlayerConnectEvent event) {
    // Handle event
}

@Override
protected void setup() {
    getEventRegistry().register(PlayerConnectEvent.class, this::onPlayerJoin);
}
```

### Codec Registration Chain

```java
getCodecRegistry(ParentCodec.CODEC)
    .register("TypeA", TypeA.class, TypeA.CODEC)
    .register("TypeB", TypeB.class, TypeB.CODEC)
    .register("TypeC", TypeC.class, TypeC.CODEC);
```

### Plugin Configuration

Plugins can define configuration that is loaded from JSON files:

```java
import com.hypixel.hytale.codec.Codec;
import com.hypixel.hytale.codec.KeyedCodec;
import com.hypixel.hytale.codec.builder.BuilderCodec;
import com.hypixel.hytale.server.core.util.Config;

public class MyPlugin extends JavaPlugin {

    // Define configuration class
    public static class MyPluginConfig {
        public static final BuilderCodec<MyPluginConfig> CODEC =
            ((BuilderCodec.Builder) BuilderCodec.builder(MyPluginConfig.class, MyPluginConfig::new)
                .append(new KeyedCodec<>("Enabled", Codec.BOOLEAN),
                    (c, v) -> c.enabled = v, c -> c.enabled)
                .add())
                .append(new KeyedCodec<>("MaxPlayers", Codec.INTEGER),
                    (c, v) -> c.maxPlayers = v, c -> c.maxPlayers)
                .add()
                .build();

        private boolean enabled = true;
        private int maxPlayers = 100;

        public boolean isEnabled() { return enabled; }
        public int getMaxPlayers() { return maxPlayers; }
    }

    // Register config BEFORE setup() - must be called in constructor or field initializer
    private final Config<MyPluginConfig> config = this.withConfig("MyPlugin", MyPluginConfig.CODEC);

    public MyPlugin(@Nonnull JavaPluginInit init) {
        super(init);
    }

    @Override
    protected void start() {
        // Access config after loading
        MyPluginConfig cfg = config.get();
        if (cfg.isEnabled()) {
            getLogger().at(Level.INFO).log("Plugin enabled with max players: " + cfg.getMaxPlayers());
        }
    }
}
```

### World Execution Pattern

World operations should be executed within the world's thread context:

```java
// Execute code in specific world context
world.execute(() -> {
    // Code runs in world's execution context
    Store<EntityStore> store = world.getStore();
    // Safe to access and modify entities here
});
```

This pattern is commonly used when handling commands that target players in different worlds:

```java
@Override
protected void executeSync(@Nonnull CommandContext context) {
    PlayerRef playerRef = playerArg.get(context);
    Ref<EntityStore> ref = playerRef.getReference();

    if (ref == null || !ref.isValid()) {
        context.sendMessage(Message.translation("server.commands.errors.playerNotInWorld"));
        return;
    }

    Store<EntityStore> store = ref.getStore();
    World world = store.getExternalData().getWorld();

    // Execute in the player's world context
    world.execute(() -> {
        // Safe to modify entity components here
        store.tryRemoveComponent(ref, SomeComponent.getComponentType());
        context.sendMessage(Message.translation("server.commands.success"));
    });
}
```

### Async Event Handling

```java
getEventRegistry().registerAsync(
    PlayerChatEvent.class,
    future -> future.thenApply(event -> {
        // Async processing
        if (containsBadWord(event.getMessage())) {
            event.setCancelled(true);
        }
        return event;
    })
);
```

## Project Structure

```
my-plugin/
├── src/
│   └── main/
│       └── java/
│           └── com/
│               └── example/
│                   └── myplugin/
│                       ├── MyPlugin.java
│                       ├── components/
│                       │   └── HealthComponent.java
│                       ├── systems/
│                       │   └── HealthRegenSystem.java
│                       ├── commands/
│                       │   └── HealthCommand.java
│                       ├── events/
│                       │   └── PlayerLevelUpEvent.java
│                       └── interactions/
│                           └── TeleportInteraction.java
├── resources/
│   └── manifest.json
└── build.gradle
```

## Gradle Build Example

```groovy
plugins {
    id 'java'
}

group = 'com.example'
version = '1.0.0'

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

repositories {
    mavenCentral()
    flatDir {
        dirs 'libs'
    }
}

dependencies {
    compileOnly name: 'HytaleServer'
}

jar {
    from('src/main/resources') {
        include 'manifest.json'
    }
}
```

## Deployment

1. Build your plugin JAR with the manifest.json in the root
2. Place the JAR in the `mods/` directory
3. Restart the server
4. Check logs for successful loading

### Troubleshooting

- **Plugin not loading**: Verify manifest.json is at the root of the JAR and has valid JSON
- **ClassNotFoundException**: Ensure the `Main` class path matches your package structure
- **Missing dependencies**: Check that required plugins are also in the mods directory
- **Version conflicts**: Verify `ServerVersion` in manifest matches the server version

### Logging

Use the plugin logger for debug output:

```java
getLogger().at(Level.INFO).log("Plugin started");
getLogger().at(Level.WARNING).log("Something unexpected: %s", value);
getLogger().at(Level.SEVERE).withCause(exception).log("Failed to process: %s", item);
```
