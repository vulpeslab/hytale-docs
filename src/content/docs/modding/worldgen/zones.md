---
title: Zone System
description: Understanding and customizing Hytale's zone system for server mods.
sidebar:
  order: 3
---

Hytale's zone system divides the world into large-scale regions, each with its own biomes, caves, unique structures, and discovery mechanics. Zones provide the top-level organization for world generation.

## Core Classes

### Zone

The main zone record containing all zone configuration:

```java
import com.hypixel.hytale.server.worldgen.zone.Zone;
import com.hypixel.hytale.server.worldgen.zone.ZoneDiscoveryConfig;
import com.hypixel.hytale.server.worldgen.biome.BiomePatternGenerator;
import com.hypixel.hytale.server.worldgen.cave.CaveGenerator;
import com.hypixel.hytale.server.worldgen.container.UniquePrefabContainer;

public record Zone(
    int id,
    String name,
    ZoneDiscoveryConfig discoveryConfig,
    CaveGenerator caveGenerator,
    BiomePatternGenerator biomePatternGenerator,
    UniquePrefabContainer uniquePrefabContainer
) {
    // Record provides these accessor methods automatically:
    public int id();
    public String name();
    public ZoneDiscoveryConfig discoveryConfig();
    public CaveGenerator caveGenerator();
    public BiomePatternGenerator biomePatternGenerator();
    public UniquePrefabContainer uniquePrefabContainer();
}
```

**Zone Components:**

- `id` - Unique zone identifier
- `name` - Human-readable zone name
- `discoveryConfig` - Discovery notification settings
- `caveGenerator` - Cave generation configuration (can be null)
- `biomePatternGenerator` - Biome distribution for this zone
- `uniquePrefabContainer` - Unique structures (dungeons, cities, etc.)

### ZoneDiscoveryConfig

Configuration for zone discovery notifications:

```java
import com.hypixel.hytale.server.worldgen.zone.ZoneDiscoveryConfig;

public record ZoneDiscoveryConfig(
    boolean display,              // Show discovery notification
    String zone,                  // Display name
    String soundEventId,          // Optional: sound to play
    String icon,                  // Optional: icon to display
    boolean major,                // Major zone (affects UI)
    float duration,               // Display duration (seconds)
    float fadeInDuration,         // Fade in time (seconds)
    float fadeOutDuration         // Fade out time (seconds)
) {
    // Default configuration (no display)
    public static final ZoneDiscoveryConfig DEFAULT;
    
    // Create with optional parameters
    public static ZoneDiscoveryConfig of(
        Boolean display,
        String zone,
        String soundEventId,
        String icon,
        Boolean major,
        Float duration,
        Float fadeInDuration,
        Float fadeOutDuration
    );
}
```

**Discovery Settings:**

- `display` - Whether to show notification when entering zone
- `zone` - Name displayed to player
- `soundEventId` - Optional sound effect identifier
- `icon` - Optional icon resource path
- `major` - Indicates major zone (different UI treatment)
- `duration` - Total display time (default: 4.0s)
- `fadeInDuration` - Fade in animation time (default: 1.5s)
- `fadeOutDuration` - Fade out animation time (default: 1.5s)

**Example Configurations:**

```java
// Major zone with notification
ZoneDiscoveryConfig forest = new ZoneDiscoveryConfig(
    true,                        // display
    "Emerald Grove",             // zone name
    "zone.forest.discover",      // sound event
    "icons/zone_forest.png",     // icon
    true,                        // major zone
    5.0f,                        // 5 second duration
    2.0f,                        // 2 second fade in
    2.0f                         // 2 second fade out
);

// Minor zone without notification
ZoneDiscoveryConfig cave = new ZoneDiscoveryConfig(
    false,                       // no display
    "Deep Caverns",              // zone name
    null,                        // no sound
    null,                        // no icon
    false,                       // minor zone
    4.0f,                        // duration (unused)
    1.5f,                        // fade in (unused)
    1.5f                         // fade out (unused)
);

// Using the factory method with defaults
ZoneDiscoveryConfig partial = ZoneDiscoveryConfig.of(
    true,                        // display
    "Ancient Ruins",             // zone name
    null,                        // no sound
    null,                        // no icon
    null,                        // default major (true)
    null,                        // default duration (4.0f)
    null,                        // default fade in (1.5f)
    null                         // default fade out (1.5f)
);
```

## Zone Pattern Generation

### ZonePatternGenerator

Determines which zone exists at any world position:

```java
import com.hypixel.hytale.server.worldgen.zone.ZonePatternGenerator;
import com.hypixel.hytale.server.worldgen.zone.ZoneGeneratorResult;
import com.hypixel.hytale.procedurallib.logic.point.IPointGenerator;

public class ZonePatternGenerator {
    // Generate zone at position
    public ZoneGeneratorResult generate(int seed, double x, double z);
    
    // Generate with reusable result object
    public ZoneGeneratorResult generate(int seed, double x, double z,
                                       ZoneGeneratorResult result);
    
    // Get all zones
    public Zone[] getZones();
    
    // Get unique zones
    public Zone.Unique[] getUniqueZones();
}
```

**Zone Selection Process:**

1. **Mask Lookup:**
   - Transform (x, z) coordinates using `MaskProvider`
   - Sample mask image to get RGB color value
   - Look up zones via `ZoneColorMapping`

2. **Zone Selection:**
   - If single zone for color → use that zone
   - If multiple zones for color → use `IPointGenerator` for selection
   - Calculate distance to zone border

3. **Result:**
   - `ZoneGeneratorResult` contains selected zone and border distance

### ZoneGeneratorResult

Container for zone lookup results:

```java
import com.hypixel.hytale.server.worldgen.zone.ZoneGeneratorResult;

public class ZoneGeneratorResult {
    // Constructors
    public ZoneGeneratorResult();
    public ZoneGeneratorResult(Zone zone, double borderDistance);
    
    // Setters (for reuse)
    public void setZone(Zone zone);
    public void setBorderDistance(double borderDistance);
    
    // Getters
    public Zone getZone();
    public double getBorderDistance();
}
```

**Usage:**

```java
ZonePatternGenerator generator = /* ... */;

// One-time lookup
ZoneGeneratorResult result = generator.generate(seed, x, z);
Zone zone = result.getZone();
double distance = result.getBorderDistance();

// Reusable result (better performance)
ZoneGeneratorResult reusable = new ZoneGeneratorResult();
for (int i = 0; i < many; i++) {
    generator.generate(seed, x, z, reusable);
    Zone zone = reusable.getZone();
    // Process zone...
}
```

**Border Distance:**

- Distance to nearest zone boundary (in blocks)
- Used for zone transition effects
- Important for biome fading near zone edges
- `Double.POSITIVE_INFINITY` if not near a border

### ZoneColorMapping

Maps RGB color values from mask images to zones:

```java
import com.hypixel.hytale.server.worldgen.zone.ZoneColorMapping;

public class ZoneColorMapping {
    // Add single zone for color
    public void add(int rgb, Zone zone);
    
    // Add multiple zones for color (randomly selected)
    public void add(int rgb, Zone[] zones);
    
    // Get zones for color
    public Zone[] get(int rgb);
}
```

**Color Mapping Strategy:**

- Single zone per color → Direct assignment
- Multiple zones per color → Random selection based on point generator
- RGB values are 24-bit integers (0xRRGGBB)
- Alpha channel is ignored (masked to 0xFFFFFF)

**Example:**

```java
ZoneColorMapping mapping = new ZoneColorMapping();

// Single zone assignments
mapping.add(0x00FF00, forestZone);      // Green = forest
mapping.add(0xFFFF00, desertZone);      // Yellow = desert
mapping.add(0x0000FF, oceanZone);       // Blue = ocean

// Multiple zones (randomly selected)
Zone[] mountainVariants = {alpineZone, snowyZone, rockyZone};
mapping.add(0x808080, mountainVariants);  // Gray = random mountain type
```

## Unique Zones

Special zones with guaranteed single instances in the world:

### Zone.Unique

A unique zone with a specific position:

```java
// Located in Zone record
public record Unique(
    Zone zone,
    CompletableFuture<Vector2i> position
) {
    // Wait for position to be determined
    public Vector2i getPosition();
}
```

### Zone.UniqueEntry

Configuration for placing unique zones:

```java
// Located in Zone record
public record UniqueEntry(
    Zone zone,
    int color,        // Parent zone color requirement
    int[] parent,     // Valid parent zone IDs
    int radius,       // Search radius
    int padding       // Minimum distance from edge
) {
    // Check if color is valid parent
    public boolean matchesParent(int color);
}
```

**Unique Zone Placement:**

- Unique zones must be placed within specific parent zones
- `color` - The mask color of the parent zone
- `parent` - Array of valid parent zone IDs
- `radius` - How far to search for suitable location
- `padding` - Minimum distance from parent zone edge
- Position is determined asynchronously

### Zone.UniqueCandidate

Candidate positions for unique zone placement:

```java
// Located in Zone record
public record UniqueCandidate(
    UniqueEntry zone,
    Vector2i[] positions
) {
    public static final UniqueCandidate[] EMPTY_ARRAY;
}
```

## Zone Pattern Provider

### MaskProvider

Provides coordinate transformation and mask lookup:

```java
import com.hypixel.hytale.server.worldgen.chunk.MaskProvider;

// Referenced by ZonePatternGenerator
// Transforms world coordinates to mask coordinates
public double getX(int seed, double x, double z);
public double getY(int seed, double x, double z);

// Get mask value at position
public int get(int seed, double x, double y);

// Bounds checking
public boolean inBounds(double x, double y);
public double distance(double x, double y);
```

**Mask System:**

- Zones are defined by color maps (images)
- World coordinates are transformed before mask lookup
- Allows rotation, scaling, and distortion of zone patterns
- Distance calculation for border effects

## Zone Integration

### With Biomes

Each zone has its own biome pattern:

```java
Zone zone = /* ... */;
BiomePatternGenerator biomeGen = zone.biomePatternGenerator();

// Generate zone-specific biome
ZoneGeneratorResult zoneResult = /* zone lookup */;
Biome biome = biomeGen.generateBiomeAt(zoneResult, seed, x, z);
```

**Biome-Zone Relationship:**

- Each zone defines available biomes
- Biome interpolation respects zone boundaries
- Custom biomes can use zone border distance for fading

### With Caves

Zones can have unique cave configurations:

```java
Zone zone = /* ... */;
CaveGenerator caveGen = zone.caveGenerator();

// May be null if zone has no caves
if (caveGen != null) {
    CaveType[] caveTypes = caveGen.getCaveTypes();
    // Generate caves using zone-specific configuration
}
```

**Cave-Zone Relationship:**

- Not all zones need caves (can be null)
- Cave types can be zone-specific
- Cave biome masks interact with zone biomes

### With Unique Prefabs

Zones can contain unique structures:

```java
Zone zone = /* ... */;
UniquePrefabContainer prefabs = zone.uniquePrefabContainer();

// Zone-specific unique structures
// Dungeons, cities, boss arenas, etc.
```

## Creating Custom Zones

### Basic Zone Creation

```java
import com.hypixel.hytale.server.worldgen.zone.Zone;
import com.hypixel.hytale.server.worldgen.zone.ZoneDiscoveryConfig;

// Create discovery configuration
ZoneDiscoveryConfig discovery = new ZoneDiscoveryConfig(
    true,                           // Show notification
    "Mystic Highlands",             // Display name
    "zone.highlands.discover",      // Sound event
    "icons/highlands.png",          // Icon
    true,                           // Major zone
    5.0f,                           // 5 second duration
    2.0f,                           // 2 second fade in
    1.5f                            // 1.5 second fade out
);

// Create biome pattern generator
BiomePatternGenerator biomes = /* ... */;

// Create cave generator (optional)
CaveGenerator caves = /* ... */;

// Create unique prefab container
UniquePrefabContainer uniquePrefabs = /* ... */;

// Create the zone
Zone customZone = new Zone(
    100,                // Unique ID
    "highlands",        // Internal name
    discovery,          // Discovery config
    caves,              // Cave generator (can be null)
    biomes,             // Biome pattern
    uniquePrefabs       // Unique structures
);
```

### Zone Pattern Generator Setup

```java
import com.hypixel.hytale.server.worldgen.zone.ZonePatternGenerator;
import com.hypixel.hytale.server.worldgen.zone.ZoneColorMapping;

// Create point generator for multi-zone colors
IPointGenerator pointGen = /* ... */;

// Define all zones
Zone[] zones = {zone1, zone2, zone3, /* ... */};

// Define unique zones (optional)
Zone.Unique[] uniqueZones = /* ... */;

// Create mask provider
MaskProvider maskProvider = /* ... */;

// Create color mapping
ZoneColorMapping colorMapping = new ZoneColorMapping();
colorMapping.add(0x00FF00, zone1);          // Green → zone1
colorMapping.add(0xFF0000, zone2);          // Red → zone2
colorMapping.add(0x0000FF, new Zone[]{      // Blue → random choice
    zone3, zone4, zone5
});

// Create pattern generator
ZonePatternGenerator zoneGen = new ZonePatternGenerator(
    pointGen,
    zones,
    uniqueZones,
    maskProvider,
    colorMapping
);
```

### Unique Zone Configuration

```java
import com.hypixel.hytale.server.worldgen.zone.Zone;
import java.util.concurrent.CompletableFuture;
import com.hypixel.hytale.math.vector.Vector2i;

// Create unique entry
Zone.UniqueEntry entry = new Zone.UniqueEntry(
    bossArenaZone,                  // The unique zone
    0x808080,                       // Parent zone color (gray)
    new int[]{MOUNTAIN_ZONE_ID},    // Valid parent zones
    500,                            // Search radius
    100                             // Padding from edge
);

// Position will be calculated asynchronously
CompletableFuture<Vector2i> position = /* async calculation */;

// Create unique zone instance
Zone.Unique unique = new Zone.Unique(
    bossArenaZone,
    position
);

// Later, get the position (blocks until calculated)
Vector2i pos = unique.getPosition();
```

## Zone Transitions and Borders

### Border Distance Usage

The border distance from `ZoneGeneratorResult` is crucial for smooth transitions:

```java
ZoneGeneratorResult result = generator.generate(seed, x, z);
double borderDistance = result.getBorderDistance();

// Use in biome generation
if (borderDistance < customBiome.getFadeContainer().getMaskFadeSum()) {
    double fadeFactor = customBiome.getFadeContainer().getMaskFactor(result);
    // Apply fading near zone boundary
}

// Use in feature placement
if (borderDistance > MIN_DISTANCE_FROM_BORDER) {
    // Place zone-specific feature
}
```

**Transition Strategies:**

1. **Biome Fading:**
   - Custom biomes fade out near zone borders
   - Prevents abrupt biome changes at zone boundaries

2. **Feature Exclusion:**
   - Don't place zone-specific features too close to borders
   - Prevents features from being cut off

3. **Heightmap Blending:**
   - Blend terrain height between zones
   - Smoother terrain transitions

4. **Environment Gradients:**
   - Fade environmental effects (fog, particles, sky color)
   - Gradual atmospheric changes

## Advanced Patterns

### Multi-Zone Colors

When multiple zones share a color, selection is based on point generation:

```java
// Define zones that share a color
Zone[] forestVariants = {
    temperateForest,
    tropicalForest,
    borealForest
};

// Add to color mapping
colorMapping.add(0x00FF00, forestVariants);

// ZonePatternGenerator uses point generator to select:
// 1. Find nearest point for (x, z)
// 2. Hash point coordinates
// 3. Use hash to select from array
// 4. Same point always selects same zone
```

**Benefits:**

- Deterministic zone selection
- Smooth zone boundaries (follows point generator cells)
- Variety within similar terrain types

### Conditional Zone Selection

You can implement custom selection logic:

```java
// Custom zone pattern generator
public class CustomZonePatternGenerator extends ZonePatternGenerator {
    @Override
    protected void getZone(int seed, double x, double z,
                          ZoneGeneratorResult result,
                          Zone[] zoneArr) {
        // Custom selection logic
        // Could use additional noise, distance calculations, etc.
        
        // Example: Select based on distance from origin
        double distanceFromSpawn = Math.sqrt(x * x + z * z);
        int index = (int)(distanceFromSpawn / 1000.0) % zoneArr.length;
        
        result.setZone(zoneArr[index]);
        result.setBorderDistance(/* calculate border distance */);
    }
}
```

### Nested Zones

While not directly supported, you can create sub-zones using custom biomes:

```java
// Use custom biomes to create "zones within zones"
// Parent zone has broad characteristics
// Custom biomes create localized variation

// Example: Desert zone with oasis "sub-zones"
Zone desert = /* desert configuration */;
CustomBiome oasis = /* oasis configuration with noise threshold */;

// Oasis only appears in desert (via parent biome mask)
// Noise determines oasis locations within desert
```

## Best Practices

### Zone Design

1. **Clear boundaries** - Use distinct mask colors
2. **Appropriate scale** - Zones should be large regions (1000s of blocks)
3. **Consistent themes** - Match biomes, caves, and prefabs to zone theme
4. **Discovery feedback** - Use notifications for major zones
5. **Border transitions** - Design for smooth zone edges

### Performance

1. **Limit unique zones** - Expensive position calculations
2. **Optimize mask lookups** - Cache transformed coordinates when possible
3. **Reasonable zone count** - Each zone adds overhead
4. **Efficient color mapping** - Use simple color values
5. **Reuse result objects** - Avoid allocation in hot paths

### Integration

1. **Coordinate with biomes** - Ensure biome patterns fit zone theme
2. **Match cave types** - Zone-appropriate cave configurations
3. **Align environments** - Consistent environment IDs
4. **Test borders** - Verify smooth transitions
5. **Balance discovery** - Don't overwhelm with notifications

### Debugging

1. **Use distinct colors** - Easy to identify zones in mask images
2. **Log zone transitions** - Monitor border distance calculations
3. **Visualize coverage** - Ensure all mask colors are mapped
4. **Test unique placement** - Verify unique zones spawn correctly
5. **Profile generation** - Monitor zone lookup performance

## Common Patterns

### Concentric Zones

Rings of zones radiating from spawn:

```java
// Use radial color gradients in mask image
// Inner rings: safer zones
// Outer rings: dangerous zones
// Border distance naturally follows circles
```

### Continent Zones

Large landmasses with distinct zone colors:

```java
// Paint continents with different colors
// Ocean as separate zone
// Natural islands and coastlines
// Use multi-zone colors for continent variety
```

### Biome-Based Zones

Zones organized by biome similarity:

```java
// Temperate zone: forests, plains, rivers
// Arctic zone: tundra, ice, snow
// Volcanic zone: lava, ash, obsidian
// Each zone has thematically consistent biomes
```

### Progressive Difficulty

Zones arranged by difficulty:

```java
ZoneDiscoveryConfig.of(
    true,
    "Beginner Plains",    // Low difficulty
    null,
    null,
    true,
    null, null, null
);

ZoneDiscoveryConfig.of(
    true,
    "Expert Wastelands",  // High difficulty
    null,
    null,
    true,
    null, null, null
);

// Use mask or distance-based placement
// Difficulty increases with distance from spawn
```
