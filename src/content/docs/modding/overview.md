---
title: Modding Overview
description: Unofficial community guide to creating mods and plugins for Hytale servers.
sidebar:
  order: 1
---

This documentation provides a comprehensive guide to creating mods and plugins for the Hytale dedicated server.

## Documentation Sections

<div class="not-content">
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1rem; margin: 1.5rem 0;">
<a href="/docs/modding/plugins" style="display: block; padding: 1.25rem; border: 1px solid var(--sl-color-gray-5); border-radius: 0.5rem; text-decoration: none;">
<strong style="color: var(--sl-color-white);">🔌 Plugin Development</strong>
<p style="margin: 0.5rem 0 0; font-size: 0.875rem; color: var(--sl-color-gray-2);">Plugin system, events, commands, permissions, and task scheduling.</p>
</a>
<a href="/docs/modding/ecs" style="display: block; padding: 1.25rem; border: 1px solid var(--sl-color-gray-5); border-radius: 0.5rem; text-decoration: none;">
<strong style="color: var(--sl-color-white);">🎯 Entity System (ECS)</strong>
<p style="margin: 0.5rem 0 0; font-size: 0.875rem; color: var(--sl-color-gray-2);">Components, entity stats, physics simulation, and player persistence.</p>
</a>
<a href="/docs/modding/systems" style="display: block; padding: 1.25rem; border: 1px solid var(--sl-color-gray-5); border-radius: 0.5rem; text-decoration: none;">
<strong style="color: var(--sl-color-white);">⚙️ Gameplay Systems</strong>
<p style="margin: 0.5rem 0 0; font-size: 0.875rem; color: var(--sl-color-gray-2);">Damage, movement, mounts, interactions, projectiles, and effects.</p>
</a>
<a href="/docs/modding/npc-ai" style="display: block; padding: 1.25rem; border: 1px solid var(--sl-color-gray-5); border-radius: 0.5rem; text-decoration: none;">
<strong style="color: var(--sl-color-white);">🤖 NPC & AI</strong>
<p style="margin: 0.5rem 0 0; font-size: 0.875rem; color: var(--sl-color-gray-2);">AI behaviors, spawning, flocking, and navigation.</p>
</a>
<a href="/docs/modding/worldgen" style="display: block; padding: 1.25rem; border: 1px solid var(--sl-color-gray-5); border-radius: 0.5rem; text-decoration: none;">
<strong style="color: var(--sl-color-white);">🌍 World Generation</strong>
<p style="margin: 0.5rem 0 0; font-size: 0.875rem; color: var(--sl-color-gray-2);">Zones, biomes, and cave systems.</p>
</a>
<a href="/docs/modding/content" style="display: block; padding: 1.25rem; border: 1px solid var(--sl-color-gray-5); border-radius: 0.5rem; text-decoration: none;">
<strong style="color: var(--sl-color-white);">📦 Content & World</strong>
<p style="margin: 0.5rem 0 0; font-size: 0.875rem; color: var(--sl-color-gray-2);">Assets, inventory, prefabs, fluids, time, and lighting.</p>
</a>
<a href="/docs/modding/networking" style="display: block; padding: 1.25rem; border: 1px solid var(--sl-color-gray-5); border-radius: 0.5rem; text-decoration: none;">
<strong style="color: var(--sl-color-white);">🌐 Networking</strong>
<p style="margin: 0.5rem 0 0; font-size: 0.875rem; color: var(--sl-color-gray-2);">Protocol handling, packet interception, and network utilities.</p>
</a>
<a href="/javadoc/" style="display: block; padding: 1.25rem; border: 1px solid var(--sl-color-gray-5); border-radius: 0.5rem; text-decoration: none;">
<strong style="color: var(--sl-color-white);">📚 JavaDoc API Reference</strong>
<p style="margin: 0.5rem 0 0; font-size: 0.875rem; color: var(--sl-color-gray-2);">Full API documentation for all Hytale server classes, methods, and fields.</p>
</a>
</div>
</div>

## Server Architecture

```
HytaleServer
├── PluginManager      - Plugin loading, lifecycle, and hot-reloading
├── EventBus           - Event dispatch system
├── CommandManager     - Command registration and execution
├── Universe           - World, entity, and player management
├── ServerManager      - Network I/O (QUIC/UDP protocol)
└── AssetModule        - Asset pack loading and management
```

### Plugin Locations

Plugins are loaded from multiple locations in this order:
1. **Core plugins** - Built-in server functionality
2. **Builtin directory** - `builtin/` next to the server JAR
3. **Classpath** - Plugins bundled with the server
4. **Mods directory** - `mods/` (user plugins)
5. **Additional directories** - Specified via `--mods-directories` option

## Key Concepts

### Plugins
Plugins are Java JAR files placed in the `mods/` directory. Each plugin has a `manifest.json` that defines metadata, dependencies, and the main class. See [Plugin Development](/docs/modding/plugins) for details.

### Components (ECS)
Hytale uses an Entity-Component-System architecture. Entities are lightweight references, components store data, and systems process logic. See [Entity System](/docs/modding/ecs) for details.

### Events
The event system allows plugins to react to game occurrences. Events can be synchronous or asynchronous, and support priority ordering. See [Events](/docs/modding/plugins/events) for details.

### Registries
Custom content (components, commands, assets) is registered through type-safe registries that handle lifecycle management. See [Assets & Registry](/docs/modding/content/assets) for details.

## Requirements

- Java 25 or higher (Adoptium/Temurin recommended)
- HytaleServer.jar

## Quick Start

1. Create a new Java project
2. Add HytaleServer.jar to your classpath
3. Create your plugin class extending `JavaPlugin`
4. Create a `manifest.json` file
5. Build your JAR and place it in the `mods/` directory

See [Plugin System](/docs/modding/plugins/plugin-system) for a complete guide.

## Default Server Port

The default server port is **5520** (UDP with QUIC protocol).
