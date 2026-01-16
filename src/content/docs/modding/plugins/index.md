---
author: UnlimitedBytes
title: Plugin Development
description: Learn the fundamentals of creating plugins for the Hytale server.
sidebar:
  order: 1
verified: false
human-verified: false
---

This section covers everything you need to know about creating plugins for the Hytale dedicated server.

## What is a Plugin?

Plugins are Java JAR files that extend the Hytale server's functionality. They allow you to:

- Add custom game mechanics
- Create new commands
- Subscribe to game events
- Implement custom permissions
- Schedule and manage tasks

## Getting Started

1. **[Plugin System](./plugin-system)** - Learn about plugin structure, manifest files, and lifecycle hooks
2. **[Event System](./events)** - Subscribe to and create custom events
3. **[Command System](./commands)** - Create custom server commands
4. **[Permissions](./permissions)** - Implement permission-based access control
5. **[Task Scheduling](./tasks)** - Schedule and manage asynchronous tasks

## Plugin Architecture

```
Plugin JAR
├── manifest.json          - Plugin metadata and dependencies
├── com/example/MyPlugin   - Main plugin class
└── resources/             - Assets and configuration
```

## Quick Start

```java
package com.example;

import com.hypixel.hytale.server.core.plugin.JavaPlugin;
import com.hypixel.hytale.server.core.plugin.JavaPluginInit;

import java.util.logging.Level;

public class MyPlugin extends JavaPlugin {

    public MyPlugin(JavaPluginInit init) {
        super(init);
    }

    @Override
    protected void setup() {
        getLogger().at(Level.INFO).log("Plugin setup!");
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

| Method | Description |
|--------|-------------|
| `setup()` | Called during server initialization. Register components, commands, and events here. |
| `start()` | Called after all plugins are set up. Start background tasks here. |
| `shutdown()` | Called when the server is stopping. Clean up resources here. |

## Next Steps

- Read the [Plugin System](./plugin-system) guide for detailed documentation
- Learn about the [Event System](./events) for reacting to game occurrences
- Create your first [Custom Command](./commands)
