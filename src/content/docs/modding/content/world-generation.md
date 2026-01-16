---
author: UnlimitedBytes
title: World Generation
description: Understanding and customizing Hytale's procedural world generation system.
sidebar:
  order: 5
---

Hytale features a sophisticated procedural world generation system for terrain, biomes, caves, and structures.

## Architecture

| Layer | Purpose |
|-------|---------|
| `IWorldGen` / `IWorldGenProvider` | Core interfaces |
| `ChunkGenerator` | Main terrain generation |
| `NStagedChunkGenerator` | Staged pipeline |
| Zone System | Large-scale regions |
| Biome System | Terrain characteristics |
| Cave System | Underground structures |
| Prefab System | Structure placement |

## Core Interfaces

### IWorldGen

The fundamental interface for world generators:

```java
import com.hypixel.hytale.server.core.universe.world.worldgen.IWorldGen;

public interface IWorldGen {
    // Timing statistics
    WorldGenTimingsCollector getTimings();

    // Generate chunk asynchronously
    CompletableFuture<GeneratedChunk> generate(
        int seed, long index, int x, int z,
        LongPredicate stillNeeded
    );

    // Get spawn points (deprecated)
    @Deprecated
    Transform[] getSpawnPoints(int seed);

    // Get default spawn provider (default method)
    default ISpawnProvider getDefaultSpawnProvider(int seed);

    // Shutdown hook (default method)
    default void shutdown();
}
```

Note: `getSpawnPoints(...)` is `@Deprecated`. The default `getDefaultSpawnProvider(...)` wraps `new FitToHeightMapSpawnProvider(new IndividualSpawnProvider(getSpawnPoints(seed)))`.

### Registering Custom Generators

```java
public class MyWorldGenPlugin extends JavaPlugin {
    @Override
    protected void setup() {
        IWorldGenProvider.CODEC.register(
            Priority.DEFAULT,
            "MyGenerator",
            MyWorldGenProvider.class,
            MyWorldGenProvider.CODEC
        );
    }
}
```

The `IWorldGenProvider.CODEC` is a `BuilderCodecMapCodec<IWorldGenProvider>` that uses a "Type" key for serialization.

## Generated Chunk Structures

### GeneratedChunk

Container for all chunk data:

```java
import com.hypixel.hytale.server.core.universe.world.worldgen.GeneratedChunk;

// Create a new generated chunk
GeneratedChunk chunk = new GeneratedChunk();

// Access chunk data
GeneratedBlockChunk blocks = chunk.getBlockChunk();
GeneratedBlockStateChunk states = chunk.getBlockStateChunk();
GeneratedEntityChunk entities = chunk.getEntityChunk();
Holder<ChunkStore>[] sections = chunk.getSections();

// Convert to world chunk
Holder<ChunkStore> worldChunk = chunk.toWorldChunk(world);
// or use the alias
Holder<ChunkStore> holder = chunk.toHolder(world);
```

### GeneratedChunkSection

Stores block data for 32x32x32 sections (32768 blocks per section):

```java
GeneratedChunkSection section = new GeneratedChunkSection();

// Set blocks with all parameters (x, y, z, blockId, rotation, filler)
section.setBlock(x, y, z, blockId, rotation, filler);

// Set blocks with index-based method (index, blockId, rotation, filler)
section.setBlock(index, blockId, rotation, filler);

// Get block data
int blockId = section.getBlock(x, y, z);
int filler = section.getFiller(x, y, z);
int rotation = section.getRotationIndex(x, y, z);

// Get raw data array
int[] data = section.getData();

// Check if section is all air
boolean isEmpty = section.isSolidAir();

// Reset section to default state
section.reset();

// Convert to final chunk section
BlockSection blockSection = section.toChunkSection();
```

## Staged Generation (NStagedChunkGenerator)

The staged chunk generator provides a flexible pipeline where each stage processes buffers. Located in `com.hypixel.hytale.builtin.hytalegenerator.newsystem`.

```java
import com.hypixel.hytale.builtin.hytalegenerator.newsystem.NStagedChunkGenerator;
import com.hypixel.hytale.builtin.hytalegenerator.newsystem.stages.*;

NStagedChunkGenerator generator = new NStagedChunkGenerator.Builder()
    .withConcurrentExecutor(executor, workerIndexer)
    .withMaterialCache(materialCache)
    .withBufferCapacity(bufferCapacityFactor, targetViewDistance, targetPlayerCount)
    .withStats(statsHeader, statsCheckpoints) // Optional statistics
    .appendStage(new NBiomeStage(...))
    .appendStage(new NTerrainStage(...))
    .appendStage(new NPropStage(...))
    .appendStage(new NTintStage(...))
    .appendStage(new NEnvironmentStage(...))
    .build();

// Generate a chunk
GeneratedChunk chunk = generator.generate(chunkRequestArguments);
```

### NStage Interface

All stages implement the `NStage` interface:

```java
public interface NStage {
    void run(NStage.Context context);
    Map<NBufferType, Bounds3i> getInputTypesAndBounds_bufferGrid();
    List<NBufferType> getOutputTypes();
    String getName();
}
```

### Built-in Stages

| Stage | Purpose |
|-------|---------|
| `NBiomeStage` | Biome data generation |
| `NBiomeDistanceStage` | Distance to biome borders |
| `NTerrainStage` | Terrain heightmap/blocks |
| `NPropStage` | Props and decorations |
| `NTintStage` | Color tinting |
| `NEnvironmentStage` | Environment data |
| `NTestTerrainStage` | Testing terrain |
| `NTestPropStage` | Testing props |

## Procedural Library

### Noise Functions

All noise functions implement the `NoiseFunction` interface which extends both `NoiseFunction2d` and `NoiseFunction3d`:

```java
import com.hypixel.hytale.procedurallib.logic.*;

// SimplexNoise has a singleton instance
SimplexNoise simplex = SimplexNoise.INSTANCE;
double value2d = simplex.get(seed, offset, x, z);          // 2D: (seed, offset, x, z)
double value3d = simplex.get(seed, offset, x, y, z);       // 3D: (seed, offset, x, y, z)

// PerlinNoise requires an interpolation function
PerlinNoise perlin = new PerlinNoise(interpolationFunction);
double perlinValue = perlin.get(seed, offset, x, z);

// ValueNoise requires an interpolation function
ValueNoise valueNoise = new ValueNoise(interpolationFunction);
double valueResult = valueNoise.get(seed, offset, x, z);

// CellNoise requires configuration
CellNoise cell = new CellNoise(
    distanceFunction,    // CellDistanceFunction
    pointEvaluator,      // PointEvaluator
    cellFunction,        // CellFunction
    noiseLookup          // NoiseProperty
);
double cellValue = cell.get(seed, offset, x, z);
```

### NoiseFunction Interface

```java
public interface NoiseFunction2d {
    double get(int seed, int offset, double x, double z);
}

public interface NoiseFunction3d {
    double get(int seed, int offset, double x, double y, double z);
}

public interface NoiseFunction extends NoiseFunction2d, NoiseFunction3d {}
```

### NoiseProperty Types

| Type | Description |
|------|-------------|
| `FractalNoiseProperty` | Multi-octave fractal |
| `SumNoiseProperty` | Add noise sources |
| `MultiplyNoiseProperty` | Multiply sources |
| `ScaleNoiseProperty` | Scale coordinates |
| `NormalizeNoiseProperty` | Normalize to 0-1 |
| `CurveNoiseProperty` | Apply curve |
| `BlendNoiseProperty` | Blend sources |
| `DistortedNoiseProperty` | Domain distortion |
| `SingleNoiseProperty` | Single noise source |
| `MaxNoiseProperty` | Maximum of sources |
| `MinNoiseProperty` | Minimum of sources |
| `InvertNoiseProperty` | Invert noise values |
| `RotateNoiseProperty` | Rotate coordinates |
| `OffsetNoiseProperty` | Offset coordinates |
| `GradientNoiseProperty` | Gradient-based noise |

### Conditions

```java
import com.hypixel.hytale.procedurallib.condition.*;

// Coordinate condition - evaluates based on position
public interface ICoordinateCondition {
    boolean eval(int seed, int x, int y);       // 2D evaluation
    boolean eval(int seed, int x, int y, int z); // 3D evaluation
}

// Double value condition
public interface IDoubleCondition {
    boolean eval(double value);
    // Optional: evaluate with a function
    default boolean eval(int seed, IntToDoubleFunction seedFunction);
}

// Integer value condition
public interface IIntCondition {
    boolean eval(int value);
    // Optional: evaluate with a function
    default boolean eval(int seed, IntToIntFunction seedFunction);
}
```

### Height Threshold

Controls terrain density at different heights:

```java
public interface IHeightThresholdInterpreter {
    int getLowestNonOne();    // Below: always solid
    int getHighestNonZero();  // Above: always air
    int getLength();          // Height range length

    // Get threshold at position
    float getThreshold(int seed, double x, double z, int y);
    // Get threshold with additional context
    float getThreshold(int seed, double x, double z, int y, double context);

    // Get context value for position
    double getContext(int seed, double x, double z);

    // Check if height is spawnable (default method)
    default boolean isSpawnable(int height);

    // Linear interpolation utility
    static float lerp(float a, float b, float t);
}
```

### Point Generators

For placing features at distributed points:

```java
import com.hypixel.hytale.procedurallib.logic.point.IPointGenerator;
import com.hypixel.hytale.procedurallib.logic.ResultBuffer.*;

public interface IPointGenerator {
    // Find nearest point in 2D
    ResultBuffer2d nearest2D(int seed, double x, double z);

    // Find nearest point in 3D
    ResultBuffer3d nearest3D(int seed, double x, double y, double z);

    // Find transition between points in 2D
    ResultBuffer2d transition2D(int seed, double x, double z);

    // Find transition between points in 3D
    ResultBuffer3d transition3D(int seed, double x, double y, double z);

    // Collect all points in area
    void collect(int seed, double minX, double minZ, double maxX, double maxZ,
                 PointConsumer2d consumer);

    // Get point spacing interval
    double getInterval();
}

// Usage example
IPointGenerator generator = /* ... */;

// Find nearest point
ResultBuffer2d nearest = generator.nearest2D(seed, x, z);
double distance = nearest.distance;
double pointX = nearest.x;
double pointY = nearest.y;
int hash = nearest.hash;

// Collect points in area
generator.collect(seed, minX, minZ, maxX, maxZ, (px, pz) -> {
    // Process each point at (px, pz)
});
```

## Zones

Large-scale region definitions. Zones are Java records that define areas with shared characteristics:

```java
import com.hypixel.hytale.server.worldgen.zone.Zone;
import com.hypixel.hytale.server.worldgen.zone.ZoneDiscoveryConfig;

// Zone is a record with the following components:
public record Zone(
    int id,
    String name,
    ZoneDiscoveryConfig discoveryConfig,
    CaveGenerator caveGenerator,
    BiomePatternGenerator biomePatternGenerator,
    UniquePrefabContainer uniquePrefabContainer
) {
    // Accessor methods (auto-generated by record)
    public int id();
    public String name();
    public ZoneDiscoveryConfig discoveryConfig();
    public CaveGenerator caveGenerator();
    public BiomePatternGenerator biomePatternGenerator();
    public UniquePrefabContainer uniquePrefabContainer();
}

// Usage example
Zone zone = /* obtained from world generation context */;
String zoneName = zone.name();
int zoneId = zone.id();
CaveGenerator caves = zone.caveGenerator();
BiomePatternGenerator biomes = zone.biomePatternGenerator();
```

## Biomes

Terrain characteristics and block placement. The abstract `Biome` class provides the core biome functionality:

```java
import com.hypixel.hytale.server.worldgen.biome.Biome;

// Biome is an abstract class with these key methods:
public abstract class Biome {
    // Identity
    public int getId();
    public String getName();
    public int getMapColor();

    // Terrain generation
    public IHeightThresholdInterpreter getHeightmapInterpreter();
    public NoiseProperty getHeightmapNoise();
    public BiomeInterpolation getInterpolation();

    // Block layers and covers
    public CoverContainer getCoverContainer();
    public LayerContainer getLayerContainer();

    // Prefab placement
    public PrefabContainer getPrefabContainer();

    // Visual properties
    public TintContainer getTintContainer();
    public EnvironmentContainer getEnvironmentContainer();
    public WaterContainer getWaterContainer();
    public FadeContainer getFadeContainer();
}
```

### BiomeType Interface

For the staged chunk generator, biomes implement `BiomeType`:

```java
import com.hypixel.hytale.builtin.hytalegenerator.biome.BiomeType;

public interface BiomeType extends MaterialSource, PropsSource, EnvironmentSource, TintSource {
    String getBiomeName();
    Density getTerrainDensity();
}
```

## Caves

Underground structure generation using `CaveGenerator`:

```java
import com.hypixel.hytale.server.worldgen.cave.CaveGenerator;
import com.hypixel.hytale.server.worldgen.cave.CaveType;
import com.hypixel.hytale.server.worldgen.cave.Cave;

public class CaveGenerator {
    // Get available cave types
    public CaveType[] getCaveTypes();

    // Generate a cave structure
    public Cave generate(
        int seed,
        ChunkGenerator chunkGenerator,
        CaveType caveType,
        int x, int y, int z
    );

    // Protected methods for subclass customization
    protected Cave newCave(CaveType caveType);
    protected void startCave(int seed, ChunkGenerator generator, Cave cave,
                            Vector3d origin, Random random);
    protected void continueNode(int seed, ChunkGenerator generator, Cave cave,
                               CaveNode node, int depth, Random random);
    protected int getChildrenCount(CaveNodeType nodeType, Random random);
    protected void generatePrefabs(int seed, ChunkGenerator generator,
                                  CaveNode parentNode, CaveNode childNode);
}
```

### Cave Node Shapes

Cave systems use various shape generators:

| Shape | Description |
|-------|-------------|
| `EllipsoidCaveNodeShape` | Spherical/ellipsoid caverns |
| `PipeCaveNodeShape` | Tubular passages |
| `TetrahedronCaveNodeShape` | Tetrahedral chambers |
| `DistortedEllipsoidShape` | Distorted spheres |
| `DistortedCylinderShape` | Distorted cylinders |
| `DistortedPipeShape` | Distorted tubes |

## Best Practices

1. **Use async generation** - Never block the main thread
2. **Cache noise results** - Expensive to recompute
3. **Respect stillNeeded predicate** - Cancel work for unneeded chunks
4. **Profile with getTimings()** - Identify bottlenecks
5. **Use staged pipeline** - For complex generation logic
6. **Use the buffer system** - NStagedChunkGenerator buffers enable efficient data sharing between stages
7. **Implement proper stage dependencies** - Define input/output buffer types correctly
