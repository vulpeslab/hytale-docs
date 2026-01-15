---
author: UnlimitedBytes
title: Server Settings
description: Configure main server settings in config.json.
sidebar:
  order: 2
---

The main `config.json` file controls server-wide settings. This configuration is managed by the `HytaleServerConfig` class (`com.hypixel.hytale.server.core.HytaleServerConfig`).

## Configuration File

```json
{
  "ServerName": "Hytale Server",
  "MOTD": "",
  "Password": "",
  "MaxPlayers": 100,
  "MaxViewRadius": 32,
  "LocalCompressionEnabled": false,
  "DisplayTmpTagsInStrings": false,
  "Defaults": {
    "World": "default",
    "GameMode": "Adventure"
  },
  "ConnectionTimeouts": {
    "InitialTimeout": "PT10S",
    "AuthTimeout": "PT30S",
    "PlayTimeout": "PT1M",
    "JoinTimeouts": {}
  },
  "RateLimit": {
    "Enabled": true,
    "PacketsPerSecond": 2000,
    "BurstCapacity": 500
  },
  "Modules": {},
  "LogLevels": {},
  "Mods": {},
  "PlayerStorage": {},
  "AuthCredentialStore": null
}
```

## Server Identity

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `ServerName` | string | `"Hytale Server"` | Display name for your server |
| `MOTD` | string | `""` | Message of the day shown to players |
| `Password` | string | `""` | Server password (empty for no password) |

## Player Limits

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `MaxPlayers` | integer | `100` | Maximum concurrent players |
| `MaxViewRadius` | integer | `32` | Maximum view radius in chunks (constant: `DEFAULT_MAX_VIEW_RADIUS`) |

## Display Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `DisplayTmpTagsInStrings` | boolean | `false` | Enable display of temporary tags in strings |

## Default Settings

The `Defaults` section is handled by the nested `Defaults` class within `HytaleServerConfig`.

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `Defaults.World` | string | `"default"` | Default world players spawn in |
| `Defaults.GameMode` | GameMode | `Adventure` | Default game mode for new players |

### Available Game Modes

The `GameMode` enum (`com.hypixel.hytale.protocol.GameMode`) defines the following values:

| Value | ID | Description |
|-------|-----|-------------|
| `Adventure` | 0 | Adventure mode (default) |
| `Creative` | 1 | Creative mode |

## Network Settings

### Compression

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `LocalCompressionEnabled` | boolean | `false` | Enable compression for local network |

:::note
Compression is typically only beneficial for remote connections. Keep disabled for LAN servers.
:::

### Connection Timeouts

Connection timeouts are handled by the `ConnectionTimeouts` nested class and use ISO-8601 duration format:

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `InitialTimeout` | Duration | `PT10S` | Initial connection timeout (constant: `DEFAULT_INITIAL_TIMEOUT`) |
| `AuthTimeout` | Duration | `PT30S` | Authentication timeout (constant: `DEFAULT_AUTH_TIMEOUT`) |
| `PlayTimeout` | Duration | `PT1M` | Play session timeout (constant: `DEFAULT_PLAY_TIMEOUT`) |
| `JoinTimeouts` | Map\<String, Duration\> | `{}` | Custom per-context join timeouts |

### Rate Limiting

Rate limiting is handled by the `RateLimitConfig` nested class and protects against packet flooding:

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `RateLimit.Enabled` | Boolean | `true` | Enable rate limiting |
| `RateLimit.PacketsPerSecond` | Integer | `2000` | Max packets per second (constant: `DEFAULT_PACKETS_PER_SECOND`) |
| `RateLimit.BurstCapacity` | Integer | `500` | Burst capacity allowance (constant: `DEFAULT_BURST_CAPACITY`) |

:::caution
Disabling rate limiting can expose your server to denial-of-service attacks.
:::

## Modules

The `Modules` section allows configuring server modules. Each module is handled by the `Module` nested class.

```json
{
  "Modules": {
    "ModuleName": {
      "Enabled": true
    }
  }
}
```

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `Enabled` | Boolean | `null` | Enable or disable the module |

Modules can contain nested modules and additional configuration stored as a BSON document.

## Log Levels

The `LogLevels` section allows configuring logging levels for specific loggers.

```json
{
  "LogLevels": {
    "com.hypixel.hytale.server": "INFO",
    "com.hypixel.hytale.server.network": "WARNING"
  }
}
```

Log levels use Java's `java.util.logging.Level` values: `SEVERE`, `WARNING`, `INFO`, `CONFIG`, `FINE`, `FINER`, `FINEST`, `ALL`, `OFF`.

## Mods Configuration

The `Mods` section configures mod/plugin settings. This was previously named `Plugins` in config versions 0-2 and is automatically migrated.

```json
{
  "Mods": {
    "modname:modid": {
      "Enabled": true,
      "RequiredVersion": ">=1.0.0"
    }
  }
}
```

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `Enabled` | Boolean | `null` | Enable or disable the mod |
| `RequiredVersion` | SemverRange | `null` | Required semantic version range |

## Player Storage

The `PlayerStorage` section configures how player data is persisted. This is handled by the `PlayerStorageProvider` interface (`com.hypixel.hytale.server.core.universe.playerdata.PlayerStorageProvider`).

### Available Providers

#### Hytale (Default)

The default provider (`DefaultPlayerStorageProvider`) uses disk storage with the default path.

```json
{
  "PlayerStorage": {
    "Type": "Hytale"
  }
}
```

#### Disk

Custom disk storage provider (`DiskPlayerStorageProvider`) that allows specifying a custom path.

```json
{
  "PlayerStorage": {
    "Type": "Disk",
    "Path": "universe/players"
  }
}
```

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `Type` | string | `"Hytale"` | Storage provider type |
| `Path` | string | `"universe/players"` | Path to player data directory (Disk provider only) |

## Authentication Credential Store

The `AuthCredentialStore` section configures how authentication credentials are stored. This is handled by the `AuthCredentialStoreProvider` interface (`com.hypixel.hytale.server.core.auth.AuthCredentialStoreProvider`).

### Available Providers

#### Memory (Default)

The default provider (`MemoryAuthCredentialStoreProvider`) stores credentials in memory only (not persisted).

```json
{
  "AuthCredentialStore": {
    "Type": "Memory"
  }
}
```

#### Encrypted

The encrypted provider (`EncryptedAuthCredentialStoreProvider`) stores credentials in an encrypted file.

```json
{
  "AuthCredentialStore": {
    "Type": "Encrypted",
    "Path": "auth.enc"
  }
}
```

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `Type` | string | - | Credential store provider type |
| `Path` | string | `"auth.enc"` | Path to encrypted credentials file (Encrypted provider only) |

## ISO-8601 Duration Format

Duration values use the ISO-8601 format:
- `PT10S` = 10 seconds
- `PT30S` = 30 seconds
- `PT1M` = 1 minute
- `PT5M` = 5 minutes
- `PT1H` = 1 hour

## Configuration Version

The configuration file includes a version number for migration purposes. The current version is `3` (constant: `HytaleServerConfig.VERSION`).
