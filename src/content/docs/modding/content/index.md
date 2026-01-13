---
title: Content & World
description: Learn about creating custom content, assets, and world generation for Hytale.
sidebar:
  order: 1
---

This section covers content creation and world building features in Hytale, including assets, items, prefabs, and world generation.

## Overview

Hytale's content system allows you to:

- Register and manage custom assets
- Create items and inventory systems
- Build and place prefab structures
- Customize world generation

## Getting Started

1. **[Assets & Registry](./assets)** - Register custom content and manage assets
2. **[Inventory & Items](./inventory)** - Player inventories and item management
3. **[Prefab System](./prefabs)** - Create and place structures
4. **[Terrain Generation](./world-generation)** - Customize terrain generation
5. **[Fluid System](./fluid)** - Fluid storage, ticking/flow, and replication
6. **[Time System](./time)** - Day/night cycle, moon phases, and time packets
7. **[Lighting System](./lighting)** - Chunk lighting, propagation, and invalidation

## Architecture

```
AssetRegistry (com.hypixel.hytale.assetstore.AssetRegistry)
├── AssetStore<K, T, M>[]     - Type-specific stores (K=key, T=asset, M=map)
│   ├── AssetCodec<K, T>      - Serialization/deserialization
│   ├── AssetMap<K, T>        - Storage and lookup
│   └── AssetPack             - Content pack container
└── TagPattern                 - Asset tag matching

World Generation (com.hypixel.hytale.server.worldgen)
├── IWorldGen                  - Generator interface
├── ChunkGenerator             - Terrain generation
├── CavePopulator              - Underground cave generation
├── CaveNodeType               - Cave configuration
└── PrefabStore                - Structure placement
```

## Quick Example

### Registering an Asset

```java
// In your plugin's setup method, use the provided AssetRegistry
@Override
protected void setup(AssetRegistry registry) {
    // For String-keyed assets (most common case)
    registry.register(
        HytaleAssetStore.builder(MyAsset.class, new IndexedLookupTableAssetMap<>(MyAsset[]::new))
            .setPath("MyAssets")
            .setCodec(MyAsset.CODEC)
            .setKeyFunction(MyAsset::getId)
            .build()
    );

    // For custom key types, use the 3-parameter builder
    // HytaleAssetStore.builder(KeyClass.class, AssetClass.class, assetMap)
}
```

### Placing a Prefab

```java
PrefabStore store = PrefabStore.get();
BlockSelection prefab = store.getServerPrefab("structures/house.prefab.json");

// Place at position - requires a CommandSender for feedback
// place(CommandSender feedback, World world, Vector3i position, BlockMask mask)
prefab.place(commandSender, world, new Vector3i(100, 64, 100), null);

// Alternative: place without returning replaced blocks
prefab.placeNoReturn(null, null, world, componentAccessor);
```

## Content Types

| Type | Description |
|------|-------------|
| Assets | Registered game content (items, blocks, entities) |
| Items | Holdable objects with behaviors |
| Prefabs | Pre-built structures and decorations |
| World Generators | Terrain and biome generation logic |

## Next Steps

- Read the [Assets & Registry](./assets) guide for content registration
- Learn about the [Inventory System](./inventory) for item management
- Explore [Prefabs](./prefabs) for structure placement
- Customize terrain with [World Generation](./world-generation)
