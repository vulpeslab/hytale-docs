---
author: UnlimitedBytes
title: Plugin System
description: Learn how to create and structure plugins for the Hytale server.
sidebar:
  order: 2
---

The Hytale server uses a powerful plugin system that allows you to extend server functionality.

## Plugin Structure

### Manifest File

Every plugin requires a `manifest.json` file in the root of your JAR:

```json
{
  "Group": "com.example",
  "Name": "MyPlugin",
  "Version": "1.0.0",
  "Description": "A sample plugin",
  "Main": "com.example.MyPlugin",
  "Authors": [
    {
      "Name": "Your Name",
      "Email": "you@example.com",
      "Url": "https://example.com"
    }
  ],
  "Website": "https://example.com/myplugin",
  "ServerVersion": ">=0.0.1",
  "Dependencies": {
    "Hytale:SomePlugin": ">=1.0.0"
  },
  "OptionalDependencies": {
    "Hytale:OptionalPlugin": "*"
  },
  "LoadBefore": {
    "Hytale:AnotherPlugin": "*"
  },
  "DisabledByDefault": false,
  "IncludesAssetPack": false
}
```

#### Manifest Fields

| Field | Required | Description |
|-------|----------|-------------|
| `Group` | Yes | The plugin's group/namespace (e.g., `com.example`) |
| `Name` | Yes | The plugin name (used with Group to form identifier) |
| `Version` | Yes | Semantic version string (e.g., `1.0.0`) |
| `Description` | No | Short description of the plugin |
| `Main` | Yes | Fully qualified class name of the main plugin class |
| `Authors` | No | Array of author objects with `Name`, `Email`, and `Url` fields (all optional) |
| `Website` | No | Plugin website URL |
| `ServerVersion` | No | Required server version range (e.g., `>=0.1.0`) |
| `Dependencies` | No | Map of required plugin identifiers to version ranges |
| `OptionalDependencies` | No | Map of optional plugin identifiers to version ranges |
| `LoadBefore` | No | Map of plugins that should load after this plugin |
| `DisabledByDefault` | No | If true, plugin won't load unless explicitly enabled |
| `IncludesAssetPack` | No | If true, registers the JAR as an asset pack |
| `SubPlugins` | No | Array of nested plugin manifests (for multi-plugin JARs) |

The plugin identifier is formed as `Group:Name` (e.g., `com.example:MyPlugin`).

### Main Plugin Class

```java
package com.example;

import com.hypixel.hytale.server.core.plugin.JavaPlugin;
import com.hypixel.hytale.server.core.plugin.JavaPluginInit;
import javax.annotation.Nonnull;
import java.util.logging.Level;

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
        getLogger().at(Level.INFO).log("Plugin setup complete!");
    }

    @Override
    protected void start() {
        getLogger().at(Level.INFO).log("Plugin started!");
    }

    @Override
    protected void shutdown() {
        getLogger().at(Level.INFO).log("Plugin shutting down!");
    }
}
```

## Plugin Lifecycle

### Lifecycle Methods

| Method | When Called | Purpose |
|--------|-------------|---------|
| `setup()` | During server initialization | Register components, commands, events |
| `start()` | After all plugins are set up | Start background tasks, initialize state |
| `shutdown()` | When server is stopping | Clean up resources, save data |

### Lifecycle Events

The plugin system fires events at each lifecycle stage:

```java
import com.hypixel.hytale.server.core.event.events.BootEvent;
import java.util.logging.Level;

// In setup()
getEventRegistry().register(BootEvent.class, event -> {
    getLogger().at(Level.INFO).log("Server booted!");
});
```

## Plugin Registries

Each plugin has access to several registries for registering various components:

| Registry | Getter Method | Purpose |
|----------|---------------|---------|
| `CommandRegistry` | `getCommandRegistry()` | Register custom commands |
| `EventRegistry` | `getEventRegistry()` | Register event listeners |
| `TaskRegistry` | `getTaskRegistry()` | Register async tasks |
| `EntityRegistry` | `getEntityRegistry()` | Register custom entities |
| `BlockStateRegistry` | `getBlockStateRegistry()` | Register block states |
| `AssetRegistry` | `getAssetRegistry()` | Register custom assets |
| `ClientFeatureRegistry` | `getClientFeatureRegistry()` | Register client features |
| `EntityStoreRegistry` | `getEntityStoreRegistry()` | Register entity storage components |
| `ChunkStoreRegistry` | `getChunkStoreRegistry()` | Register chunk storage components |

### Example Usage

```java
import com.hypixel.hytale.server.core.event.events.player.PlayerConnectEvent;

@Override
protected void setup() {
    // Commands
    getCommandRegistry().registerCommand(new MyCommand());

    // Events - use PlayerConnectEvent for player connection handling
    getEventRegistry().register(PlayerConnectEvent.class, this::onPlayerConnect);

    // Tasks - register a CompletableFuture<Void> for async operations
    getTaskRegistry().registerTask(myFuture);

    // Logging
    getLogger().at(Level.INFO).log("Setup complete!");
}
```

## Hot Reloading

Plugins can be reloaded at runtime. To support hot reloading:

1. **Clean up in `shutdown()`** - Unregister listeners, stop tasks
2. **Use registries** - Registrations are automatically cleaned up
3. **Avoid static state** - Use the plugin instance pattern

```java
private static MyPlugin instance;

public static MyPlugin get() {
    return instance;
}

@Override
protected void setup() {
    instance = this;
    // Safe: instance is refreshed on reload
}
```

## Building Plugins

### Build Configuration (Gradle)

```groovy
plugins {
    id 'java'
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

dependencies {
    compileOnly files('path/to/HytaleServer.jar')
}

jar {
    from('src/main/resources') {
        include 'manifest.json'
    }
}
```

### Deployment

1. Build your JAR file
2. Place it in the `mods/` directory
3. Restart the server (or use hot reload if supported)

## Plugin Loading Order

Plugins are loaded from multiple locations in this order:
1. **Core plugins** - Built-in server functionality
2. **Builtin directory** - `builtin/` next to the server JAR
3. **Classpath** - Plugins bundled with the server
4. **Mods directory** - `mods/` (user plugins)
5. **Additional directories** - Specified via `--mods-directories` option

Dependencies are resolved to ensure correct loading order within each stage.
