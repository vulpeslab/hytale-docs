---
author: UnlimitedBytes
title: Biome System
description: Understanding and customizing Hytale's biome generation system for server mods.
sidebar:
  order: 1
---

Hytale's biome system controls terrain characteristics, block placement, vegetation, and environmental properties across different regions of the world. This system uses pattern generation and interpolation to create smooth biome transitions.

## Core Classes

### Biome

The abstract base class for all biomes, located in `com.hypixel.hytale.server.worldgen.biome.Biome`:

```java
import com.hypixel.hytale.server.worldgen.biome.Biome;
import com.hypixel.hytale.server.worldgen.biome.BiomeInterpolation;
import com.hypixel.hytale.procedurallib.condition.IHeightThresholdInterpreter;
import com.hypixel.hytale.procedurallib.property.NoiseProperty;

public abstract class Biome {
    // Identity
    public int getId();
    public String getName();
    public int getMapColor();
    
    // Interpolation settings
    public BiomeInterpolation getInterpolation();
    
    // Terrain generation
    public IHeightThresholdInterpreter getHeightmapInterpreter();
    public NoiseProperty getHeightmapNoise();
    
    // Block placement containers
    public CoverContainer getCoverContainer();
    public LayerContainer getLayerContainer();
    public PrefabContainer getPrefabContainer();
    
    // Visual and environment
    public TintContainer getTintContainer();
    public EnvironmentContainer getEnvironmentContainer();
    public WaterContainer getWaterContainer();
    public FadeContainer getFadeContainer();
}
```

**Key Properties:**

- `id` - Unique biome identifier used for lookups and masks
- `name` - Human-readable biome name
- `interpolation` - Controls how this biome blends with neighbors
- `heightmapInterpreter` - Determines terrain height based on noise
- `coverContainer` - Top surface blocks (grass, sand, etc.)
- `layerContainer` - Subsurface layers (dirt, stone, etc.)
- `prefabContainer` - Structure placement (trees, rocks, etc.)
- `mapColor` - Color displayed on maps

### TileBiome

Standard biomes that use tile-based pattern generation:

```java
import com.hypixel.hytale.server.worldgen.biome.TileBiome;

public class TileBiome extends Biome {
    public double getWeight();        // Generation frequency
    public double getSizeModifier();  // Scale of biome patches
}
```

**Usage:**

- `weight` - Higher values make the biome more common (used in weighted selection)
- `sizeModifier` - Affects the scale parameter passed to point generators

### CustomBiome

Specialized biomes with custom generation logic:

```java
import com.hypixel.hytale.server.worldgen.biome.CustomBiome;
import com.hypixel.hytale.server.worldgen.biome.CustomBiomeGenerator;

public class CustomBiome extends Biome {
    public CustomBiomeGenerator getCustomBiomeGenerator();
}

// The generator controls when and where the custom biome appears
public class CustomBiomeGenerator {
    // Check if biome should generate at position
    public boolean shouldGenerateAt(int seed, double x, double z, 
                                   ZoneGeneratorResult zoneResult, 
                                   Biome customBiome);
    
    // Check if parent biome is valid
    public boolean isValidParentBiome(int index);
    
    // Priority for overlapping custom biomes
    public int getPriority();
}
```

**Custom Biome Generation:**

Custom biomes override tile biomes based on:
- **Noise threshold** - `NoiseProperty` and `IDoubleThreshold` determine if noise values match
- **Parent biome mask** - Only generates over specific tile biomes
- **Zone fade** - Respects zone borders using `FadeContainer.getMaskFactor()`
- **Priority** - Higher priority custom biomes take precedence

## Biome Pattern Generation

### BiomePatternGenerator

Generates the biome layout across the world:

```java
import com.hypixel.hytale.server.worldgen.biome.BiomePatternGenerator;
import com.hypixel.hytale.procedurallib.logic.point.IPointGenerator;
import com.hypixel.hytale.common.map.IWeightedMap;

public class BiomePatternGenerator {
    // Get biome at position
    public TileBiome getBiome(int seed, int x, int z);
    
    // Direct biome lookup (no point generation)
    public TileBiome getBiomeDirect(int seed, int x, int z);
    
    // Generate final biome (includes custom biomes)
    public Biome generateBiomeAt(ZoneGeneratorResult zoneResult, 
                                int seed, int x, int z);
    
    // Check for custom biome override
    public CustomBiome getCustomBiomeAt(int seed, double x, double z,
                                       ZoneGeneratorResult zoneResult,
                                       Biome parentResult);
    
    // Get all biomes (tile + custom)
    public Biome[] getBiomes();
    
    // Get only custom biomes
    public CustomBiome[] getCustomBiomes();
    
    // Get interpolation extents
    public int getExtents();
}
```

**Pattern Generation Process:**

1. **Point generation** - `IPointGenerator` determines biome cell centers
2. **Weighted selection** - `IWeightedMap<TileBiome>` selects biome based on weight
3. **Custom override** - Checks if any `CustomBiome` should replace the tile biome
4. **Priority sorting** - When multiple custom biomes match, highest priority wins

### Creating a BiomePatternGenerator

```java
// Define point generator for biome placement
IPointGenerator pointGenerator = /* ... */;

// Create weighted map of tile biomes
IWeightedMap<TileBiome> tileBiomes = /* ... */;
// Add biomes with weights:
// - Higher weight = more common
// - Weights are relative to each other

// Create array of custom biomes
CustomBiome[] customBiomes = new CustomBiome[] {
    // Custom biomes that can override tile biomes
};

BiomePatternGenerator generator = new BiomePatternGenerator(
    pointGenerator,
    tileBiomes,
    customBiomes
);

// Use in world generation
Biome biome = generator.generateBiomeAt(zoneResult, seed, x, z);
```

## Biome Interpolation

### BiomeInterpolation

Controls how biomes blend at their borders:

```java
import com.hypixel.hytale.server.worldgen.biome.BiomeInterpolation;
import it.unimi.dsi.fastutil.ints.Int2IntMap;

public class BiomeInterpolation {
    // Default interpolation (radius 5)
    public static final BiomeInterpolation DEFAULT;
    
    // Create custom interpolation
    public static BiomeInterpolation create(int radius, Int2IntMap biomeRadii2);
    
    // Get interpolation radius
    public int getRadius();
    
    // Get squared radius for specific biome
    public int getBiomeRadius2(int biome);
}
```

**Interpolation Settings:**

- `radius` - Default interpolation distance (default: 5 blocks)
- `biomeRadii2` - Per-biome squared radius overrides (map of biome ID to radius²)
- Interpolation affects block placement, heightmap, and visual properties

**Usage Example:**

```java
import it.unimi.dsi.fastutil.ints.Int2IntOpenHashMap;

// Create custom interpolation
Int2IntOpenHashMap biomeRadii = new Int2IntOpenHashMap();
biomeRadii.put(FOREST_BIOME_ID, 7 * 7);  // Forest: 7 block radius
biomeRadii.put(DESERT_BIOME_ID, 3 * 3);  // Desert: 3 block radius

BiomeInterpolation interpolation = BiomeInterpolation.create(
    5,              // Default radius
    biomeRadii      // Per-biome overrides
);
```

## Biome Containers

Biomes use containers to define their characteristics:

### CoverContainer

Surface blocks (grass, sand, snow, etc.):

```java
// Referenced by biome.getCoverContainer()
// Controls the top layer of blocks
```

### LayerContainer

Subsurface layers (dirt, stone, gravel, etc.):

```java
// Referenced by biome.getLayerContainer()
// Controls underground block layers
```

### PrefabContainer

Structure placement (trees, rocks, plants, etc.):

```java
public PrefabContainer getPrefabContainer();

// Get max prefab size for bounds calculation
public int getMaxSize();
```

The `extents` value in `BiomePatternGenerator` is calculated from the maximum prefab size across all biomes.

### TintContainer

Color tinting for blocks and foliage:

```java
// Referenced by biome.getTintContainer()
// Applies color variations to grass, leaves, water, etc.
```

### EnvironmentContainer

Environmental properties (particles, sounds, sky color):

```java
// Referenced by biome.getEnvironmentContainer()
// Defines ambient effects and atmosphere
```

### WaterContainer

Water-specific properties:

```java
// Referenced by biome.getWaterContainer()
// Controls water color, behavior, and placement
```

### FadeContainer

Zone border fading:

```java
public FadeContainer getFadeContainer();

// Get mask fade parameters
public double getMaskFadeSum();
public double getMaskFactor(ZoneGeneratorResult zoneResult);
```

Used by custom biome generators to fade out near zone borders.

## Custom Biome Implementation

### Creating a Custom Biome

```java
import com.hypixel.hytale.server.worldgen.biome.CustomBiome;
import com.hypixel.hytale.server.worldgen.biome.CustomBiomeGenerator;
import com.hypixel.hytale.procedurallib.property.NoiseProperty;
import com.hypixel.hytale.procedurallib.condition.IDoubleThreshold;
import com.hypixel.hytale.procedurallib.condition.IIntCondition;

// Create noise property for custom biome
NoiseProperty noise = /* noise configuration */;

// Create threshold (e.g., noise > 0.5)
IDoubleThreshold threshold = /* threshold condition */;

// Create biome mask (which parent biomes are valid)
IIntCondition biomeMask = /* parent biome condition */;

// Create the generator
CustomBiomeGenerator generator = new CustomBiomeGenerator(
    noise,       // Noise property
    threshold,   // Noise threshold
    biomeMask,   // Parent biome mask
    10           // Priority (higher = more important)
);

// Create the custom biome
CustomBiome customBiome = new CustomBiome(
    id,                      // Unique ID
    "MyCustomBiome",         // Name
    interpolation,           // Biome interpolation
    generator,               // Custom generator
    heightmapInterpreter,    // Height interpreter
    coverContainer,          // Surface blocks
    layerContainer,          // Subsurface layers
    prefabContainer,         // Structures
    tintContainer,           // Color tints
    environmentContainer,    // Environment effects
    waterContainer,          // Water properties
    fadeContainer,           // Zone fading
    heightmapNoise,          // Heightmap noise
    mapColor                 // Map color
);
```

### Custom Biome Generation Logic

The `shouldGenerateAt` method determines biome placement:

```java
public boolean shouldGenerateAt(int seed, double x, double z,
                               ZoneGeneratorResult zoneResult,
                               Biome customBiome) {
    // 1. Get noise value at position
    double noise = noiseProperty.get(seed, x, z);
    
    // 2. Check if near zone border
    if (zoneResult.getBorderDistance() < customBiome.getFadeContainer().getMaskFadeSum()) {
        // Apply fade factor near borders
        double factor = customBiome.getFadeContainer().getMaskFactor(zoneResult);
        return isThreshold(noise, factor);
    }
    
    // 3. Normal threshold check
    return isThreshold(noise);
}

public boolean isValidParentBiome(int index) {
    // Check if this custom biome can generate over the parent biome
    return biomeMask.eval(index);
}
```

## Integration with Zones

Biomes are associated with zones through the `Zone` record:

```java
import com.hypixel.hytale.server.worldgen.zone.Zone;

// Each zone has its own biome pattern generator
Zone zone = /* ... */;
BiomePatternGenerator biomeGen = zone.biomePatternGenerator();

// Generate biomes in context of zone
ZoneGeneratorResult zoneResult = /* zone lookup */;
Biome biome = biomeGen.generateBiomeAt(zoneResult, seed, x, z);
```

## Best Practices

### Biome Design

1. **Use reasonable weights** - Balance biome frequency (typical range: 0.5 to 2.0)
2. **Set appropriate size modifiers** - Larger biomes need higher values (typical: 0.8 to 1.5)
3. **Design smooth transitions** - Use interpolation radius based on biome characteristics
4. **Test border fading** - Ensure custom biomes fade properly at zone boundaries

### Custom Biome Guidelines

1. **Use specific noise patterns** - Make custom biomes visually distinct
2. **Set appropriate thresholds** - Control rarity (tighter threshold = rarer)
3. **Limit parent biomes** - Restrict to thematically appropriate base biomes
4. **Use priority wisely** - Higher priority for more specific/rare biomes
5. **Consider zone borders** - Implement proper fade container settings

### Performance Considerations

1. **Cache biome lookups** - Biome generation can be expensive
2. **Minimize custom biomes** - Each adds overhead to pattern generation
3. **Optimize noise properties** - Complex noise is costly
4. **Use extents correctly** - Affects chunk generation bounds

### Integration

1. **Coordinate with zones** - Ensure biomes fit the zone theme
2. **Match cave systems** - Some cave types use biome masks
3. **Align with prefabs** - Prefab placement depends on biome
4. **Sync with tinting** - Visual consistency across biome features
