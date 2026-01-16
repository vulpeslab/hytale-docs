---
author: UnlimitedBytes
title: Assets & Registry
description: Register custom content and manage assets in your Hytale plugin.
sidebar:
  order: 2
---

The Hytale asset system provides a powerful way to register, load, and manage custom game content.

## Architecture

```
AssetRegistry (com.hypixel.hytale.assetstore.AssetRegistry)
├── AssetStore<K, T, M>[]     - Type-specific stores
│   ├── AssetCodec            - Serialization
│   ├── AssetMap              - Storage/lookup
│   └── AssetPack[]           - Content packs
└── Tag indices               - TAG_MAP / CLIENT_TAG_MAP (string → int)
```

## Asset Stores

### Registering an Asset Store

```java
import com.hypixel.hytale.assetstore.codec.AssetCodec;
import com.hypixel.hytale.assetstore.map.IndexedLookupTableAssetMap;
import com.hypixel.hytale.server.core.asset.HytaleAssetStore;

@Override
protected void setup() {
    getAssetRegistry().register(
        HytaleAssetStore.builder(MyAsset.class, new IndexedLookupTableAssetMap<>(MyAsset[]::new))
            .setPath("MyAssets")
            .setCodec((AssetCodec) MyAsset.CODEC)
            .setKeyFunction(MyAsset::getId)
            .loadsAfter(OtherAsset.class)  // Load dependencies
            .build()
    );
}
```

### Asset Store Builder

```java
HytaleAssetStore.builder(AssetClass.class, new IndexedLookupTableAssetMap<>(AssetClass[]::new))
    .setPath("AssetDirectory")           // JSON files location
    .setCodec((AssetCodec) Asset.CODEC)  // Serialization codec
    .setKeyFunction(Asset::getId)         // Key extraction function
    .loadsAfter(Dependency.class)         // Load after this asset type
    .loadsBefore(Dependent.class)         // Load before this asset type
    .build();
```

## Creating Assets

### Asset Class

```java
import com.hypixel.hytale.assetstore.map.JsonAssetWithMap;
import com.hypixel.hytale.codec.builder.BuilderCodec;

public class MyAsset
implements JsonAssetWithMap<String, IndexedLookupTableAssetMap<String, MyAsset>> {

    public static final BuilderCodec<MyAsset> ABSTRACT_CODEC =
        BuilderCodec.builder(MyAsset.class, MyAsset::new)
            .append(new KeyedCodec<>("Name", Codec.STRING),
                (obj, val) -> obj.name = val,
                obj -> obj.name)
            .add()
            .append(new KeyedCodec<>("Value", Codec.INTEGER),
                (obj, val) -> obj.value = val,
                obj -> obj.value)
            .add()
            .build();

    private String id;
    private String name;
    private int value;

    @Override
    public String getId() { return id; }
    public String getName() { return name; }
    public int getValue() { return value; }
}
```

### Asset JSON File

```json
{
  "Id": "my_asset_id",
  "Name": "My Asset",
  "Value": 42
}
```

## Codec System

### BuilderCodec

Type-safe serialization for structured data:

```java
public static final BuilderCodec<MyData> CODEC =
    BuilderCodec.builder(MyData.class, MyData::new)
        .append(new KeyedCodec<>("Name", Codec.STRING),
            (obj, val) -> obj.name = val,
            obj -> obj.name)
        .add()
        .append(new KeyedCodec<>("Count", Codec.INTEGER),
            (obj, val) -> obj.count = val,
            obj -> obj.count)
        .add()
        .build();
```

### Built-in Codecs

| Codec | Type |
|-------|------|
| `Codec.STRING` | String |
| `Codec.BOOLEAN` | boolean |
| `Codec.INTEGER` | int |
| `Codec.LONG` | long |
| `Codec.FLOAT` | float |
| `Codec.DOUBLE` | double |
| `Codec.UUID_STRING` | UUID |

### Collection Codecs

```java
// List codec
Codec<List<String>> stringList = Codec.list(Codec.STRING);

// Map codec
Codec<Map<String, Integer>> stringIntMap =
    Codec.map(Codec.STRING, Codec.INTEGER);

// Optional codec
Codec<Optional<String>> optionalString = Codec.optional(Codec.STRING);
```

### Polymorphic Codecs

For types with multiple implementations:

```java
import com.hypixel.hytale.assetstore.codec.AssetCodecMapCodec;

public abstract class Interaction {
    public static final AssetCodecMapCodec<String, Interaction> CODEC =
        new AssetCodecMapCodec<>(...);
}

// Register implementations
Interaction.CODEC.register("Click", ClickInteraction.class, ClickInteraction.CODEC);
```

Registration in plugin:

```java
@Override
protected void setup() {
    getCodecRegistry(Interaction.CODEC)
        .register("MyInteraction", MyInteraction.class, MyInteraction.CODEC);
}
```

## Asset Access

### Get Asset by Key

```java
DefaultAssetMap<String, MyAsset> map = MyAsset.getAssetMap();
MyAsset asset = map.getAsset("my_asset_id");

if (asset != null) {
    // Use asset
}
```

### Iterate All Assets

```java
for (String key : map.getKeys()) {
    MyAsset asset = map.getAsset(key);
    // Process asset
}
```

## Asset Events

Listen for asset loading/unloading:

```java
@Override
protected void setup() {
    getEventRegistry().register(
        LoadedAssetsEvent.class,
        MyAsset.class,
        this::onAssetsLoaded
    );
}

private void onAssetsLoaded(LoadedAssetsEvent<MyAsset> event) {
    for (MyAsset asset : event.getAssets()) {
        getLogger().at(Level.INFO).log("Loaded asset: " + asset.getId());
    }
}
```

## Asset Inheritance

Assets can inherit from parent assets:

```json
{
  "Id": "my_child_asset",
  "Parent": "my_parent_asset",
  "Name": "Overridden Name"
}
```

## Plugin Registries

The `PluginBase` class provides several registry accessors:

```java
// Codec registry for polymorphic types
getCodecRegistry(ParentCodec.CODEC).register("Type", MyClass.class, MyClass.CODEC);

// Entity store registry
getEntityStoreRegistry().registerComponent(MyComponent.class, "Name", MyComponent.CODEC);
getEntityStoreRegistry().registerSystem(new MySystem());

// Command registry
getCommandRegistry().registerCommand(new MyCommand());

// Event registry
getEventRegistry().register(SomeEvent.class, this::onEvent);
```

## Best Practices

1. **Define clear codecs** - Type-safe serialization prevents errors
2. **Use load ordering** - Declare dependencies with loadsAfter/loadsBefore
3. **Validate assets** - Add validators to catch invalid data
4. **Handle events** - React to asset loading/unloading
5. **Use inheritance** - Reduce duplication with parent assets
6. **Cache asset references** - Store frequently accessed assets
