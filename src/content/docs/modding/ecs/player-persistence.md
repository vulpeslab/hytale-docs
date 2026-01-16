---
author: UnlimitedBytes
title: Player Management & Persistence
description: Manage players, store custom data, and handle player events in your Hytale plugins.
sidebar:
  order: 5
human-verified: false
---

This guide covers the Hytale player management and persistence systems, including how to look up players, store custom player data, and handle player events.

## Architecture Overview

```
Universe
├── PlayerRef (connected players map)
├── PlayerStorage (data persistence)
└── World
    ├── Players (world-specific player map)
    └── EntityStore (ECS for player entities)

Player Data Flow:
PlayerStorage.load() -> Holder<EntityStore> -> World.addPlayer() -> Ref<EntityStore>
```

## PlayerRef - Player Session Handle

`PlayerRef` is the primary handle for accessing a connected player's session. It implements `Component<EntityStore>`, `MetricProvider`, and `IMessageReceiver`:

```java
import com.hypixel.hytale.server.core.universe.PlayerRef;
import com.hypixel.hytale.server.core.universe.Universe;

// Get a player by UUID
PlayerRef player = Universe.get().getPlayer(uuid);

// Access player information
UUID uuid = player.getUuid();
String username = player.getUsername();
String language = player.getLanguage();

// Get the entity reference (if player is in a world)
Ref<EntityStore> entityRef = player.getReference();

// Get the holder (if player is between worlds)
Holder<EntityStore> holder = player.getHolder();

// Additional methods available on PlayerRef
PacketHandler packetHandler = player.getPacketHandler();
ChunkTracker chunkTracker = player.getChunkTracker();
HiddenPlayersManager hiddenPlayers = player.getHiddenPlayersManager();
Transform transform = player.getTransform();
UUID worldUuid = player.getWorldUuid();
```

### Looking Up Players

```java
import com.hypixel.hytale.server.core.NameMatching;
import com.hypixel.hytale.server.core.universe.Universe;

Universe universe = Universe.get();

// By UUID (exact match)
PlayerRef player = universe.getPlayer(uuid);

// By username with matching strategy
PlayerRef playerExact = universe.getPlayerByUsername("PlayerName", NameMatching.EXACT);
PlayerRef playerPartial = universe.getPlayerByUsername("Play", NameMatching.STARTS_WITH);
PlayerRef playerIgnoreCase = universe.getPlayerByUsername("playername", NameMatching.EXACT_IGNORE_CASE);
PlayerRef playerStartsIgnoreCase = universe.getPlayerByUsername("play", NameMatching.STARTS_WITH_IGNORE_CASE);

// Get all connected players
List<PlayerRef> allPlayers = universe.getPlayers();
int playerCount = universe.getPlayerCount();
```

**Available NameMatching strategies:**
- `EXACT` - Exact string match
- `EXACT_IGNORE_CASE` - Exact match ignoring case
- `STARTS_WITH` - Match if username starts with the given value
- `STARTS_WITH_IGNORE_CASE` - Match if username starts with the given value (case insensitive, this is the default)

## Player Entity Component

The `Player` class is an entity component that extends `LivingEntity` and implements `CommandSender`, `PermissionHolder`, and `MetricProvider`:

```java
import com.hypixel.hytale.server.core.entity.entities.Player;
import com.hypixel.hytale.component.Ref;
import com.hypixel.hytale.protocol.GameMode;

// From PlayerRef (when player is in a world)
Ref<EntityStore> ref = playerRef.getReference();
if (ref != null) {
    Store<EntityStore> store = ref.getStore();
    Player player = store.getComponent(ref, Player.getComponentType());

    // Access player-specific data
    GameMode gameMode = player.getGameMode();
    Inventory inventory = player.getInventory();
    int viewRadius = player.getViewRadius();
    int clientViewRadius = player.getClientViewRadius();
    boolean isFirstSpawn = player.isFirstSpawn();
}
```

### Player Managers

```java
// Access various player managers through the Player component
WindowManager windowManager = player.getWindowManager();
PageManager pageManager = player.getPageManager();
HudManager hudManager = player.getHudManager();
HotbarManager hotbarManager = player.getHotbarManager();
WorldMapTracker worldMapTracker = player.getWorldMapTracker();
```

## Storing Custom Player Data

### Using PlayerConfigData

`PlayerConfigData` stores persistent player information across sessions:

```java
import com.hypixel.hytale.server.core.entity.entities.player.data.PlayerConfigData;
import com.hypixel.hytale.server.core.entity.entities.player.data.PlayerWorldData;

Player player = /* get player component */;
PlayerConfigData config = player.getPlayerConfigData();

// Global player data
String currentWorld = config.getWorld();
Set<String> knownRecipes = config.getKnownRecipes();
Set<String> discoveredZones = config.getDiscoveredZones();
Set<UUID> discoveredInstances = config.getDiscoveredInstances();
Object2IntMap<String> reputationData = config.getReputationData();
Set<UUID> activeObjectiveUUIDs = config.getActiveObjectiveUUIDs();
String preset = config.getPreset();

// Per-world player data
PlayerWorldData worldData = config.getPerWorldData("world_name");
Transform lastPosition = worldData.getLastPosition();
boolean isFirstSpawn = worldData.isFirstSpawn();
SavedMovementStates lastMovementStates = worldData.getLastMovementStates();
MapMarker[] worldMapMarkers = worldData.getWorldMapMarkers();
PlayerRespawnPointData[] respawnPoints = worldData.getRespawnPoints();
List<PlayerDeathPositionData> deathPositions = worldData.getDeathPositions();

// Mark data as changed to trigger save
config.markChanged();
```

### Adding Custom Components

For custom persistent data, register your own components:

```java
// Define your custom component
public class MyPlayerData implements Component<EntityStore> {
    public static final BuilderCodec<MyPlayerData> CODEC = BuilderCodec.builder(
        MyPlayerData.class,
        MyPlayerData::new
    )
    .addField(new KeyedCodec<>("customField", Codec.STRING),
        (data, value) -> data.customField = value,
        data -> data.customField)
    .build();

    private String customField;

    public String getCustomField() { return customField; }
    public void setCustomField(String value) {
        this.customField = value;
    }

    @Override
    public Component<EntityStore> clone() {
        MyPlayerData copy = new MyPlayerData();
        copy.customField = this.customField;
        return copy;
    }
}

// Register in your plugin's setup
@Override
protected void setup() {
    ComponentType<EntityStore, MyPlayerData> myDataType =
        getEntityStoreRegistry().registerComponent(
            MyPlayerData.class,
            MyPlayerData::new
        );
}

// Use the component
Holder<EntityStore> holder = playerRef.getHolder();
MyPlayerData data = holder.ensureAndGetComponent(myDataType);
data.setCustomField("value");
```

## Player Events

### Connection Events

```java
import com.hypixel.hytale.server.core.event.events.player.*;

@Override
protected void setup() {
    EventRegistry events = getEventRegistry();

    // Player connecting to server (before entering world)
    // Note: This is NOT a keyed event - use the non-keyed registration
    events.register(PlayerConnectEvent.class, event -> {
        PlayerRef playerRef = event.getPlayerRef();
        Holder<EntityStore> holder = event.getHolder();
        World targetWorld = event.getWorld();

        // Redirect to a different world (can be null)
        event.setWorld(Universe.get().getWorld("lobby"));

        // Access the Player component from the holder (deprecated method)
        Player player = event.getPlayer(); // @Deprecated - use holder.getComponent() instead
    });

    // Player disconnected from server
    // Note: This is NOT a keyed event - use the non-keyed registration
    events.register(PlayerDisconnectEvent.class, event -> {
        PlayerRef playerRef = event.getPlayerRef();
        PacketHandler.DisconnectReason reason = event.getDisconnectReason();
        getLogger().at(Level.INFO).log(playerRef.getUsername() + " disconnected: " + reason);
    });
}
```

### World Events

```java
// Player added to a world (keyed by world name - implements IEvent<String>)
events.register(AddPlayerToWorldEvent.class, "world_name", event -> {
    Holder<EntityStore> holder = event.getHolder();
    World world = event.getWorld();

    // Suppress join message broadcast
    event.setBroadcastJoinMessage(false);

    // Check current setting
    boolean willBroadcast = event.shouldBroadcastJoinMessage();
});

// Player removed/drained from a world (keyed by world name - implements IEvent<String>)
events.register(DrainPlayerFromWorldEvent.class, "world_name", event -> {
    Holder<EntityStore> holder = event.getHolder();
    World world = event.getWorld();
    Transform transform = event.getTransform();

    // Redirect to a different world
    event.setWorld(Universe.get().getWorld("hub"));
    event.setTransform(new Transform(0, 64, 0));
});

// Player ready to receive gameplay (keyed by world name - extends PlayerEvent<String>)
events.register(PlayerReadyEvent.class, "world_name", event -> {
    Player player = event.getPlayer();
    Ref<EntityStore> ref = event.getPlayerRef();
    int readyId = event.getReadyId(); // Increments each time the player becomes ready

    // Safe to send initial game state now
});
```

## Player Transfer Between Worlds

### Moving Players Between Worlds

```java
import com.hypixel.hytale.server.core.universe.Universe;
import com.hypixel.hytale.server.core.universe.world.World;
import com.hypixel.hytale.math.vector.Transform;

World targetWorld = Universe.get().getWorld("adventure");
Transform spawnPoint = new Transform(100, 64, 200);

// Add player to new world (returns CompletableFuture<PlayerRef>)
targetWorld.addPlayer(playerRef, spawnPoint)
    .thenAccept(resultPlayerRef -> {
        getLogger().at(Level.INFO).log("Player transferred to " + targetWorld.getName());
    })
    .exceptionally(error -> {
        getLogger().at(Level.SEVERE).log("Transfer failed: " + error.getMessage());
        return null;
    });

// Alternative overloads available:
// addPlayer(PlayerRef playerRef) - uses spawn provider for position
// addPlayer(PlayerRef playerRef, Transform transform) - with explicit position
// addPlayer(PlayerRef playerRef, Transform transform, Boolean clearWorldOverride, Boolean fadeInOutOverride)
```

### Server Referral

Transfer players to another server:

```java
// Refer player to another server
playerRef.referToServer("other.server.com", 25565);

// With custom data payload (max 4096 bytes)
byte[] transferData = /* custom data */;
playerRef.referToServer("other.server.com", 25565, transferData);
```

## Best Practices

1. **Use PlayerRef for session data** - Keep runtime state in PlayerRef, persistent state in PlayerConfigData
2. **Check entity reference validity** - Always verify `playerRef.getReference() != null` before accessing entity state; `playerRef.isValid()` checks both reference and holder
3. **Handle async operations** - Player storage and world transfer operations are async; use CompletableFuture properly
4. **Mark data as changed** - Call `markChanged()` on PlayerConfigData when modifying persistent fields (setter methods already call this)
5. **Use world-keyed events** - Register for specific worlds (AddPlayerToWorldEvent, DrainPlayerFromWorldEvent, PlayerReadyEvent) when possible for better performance
6. **Clean up on disconnect** - Remove temporary data in PlayerDisconnectEvent handlers (not world-keyed)
7. **Respect player state** - Check if player is in a world (getReference() returns Ref) vs between worlds (getHolder() returns Holder)
8. **Handle transfer failures** - World transfers can fail; always handle exceptions in CompletableFuture chains
9. **Use correct event registration** - PlayerConnectEvent and PlayerDisconnectEvent are NOT keyed events; world events (AddPlayerToWorld, DrainPlayerFromWorld, PlayerReady) ARE keyed by world name
10. **Deprecated API awareness** - `PlayerRef.getComponent()` is deprecated; use holder/store component access instead
