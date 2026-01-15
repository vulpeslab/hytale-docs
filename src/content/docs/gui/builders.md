---
author: UnlimitedBytes
title: UI Building Tools
description: Use UICommandBuilder and UIEventBuilder to create dynamic UIs in Hytale.
sidebar:
  order: 5
---

The UI building tools provide a fluent API for constructing and updating user interfaces from server-side code.

## UICommandBuilder

Build UI manipulation commands to send to the client.

### Creating a Builder

```java
import com.hypixel.hytale.server.core.ui.builder.UICommandBuilder;

UICommandBuilder builder = new UICommandBuilder();
```

### Command Types

These are the available `CustomUICommandType` enum values from `com.hypixel.hytale.protocol.packets.interface_`:

| Type | Description |
|------|-------------|
| `Append` | Add elements from a document path to root or a selector |
| `AppendInline` | Add elements from inline UI definition to a selector |
| `InsertBefore` | Insert elements from a document path before a selector |
| `InsertBeforeInline` | Insert inline elements before a selector |
| `Remove` | Remove elements matching selector |
| `Set` | Set property value on elements |
| `Clear` | Clear children of elements matching selector |

```java
import com.hypixel.hytale.protocol.packets.interface_.CustomUICommandType;
```

### Appending Content

```java
// Append UI document to page root
builder.append("Pages/MyPage.ui");

// Append to specific container
builder.append("#container", "Components/Button.ui");

// Append inline UI markup
builder.appendInline("#container", "<div class=\"item\">Content</div>");
```

### Inserting Content

```java
// Insert before an element
builder.insertBefore("#target-element", "Components/Header.ui");

// Insert inline before an element
builder.insertBeforeInline("#target-element", "<div>Inserted Content</div>");
```

### Removing and Clearing

```java
// Remove element from DOM entirely
builder.remove("#old-element");

// Clear element's children but keep element
builder.clear("#container");
```

### Setting Values

```java
// Set text content
builder.set("#health-text", "100 HP");

// Set Message objects (for localized/formatted text)
builder.set("#greeting", message);

// Set numeric values
builder.set("#health-bar", 0.75f);  // float
builder.set("#count", 42);           // int
builder.set("#value", 3.14);         // double

// Set boolean values
builder.set("#is-visible", true);

// Set null value
builder.setNull("#optional-field");

// Set complex objects (must have a registered codec)
builder.setObject("#item-slot", itemGridSlot);

// Set arrays of compatible types
builder.set("#items", itemStackArray);

// Set lists of compatible types
builder.set("#items", itemStackList);
```

#### Supported Types

The `set()` method has dedicated overloads for these primitive types:
- `String` - Text values
- `boolean` - Boolean values
- `int` - Integer values
- `float` - Float values
- `double` - Double values
- `Message` - Localized/formatted messages (`com.hypixel.hytale.server.core.Message`)
- `Value<T>` - References to values in other UI documents

For `setObject()`, the following types are registered in the `CODEC_MAP`:

| Type | Package |
|------|---------|
| `Area` | `com.hypixel.hytale.server.core.ui.Area` |
| `ItemGridSlot` | `com.hypixel.hytale.server.core.ui.ItemGridSlot` |
| `ItemStack` | `com.hypixel.hytale.server.core.inventory.ItemStack` |
| `LocalizableString` | `com.hypixel.hytale.server.core.ui.LocalizableString` |
| `PatchStyle` | `com.hypixel.hytale.server.core.ui.PatchStyle` |
| `DropdownEntryInfo` | `com.hypixel.hytale.server.core.ui.DropdownEntryInfo` |
| `Anchor` | `com.hypixel.hytale.server.core.ui.Anchor` |

These types can also be used in arrays (`T[]`) or lists (`List<T>`) with the `set()` method.

### Using Value References

Reference values from other UI documents using the `Value` class:

```java
import com.hypixel.hytale.server.core.ui.Value;

// Reference a style from Common.ui
builder.set("#button.Style", Value.ref("Common.ui", "DefaultButtonStyle"));

// Reference with nested path
builder.set("#panel.Theme", Value.ref("Themes.ui", "DarkTheme.Colors"));
```

The `Value` class supports two factory methods:
- `Value.ref(String documentPath, String valueName)` - Create a reference to a value in another UI document
- `Value.of(T value)` - Wrap a direct value (note: cannot be used with `set()` which only accepts references)

### Getting Commands

```java
// Get array of commands to send
CustomUICommand[] commands = builder.getCommands();

// Empty array constant (useful when no commands needed)
CustomUICommand[] empty = UICommandBuilder.EMPTY_COMMAND_ARRAY;
```

## UIEventBuilder

Bind UI events to server-side handlers.

### Creating a Builder

```java
import com.hypixel.hytale.server.core.ui.builder.UIEventBuilder;

UIEventBuilder eventBuilder = new UIEventBuilder();
```

### Event Types

These are the available `CustomUIEventBindingType` enum values from `com.hypixel.hytale.protocol.packets.interface_`:

| Type | Description |
|------|-------------|
| `Activating` | Primary activation (click/tap) |
| `RightClicking` | Right mouse button click |
| `DoubleClicking` | Double click |
| `MouseEntered` | Mouse entered element bounds |
| `MouseExited` | Mouse exited element bounds |
| `ValueChanged` | Value changed (sliders, inputs) |
| `ElementReordered` | Element was reordered in a list |
| `Validating` | Validation event |
| `Dismissing` | Page is being dismissed |
| `FocusGained` | Element gained focus |
| `FocusLost` | Element lost focus |
| `KeyDown` | Key press event |
| `MouseButtonReleased` | Mouse button released |
| `SlotClicking` | Slot click (for inventory-style grids) |
| `SlotDoubleClicking` | Slot double click |
| `SlotMouseEntered` | Mouse entered slot |
| `SlotMouseExited` | Mouse exited slot |
| `DragCancelled` | Drag operation cancelled |
| `Dropped` | Element was dropped |
| `SlotMouseDragCompleted` | Slot drag completed |
| `SlotMouseDragExited` | Slot drag exited |
| `SlotClickReleaseWhileDragging` | Slot click released while dragging |
| `SlotClickPressWhileDragging` | Slot click pressed while dragging |
| `SelectedTabChanged` | Tab selection changed |

```java
import com.hypixel.hytale.protocol.packets.interface_.CustomUIEventBindingType;
```

### Basic Event Binding

```java
import com.hypixel.hytale.protocol.packets.interface_.CustomUIEventBindingType;

// Simple activation (click) binding
eventBuilder.addEventBinding(CustomUIEventBindingType.Activating, "#my-button");

// Value change binding for inputs
eventBuilder.addEventBinding(CustomUIEventBindingType.ValueChanged, "#slider");

// With explicit locking behavior (second parameter)
eventBuilder.addEventBinding(CustomUIEventBindingType.Activating, "#button", true); // locks interface
```

### Events with Data

```java
import com.hypixel.hytale.server.core.ui.builder.EventData;

// Create event data (all values are stored as strings)
EventData data = new EventData()
    .append("action", "submit")
    .append("itemId", "123")
    .append("quantity", "5");  // Note: numeric values must be strings

// Bind with data
eventBuilder.addEventBinding(CustomUIEventBindingType.Activating, "#submit-btn", data);
```

### Non-Locking Events

By default, events lock the UI until the server responds (the `locksInterface` parameter defaults to `true`). For responsive UIs that shouldn't wait for server response, set `locksInterface` to `false`:

```java
// Non-locking event (doesn't block UI while waiting for server)
eventBuilder.addEventBinding(
    CustomUIEventBindingType.ValueChanged,
    "#slider",
    data,
    false  // locksInterface = false
);
```

### Getting Event Bindings

```java
// Get array of bindings
CustomUIEventBinding[] bindings = eventBuilder.getEvents();

// Empty array constant (useful when no events needed)
CustomUIEventBinding[] empty = UIEventBuilder.EMPTY_EVENT_BINDING_ARRAY;
```

## EventData

`EventData` is a record that wraps a `Map<String, String>` for passing key-value parameters with events.

```java
public record EventData(Map<String, String> events) { ... }
```

### Creating EventData

```java
import com.hypixel.hytale.server.core.ui.builder.EventData;

// Create empty event data using no-arg constructor
EventData data = new EventData()
    .append("key1", "value1")
    .append("key2", "value2")
    .append("count", "42");

// Create with initial value using factory method
EventData data = EventData.of("action", "confirm");

// Append enum values (converted to enum name string)
data.append("direction", Direction.NORTH);  // stores "NORTH"

// Create with an existing map
Map<String, String> existingMap = new HashMap<>();
existingMap.put("key", "value");
EventData data = new EventData(existingMap);
```

### Available Methods

| Method | Description |
|--------|-------------|
| `new EventData()` | Create empty event data (uses `Object2ObjectOpenHashMap` internally) |
| `new EventData(Map<String, String>)` | Create with an existing map |
| `EventData.of(String key, String value)` | Factory method to create with initial key-value pair |
| `append(String key, String value)` | Add a string value (returns `this` for chaining) |
| `append(String key, Enum<?> enumValue)` | Add an enum value (stored as `enumValue.name()`) |
| `put(String key, String value)` | Alias for `append` (returns `this` for chaining) |
| `events()` | Get the underlying `Map<String, String>` |

### Supported Value Types

All values are stored as strings in the underlying map:

- `String` - Text values (stored directly)
- `Enum<T>` - Enum constants (serialized via `name()` method)

## Complete Example

A custom interactive page with event handling:

```java
import com.hypixel.hytale.codec.builder.BuilderCodec;
import com.hypixel.hytale.component.Ref;
import com.hypixel.hytale.component.Store;
import com.hypixel.hytale.protocol.packets.interface_.CustomPageLifetime;
import com.hypixel.hytale.protocol.packets.interface_.CustomUIEventBindingType;
import com.hypixel.hytale.server.core.entity.entities.player.pages.InteractiveCustomUIPage;
import com.hypixel.hytale.server.core.ui.builder.EventData;
import com.hypixel.hytale.server.core.ui.builder.UICommandBuilder;
import com.hypixel.hytale.server.core.ui.builder.UIEventBuilder;
import com.hypixel.hytale.server.core.universe.PlayerRef;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;

import java.util.List;

public class ShopPage extends InteractiveCustomUIPage<ShopEventData> {

    private final List<ShopItem> items;

    public ShopPage(PlayerRef playerRef, List<ShopItem> items, BuilderCodec<ShopEventData> codec) {
        super(playerRef, CustomPageLifetime.CanDismiss, codec);
        this.items = items;
    }

    @Override
    public void build(Ref<EntityStore> ref, UICommandBuilder commands,
                      UIEventBuilder events, Store<EntityStore> store) {
        // Load page template
        commands.append("Pages/ShopPage.ui");
        commands.set("#shop-title", "Item Shop");

        // Add items dynamically
        for (int i = 0; i < items.size(); i++) {
            ShopItem item = items.get(i);

            // Append item template
            commands.append("#item-list", "Components/ShopItem.ui");
            commands.set("#item-" + i + "-name", item.getName());
            commands.set("#item-" + i + "-price", item.getPrice() + " coins");

            // Bind purchase event (note: index must be string)
            events.addEventBinding(
                CustomUIEventBindingType.Activating,
                "#buy-btn-" + i,
                EventData.of("action", "buy").append("index", String.valueOf(i))
            );
        }

        // Bind close button
        events.addEventBinding(CustomUIEventBindingType.Activating, "#close-btn");
    }

    @Override
    public void handleDataEvent(Ref<EntityStore> ref, Store<EntityStore> store,
                                ShopEventData data) {
        if ("buy".equals(data.action())) {
            int index = Integer.parseInt(data.index());
            ShopItem item = items.get(index);
            // Process purchase...

            // Update UI
            UICommandBuilder update = new UICommandBuilder();
            update.set("#balance", newBalance + " coins");
            sendUpdate(update, null, false);
        } else {
            close();
        }
    }
}
```

### CustomPageLifetime Options

The `CustomPageLifetime` enum controls how the page can be closed:

| Value | Description |
|-------|-------------|
| `CantClose` | Page cannot be closed by user |
| `CanDismiss` | Page can be dismissed (e.g., pressing Escape) |
| `CanDismissOrCloseThroughInteraction` | Page can be dismissed or closed through in-game interaction |

## Best Practices

1. **Batch updates** - Combine multiple `set()` calls in one builder
2. **Use non-locking events** for frequent updates like sliders
3. **Reference styles** from Common.ui for consistency
4. **Clear before append** when replacing dynamic content
5. **Handle event data validation** - clients can send malformed data
