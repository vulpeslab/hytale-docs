---
author: UnlimitedBytes
title: Event System
description: Subscribe to and create custom events in your Hytale plugins.
sidebar:
  order: 3
human-verified: false
---

The Hytale event system provides a powerful way to react to game occurrences and enable inter-plugin communication.

## Architecture

```
EventBus (Global)
├── SyncEventBusRegistry    - Synchronous events (IEvent)
└── AsyncEventBusRegistry   - Asynchronous events (IAsyncEvent)

EventRegistry (Per-Plugin)
└── Wraps EventBus with lifecycle management
```

## Event Types

### Synchronous Events (IEvent)

Execute handlers immediately in priority order:

```java
public interface IEvent<KeyType> extends IBaseEvent<KeyType> {
}
```

### Asynchronous Events (IAsyncEvent)

Execute handlers with CompletableFuture chaining:

```java
public interface IAsyncEvent<KeyType> extends IBaseEvent<KeyType> {
}
```

### Cancellable Events

Events that can be cancelled to prevent default behavior:

```java
public interface ICancellable {
    boolean isCancelled();
    void setCancelled(boolean var1);
}
```

:::note
Many built-in events like `PlaceBlockEvent`, `BreakBlockEvent`, `AddWorldEvent`, and `RemoveWorldEvent` implement `ICancellable`.
:::

## Event Priorities

Events are dispatched in priority order:

| Priority | Value | Description |
|----------|-------|-------------|
| `FIRST` | -21844 | Execute first |
| `EARLY` | -10922 | Execute early |
| `NORMAL` | 0 | Default priority |
| `LATE` | 10922 | Execute late |
| `LAST` | 21844 | Execute last |

## Subscribing to Events

### Basic Registration

```java
@Override
protected void setup() {
    getEventRegistry().register(BootEvent.class, this::onBoot);
}

private void onBoot(BootEvent event) {
    getLogger().at(Level.INFO).log("Server booted!");
}
```

### With Priority

```java
getEventRegistry().register(
    EventPriority.EARLY,
    PlayerJoinEvent.class,
    event -> {
        // Handle early
    }
);

// Or with custom priority value
getEventRegistry().register(
    (short) -5000,
    PlayerJoinEvent.class,
    this::onPlayerJoin
);
```

### Keyed Events

Listen to events for specific contexts:

```java
// Listen to events for specific world
getEventRegistry().register(
    WorldEvent.class,
    "world_name",  // Key
    event -> {
        // Only fires for events in "world_name"
    }
);
```

### Global Registration

Listen to all instances regardless of key:

```java
getEventRegistry().registerGlobal(
    EntitySpawnEvent.class,
    event -> {
        // Handles all entity spawns in all worlds
    }
);
```

## Creating Custom Events

### Simple Synchronous Event

```java
public class MyEvent implements IEvent<Void> {
    private final String data;

    public MyEvent(String data) {
        this.data = data;
    }

    public String getData() {
        return data;
    }
}
```

### Keyed Event

```java
public class WorldSpecificEvent implements IEvent<String> {
    private final String worldName;
    private final int value;

    public WorldSpecificEvent(String worldName, int value) {
        this.worldName = worldName;
        this.value = value;
    }

    public String getWorldName() {
        return worldName;
    }

    public int getValue() {
        return value;
    }
}
```

### Cancellable Event

```java
public class CancellableEvent implements IEvent<Void>, ICancellable {
    private boolean cancelled = false;
    private final String action;

    public CancellableEvent(String action) {
        this.action = action;
    }

    @Override
    public boolean isCancelled() {
        return cancelled;
    }

    @Override
    public void setCancelled(boolean cancelled) {
        this.cancelled = cancelled;
    }

    public String getAction() {
        return action;
    }
}
```

### Async Event

```java
public class MyAsyncEvent implements IAsyncEvent<Void>, ICancellable {
    private boolean cancelled = false;
    private String result;

    @Override
    public boolean isCancelled() { return cancelled; }

    @Override
    public void setCancelled(boolean cancelled) { this.cancelled = cancelled; }

    public String getResult() { return result; }
    public void setResult(String result) { this.result = result; }
}
```

## Dispatching Events

### Basic Dispatch

```java
IEventDispatcher<MyEvent, MyEvent> dispatcher =
    HytaleServer.get().getEventBus().dispatchFor(MyEvent.class);

if (dispatcher.hasListener()) {
    MyEvent event = new MyEvent("data");
    dispatcher.dispatch(event);
}
```

### With Key

```java
IEventDispatcher<WorldEvent, WorldEvent> dispatcher =
    HytaleServer.get().getEventBus().dispatchFor(
        WorldEvent.class,
        worldName  // Key
    );

dispatcher.dispatch(new WorldEvent(worldName, value));
```

### Async Dispatch

```java
HytaleServer.get().getEventBus()
    .dispatchForAsync(PlayerChatEvent.class)
    .dispatch(new PlayerChatEvent(sender, targets, message))
    .whenComplete((event, error) -> {
        if (error != null || event.isCancelled()) {
            return;
        }
        sendMessage(event.getTargets(), event.getMessage());
    });
```

## Built-in Events

### Server Lifecycle

| Event | Key Type | Description |
|-------|----------|-------------|
| `BootEvent` | `Void` | Server fully booted |
| `ShutdownEvent` | `Void` | Server shutting down (has priority constants: `DISCONNECT_PLAYERS`, `UNBIND_LISTENERS`, `SHUTDOWN_WORLDS`) |
| `PluginSetupEvent` | `Void` | Plugin setup completed |
| `PrepareUniverseEvent` | `Void` | Universe preparation |

### World Events

| Event | Key Type | Cancellable | Description |
|-------|----------|-------------|-------------|
| `AddWorldEvent` | `String` | Yes | World added to universe |
| `RemoveWorldEvent` | `String` | Yes | World removed (cannot cancel if `RemovalReason.EXCEPTIONAL`) |
| `AllWorldsLoadedEvent` | `Void` | No | All worlds finished loading |
| `StartWorldEvent` | `String` | No | World started |

### Player Events

| Event | Key Type | Async | Cancellable | Description |
|-------|----------|-------|-------------|-------------|
| `PlayerConnectEvent` | `Void` | No | No | Player connecting, can set initial world |
| `PlayerDisconnectEvent` | `Void` | No | No | Player disconnected, provides `DisconnectReason` |
| `PlayerChatEvent` | `String` | Yes | Yes | Player chat message with customizable formatter |
| `PlayerCraftEvent` | `String` | No | No | Player crafting (deprecated) |
| `PlayerSetupConnectEvent` | `Void` | No | Yes | Player setup phase connection |
| `PlayerSetupDisconnectEvent` | `Void` | No | No | Player setup phase disconnection |
| `AddPlayerToWorldEvent` | `String` | No | No | Player added to a world |
| `DrainPlayerFromWorldEvent` | `String` | No | No | Player removed from a world |
| `PlayerReadyEvent` | `String` | No | No | Player ready to play |

### Entity Events

| Event | Key Type | Description |
|-------|----------|-------------|
| `EntityRemoveEvent` | `Void` | Entity removed from world |
| `LivingEntityInventoryChangeEvent` | `String` | Living entity inventory changed |
| `LivingEntityUseBlockEvent` | `String` | Living entity uses a block |

### Block Events (ECS Events)

| Event | Cancellable | Description |
|-------|-------------|-------------|
| `PlaceBlockEvent` | Yes | Block placed, provides `ItemStack`, `Vector3i`, and `RotationTuple` |
| `BreakBlockEvent` | Yes | Block broken, provides `ItemStack`, `Vector3i`, and `BlockType` |
| `DamageBlockEvent` | Yes | Block damaged |
| `UseBlockEvent` | Yes | Block used/interacted with |

### Other ECS Events

| Event | Cancellable | Description |
|-------|-------------|-------------|
| `CraftRecipeEvent` | Yes | Recipe crafted |
| `DropItemEvent` | Yes | Item dropped |
| `InteractivelyPickupItemEvent` | Yes | Item picked up interactively |
| `SwitchActiveSlotEvent` | Yes | Active slot switched |
| `ChangeGameModeEvent` | Yes | Game mode changed |
| `DiscoverZoneEvent` | Yes | Zone discovered |

### Asset Events

| Event | Key Type | Description |
|-------|----------|-------------|
| `LoadedAssetsEvent` | `Void` | Assets loaded, provides asset map and query |
| `RemovedAssetsEvent` | `Void` | Assets removed, indicates if replaced |
| `GenerateAssetsEvent` | `Void` | Asset generation, implements `IProcessedEvent` |

### Permission Events

| Event | Key Type | Description |
|-------|----------|-------------|
| `GroupPermissionChangeEvent` | `Void` | Group permission changed |
| `PlayerPermissionChangeEvent` | `Void` | Player permission changed |
| `PlayerGroupEvent` | `Void` | Player group changed |

## Unregistering Event Handlers

Event registrations can be removed when no longer needed:

```java
EventRegistration<Void, BootEvent> registration =
    getEventRegistry().register(BootEvent.class, this::onBoot);

// Later, unregister when done
registration.close();
```

The `EventRegistry` provided by plugins automatically handles cleanup when the plugin is unloaded.

## Async Event Handlers

For async events, use the `registerAsync` method with a `Function` that transforms the `CompletableFuture`:

```java
getEventRegistry().registerAsync(
    PlayerChatEvent.class,
    future -> future.thenApply(event -> {
        // Modify the event asynchronously
        event.setContent(event.getContent().toUpperCase());
        return event;
    })
);
```

## Unhandled Event Handlers

Register handlers that only fire when no other handler processed the event:

```java
getEventRegistry().registerUnhandled(
    CustomEvent.class,
    event -> {
        // This only fires if no keyed handlers matched
        getLogger().at(Level.INFO).log("Unhandled event: " + event);
    }
);
```

## Best Practices

1. **Use appropriate priority** - Don't always use FIRST/LAST
2. **Check hasListener()** - Avoid creating events when no one listens
3. **Handle async properly** - Don't block in async handlers
4. **Respect cancellation** - Check isCancelled() before actions
5. **Use keyed events** - For scoped/efficient event handling
6. **Clean exception handling** - Exceptions are logged but don't stop other handlers
7. **Use registerGlobal for cross-key listeners** - When you need to handle all instances of a keyed event
8. **Prefer async events for I/O operations** - Avoid blocking the main thread
