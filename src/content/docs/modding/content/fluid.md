---
author: UnlimitedBytes
title: Fluid System
description: Fluid states, storage in chunks, ticking/flow, FX, and replication to clients.
sidebar:
  order: 1
human-verified: false
---

> **Scope note:** This page only describes behavior that is visible in the decompiled server code.

## Where fluids live

Fluids are stored per **chunk section** in the `FluidSection` component:

- `com.hypixel.hytale.server.core.universe.world.chunk.section.FluidSection`
  - Stores a per-block **fluid id** using an `ISectionPalette` (`typePalette`).
  - Stores a per-block **fluid level** as a packed nibble array `levelData` (size `16384`, two 4-bit levels per byte).
  - Uses a `StampedLock` for concurrent access.
  - Tracks changed block indices in `changedPositions` for replication.

### Fluid id vs. level

`FluidSection.setFluid(int index, int fluidId, byte level)` applies these rules:

- `level` is masked to 4 bits: `level & 0xF`.
- If `level == 0`, the fluid id is forced to `0`.
- If `fluidId == 0`, the level is forced to `0`.

This means the “empty” state is always `(fluidId=0, level=0)`.

## Builtin fluid plugin and systems

The builtin plugin `com.hypixel.hytale.builtin.fluid.FluidPlugin` wires the system together by registering:

- `FluidSystems.EnsureFluidSection` — adds a `FluidSection` to section entities missing it.
- `FluidSystems.MigrateFromColumn` — migrates legacy per-section fluid data from `BlockSection.takeMigratedFluid()`.
- `FluidSystems.SetupSection` — calls `fluidSection.load(x, y, z)` when the section entity is added.
- `FluidSystems.LoadPacketGenerator` — contributes per-section fluid packets to the “chunk load” packet batch.
- `FluidSystems.ReplicateChanges` — sends incremental (or full) updates to players.
- `FluidSystems.Ticking` — runs fluid tick logic on blocks that are marked ticking.

## Ticking and flow

### What drives fluid ticking

`FluidSystems.Ticking` runs on chunk-store section entities that have `FluidSection` and `ChunkSection`.

It:

1. Resolves the owning `BlockChunk` from the section’s chunk-column reference.
2. Gets the matching `BlockSection` at `fluidSection.getY()`.
3. Early-outs if there are no ticking blocks (`blockSection.getTickingBlocksCountCopy() == 0`).
4. Iterates `blockSection.forEachTicking(...)` and, per ticking block:
   - Reads `fluidId = fluidSection.getFluidId(x, y, z)`.
   - If `fluidId == 0`, returns `BlockTickStrategy.IGNORED`.
   - Looks up the fluid type: `Fluid.getAssetMap().getAsset(fluidId)`.
   - Calls `fluid.getTicker().tick(...)`.

So: fluid simulation is *tied to the block ticking bitset* in `BlockSection`.

### FluidTicker basics

`com.hypixel.hytale.server.core.asset.type.fluid.FluidTicker` is the abstract base for per-fluid behavior.

Key pieces:

- `FlowRate` (seconds): controls how often `tick(...)` runs (it converts to ticks using `world.getTps()`).
- `CanDemote`: if true, a fluid may “demote” (reduce level / disappear) when unsupported.
- `SupportedBy`: a fluid id key that is treated as “self/support” in `isSelfFluid(...)`.

`FluidTicker.process(...)` contains shared logic:

- If the current block is “fully solid” (`isFullySolid(BlockType)`), the fluid is cleared.
- It evaluates `isAlive(...)` and either:
  - spreads (calls the fluid-specific `spread(...)`),
  - demotes (decrements level / clears),
  - or waits for adjacent chunk load.

The shape-based blocking tests (`blocksFluidFrom(...)`) use block hitbox data via `BlockBoundingBoxes`.

## Replication (network updates)

`FluidSystems.ReplicateChanges` sends updates based on `fluidSection.getAndClearChangedPositions()`:

- **1 change**: sends `ServerSetFluid(x, y, z, fluidId, level)`.
- **2..1023 changes**: sends `ServerSetFluids(sectionX, sectionY, sectionZ, SetFluidCmd[])` with indices and values.
- **>= 1024 changes**: sends a cached full-section packet from `fluidSection.getCachedPacket()` (built from `SetFluids`).

Updates are only sent to players whose `ChunkTracker` reports the chunk as loaded.

### Lighting invalidation on fluid changes

On any non-empty change set, `ReplicateChanges` also schedules:

- `world.getChunkLighting().invalidateLightInChunkSection(worldChunk, sectionY)`

This means fluid edits can force lighting recomputation for the affected section.

## Fluid assets and fluid FX

### Fluid asset

`com.hypixel.hytale.server.core.asset.type.fluid.Fluid` is the asset that defines a fluid type.

Fields surfaced by the asset codec include (non-exhaustive):

- `MaxFluidLevel` (default `8`)
- `Textures` (array of `BlockTypeTextures`)
- `Effect` (array of `ShaderType`)
- `Opacity` / `RequiresAlphaBlending`
- `FluidFXId` → resolved to `fluidFXIndex` via `FluidFX.getAssetMap().getIndex(...)`
- `Ticker` (`FluidTicker`)
- `Light` (`ColorLight`) — used by lighting when seeding local light
- `DamageToEntities`
- `BlockParticleSetId`, `ParticleColor`, `BlockSoundSetId`
- `Interactions` (map keyed by `InteractionType`)

### FluidFX asset

`com.hypixel.hytale.server.core.asset.type.fluidfx.config.FluidFX` is a separate asset referenced by `Fluid.FluidFXId`.

It serializes to a protocol `FluidFX` packet including:

- fog mode/color/distance
- saturation & color filter
- distortion amplitude/frequency
- optional `FluidParticle`
- optional `FluidFXMovementSettings`

`FluidParticle` itself contains:

- `SystemId` (particle system id)
- `Color` (default color override)
- `Scale` (defaults to `1.0`)

### Asset replication (types + FX)

In addition to per-block fluid state replication, fluid-related *assets* are also synchronized to clients via dedicated asset packets:

- `FluidTypePacketGenerator` → `UpdateFluids` (Init / AddOrUpdate / Remove)
- `FluidFXPacketGenerator` → `UpdateFluidFX` (Init / AddOrUpdate / Remove)

Both packet types include a `maxId` taken from the indexed lookup table’s `getNextIndex()`.

## Practical mod patterns (code-backed)

### Setting a fluid in the world

The builtin `fluid set` command demonstrates the minimal pattern:

- Resolve the chunk section reference asynchronously: `world.getChunkStore().getChunkSectionReferenceAsync(cx, cy, cz)`.
- Get `FluidSection` from the section store.
- Call `fluidSection.setFluid(index, fluid, level)`.
- Mark the owning `WorldChunk` dirty (`worldChunk.markNeedsSaving()`).
- Ensure simulation runs by setting ticking (`worldChunk.setTicking(x, y, z, true)`).

See `com.hypixel.hytale.builtin.fluid.FluidCommand.SetCommand`.

## Related classes

- `com.hypixel.hytale.builtin.fluid.FluidState` (pre-generated level/fill states)
- `com.hypixel.hytale.server.core.universe.world.chunk.section.FluidSection`
- `com.hypixel.hytale.server.core.asset.type.fluid.Fluid`
- `com.hypixel.hytale.server.core.asset.type.fluid.FluidTicker`
- `com.hypixel.hytale.builtin.fluid.FluidSystems`
- Packets: `SetFluids`, `ServerSetFluid`, `ServerSetFluids`, `SetFluidCmd`
