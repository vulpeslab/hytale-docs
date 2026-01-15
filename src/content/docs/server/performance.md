---
author: UnlimitedBytes
title: Performance Tuning
description: Optimize your Hytale server performance with memory and JVM settings.
sidebar:
  order: 5
---

Optimize your Hytale server for better performance with proper memory allocation and JVM tuning.

## Memory Allocation

### Recommended RAM by Player Count

| Players | Recommended RAM |
|---------|-----------------|
| 1-10 | 4GB |
| 10-20 | 6GB |
| 20-50 | 8GB |
| 50+ | 12GB+ |

### Setting Memory Limits

```bash
java -Xms4G -Xmx4G -jar HytaleServer.jar --assets ../HytaleAssets
```

| Flag | Description |
|------|-------------|
| `-Xms` | Initial heap size (minimum memory) |
| `-Xmx` | Maximum heap size (memory cap) |

:::tip
Set `-Xms` and `-Xmx` to the same value to prevent heap resizing during operation, which can cause lag spikes.
:::

### Example Configurations

**Small Server (1-10 players):**
```bash
java -Xms4G -Xmx4G -jar HytaleServer.jar --assets ../HytaleAssets
```

**Medium Server (20-50 players):**
```bash
java -Xms8G -Xmx8G -jar HytaleServer.jar --assets ../HytaleAssets
```

**Large Server (50+ players):**
```bash
java -Xms12G -Xmx12G -jar HytaleServer.jar --assets ../HytaleAssets
```

## JVM Garbage Collection

### G1GC (Recommended)

For better garbage collection performance, use G1GC:

```bash
java -Xms4G -Xmx4G \
  -XX:+UseG1GC \
  -XX:+ParallelRefProcEnabled \
  -XX:MaxGCPauseMillis=200 \
  -jar HytaleServer.jar --assets ../HytaleAssets
```

| Flag | Description |
|------|-------------|
| `-XX:+UseG1GC` | Enable G1 Garbage Collector |
| `-XX:+ParallelRefProcEnabled` | Parallel reference processing |
| `-XX:MaxGCPauseMillis=200` | Target max GC pause time |

### Advanced G1GC Tuning

For high-performance servers:

```bash
java -Xms8G -Xmx8G \
  -XX:+UseG1GC \
  -XX:+ParallelRefProcEnabled \
  -XX:MaxGCPauseMillis=200 \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC \
  -XX:G1NewSizePercent=30 \
  -XX:G1MaxNewSizePercent=40 \
  -XX:G1HeapRegionSize=8M \
  -XX:G1ReservePercent=20 \
  -XX:G1HeapWastePercent=5 \
  -XX:G1MixedGCCountTarget=4 \
  -XX:InitiatingHeapOccupancyPercent=15 \
  -XX:G1MixedGCLiveThresholdPercent=90 \
  -XX:G1RSetUpdatingPauseTimePercent=5 \
  -XX:SurvivorRatio=32 \
  -XX:+PerfDisableSharedMem \
  -XX:MaxTenuringThreshold=1 \
  -jar HytaleServer.jar --assets ../HytaleAssets
```

## View Distance

Adjust maximum view radius in `config.json` to balance performance:

```json
{
  "MaxViewRadius": 32
}
```

| View Radius | Performance Impact | Visual Range |
|-------------|-------------------|--------------|
| 16 | Low | ~256 blocks |
| 24 | Medium | ~384 blocks |
| 32 | High (default) | ~512 blocks |
| 48 | Very High | ~768 blocks |

:::tip
Lower view distances significantly reduce server load. For busy servers, consider starting with 24 chunks.
:::

## Tick Rate

The server runs at 30 TPS (ticks per second) by default. Monitor tick times to identify performance issues:

- **Good:** <33ms per tick (30+ TPS)
- **Acceptable:** 33-50ms per tick (20-30 TPS)
- **Poor:** >50ms per tick (<20 TPS)

## Performance Monitoring

### Key Metrics to Watch

1. **TPS (Ticks Per Second)** - Should stay at 30
2. **Memory Usage** - Should stay below 80% of max
3. **Chunk Load Time** - Affects player experience
4. **Entity Count** - High counts cause lag

### Reducing Server Load

1. **Limit entity spawning** - Reduce mob caps
2. **Reduce view distance** - Lower `MaxViewRadius`
3. **Disable unused worlds** - Less memory overhead
4. **Optimize plugins** - Profile and fix slow plugins
5. **Use SSDs** - Faster chunk loading/saving

## Hardware Recommendations

### CPU
- Modern multi-core processor (4+ cores)
- High single-thread performance preferred
- Intel i7/i9 or AMD Ryzen 7/9 recommended

### RAM
- Minimum: 8GB system RAM (4GB for server)
- Recommended: 16GB+ system RAM
- Fast DDR4/DDR5 memory

### Storage
- SSD strongly recommended
- NVMe preferred for large servers
- Minimum 50GB free space

### Network
- Stable connection required
- 100Mbps+ recommended for public servers
- Low latency to players
