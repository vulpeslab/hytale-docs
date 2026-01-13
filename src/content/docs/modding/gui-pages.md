---
title: Custom Pages System
description: Create and manage custom GUI pages for player interactions in your Hytale server plugins.
sidebar:
  order: 18
---

The Custom Pages System allows you to create fully customizable GUI interfaces for players. This includes interactive dialogs, settings pages, choice menus, shop interfaces, and more.

## Architecture

```
PageManager (Per-Player)
├── Standard Pages (Page enum)
│   └── None, Bench, Inventory, ToolsSettings, Map, etc.
└── Custom Pages (CustomUIPage hierarchy)
    ├── BasicCustomUIPage     - Simple display-only pages
    ├── InteractiveCustomUIPage<T> - Pages with event handling
    └── ChoiceBasePage        - Choice/dialog pages

UICommandBuilder - Build UI element commands
UIEventBuilder   - Bind events to UI elements
EventData        - Pass data with events
Value<T>         - Reference UI document values
```

## PageManager

The `PageManager` handles opening, closing, and updating pages for each player. Access it through the `Player` component.

### Key Methods

| Method | Description |
|--------|-------------|
| `setPage(ref, store, page)` | Set a standard page (from Page enum) |
| `setPage(ref, store, page, canClose)` | Set page with close-through-interaction option |
| `openCustomPage(ref, store, customPage)` | Open a custom UI page |
| `openCustomPageWithWindows(ref, store, page, windows...)` | Open custom page with inventory windows |
| `updateCustomPage(customPage)` | Send updates to the current custom page |
| `handleEvent(ref, store, event)` | Process incoming page events |
| `getCustomPage()` | Get the currently open custom page |

### Standard Page Enum

The `Page` enum defines built-in page types:

| Value | Description |
|-------|-------------|
| `None` | No page open (closes current page) |
| `Bench` | Crafting bench interface |
| `Inventory` | Player inventory |
| `ToolsSettings` | Tool settings interface |
| `Map` | World map |
| `MachinimaEditor` | Machinima editing tools |
| `ContentCreation` | Content creation tools |
| `Custom` | Custom page (used internally) |

### Page Acknowledgment System

The PageManager uses an acknowledgment system to ensure UI updates are processed in order. When a custom page is opened or updated, the client must acknowledge receipt before data events are processed. This prevents race conditions between UI updates and user interactions.

```java
// Internal tracking - handled automatically
private final AtomicInteger customPageRequiredAcknowledgments = new AtomicInteger();
```

### Opening a Standard Page

```java
Player playerComponent = store.getComponent(ref, Player.getComponentType());
PageManager pageManager = playerComponent.getPageManager();

// Open inventory
pageManager.setPage(ref, store, Page.Inventory);

// Open page that can be closed by clicking elsewhere
pageManager.setPage(ref, store, Page.Bench, true);

// Close any open page
pageManager.setPage(ref, store, Page.None);
```

## CustomUIPage Hierarchy

### CustomUIPage (Base Class)

The abstract base class for all custom pages.

```java
public abstract class CustomUIPage {
    protected final PlayerRef playerRef;
    protected CustomPageLifetime lifetime;

    // Must implement - builds the initial page UI
    public abstract void build(
        Ref<EntityStore> ref,
        UICommandBuilder commandBuilder,
        UIEventBuilder eventBuilder,
        Store<EntityStore> store
    );

    // Override to handle raw data events (use InteractiveCustomUIPage instead)
    public void handleDataEvent(Ref<EntityStore> ref, Store<EntityStore> store, String rawData);

    // Override for cleanup when page is dismissed
    public void onDismiss(Ref<EntityStore> ref, Store<EntityStore> store);

    // Rebuild the entire page UI
    protected void rebuild();

    // Send partial updates to the page
    protected void sendUpdate();
    protected void sendUpdate(UICommandBuilder commandBuilder);
    protected void sendUpdate(UICommandBuilder commandBuilder, boolean clear);

    // Close this page (sets page to None)
    protected void close();
}
```

### CustomPageLifetime Enum

Controls how the page can be closed:

| Value | Description |
|-------|-------------|
| `CantClose` | Player cannot close the page (e.g., death screen) |
| `CanDismiss` | Player can dismiss with escape key |
| `CanDismissOrCloseThroughInteraction` | Can dismiss or close by clicking outside |

### BasicCustomUIPage

For simple pages that don't need event handling:

```java
public abstract class BasicCustomUIPage extends CustomUIPage {
    public BasicCustomUIPage(PlayerRef playerRef, CustomPageLifetime lifetime) {
        super(playerRef, lifetime);
    }

    // Simplified build method - no event builder needed
    public abstract void build(UICommandBuilder commandBuilder);
}
```

### InteractiveCustomUIPage<T>

For pages that handle user interactions. The generic type `T` represents your event data class:

```java
public abstract class InteractiveCustomUIPage<T> extends CustomUIPage {
    protected final BuilderCodec<T> eventDataCodec;

    public InteractiveCustomUIPage(
        PlayerRef playerRef,
        CustomPageLifetime lifetime,
        BuilderCodec<T> eventDataCodec
    ) {
        super(playerRef, lifetime);
        this.eventDataCodec = eventDataCodec;
    }

    // Override to handle typed event data
    public void handleDataEvent(Ref<EntityStore> ref, Store<EntityStore> store, T data);

    // Extended sendUpdate with event builder support
    protected void sendUpdate(
        UICommandBuilder commandBuilder,
        UIEventBuilder eventBuilder,
        boolean clear
    );
}
```

## UICommandBuilder

Build UI manipulation commands to send to the client.

### Command Types

| Type | Description |
|------|-------------|
| `Append` | Add elements from a document path |
| `AppendInline` | Add elements from inline UI definition |
| `InsertBefore` | Insert elements before a selector |
| `InsertBeforeInline` | Insert inline elements before a selector |
| `Remove` | Remove elements matching selector |
| `Set` | Set property value on elements |
| `Clear` | Clear children of elements |

### Methods

```java
UICommandBuilder builder = new UICommandBuilder();

// Append UI document to page or container
builder.append("Pages/MyPage.ui");
builder.append("#Container", "Components/Button.ui");

// Append inline UI definition
builder.appendInline("#List", "Label { Text: Hello; }");

// Insert before element
builder.insertBefore("#ExistingElement", "Components/Header.ui");
builder.insertBeforeInline("#Footer", "Divider { }");

// Remove elements
builder.remove("#ElementToRemove");

// Clear container children
builder.clear("#ListContainer");

// Set property values
builder.set("#Label.Text", "Hello World");
builder.set("#Checkbox.Value", true);
builder.set("#Slider.Value", 50);
builder.set("#Input.Value", 3.14);
builder.set("#Element.Visible", false);

// Set with Message (for localization)
builder.set("#Title.TextSpans", Message.translation("my.translation.key"));
builder.set("#Desc.TextSpans", Message.raw("Plain text"));

// Set null value
builder.setNull("#OptionalField.Value");

// Set arrays
builder.set("#Dropdown.Entries", dropdownEntries);

// Set with Value reference (for document references)
builder.set("#Button.Style", Value.ref("Common/Button.ui", "DefaultStyle"));
```

## UIEventBuilder

Bind events to UI elements so the server receives callbacks when users interact.

### Event Binding Types

| Type | Description |
|------|-------------|
| `Activating` | Element clicked/activated |
| `RightClicking` | Right mouse button click |
| `DoubleClicking` | Double click |
| `MouseEntered` | Mouse enters element |
| `MouseExited` | Mouse leaves element |
| `ValueChanged` | Input value changed |
| `ElementReordered` | Drag-reorder completed |
| `Validating` | Input validation |
| `Dismissing` | Page being dismissed |
| `FocusGained` | Element gained focus |
| `FocusLost` | Element lost focus |
| `KeyDown` | Key pressed |
| `MouseButtonReleased` | Mouse button released |
| `SlotClicking` | Inventory slot clicked |
| `SlotDoubleClicking` | Inventory slot double-clicked |
| `SlotMouseEntered` | Mouse enters slot |
| `SlotMouseExited` | Mouse exits slot |
| `DragCancelled` | Drag operation cancelled |
| `Dropped` | Drop completed |
| `SelectedTabChanged` | Tab selection changed |

### Methods

```java
UIEventBuilder eventBuilder = new UIEventBuilder();

// Simple event binding (locks interface while processing)
eventBuilder.addEventBinding(CustomUIEventBindingType.Activating, "#Button");

// With custom data
eventBuilder.addEventBinding(
    CustomUIEventBindingType.Activating,
    "#SaveButton",
    EventData.of("Action", "Save")
);

// Without interface lock (for real-time updates)
eventBuilder.addEventBinding(
    CustomUIEventBindingType.ValueChanged,
    "#SearchInput",
    EventData.of("@Query", "#SearchInput.Value"),
    false  // Don't lock interface
);

// Complex event data with multiple fields
eventBuilder.addEventBinding(
    CustomUIEventBindingType.Activating,
    "#SubmitButton",
    new EventData()
        .append("Action", "Submit")
        .append("@Name", "#NameInput.Value")
        .append("@Amount", "#AmountSlider.Value")
        .append("@Enabled", "#EnableCheckbox.Value"),
    true  // Lock interface
);
```

### Event Data Keys

- **Static keys** (e.g., `"Action"`, `"Index"`) - Sent as literal string values
- **Reference keys** (prefixed with `@`, e.g., `"@Name"`) - Reference UI element values at event time

## EventData

Create key-value pairs to send with events.

```java
// Single key-value
EventData data = EventData.of("Action", "Save");

// Multiple values with chaining
EventData data = new EventData()
    .append("Type", "Update")
    .append("Index", "5")
    .append("@Value", "#Input.Value");

// Enum values
EventData data = new EventData()
    .append("Mode", MyEnum.OPTION_A);  // Sends enum name as string
```

## Value<T>

Reference values from UI documents or provide direct values.

```java
// Reference a value defined in a UI document
Value<String> styleRef = Value.ref("Common/Button.ui", "DefaultStyle");

// Direct value
Value<String> directValue = Value.of("my-value");

// Use with UICommandBuilder.set() for references
commandBuilder.set("#Button.Style", styleRef);
```

## ChoiceBasePage

A specialized interactive page for presenting choices to players, commonly used for shops, dialogs, and selection menus.

### Structure

```java
public abstract class ChoiceBasePage extends InteractiveCustomUIPage<ChoicePageEventData> {
    private final ChoiceElement[] elements;
    private final String pageLayout;

    public ChoiceBasePage(PlayerRef playerRef, ChoiceElement[] elements, String pageLayout) {
        super(playerRef, CustomPageLifetime.CanDismiss, ChoicePageEventData.CODEC);
        // ...
    }
}
```

### ChoiceElement

Base class for choice options:

```java
public abstract class ChoiceElement {
    protected String displayNameKey;      // Localization key for display name
    protected String descriptionKey;      // Localization key for description
    protected ChoiceInteraction[] interactions;  // Actions when selected
    protected ChoiceRequirement[] requirements;  // Requirements to select

    // Implement to render the choice button
    public abstract void addButton(
        UICommandBuilder commandBuilder,
        UIEventBuilder eventBuilder,
        String selector,
        PlayerRef playerRef
    );

    // Check if player meets requirements
    public boolean canFulfillRequirements(Store<EntityStore> store, Ref<EntityStore> ref, PlayerRef playerRef);
}
```

### ChoiceInteraction

Actions executed when a choice is selected:

```java
public abstract class ChoiceInteraction {
    public abstract void run(Store<EntityStore> store, Ref<EntityStore> ref, PlayerRef playerRef);
}
```

### ChoiceRequirement

Conditions that must be met to select a choice:

```java
public abstract class ChoiceRequirement {
    public abstract boolean canFulfillRequirement(
        Store<EntityStore> store,
        Ref<EntityStore> ref,
        PlayerRef playerRef
    );
}
```

### ChoicePageEventData

Event data sent when a choice is selected:

```java
public static class ChoicePageEventData {
    private int index;  // Index of selected choice

    public int getIndex() {
        return this.index;
    }
}
```

## Complete Examples

### Basic Information Page

A simple page that displays information without interaction:

```java
import com.hypixel.hytale.protocol.packets.interface_.CustomPageLifetime;
import com.hypixel.hytale.server.core.Message;
import com.hypixel.hytale.server.core.entity.entities.player.pages.BasicCustomUIPage;
import com.hypixel.hytale.server.core.ui.builder.UICommandBuilder;
import com.hypixel.hytale.server.core.universe.PlayerRef;

public class WelcomePage extends BasicCustomUIPage {

    private static final String LAYOUT = "Pages/WelcomePage.ui";
    private final String playerName;
    private final int onlineCount;

    public WelcomePage(PlayerRef playerRef, String playerName, int onlineCount) {
        super(playerRef, CustomPageLifetime.CanDismiss);
        this.playerName = playerName;
        this.onlineCount = onlineCount;
    }

    @Override
    public void build(UICommandBuilder commandBuilder) {
        commandBuilder.append(LAYOUT);
        commandBuilder.set("#Title.TextSpans",
            Message.translation("welcome.title").param("player", playerName));
        commandBuilder.set("#OnlineCount.Text", String.valueOf(onlineCount));
        commandBuilder.set("#ServerTime.Text", java.time.LocalTime.now().toString());
    }
}
```

**Opening the page:**

```java
Player playerComponent = store.getComponent(ref, Player.getComponentType());
PlayerRef playerRef = store.getComponent(ref, PlayerRef.getComponentType());

WelcomePage page = new WelcomePage(playerRef, player.getDisplayName(), onlinePlayerCount);
playerComponent.getPageManager().openCustomPage(ref, store, page);
```

### Interactive Settings Page

A page with form inputs and event handling:

```java
import com.hypixel.hytale.codec.Codec;
import com.hypixel.hytale.codec.KeyedCodec;
import com.hypixel.hytale.codec.builder.BuilderCodec;
import com.hypixel.hytale.component.Ref;
import com.hypixel.hytale.component.Store;
import com.hypixel.hytale.protocol.packets.interface_.CustomPageLifetime;
import com.hypixel.hytale.protocol.packets.interface_.CustomUIEventBindingType;
import com.hypixel.hytale.protocol.packets.interface_.Page;
import com.hypixel.hytale.server.core.Message;
import com.hypixel.hytale.server.core.entity.entities.Player;
import com.hypixel.hytale.server.core.entity.entities.player.pages.InteractiveCustomUIPage;
import com.hypixel.hytale.server.core.ui.builder.EventData;
import com.hypixel.hytale.server.core.ui.builder.UICommandBuilder;
import com.hypixel.hytale.server.core.ui.builder.UIEventBuilder;
import com.hypixel.hytale.server.core.universe.PlayerRef;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;

public class PlayerSettingsPage extends InteractiveCustomUIPage<PlayerSettingsPage.SettingsEventData> {

    private static final String LAYOUT = "Pages/PlayerSettings.ui";
    private boolean notificationsEnabled;
    private int renderDistance;

    public PlayerSettingsPage(PlayerRef playerRef, boolean notifications, int renderDistance) {
        super(playerRef, CustomPageLifetime.CanDismissOrCloseThroughInteraction, SettingsEventData.CODEC);
        this.notificationsEnabled = notifications;
        this.renderDistance = renderDistance;
    }

    @Override
    public void build(Ref<EntityStore> ref, UICommandBuilder commandBuilder,
                      UIEventBuilder eventBuilder, Store<EntityStore> store) {
        commandBuilder.append(LAYOUT);

        // Set initial values
        commandBuilder.set("#NotificationsToggle.Value", notificationsEnabled);
        commandBuilder.set("#RenderDistanceSlider.Value", renderDistance);
        commandBuilder.set("#RenderDistanceLabel.Text", String.valueOf(renderDistance));

        // Bind events
        eventBuilder.addEventBinding(
            CustomUIEventBindingType.ValueChanged,
            "#RenderDistanceSlider",
            EventData.of("@RenderDistance", "#RenderDistanceSlider.Value"),
            false  // Don't lock - allow real-time updates
        );

        eventBuilder.addEventBinding(
            CustomUIEventBindingType.Activating,
            "#SaveButton",
            new EventData()
                .append("Action", "Save")
                .append("@Notifications", "#NotificationsToggle.Value")
                .append("@RenderDistance", "#RenderDistanceSlider.Value")
        );

        eventBuilder.addEventBinding(
            CustomUIEventBindingType.Activating,
            "#CancelButton",
            EventData.of("Action", "Cancel")
        );
    }

    @Override
    public void handleDataEvent(Ref<EntityStore> ref, Store<EntityStore> store,
                                 SettingsEventData data) {
        // Handle real-time slider updates
        if (data.renderDistance != null && data.action == null) {
            UICommandBuilder builder = new UICommandBuilder();
            builder.set("#RenderDistanceLabel.Text", String.valueOf(data.renderDistance));
            sendUpdate(builder);
            return;
        }

        // Handle button actions
        if (data.action == null) return;

        Player playerComponent = store.getComponent(ref, Player.getComponentType());

        switch (data.action) {
            case "Save":
                // Save settings
                this.notificationsEnabled = data.notifications != null && data.notifications;
                this.renderDistance = data.renderDistance != null ? data.renderDistance : 8;

                // Apply settings to player...
                playerComponent.sendMessage(Message.translation("settings.saved"));
                playerComponent.getPageManager().setPage(ref, store, Page.None);
                break;

            case "Cancel":
                playerComponent.getPageManager().setPage(ref, store, Page.None);
                break;
        }
    }

    // Event data class with codec
    public static class SettingsEventData {
        public static final BuilderCodec<SettingsEventData> CODEC = ((BuilderCodec.Builder)
            ((BuilderCodec.Builder)((BuilderCodec.Builder)BuilderCodec.builder(
                SettingsEventData.class, SettingsEventData::new)
                .append(new KeyedCodec<>("Action", Codec.STRING),
                    (d, v) -> d.action = v, d -> d.action).add())
                .append(new KeyedCodec<>("@Notifications", Codec.BOOLEAN),
                    (d, v) -> d.notifications = v, d -> d.notifications).add())
                .append(new KeyedCodec<>("@RenderDistance", Codec.INTEGER),
                    (d, v) -> d.renderDistance = v, d -> d.renderDistance).add())
            .build();

        private String action;
        private Boolean notifications;
        private Integer renderDistance;
    }
}
```

### Choice Dialog Page

A dialog presenting multiple choices to the player:

```java
import com.hypixel.hytale.component.Ref;
import com.hypixel.hytale.component.Store;
import com.hypixel.hytale.server.core.Message;
import com.hypixel.hytale.server.core.entity.entities.player.pages.choices.ChoiceBasePage;
import com.hypixel.hytale.server.core.entity.entities.player.pages.choices.ChoiceElement;
import com.hypixel.hytale.server.core.entity.entities.player.pages.choices.ChoiceInteraction;
import com.hypixel.hytale.server.core.entity.entities.player.pages.choices.ChoiceRequirement;
import com.hypixel.hytale.server.core.ui.builder.UICommandBuilder;
import com.hypixel.hytale.server.core.ui.builder.UIEventBuilder;
import com.hypixel.hytale.server.core.universe.PlayerRef;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;

public class QuestDialogPage extends ChoiceBasePage {

    public QuestDialogPage(PlayerRef playerRef, String questId) {
        super(playerRef, createChoices(questId), "Pages/QuestDialog.ui");
    }

    private static ChoiceElement[] createChoices(String questId) {
        return new ChoiceElement[] {
            new QuestChoiceElement(
                "quest.accept.title",
                "quest.accept.description",
                new ChoiceInteraction[] { new AcceptQuestInteraction(questId) },
                null  // No requirements
            ),
            new QuestChoiceElement(
                "quest.decline.title",
                "quest.decline.description",
                new ChoiceInteraction[] { new DeclineQuestInteraction(questId) },
                null
            ),
            new QuestChoiceElement(
                "quest.later.title",
                "quest.later.description",
                new ChoiceInteraction[] { new ClosePageInteraction() },
                null
            )
        };
    }
}

// Custom choice element
class QuestChoiceElement extends ChoiceElement {

    public QuestChoiceElement(String displayKey, String descKey,
                              ChoiceInteraction[] interactions,
                              ChoiceRequirement[] requirements) {
        super(displayKey, descKey, interactions, requirements);
    }

    @Override
    public void addButton(UICommandBuilder commandBuilder, UIEventBuilder eventBuilder,
                          String selector, PlayerRef playerRef) {
        commandBuilder.append(selector, "Components/QuestChoiceButton.ui");
        commandBuilder.set(selector + " #Title.TextSpans",
            Message.translation(displayNameKey));
        commandBuilder.set(selector + " #Description.TextSpans",
            Message.translation(descriptionKey));
    }
}

// Interaction implementations
class AcceptQuestInteraction extends ChoiceInteraction {
    private final String questId;

    public AcceptQuestInteraction(String questId) {
        this.questId = questId;
    }

    @Override
    public void run(Store<EntityStore> store, Ref<EntityStore> ref, PlayerRef playerRef) {
        // Start the quest for the player
        // QuestManager.startQuest(playerRef, questId);
        playerRef.sendMessage(Message.translation("quest.accepted"));
    }
}

class DeclineQuestInteraction extends ChoiceInteraction {
    private final String questId;

    public DeclineQuestInteraction(String questId) {
        this.questId = questId;
    }

    @Override
    public void run(Store<EntityStore> store, Ref<EntityStore> ref, PlayerRef playerRef) {
        playerRef.sendMessage(Message.translation("quest.declined"));
    }
}

class ClosePageInteraction extends ChoiceInteraction {
    @Override
    public void run(Store<EntityStore> store, Ref<EntityStore> ref, PlayerRef playerRef) {
        // Page will close automatically after interaction
    }
}
```

### Page Supplier Pattern

For pages triggered by block/entity interactions, use a supplier:

```java
import com.hypixel.hytale.codec.Codec;
import com.hypixel.hytale.codec.KeyedCodec;
import com.hypixel.hytale.codec.builder.BuilderCodec;
import com.hypixel.hytale.component.ComponentAccessor;
import com.hypixel.hytale.component.Ref;
import com.hypixel.hytale.server.core.entity.InteractionContext;
import com.hypixel.hytale.server.core.entity.entities.player.pages.CustomUIPage;
import com.hypixel.hytale.server.core.modules.interaction.interaction.config.server.OpenCustomUIInteraction;
import com.hypixel.hytale.server.core.universe.PlayerRef;
import com.hypixel.hytale.server.core.universe.world.storage.EntityStore;

public class MyPageSupplier implements OpenCustomUIInteraction.CustomPageSupplier {

    public static final BuilderCodec<MyPageSupplier> CODEC = ((BuilderCodec.Builder)
        BuilderCodec.builder(MyPageSupplier.class, MyPageSupplier::new)
            .appendInherited(new KeyedCodec<>("ConfigId", Codec.STRING),
                (data, o) -> data.configId = o,
                data -> data.configId,
                (data, parent) -> data.configId = parent.configId)
            .add())
        .build();

    protected String configId;

    @Override
    public CustomUIPage tryCreate(Ref<EntityStore> ref,
                                   ComponentAccessor<EntityStore> componentAccessor,
                                   PlayerRef playerRef,
                                   InteractionContext context) {
        // Create and return the page instance
        return new MyConfigPage(playerRef, configId);
    }
}
```

## Updating Pages Dynamically

### Partial Updates

Send incremental changes without rebuilding the entire page:

```java
// In your InteractiveCustomUIPage subclass
private void updateScore(int newScore) {
    UICommandBuilder builder = new UICommandBuilder();
    builder.set("#ScoreLabel.Text", String.valueOf(newScore));
    sendUpdate(builder);
}

// With event bindings update
private void addNewListItem(String itemName) {
    UICommandBuilder commandBuilder = new UICommandBuilder();
    UIEventBuilder eventBuilder = new UIEventBuilder();

    int index = items.size();
    String selector = "#ItemList[" + index + "]";

    commandBuilder.append("#ItemList", "Components/ListItem.ui");
    commandBuilder.set(selector + " #Name.Text", itemName);

    eventBuilder.addEventBinding(
        CustomUIEventBindingType.Activating,
        selector,
        EventData.of("Index", String.valueOf(index)),
        false
    );

    sendUpdate(commandBuilder, eventBuilder, false);
}
```

### Full Rebuild

When many things change, rebuild the entire page:

```java
private void refreshPage() {
    rebuild();  // Calls build() again and sends full update
}
```

### Clearing and Updating

```java
// Clear list then repopulate
private void refreshList(List<String> items) {
    UICommandBuilder builder = new UICommandBuilder();
    UIEventBuilder eventBuilder = new UIEventBuilder();

    builder.clear("#ItemList");

    for (int i = 0; i < items.size(); i++) {
        String selector = "#ItemList[" + i + "]";
        builder.append("#ItemList", "Components/ListItem.ui");
        builder.set(selector + " #Label.Text", items.get(i));
        eventBuilder.addEventBinding(
            CustomUIEventBindingType.Activating,
            selector,
            EventData.of("Index", String.valueOf(i))
        );
    }

    sendUpdate(builder, eventBuilder, false);
}
```

## Best Practices

1. **Use appropriate lifetime** - Choose `CantClose` only when necessary (e.g., death screen)
2. **Don't lock for real-time updates** - Set `locksInterface=false` for sliders and search inputs
3. **Validate on server** - Never trust client data; always validate in `handleDataEvent`
4. **Use translation keys** - Use `Message.translation()` for localizable text
5. **Handle dismissal** - Override `onDismiss()` for cleanup when pages are closed
6. **Use reference keys** - Prefix with `@` to read UI values at event time
7. **Batch updates** - Combine multiple `set()` calls in one `sendUpdate()`
8. **Check validity** - Verify entity references are valid before processing events
9. **Use suppliers** - Implement `CustomPageSupplier` for interaction-triggered pages
10. **Define codecs properly** - Create `BuilderCodec` for your event data classes
