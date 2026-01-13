---
title: Time System
description: World game time, day/night cycle mapping, moon phases, and time packets.
sidebar:
  order: 2
---

> **Scope note:** This page only describes behavior that is visible in the decompiled server code.

The time system is implemented as a core plugin module under `com.hypixel.hytale.server.core.modules.time`.

## Module wiring

`com.hypixel.hytale.server.core.modules.time.TimeModule` registers two resources on the `EntityStore`:

- `WorldTimeResource` (world “game time” and day/night/moon data)
- `TimeResource` (an `Instant now` updated by tick delta)

And installs systems:

- `WorldTimeSystems.Init` / `WorldTimeSystems.Ticking`
- `TimeSystem`
- `TimePacketSystem`
- Plus the `time` command (`TimeCommand`).

## WorldTimeResource (world game time)

`com.hypixel.hytale.server.core.modules.time.WorldTimeResource` is the primary world-time model.

### Stored state

- `Instant gameTime`
- `LocalDateTime _gameTimeLocalDateTime` (UTC)
- `int currentHour`
- `double sunlightFactor`
- `double scaledTime`
- `int moonPhase`
- Cached packets:
  - `UpdateTime currentTimePacket`
  - `UpdateTimeSettings currentSettings` / `tempSettings`

### Day/night mapping is configurable

The resource maps real tick delta (`dt`) into game time using per-world durations:

- `World.getDaytimeDurationSeconds()`
- `World.getNighttimeDurationSeconds()`

Internally it treats a “solar day” as:

- `DAYTIME_PORTION_PERCENTAGE = 0.6`
- `DAYTIME_SECONDS = SECONDS_PER_DAY * 0.6`
- `NIGHTTIME_SECONDS = SECONDS_PER_DAY * 0.4`

The algorithm computes how far to advance `gameTime` based on whether the current second-of-day is inside the daytime window (starting at `SUNRISE_SECONDS = NIGHTTIME_SECONDS / 2`) and applies a day-rate vs night-rate.

### Pausing

If `world.getWorldConfig().isGameTimePaused()` is true:

- `WorldTimeResource.tick(...)` returns early (no advancement)
- `TimePacketSystem` also returns early (no periodic broadcast)

### Moon phases

Moon phase depends on:

- `world.getGameplayConfig().getWorldConfig().getTotalMoonPhases()`
- `currentDay = _gameTimeLocalDateTime.getDayOfYear()`
- `currentHour` (day progress)

When the phase changes, `setMoonPhase(...)` invokes `MoonPhaseChangeEvent` through the store’s `ComponentAccessor`.

### Packets

`WorldTimeResource` produces two packet types:

- `UpdateTime`: contains `InstantData` with seconds + nanos.
- `UpdateTimeSettings`: contains daytime/nighttime durations, total moon phases, and pause state.

`sendTimePackets(PlayerRef)` sends *both* settings and current time to a player.

## TimePacketSystem (periodic broadcast)

`com.hypixel.hytale.server.core.modules.time.TimePacketSystem` extends `DelayedSystem<EntityStore>` with a fixed interval:

- `BROADCAST_INTERVAL = 1.0f`

Every interval, if time is not paused, it calls:

- `worldTimeResource.broadcastTimePacket(store)`

## TimeResource (“Now”)

`com.hypixel.hytale.server.core.modules.time.TimeResource` stores:

- `Instant now`
- `float timeDilationModifier` (default `1.0f`)

`TimeSystem.tick(dt, ...)` adds `dt` to `now` as nanoseconds.

### Time dilation

`World.setTimeDilation(float, ComponentAccessor<EntityStore>)`:

- Validates the range (`<= 0.01` or `> 4.0` throws).
- Updates `TimeResource.timeDilationModifier`.
- Broadcasts a `SetTimeDilation` packet to all players in the world.

(Usage of the dilation modifier in other systems is not covered here; this page only documents what is directly visible in the time module and `World`.)

## Commands

`com.hypixel.hytale.server.core.modules.time.commands.TimeCommand` provides:

- `time` (alias: `daytime`) info output (includes moon phase)
- `time set <hours>` where `hours` is validated to `[0, WorldTimeResource.HOURS_PER_DAY]`
- Period shortcuts: `Dawn`, `Midday`, `Dusk`, `Midnight` (also aliases like `day`, `morning`, `noon`, `night`)
- `time pause` (alias `stop`) delegates to `WorldConfigPauseTimeCommand.pauseTime(...)`
- `time dilation <float>` delegates to `World.setTimeDilation(...)`

## Practical mod patterns (code-backed)

### Read world time in a system/command

The core time command uses:

```java
WorldTimeResource wtr = store.getResource(WorldTimeResource.getResourceType());
Instant t = wtr.getGameTime();
```

### Set day time

`WorldTimeResource.setDayTime(double dayTime, World world, Store<EntityStore> store)` expects `dayTime` in `[0, 1]` and will broadcast the time update.

## Related classes

- `com.hypixel.hytale.server.core.modules.time.TimeModule`
- `com.hypixel.hytale.server.core.modules.time.WorldTimeResource`
- `com.hypixel.hytale.server.core.modules.time.TimeResource`
- `com.hypixel.hytale.server.core.modules.time.TimeSystem`
- `com.hypixel.hytale.server.core.modules.time.TimePacketSystem`
- `com.hypixel.hytale.server.core.modules.time.commands.TimeCommand`
- Packets: `UpdateTime`, `UpdateTimeSettings`, `SetTimeDilation`
