---
author: UnlimitedBytes
title: Command-Line Options
description: Complete reference for Hytale dedicated server command-line flags.
sidebar:
  order: 1
human-verified: false
---

Hytale servers support a rich set of command-line arguments for quick, scriptable configuration. Many of these options can also be set permanently in `config.json`, but the CLI is ideal for automation, debugging, and one-off overrides.

## Overview

You typically start the server like this:

```bash
java -Xms4G -Xmx4G -jar HytaleServer.jar --assets Assets.zip
```

The flags after `HytaleServer.jar` are parsed by the server itself and correspond to the `Options` class (`com.hypixel.hytale.server.core.Options`).

---

## General

| Argument | Description | Default |
|----------|-------------|---------|
| `--help` | Prints usage information and exits. | N/A |
| `--version` | Prints server version information and exits. | N/A |
| `--bare` | Runs the server without loading worlds, binding to ports, or creating directories (plugins may still load). | Disabled |
| `--log <Logger[:Level],...>` | Sets logger level(s), for example `--log root:INFO,server:DEBUG`. | Uses config/defaults |

---

## Networking & Transport

| Argument | Description | Default |
|----------|-------------|---------|
| `-b, --bind <IP:Port>[,...]` | One or more network addresses to listen on (comma-separated). | `0.0.0.0:5520` |
| `-t, --transport <TCP\|QUIC>` | Transport protocol (`QUIC` over UDP or `TCP`). | `QUIC` |
| `--force-network-flush <true\|false>` | Forces flushing of network output after sends. | `true` |

See also: [Performance Tuning](./performance/).

---

## Assets, Prefabs, and World Generation

| Argument | Description | Default |
|----------|-------------|---------|
| `--disable-cpb-build` | Disables building of compact prefab buffers. | N/A |
| `--prefab-cache <Path>` | Directory to use for the immutable prefab cache. | N/A |
| `--assets <Path>` | Path(s) to your `Assets.zip` or assets directory (can be given multiple times). | `../HytaleAssets` |
| `--world-gen <Path>` | Overrides the world generation data directory. | N/A |
| `--validate-assets` | Validates all assets and exits with an error code if any are invalid. | Disabled |
| `--validate-prefabs[=<Options>]` | Validates prefabs; optional comma-separated filters like `PHYSICS,BLOCKS,BLOCK_STATES,ENTITIES,BLOCK_FILLER`. | Disabled |
| `--validate-world-gen` | Validates default world generation and exits with an error code if invalid. | Disabled |
| `--shutdown-after-validate` | Automatically shuts down the server after validation completes. | Disabled |
| `--generate-schema` | Generates schema into the assets directory and then exits. | Disabled |

---

## Mods and Plugins

| Argument | Description | Default |
|----------|-------------|---------|
| `--mods <Path>[,...]` | Additional directories (besides the default `./mods` folder) to load `.jar` or `.zip` mods from. | N/A |
| `--accept-early-plugins` | Acknowledge and allow loading early plugins (unsupported, may be unstable). | Disabled |
| `--early-plugins <Path>[,...]` | Additional directories to load early plugins from (comma-separated). | N/A |

For more about configuring mods, see [Server Settings](./server-config/) and the plugin documentation in the Modding section.

---

## Backups

| Argument | Description | Default |
|----------|-------------|---------|
| `--backup` | Enables automatic background backups. | Disabled |
| `--backup-frequency <Minutes>` | Interval in minutes between automatic backups. | `30` |
| `--backup-dir <Path>` | Directory to store backups (required when `--backup` is set). | N/A |
| `--backup-max-count <Number>` | Maximum number of backup files to keep. | `5` |

See [Backup Configuration](./backups/) for detailed backup strategies and examples.

---

## Universe and Singleplayer

| Argument | Description | Default |
|----------|-------------|---------|
| `--universe <Path>` | Directory containing world and player data (the "universe" folder). | `./universe` |
| `--singleplayer` | Enables singleplayer mode (launcher-style behavior). | Disabled |
| `--owner-name <Name>` | Name of the singleplayer world owner (used with `--singleplayer`). | N/A |
| `--owner-uuid <UUID>` | UUID of the singleplayer world owner (used with `--singleplayer`). | N/A |
| `--client-pid <PID>` | PID of the client process that launched the server. | N/A |

---

## Authentication and Tokens

| Argument | Description | Default |
|----------|-------------|---------|
| `--auth-mode <Mode>` | Connection authentication mode: `AUTHENTICATED`, `OFFLINE`, or `INSECURE`. | `AUTHENTICATED` |
| `--session-token <Token>` | Session token for the Session Service API (alternative to the `HYTALE_SERVER_SESSION_TOKEN` environment variable). | N/A |
| `--identity-token <JWT>` | Identity token (JWT) used for authentication (alternative to the `HYTALE_SERVER_IDENTITY_TOKEN` environment variable). | N/A |

See [Authentication](./authentication/) for mode-specific guidance and security recommendations.

---

## Diagnostics and Debugging

| Argument | Description | Default |
|----------|-------------|---------|
| `--event-debug` | Enables extra debugging for the internal event system. | Disabled |
| `--disable-file-watcher` | Disables automatic asset file watching. | N/A |
| `--disable-sentry` | Disables automated crash/error reporting to Hypixel Studios. | N/A |
| `--disable-asset-compare` | Disables asset comparison checks. | N/A |

---

## Migrations and Boot Commands

| Argument | Description | Default |
|----------|-------------|---------|
| `--migrations <Id=Path,...>` | Runs offline migrations defined by ID-to-path mappings and then exits. | Disabled |
| `--migrate-worlds <Name,...>` | Limits migrations to specific worlds (comma-separated; only valid with `--migrations`). | All worlds |
| `--boot-command <Command,...>` | Runs one or more console commands automatically after the server boots (in order). | None |

For usage examples, see the migrations and automation sections under Universe and Server Management.

---

## Operator Controls

| Argument | Description | Default |
|----------|-------------|---------|
| `--allow-op` | Allows players to use the self-op command to grant/revoke their own OP status on multiplayer servers. | Disabled |

See [Authentication](./authentication/) and the permissions documentation for safe operator setup.

---

## Quick Examples

### Custom Port

To run on a specific port (e.g., 25565):

```bash
java -Xms4G -Xmx4G -jar HytaleServer.jar --assets Assets.zip --bind 0.0.0.0:25565
```

### Validation Only (No Players)

Validate assets and prefabs, then exit:

```bash
java -jar HytaleServer.jar \
  --assets ../HytaleAssets \
  --validate-assets \
  --validate-prefabs \
  --shutdown-after-validate
```

### Singleplayer With Owner Set

```bash
java -jar HytaleServer.jar \
  --assets ../HytaleAssets \
  --singleplayer \
  --owner-name "PlayerName" \
  --owner-uuid 00000000-0000-0000-0000-000000000000
```
