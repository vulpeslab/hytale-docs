---
title: World Generation Systems
description: Learn about Hytale's advanced world generation systems for zones, biomes, and caves.
sidebar:
  order: 1
---

This section covers Hytale's procedural world generation systems that create diverse, engaging environments through zones, biomes, and cave networks.

Go to [Setting Up Live Worldgen Editing](./live) if you want to get your hands dirty right away, editing biome files and playing around with the existing parameters. You'll be able to see the edits you make appear in game, live.

## Overview

Hytale's world generation is organized into three interconnected systems:

- **Zones** - Large-scale regions that define overall world structure
- **Biomes** - Terrain characteristics and environmental properties within zones
- **Caves** - Underground structures and networks generated within zones

These systems work together to create a rich, varied world with smooth transitions and coherent regional themes.

## Architecture

```
World Generation Hierarchy
├── ZonePatternGenerator        - Top-level region assignment
│   ├── Zone[]                  - Zone definitions
│   │   ├── BiomePatternGenerator - Biome distribution per zone
│   │   │   ├── TileBiome[]     - Standard weighted biomes
│   │   │   └── CustomBiome[]   - Conditional override biomes
│   │   ├── CaveGenerator       - Cave system configuration
│   │   │   ├── CaveType[]      - Cave type definitions
│   │   │   └── CaveNodeType[]  - Node templates (chambers, tunnels)
│   │   └── UniquePrefabContainer - Zone-specific structures
│   └── ZoneColorMapping        - Color-to-zone mapping
└── MaskProvider                - Coordinate transformation
```

## Getting Started

1. **[Zone System](./zones)** - Large-scale regions and world organization
2. **[Biome System](./biomes)** - Terrain types, block placement, and interpolation
3. **[Cave Generation](./caves)** - Underground structures and networks

## Quick Example

### Zone Lookup and Generation

```java
import com.hypixel.hytale.server.worldgen.zone.*;
import com.hypixel.hytale.server.worldgen.biome.*;
import com.hypixel.hytale.server.worldgen.cave.*;

// Get zone at position
ZonePatternGenerator zoneGen = /* world generator */;
ZoneGeneratorResult zoneResult = zoneGen.generate(seed, x, z);
Zone zone = zoneResult.getZone();

// Get biome within zone
BiomePatternGenerator biomeGen = zone.biomePatternGenerator();
Biome biome = biomeGen.generateBiomeAt(zoneResult, seed, x, z);

// Check for caves in zone
CaveGenerator caveGen = zone.caveGenerator();
if (caveGen != null) {
    CaveType[] caveTypes = caveGen.getCaveTypes();
    // Generate caves as needed
}
```

### Creating a Custom Zone

```java
// Configure zone discovery
ZoneDiscoveryConfig discovery = new ZoneDiscoveryConfig(
    true,                           // Show notification
    "Mystic Forest",                // Display name
    "zone.forest.discover",         // Sound event
    "icons/forest.png",             // Icon
    true,                           // Major zone
    5.0f, 2.0f, 1.5f               // Duration, fade in, fade out
);

// Create biome pattern
IPointGenerator biomePoints = /* point generator */;
IWeightedMap<TileBiome> tileBiomes = /* biome weights */;
CustomBiome[] customBiomes = /* conditional biomes */;

BiomePatternGenerator biomeGen = new BiomePatternGenerator(
    biomePoints,
    tileBiomes,
    customBiomes
);

// Create cave configuration
CaveType[] caveTypes = /* cave definitions */;
CaveGenerator caveGen = new CaveGenerator(caveTypes);

// Assemble the zone
Zone customZone = new Zone(
    100,                    // Unique ID
    "mystic_forest",        // Internal name
    discovery,              // Discovery config
    caveGen,                // Cave generator
    biomeGen,               // Biome pattern
    uniquePrefabs           // Unique structures
);
```

## Core Concepts

### Zone System

Zones are the highest level of world organization:

- Define large-scale regions (thousands of blocks)
- Each zone has its own biome pattern and cave configuration
- Support unique structures (dungeons, cities, landmarks)
- Provide player discovery notifications
- Use color-mapped patterns for spatial distribution

**Key Features:**
- Multiple zones can share a color (random selection)
- Border distance calculation for smooth transitions
- Unique zones with guaranteed single spawn locations
- Integration with biome and cave systems

### Biome System

Biomes control terrain characteristics within zones:

- **TileBiome** - Standard biomes with weighted distribution
- **CustomBiome** - Conditional biomes that override tile biomes
- **BiomeInterpolation** - Smooth blending at biome borders
- **Containers** - Cover, layers, prefabs, tints, environment, water, fade

**Generation Process:**
1. Point generator determines biome cell locations
2. Weighted selection chooses tile biome
3. Custom biomes check noise thresholds and parent biome masks
4. Highest priority custom biome wins if multiple match

### Cave System

Caves create underground networks:

- **CaveType** - Overall cave configuration (entry, conditions, fluids)
- **CaveNodeType** - Node templates (chambers, passages)
- **CaveNode** - Individual node instances in tree structure
- **Cave Shapes** - Geometry types (ellipsoid, pipe, cylinder, distorted, prefab)

**Generation Process:**
1. Entry point placement via point generator
2. Initial node creation with random orientation
3. Recursive child node generation with depth limit
4. Prefab placement within nodes
5. Compilation and chunk organization

## System Integration

### Zone → Biome

Each zone defines its own biome pattern:

```java
Zone zone = zoneGen.generate(seed, x, z).getZone();
BiomePatternGenerator biomeGen = zone.biomePatternGenerator();
Biome biome = biomeGen.generateBiomeAt(zoneResult, seed, x, z);
```

### Zone → Cave

Cave configuration is per-zone:

```java
Zone zone = /* ... */;
CaveGenerator caveGen = zone.caveGenerator();
if (caveGen != null) {
    // This zone has caves
    CaveType[] types = caveGen.getCaveTypes();
}
```

### Biome ↔ Cave

Caves use biome masks for placement control:

```java
// Cave type with biome restrictions
Int2FlagsCondition biomeMask = caveType.getBiomeMask();
int biomeId = biome.getId();
int flags = biomeMask.eval(biomeId);

// Check if cave can generate in this biome
if (CaveBiomeMaskFlags.canGenerate(flags)) {
    // Generate cave
}
```

### Border Transitions

All systems respect zone boundaries:

```java
ZoneGeneratorResult result = zoneGen.generate(seed, x, z);
double borderDistance = result.getBorderDistance();

// Fade custom biomes near borders
if (borderDistance < customBiome.getFadeContainer().getMaskFadeSum()) {
    double factor = customBiome.getFadeContainer().getMaskFactor(result);
    // Apply fading
}
```

## Best Practices

### Performance

1. **Cache lookups** - Zone and biome generation is expensive
2. **Reuse result objects** - Avoid allocations in hot paths
3. **Limit complexity** - Fewer custom biomes and cave types = faster
4. **Use appropriate chunk bounds** - Minimize unnecessary generation
5. **Profile generation** - Monitor timing for bottlenecks

### Design

1. **Theme consistency** - Match biomes, caves, and prefabs to zone theme
2. **Scale appropriately** - Zones = 1000s of blocks, biomes = 100s of blocks
3. **Smooth transitions** - Use interpolation and fading at boundaries
4. **Balance variety** - Mix common and rare features
5. **Test borders** - Ensure clean transitions between zones

### Integration

1. **Coordinate systems** - Zones define biomes define caves
2. **Use masks properly** - Biome masks control cave and feature placement
3. **Respect environment IDs** - Consistent across zone/biome/cave
4. **Leverage point generators** - Consistent feature spacing
5. **Handle null cases** - Not all zones need caves or unique structures

## Common Patterns

### Concentric World

Zones arranged in rings from spawn:

```java
// Inner zones: beginner-friendly
// Middle zones: standard difficulty
// Outer zones: end-game content
// Use radial distance for zone selection
```

### Continental World

Distinct landmasses with unique characteristics:

```java
// Each continent: different zone
// Ocean: separate zone
// Use color-mapped continents
// Multi-zone colors for variety within continents
```

### Themed Regions

Zones organized by environment type:

```java
// Temperate zone: forests, plains, rivers
// Arctic zone: tundra, ice, snow
// Volcanic zone: lava, ash, obsidian
// Desert zone: sand, cacti, oases
```

### Progressive Difficulty

Difficulty scales with distance:

```java
// Near spawn: safe zones
// Mid-distance: moderate challenge
// Far distance: dangerous zones
// Use border distance for smooth scaling
```

## Next Steps

- Start with the [Zone System](./zones) to understand world structure
- Learn about the [Biome System](./biomes) for terrain characteristics
- Explore [Cave Generation](./caves) for underground structures
- Refer to [World Generation](../content/world-generation) for general concepts
- Set up [Live Worldgen](./live) editing to put your knowledge into practice
