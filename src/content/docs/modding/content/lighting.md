---
title: Lighting System
description: Chunk lighting manager thread, light storage, propagation rules, and invalidation.
sidebar:
  order: 3
---

> **Scope note:** This page only describes behavior that is visible in the decompiled server code.

The lighting system lives under `com.hypixel.hytale.server.core.universe.world.lighting`.

## High-level architecture

### ChunkLightingManager

`com.hypixel.hytale.server.core.universe.world.lighting.ChunkLightingManager`:

- Belongs to a `World` and is accessible via `world.getChunkLighting()`.
- Spawns a daemon thread named `"ChunkLighting - " + world.getName()`.
- Maintains a queue of `Vector3i` positions (chunkX, chunkY, chunkZ) to (re)light.
- Delegates calculation to a pluggable `LightCalculation` implementation.
  - By default it uses `FloodLightCalculation`.

The manager’s `run()` loop dequeues work and calls `calculateLight(...)`. If the queue stays stable for long enough, it blocks on a `Semaphore` until new work is enqueued.

### CalculationResult

Lighting calculations return `CalculationResult`:

- `NOT_LOADED`
- `DONE`
- `INVALIDATED`
- `WAITING_FOR_NEIGHBOUR`

If a calculation returns `INVALIDATED`, the same chunk position is re-enqueued.

## Where light data is stored

Lighting is stored per **block section** in `BlockSection`:

- `BlockSection.localLight` / `BlockSection.globalLight` are `ChunkLightData`.
- `BlockSection.localChangeCounter` / `globalChangeCounter` are incremented when invalidated.
- `BlockSection.hasLocalLight()` is `localLight.changeId == localChangeCounter`.
- `BlockSection.hasGlobalLight()` is `globalLight.changeId == globalChangeCounter`.

### ChunkLightData format

`com.hypixel.hytale.server.core.universe.world.chunk.section.ChunkLightData` stores 4 channels (4 bits each):

- red (0)
- green (1)
- blue (2)
- sky (3)

It provides helpers like `getSkyLight(index)` and `getBlockLightIntensity(index)`.

Internally the data is stored as an octree-like structure inside a Netty `ByteBuf` (see `getTraverse(...)` and `serializeOctree(...)`).

## FloodLightCalculation (default algorithm)

`com.hypixel.hytale.server.core.universe.world.lighting.FloodLightCalculation` implements `LightCalculation` and performs two phases per section:

1. **Local light**: computed from within the section’s own blocks/fluids.
2. **Global light**: computed by propagating from neighbouring sections’ local light onto this section.

### Local light seeding includes blocks and fluids

When building local light for a section, `floodChunkSection(...)`:

- Sets sky light to `15` for blocks at or above the height map (`originY >= height`), otherwise `0`.
- Seeds RGB light from:
  - `BlockType.getLight()` for the block at that position, and/or
  - `Fluid.getLight()` for the fluid at that position.

If both exist, it combines by taking the per-channel max and keeps the computed sky light.

### Propagation rules (opacity)

The propagation step (`propagateLight(...)`) walks a BitSet queue of lit blocks:

- If the current block’s `BlockType.getOpacity()` is `Opacity.Solid`, it does not propagate from that block.
- Otherwise each step reduces each channel by at least `1`.
- If the opacity is `Opacity.Semitransparent` or `Opacity.Cutout`, it reduces each channel by an extra `1`.

This propagation is applied for RGB and sky channels.

### Global light depends on neighbours having local light

Before computing global light, the algorithm checks neighbouring sections for *local* light availability (`testNeighboursForLocalLight(...)`). If any neighbour is missing local light, it returns `WAITING_FOR_NEIGHBOUR`.

Global light is seeded from neighbour section faces/edges/corners (using `Vector3i.BLOCK_SIDES`, `BLOCK_EDGES`, `BLOCK_CORNERS`) and then propagated through the section.

## Invalidation (when you change the world)

### Invalidate from blocks

The lighting manager exposes:

- `invalidateLightAtBlock(WorldChunk, blockX, blockY, blockZ, BlockType, oldHeight, newHeight)`
- `invalidateLightInChunkSection(WorldChunk, sectionIndex)`
- `invalidateLightInChunkSections(WorldChunk, from, to)`

`FloodLightCalculation.invalidateLightInChunkSections(...)` invalidates a 3×3 chunk area around the target chunk:

- For the *target chunk*, it invalidates **local light** on affected sections.
- For *neighbour chunks*, it invalidates **global light** on affected sections.
- It then enqueues all affected `(chunkX, chunkY, chunkZ)` positions into the lighting queue.

### Invalidate from fluids

The builtin fluid replication system schedules lighting invalidation when fluids change:

- `world.getChunkLighting().invalidateLightInChunkSection(worldChunk, sectionY)`

(See `com.hypixel.hytale.builtin.fluid.FluidSystems.ReplicateChanges`.)

## Practical mod patterns (code-backed)

### Query light levels

If you have a `BlockSection` for a section, you can read:

- local: `blockSection.getLocalLight().getSkyLight(index)` / `getBlockLightIntensity(index)`
- global: `blockSection.getGlobalLight().getSkyLight(index)` / `getBlockLightIntensity(index)`

### Force a relight

After making bulk changes, you can invalidate at chunk/section granularity via `world.getChunkLighting()`.

## Related classes

- `com.hypixel.hytale.server.core.universe.world.lighting.ChunkLightingManager`
- `com.hypixel.hytale.server.core.universe.world.lighting.FloodLightCalculation`
- `com.hypixel.hytale.server.core.universe.world.lighting.LightCalculation`
- `com.hypixel.hytale.server.core.universe.world.chunk.section.ChunkLightData`
- `com.hypixel.hytale.server.core.universe.world.chunk.section.BlockSection`
- `com.hypixel.hytale.server.core.asset.type.blocktype.config.BlockType` (opacity/light)
- `com.hypixel.hytale.server.core.asset.type.fluid.Fluid` (light)
