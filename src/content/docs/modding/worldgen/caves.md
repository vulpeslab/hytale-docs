---
author: UnlimitedBytes
title: Cave Generation
description: Understanding and customizing Hytale's cave generation system for server mods.
sidebar:
  order: 2
---

Hytale's cave generation system creates complex underground networks using a node-based approach with various shapes, prefabs, and procedural logic. Caves are composed of connected nodes that can be chambers, tunnels, or prefab-based structures.

## Core Architecture

### Cave

The main container for a complete cave system:

```java
import com.hypixel.hytale.server.worldgen.cave.Cave;
import com.hypixel.hytale.server.worldgen.cave.CaveType;
import com.hypixel.hytale.server.worldgen.cave.element.CaveNode;

public class Cave {
    // Get cave configuration
    public CaveType getCaveType();
    
    // Get world bounds of entire cave
    public WorldBounds getBounds();
    
    // Get total node count
    public long getNodeCount();
    
    // Add node to cave (called during generation)
    public void addNode(CaveNode element);
    
    // Check if chunk contains cave nodes
    public boolean contains(long chunkIndex);
    
    // Get nodes affecting a chunk
    public CaveNode[] getCaveNodes(long chunkIndex);
    
    // Finalize cave structure
    public void compile();
}
```

**Cave Structure:**

- Caves consist of `CaveNode` objects connected in a tree structure
- Each node has a shape (ellipsoid, pipe, cylinder, etc.)
- Nodes are organized by chunk for efficient lookup
- `compile()` must be called after all nodes are added

### CaveType

Defines the characteristics and generation rules for a cave system:

```java
import com.hypixel.hytale.server.worldgen.cave.CaveType;
import com.hypixel.hytale.server.worldgen.cave.CaveNodeType;
import com.hypixel.hytale.procedurallib.logic.point.IPointGenerator;

public class CaveType {
    // Identity
    public String getName();
    
    // Entry configuration
    public CaveNodeType getEntryNode();
    public int getModifiedStartHeight(int seed, int x, int y, int z, Random random);
    public float getStartPitch(Random random);
    public float getStartYaw(Random random);
    public int getStartDepth(Random random);
    
    // Point generation
    public IPointGenerator getEntryPointGenerator();
    
    // Conditions and masks
    public Int2FlagsCondition getBiomeMask();
    public BlockMaskCondition getBlockMask();
    public boolean isEntryThreshold(int seed, int x, int z);
    public boolean isHeightThreshold(int seed, int x, int y, int z);
    
    // Height-based scaling
    public float getHeightRadiusFactor(int seed, double x, double z, int y);
    public ICoordinateCondition getHeightCondition();
    
    // Fluid configuration
    public FluidLevel getFluidLevel();
    
    // Environment and behavior
    public int getEnvironment();
    public boolean isSurfaceLimited();
    public boolean isSubmerge();
    public double getMaximumSize();
}
```

**Key Properties:**

- `entryNodeType` - Initial node type when cave generation starts
- `yaw/pitch/depth` - Random ranges for cave orientation and depth
- `pointGenerator` - Determines cave entry point locations
- `biomeMask` - Controls which biomes can have this cave type
- `blockMask` - Determines valid blocks for cave entry
- `heightFactors` - Scales cave radius based on depth
- `fluidLevel` - Lava or water filling configuration
- `surfaceLimited` - Whether cave connects to surface
- `submerge` - Whether cave can generate underwater
- `maximumSize` - Maximum extent of cave system

### CaveNodeType

Defines a node template in the cave tree:

```java
import com.hypixel.hytale.server.worldgen.cave.CaveNodeType;
import com.hypixel.hytale.server.worldgen.cave.shape.CaveNodeShapeEnum;
import com.hypixel.hytale.common.map.IWeightedMap;

public class CaveNodeType {
    // Identity
    public String getName();
    
    // Shape generation
    public CaveNodeShape generateCaveNodeShape(
        Random random,
        CaveType caveType,
        CaveNode parentNode,
        CaveNodeChildEntry childEntry,
        Vector3d origin,
        float yaw,
        float pitch
    );
    
    // Node properties
    public CavePrefabContainer getPrefabContainer();
    public BlockFluidEntry getFilling(Random random);
    public CaveNodeCoverEntry[] getCovers();
    public int getPriority();
    public int getEnvironment();
    public boolean hasEnvironment();
    
    // Child configuration
    public CaveNodeChildEntry[] getChildren();
    public void setChildren(CaveNodeChildEntry[] children);
    public IDoubleRange getChildrenCountBounds();
    
    // Height constraints
    public ICoordinateCondition getHeightCondition();
}
```

**Node Configuration:**

- `name` - Identifier for debugging
- `prefabContainer` - Structures to place in this node
- `fillings` - Block types for cave interior (air, water, lava)
- `shapeGenerator` - Function to create the node's geometry
- `covers` - Floor and ceiling decorations
- `priority` - Rendering/carving order (higher = later)
- `children` - Possible child node types and their connection rules
- `childrenCountBounds` - Limits on child node count

### CaveNode

A single node instance in a cave:

```java
import com.hypixel.hytale.server.worldgen.cave.element.CaveNode;
import com.hypixel.hytale.server.worldgen.cave.shape.CaveNodeShape;

public class CaveNode implements CaveElement {
    // Node configuration
    public CaveNodeType getCaveNodeType();
    public CaveNodeShape getShape();
    public int getSeedOffset();
    
    // Orientation
    public float getYaw();
    public float getPitch();
    
    // Position
    public Vector3d getEnd();
    public IWorldBounds getBounds();
    
    // Prefabs within node
    public CavePrefab[] getCavePrefabs();
    public void addPrefab(CavePrefab prefab);
    
    // Height queries
    public int getFloorPosition(int seed, double x, double z);
    public int getCeilingPosition(int seed, double x, double z);
    
    // Chunk iteration
    public void forEachChunk(LongConsumer consumer);
    
    // Finalize node
    public void compile();
}
```

## Cave Shapes

### CaveNodeShape Interface

All cave shapes implement this interface:

```java
import com.hypixel.hytale.server.worldgen.cave.shape.CaveNodeShape;

public interface CaveNodeShape {
    // Node endpoints
    public Vector3d getStart();
    public Vector3d getEnd();
    
    // Get anchor point for child nodes
    public Vector3d getAnchor(Vector3d result, double x, double y, double z);
    
    // Bounds for chunk iteration
    public IWorldBounds getBounds();
    
    // Block replacement test
    public boolean shouldReplace(int seed, double x, double z, int y);
    
    // Height queries
    public double getFloorPosition(int seed, double x, double z);
    public double getCeilingPosition(int seed, double x, double z);
    
    // Populate chunk with cave blocks
    public void populateChunk(int seed, ChunkGeneratorExecution execution,
                             Cave cave, CaveNode node, Random random);
    
    // Whether shape has geometry (default: true)
    default boolean hasGeometry();
}
```

### Available Shape Types

```java
import com.hypixel.hytale.server.worldgen.cave.shape.CaveNodeShapeEnum;

public enum CaveNodeShapeEnum {
    PIPE,        // Tubular passages
    CYLINDER,    // Cylindrical chambers
    PREFAB,      // Prefab-based structures
    EMPTY_LINE,  // Connection without geometry
    ELLIPSOID,   // Spherical/ellipsoidal caverns
    DISTORTED;   // Noise-distorted shapes
}
```

### Shape Implementations

#### EllipsoidCaveNodeShape

Spherical or ellipsoidal chambers:

```java
import com.hypixel.hytale.server.worldgen.cave.shape.EllipsoidCaveNodeShape;

// Creates spherical caverns
// Defined by center point and radius
// Can be elongated along axes for ellipsoidal shapes
```

#### PipeCaveNodeShape

Tubular passages connecting points:

```java
import com.hypixel.hytale.server.worldgen.cave.shape.PipeCaveNodeShape;

// Creates tube-shaped passages
// Connects start and end points
// Radius can vary along length
```

#### CylinderCaveNodeShape

Cylindrical chambers:

```java
import com.hypixel.hytale.server.worldgen.cave.shape.CylinderCaveNodeShape;

// Creates vertical or oriented cylinders
// Defined by axis and radius
```

#### PrefabCaveNodeShape

Prefab-based cave structures:

```java
import com.hypixel.hytale.server.worldgen.cave.shape.PrefabCaveNodeShape;

// Uses prefab structure as cave shape
// Can be rotated
public PrefabRotation getPrefabRotation();
```

#### EmptyLineCaveNodeShape

Connection without geometry:

```java
import com.hypixel.hytale.server.worldgen.cave.shape.EmptyLineCaveNodeShape;

// Connects nodes without carving blocks
// Used for logic connections
// hasGeometry() returns false
```

#### TetrahedronCaveNodeShape

Tetrahedral chambers:

```java
import com.hypixel.hytale.server.worldgen.cave.shape.TetrahedronCaveNodeShape;

// Creates tetrahedral caverns
// Four triangular faces
```

### Distorted Shapes

Shapes with procedural noise distortion for organic appearance:

```java
import com.hypixel.hytale.server.worldgen.cave.shape.distorted.*;

// Base distorted shape types
public class DistortedEllipsoidShape extends AbstractDistortedBody;
public class DistortedCylinderShape extends AbstractDistortedBody;
public class DistortedPipeShape extends AbstractDistortedExtrusion;

// Distortion configuration
public class ShapeDistortion {
    // Applies noise-based distortion to shape surface
}
```

**Distorted Shape Features:**

- Apply noise functions to deform basic shapes
- Create organic, natural-looking caves
- Different distortion patterns for variety

## Cave Generation Process

### CaveGenerator

Handles the generation of cave systems:

```java
import com.hypixel.hytale.server.worldgen.cave.CaveGenerator;

public class CaveGenerator {
    // Get available cave types
    public CaveType[] getCaveTypes();
    
    // Generate a complete cave
    public Cave generate(int seed, ChunkGenerator chunkGenerator,
                        CaveType caveType, int x, int y, int z);
    
    // Protected methods for customization:
    protected Cave newCave(CaveType caveType);
    
    protected void startCave(int seed, ChunkGenerator chunkGenerator,
                            Cave cave, Vector3d origin, Random random);
    
    protected void continueNode(int seed, ChunkGenerator chunkGenerator,
                               Cave cave, CaveNode parent, int depth,
                               Random random);
    
    protected int getChildrenCount(CaveNodeType type, Random random);
    
    protected CaveNodeChildEntry[] getChildEntriesRandomized(
        CaveNodeType type, Random random);
    
    protected void generatePrefabs(int seed, ChunkGenerator chunkGenerator,
                                  CaveNode parent, CaveNode node);
}
```

### Generation Algorithm

The cave generator follows this process:

1. **Start Cave:**
   - Determine entry height (may be fixed or variable)
   - Get initial yaw, pitch, and depth from `CaveType`
   - Create entry node using `entryNodeType`
   - Check biome mask for entry and exit points

2. **Continue Node:**
   - For each child entry in current node:
     - Check if child should generate (chance-based)
     - Select child type from weighted map
     - Calculate child origin from parent anchor
     - Calculate child yaw/pitch from parent orientation
     - Generate child shape
     - Check height and biome conditions
     - Add child node to cave if valid
     - Recursively continue child node (decremented depth)

3. **Generate Prefabs:**
   - Iterate through prefab container entries
   - For each entry:
     - Determine iteration count
     - Find random positions within node bounds
     - Check biome, height, and noise conditions
     - Place prefab if conditions met

4. **Compile:**
   - Sort nodes by priority for proper rendering order
   - Organize nodes by chunk for efficient lookup
   - Finalize all prefab placements

## Biome Masking

Caves use biome masks with flag-based results:

```java
import com.hypixel.hytale.server.worldgen.cave.CaveBiomeMaskFlags;
import com.hypixel.hytale.server.worldgen.util.condition.flag.Int2FlagsCondition;

// Biome mask returns flags
Int2FlagsCondition biomeMask = caveType.getBiomeMask();
int flags = biomeMask.eval(biomeId);

// Check flags
public static boolean canGenerate(int flags);  // Can start generation
public static boolean canPopulate(int flags);  // Can add to cave
public static boolean canContinue(int flags);  // Can continue branching

// Default masks
public static final Int2FlagsCondition DEFAULT_ALLOW;  // All flags set
public static final Int2FlagsCondition DEFAULT_DENY;   // No flags set
```

**Flag System:**

- Bit flags allow fine-grained control
- `canGenerate` - Basic permission to generate cave
- `canPopulate` - Permission to add geometry (can generate without geometry)
- `canContinue` - Permission to branch and create children
- Allows caves to "pass through" biomes without carving

## Cave Prefabs

### CavePrefab

Structures placed within cave nodes:

```java
import com.hypixel.hytale.server.worldgen.cave.element.CavePrefab;

public class CavePrefab implements CaveElement {
    // Prefab configuration
    public WorldGenPrefabSupplier getPrefab();
    public PrefabRotation getRotation();
    
    // Conditions
    public IIntCondition getBiomeMask();
    public BlockMaskCondition getConfiguration();
    
    // Position
    public int getX();
    public int getY();
    public int getZ();
    public IWorldBounds getBounds();
}
```

### CavePrefabContainer

Manages prefab placement rules:

```java
import com.hypixel.hytale.server.worldgen.cave.prefab.CavePrefabContainer;

public class CavePrefabContainer {
    public CavePrefabEntry[] getEntries();
}

// Each entry contains:
public class CavePrefabEntry {
    // Weighted selection of prefabs
    public IWeightedMap<WorldGenPrefabSupplier> getPrefabs();
    public WorldGenPrefabSupplier getPrefab(double random);
    
    // Placement configuration
    public CavePrefabConfig getConfig();
}

// Configuration for prefab placement
public class CavePrefabConfig {
    // Rotation options
    public PrefabRotation getRotation(Random random);
    
    // Placement rules
    public int getIterations(double random);
    public int getHeight(int seed, int x, int z, CaveNode caveNode);
    public double getDisplacement(int seed, int x, int z, CaveNode caveNode);
    
    // Conditions
    public boolean isMatchingNoiseDensity(int seed, int x, int z);
    public boolean isMatchingHeight(int seed, int x, int y, int z, Random random);
    public boolean isMatchingBiome(Biome biome);
    
    // Masks
    public IIntCondition getBiomeMask();
    public BlockMaskCondition getBlockMask();
}
```

### CavePrefabPlacement

Determines vertical placement strategy:

```java
import com.hypixel.hytale.server.worldgen.cave.CavePrefabPlacement;

// Placement modes for prefabs within caves
// Controls how Y coordinate is determined from cave node
```

## Cave Node Children

### CaveNodeChildEntry

Defines how child nodes connect to parent:

```java
// Located in CaveNodeType.CaveNodeChildEntry

public class CaveNodeChildEntry {
    // Child type selection
    public IWeightedMap<CaveNodeType> getTypes();
    
    // Connection geometry
    public Vector3d getAnchor();        // Relative position in parent
    public Vector3d getOffset();        // Additional offset
    public PrefabRotation getRotation(Random random);
    
    // Orientation
    public OrientationModifier getPitchModifier();
    public OrientationModifier getYawModifier();
    public CaveYawMode getYawMode();
    
    // Generation limits
    public double getChance();                    // 0-1 probability
    public IDoubleRange getRepeat();             // How many to generate
    public IDoubleRange getChildrenLimit();      // Max depth for children
}
```

### Yaw Modes

```java
import com.hypixel.hytale.server.worldgen.cave.CaveYawMode;

// How child yaw relates to parent yaw
// Combined with parent rotation for proper orientation
public CaveYawMode getYawMode();
```

### OrientationModifier

```java
@FunctionalInterface
public interface OrientationModifier {
    float calc(float parentValue, Random random);
}

// Modifies parent pitch/yaw for child
// Can add randomness or apply transformations
```

## Cave Node Covers

Decorative layers on cave floors and ceilings:

```java
// Located in CaveNodeType.CaveNodeCoverEntry

public class CaveNodeCoverEntry {
    // Get cover entry
    public Entry get(Random random);
    
    // Conditions
    public ICoordinateRndCondition getHeightCondition();
    public ICoordinateCondition getMapCondition();
    public ICoordinateCondition getDensityCondition();
    public IBlockFluidCondition getParentCondition();
    
    // Type (floor or ceiling)
    public CaveNodeCoverType getType();
}

public enum CaveNodeCoverType {
    FLOOR(-1),      // Places below cave
    CEILING(1);     // Places above cave
}

// Cover entry
public class Entry {
    public BlockFluidEntry getEntry();  // Block to place
    public int getOffset();             // Vertical offset
}
```

## Fluid Levels

Caves can be filled with fluids:

```java
// Located in CaveType.FluidLevel

public class FluidLevel {
    public static final FluidLevel EMPTY;  // No fluid
    
    public BlockFluidEntry getBlockEntry();  // Fluid block type
    public int getHeight();                  // Fill height
}
```

## Custom Cave Implementation

### Creating a Custom CaveType

```java
import com.hypixel.hytale.server.worldgen.cave.CaveType;

CaveType customCave = new CaveType(
    "MyCustomCave",           // name
    entryNodeType,            // Entry node configuration
    yawRange,                 // Random yaw range
    pitchRange,               // Random pitch range  
    depthRange,               // Cave depth range
    heightFactors,            // Height-based scaling
    pointGenerator,           // Entry point distribution
    biomeMask,                // Valid biomes
    blockMask,                // Valid entry blocks
    mapCondition,             // 2D entry condition
    heightCondition,          // 3D height condition
    fixedEntryHeight,         // Optional: fixed height
    fixedEntryHeightNoise,    // Optional: height noise
    fluidLevel,               // Fluid configuration
    environment,              // Environment ID
    false,                    // surfaceLimited
    false,                    // submerge
    1000.0                    // maximumSize
);
```

### Creating a Custom CaveNodeType

```java
import com.hypixel.hytale.server.worldgen.cave.CaveNodeType;

CaveNodeType nodeType = new CaveNodeType(
    "MyNode",                      // name
    prefabContainer,               // Optional: prefabs in node
    fillingsMap,                   // Block fillings (weighted)
    shapeGenerator,                // Shape generator function
    heightCondition,               // Height constraints
    childrenCountBounds,           // Optional: child limit
    covers,                        // Floor/ceiling decorations
    100,                           // priority
    environment                    // environment ID
);

// Set children after creation (for circular references)
nodeType.setChildren(childEntries);
```

### Creating a Custom Shape Generator

```java
import com.hypixel.hytale.server.worldgen.cave.shape.CaveNodeShapeEnum;

CaveNodeShapeEnum.CaveNodeShapeGenerator shapeGen = 
    (random, caveType, parent, childEntry, origin, yaw, pitch) -> {
        // Generate and return custom CaveNodeShape
        return new MyCustomShape(origin, yaw, pitch, /* ... */);
    };
```

## Best Practices

### Cave Design

1. **Balance depth and complexity** - Deeper caves = more nodes = more CPU time
2. **Use appropriate shapes** - Match shape to cave type (tunnels vs caverns)
3. **Test biome masks** - Ensure caves generate in intended biomes
4. **Set reasonable priorities** - Control carving order for overlapping features
5. **Consider fluid levels** - Water/lava adds visual interest but affects gameplay

### Performance

1. **Limit maximum size** - Large caves affect many chunks
2. **Control child count** - Exponential growth with depth
3. **Optimize prefab placement** - Reduce iteration counts
4. **Use chunk bounds efficiently** - Minimize chunk overlap
5. **Profile generation time** - Monitor expensive operations

### Integration

1. **Coordinate with biomes** - Use biome masks appropriately
2. **Respect zone boundaries** - Consider zone-specific cave types
3. **Match environment IDs** - Consistent with biome/zone environment
4. **Test height constraints** - Ensure caves generate at intended depths
5. **Verify block masks** - Caves should start in solid terrain

### Debugging

1. **Use descriptive names** - Easier to identify in logs
2. **Test with fixed seeds** - Reproducible generation
3. **Visualize bounds** - Check cave extent calculations
4. **Monitor node counts** - Detect runaway generation
5. **Validate prefab placement** - Ensure conditions work as expected
