---
author: UnlimitedBytes
title: World Configuration
description: Configure individual world settings in Hytale.
sidebar:
  order: 3
human-verified: false
---

Each world has its own `config.json` file in `universe/worlds/<worldname>/`.

## Configuration File

```json
{
  "UUID": "generated-uuid-here",
  "DisplayName": "My World",
  "Seed": 1234567890,
  "WorldGen": {
    "Type": "Hytale"
  },
  "ChunkStorage": {
    "Type": "Hytale"
  },
  "ChunkConfig": {
    "PregenerateRegion": { "Min": [-512, -512], "Max": [512, 512] },
    "KeepLoadedRegion": { "Min": [-256, -256], "Max": [256, 256] }
  },
  "IsTicking": true,
  "IsBlockTicking": true,
  "IsPvpEnabled": false,
  "IsFallDamageEnabled": true,
  "IsGameTimePaused": false,
  "GameTime": "1970-01-01T05:30:00Z",
  "GameMode": "Adventure",
  "IsSpawningNPC": true,
  "IsSpawnMarkersEnabled": true,
  "IsAllNPCFrozen": false,
  "IsSavingPlayers": true,
  "IsSavingChunks": true,
  "SaveNewChunks": true,
  "IsUnloadingChunks": true,
  "IsCompassUpdating": true,
  "IsObjectiveMarkersEnabled": true,
  "GameplayConfig": "Default"
}
```

## World Identity

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `UUID` | string | auto-generated | Unique identifier for this world |
| `DisplayName` | string | null | Player-facing name of the world |

## World Generation

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `Seed` | long | current time | World generation seed |
| `WorldGen.Type` | string | `"Hytale"` | World generator type |
| `WorldGen.Name` | string | `"Default"` | Name of the generator configuration (Hytale type only) |
| `WorldGen.Path` | string | server default | Path to world generation configuration (Hytale type only) |
| `ChunkStorage.Type` | string | `"Hytale"` | Chunk storage system type |

### World Generator Types

- `Hytale` - The default procedural world generator with configurable Name and Path options
- `Flat` - Generates a flat world with defined layers
  - `Tint` - Color tint for chunks
  - `Layers` - Array of layer definitions with From, To, Environment, and BlockType
- `Void` - Generates empty chunks with no blocks
  - `Tint` - Color tint for chunks
  - `Environment` - Environment to set for columns (defaults to "Default")
- `Dummy` - Places a single layer of unknown blocks (for testing)

### Chunk Storage Types

- `Hytale` - The default recommended storage system (uses IndexedStorage internally)
- `IndexedStorage` - Uses indexed storage file format to store chunks (.region.bin files)
- `Empty` - Discards chunks on save and never loads existing chunks (for temporary worlds)

## Chunk Configuration

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `ChunkConfig.PregenerateRegion` | Box2D | null | Region to pregenerate when world starts |
| `ChunkConfig.KeepLoadedRegion` | Box2D | null | Region of chunks that will never be unloaded |

The region is specified as a Box2D with Min and Max coordinates: `{ "Min": [x1, z1], "Max": [x2, z2] }`

## Gameplay Settings

### Combat & Damage

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `IsPvpEnabled` | boolean | `false` | Allow player vs player combat |
| `IsFallDamageEnabled` | boolean | `true` | Players take fall damage |

### Game Mode

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `GameMode` | string | inherits from server | Default game mode for this world |
| `GameplayConfig` | string | `"Default"` | Gameplay configuration to use |
| `Death` | object | null | Inline death configuration overrides (takes precedence over GameplayConfig) |
| `DaytimeDurationSeconds` | integer | null | Override for daytime duration in seconds |
| `NighttimeDurationSeconds` | integer | null | Override for nighttime duration in seconds |

Available game modes:
- `Adventure` - Standard survival gameplay
- `Creative` - Building mode with unlimited resources

## Time & Weather Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `IsGameTimePaused` | boolean | `false` | Whether game time is paused |
| `GameTime` | ISO-8601 | `"1970-01-01T05:30:00Z"` | Current time of day |
| `ForcedWeather` | string | null | Force a specific weather type to be active |

The `GameTime` setting affects the day/night cycle. Times are specified in ISO-8601 format where the time portion determines the in-game time of day. The default start time is 5:30 AM.

### Client Effects

Visual settings that affect how the world appears to players:

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `ClientEffects.SunHeightPercent` | float | `100.0` | Sun height as a percentage |
| `ClientEffects.SunAngleDegrees` | float | `0.0` | Sun angle in degrees |
| `ClientEffects.BloomIntensity` | float | `0.3` | Bloom post-processing intensity |
| `ClientEffects.BloomPower` | float | `8.0` | Bloom post-processing power |
| `ClientEffects.SunIntensity` | float | `0.25` | Sun light intensity |
| `ClientEffects.SunshaftIntensity` | float | `0.3` | Sunshaft effect intensity |
| `ClientEffects.SunshaftScaleFactor` | float | `4.0` | Sunshaft scale factor |

## Tick Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `IsTicking` | boolean | `true` | Whether chunks in this world tick |
| `IsBlockTicking` | boolean | `true` | Whether blocks in this world tick |

:::tip
Disable ticking for lobby or hub worlds where dynamic block behavior isn't needed. This improves performance.
:::

## Entity & Spawning

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `IsSpawningNPC` | boolean | `true` | Whether NPCs can spawn |
| `IsSpawnMarkersEnabled` | boolean | `true` | Whether spawn markers are enabled |
| `IsAllNPCFrozen` | boolean | `false` | Whether all NPCs are frozen |
| `IsObjectiveMarkersEnabled` | boolean | `true` | Whether objective markers are enabled |
| `IsCompassUpdating` | boolean | `true` | Whether the compass updates in this world |

### Spawn Provider

The `SpawnProvider` setting controls where players spawn in the world. Available types:

**Global** - A single static spawn point for all players:
```json
{
  "SpawnProvider": {
    "Type": "Global",
    "SpawnPoint": { "Position": [0, 100, 0], "Rotation": [0, 0, 0] }
  }
}
```

**Individual** - Selects from a list of spawn points based on player UUID (consistent per player):
```json
{
  "SpawnProvider": {
    "Type": "Individual",
    "SpawnPoints": [
      { "Position": [0, 100, 0], "Rotation": [0, 0, 0] },
      { "Position": [100, 100, 0], "Rotation": [0, 90, 0] }
    ]
  }
}
```

**FitToHeightMap** - Takes a spawn point from another provider and adjusts Y to terrain height:
```json
{
  "SpawnProvider": {
    "Type": "FitToHeightMap",
    "SpawnProvider": {
      "Type": "Global",
      "SpawnPoint": { "Position": [0, -1, 0], "Rotation": [0, 0, 0] }
    }
  }
}
```

## Persistence

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `IsSavingPlayers` | boolean | `true` | Whether player data is saved |
| `IsSavingChunks` | boolean | `true` | Whether chunk data is saved to disk |
| `SaveNewChunks` | boolean | `true` | Whether newly generated chunks are marked for saving |
| `IsUnloadingChunks` | boolean | `true` | Whether chunks can be unloaded |
| `DeleteOnUniverseStart` | boolean | `false` | Delete this world when the universe starts |
| `DeleteOnRemove` | boolean | `false` | Delete this world when removed from server |
| `ResourceStorage` | object | default | Storage system for world resources |

:::caution
Disabling `IsSavingChunks` means all world changes are lost on restart. Only use for temporary worlds.
:::

:::tip
Set `SaveNewChunks` to `false` to prevent random chunks from being saved if worldgen changes, but this will increase regeneration time for those chunks.
:::

## Plugin Configuration

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `RequiredPlugins` | object | empty | Map of plugin identifiers to semver version ranges |
| `Plugin` | object | empty | Plugin-specific configuration data |

Example with required plugins:
```json
{
  "RequiredPlugins": {
    "com.example.myplugin": ">=1.0.0 <2.0.0"
  },
  "Plugin": {
    "MyPlugin": {
      "customSetting": "value"
    }
  }
}
```

## Creating Multiple Worlds

To create additional worlds:

1. Create a new directory: `universe/worlds/<worldname>/`
2. Add a `config.json` with at minimum:
   ```json
   {
     "DisplayName": "My Custom World",
     "Seed": 123456
   }
   ```
3. Restart the server or use the world management commands

The server will generate missing settings with defaults.

## Complete Example

Here is a complete world configuration with all available options:

```json
{
  "UUID": "550e8400-e29b-41d4-a716-446655440000",
  "DisplayName": "Adventure World",
  "Seed": 1234567890,
  "WorldGen": {
    "Type": "Hytale",
    "Name": "Default"
  },
  "ChunkStorage": {
    "Type": "Hytale"
  },
  "ChunkConfig": {
    "PregenerateRegion": { "Min": [-512, -512], "Max": [512, 512] },
    "KeepLoadedRegion": { "Min": [-128, -128], "Max": [128, 128] }
  },
  "SpawnProvider": {
    "Type": "FitToHeightMap",
    "SpawnProvider": {
      "Type": "Global",
      "SpawnPoint": { "Position": [0, -1, 0], "Rotation": [0, 0, 0] }
    }
  },
  "IsTicking": true,
  "IsBlockTicking": true,
  "IsPvpEnabled": false,
  "IsFallDamageEnabled": true,
  "IsGameTimePaused": false,
  "GameTime": "1970-01-01T05:30:00Z",
  "GameMode": "Adventure",
  "GameplayConfig": "Default",
  "IsSpawningNPC": true,
  "IsSpawnMarkersEnabled": true,
  "IsAllNPCFrozen": false,
  "IsObjectiveMarkersEnabled": true,
  "IsCompassUpdating": true,
  "IsSavingPlayers": true,
  "IsSavingChunks": true,
  "SaveNewChunks": true,
  "IsUnloadingChunks": true,
  "ClientEffects": {
    "SunHeightPercent": 100.0,
    "SunAngleDegrees": 0.0,
    "BloomIntensity": 0.3,
    "BloomPower": 8.0,
    "SunIntensity": 0.25,
    "SunshaftIntensity": 0.3,
    "SunshaftScaleFactor": 4.0
  }
}
```
