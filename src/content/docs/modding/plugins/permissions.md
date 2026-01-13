---
title: Permissions and Access Control
description: Implement permission-based access control in your Hytale server plugins.
sidebar:
  order: 5
---

The Hytale permission system provides fine-grained access control for server features, commands, and custom functionality. It supports user-level permissions, group-based inheritance, and wildcard matching.

## Architecture

```
PermissionsModule (Core)
├── PermissionProvider (Interface)
│   └── HytalePermissionsProvider (Default Implementation)
├── Permission Groups (OP, Default, Custom)
├── User Permissions (Per-UUID)
└── Virtual Groups (GameMode-based)

PermissionHolder (Interface)
├── Player (Entity)
└── CommandSender (Commands)
```

## Core Interfaces

### PermissionHolder

The base interface for any entity that can hold permissions:

```java
import com.hypixel.hytale.server.core.permissions.PermissionHolder;

public interface PermissionHolder {
    boolean hasPermission(@Nonnull String id);
    boolean hasPermission(@Nonnull String id, boolean defaultValue);
}
```

Both `Player` and `CommandSender` implement this interface, allowing consistent permission checking across commands and gameplay logic.

### PermissionProvider

Custom permission backends implement this interface:

```java
import com.hypixel.hytale.server.core.permissions.provider.PermissionProvider;

public interface PermissionProvider {
    @Nonnull String getName();

    // User permissions
    void addUserPermissions(@Nonnull UUID uuid, @Nonnull Set<String> permissions);
    void removeUserPermissions(@Nonnull UUID uuid, @Nonnull Set<String> permissions);
    Set<String> getUserPermissions(@Nonnull UUID uuid);

    // Group permissions
    void addGroupPermissions(@Nonnull String group, @Nonnull Set<String> permissions);
    void removeGroupPermissions(@Nonnull String group, @Nonnull Set<String> permissions);
    Set<String> getGroupPermissions(@Nonnull String group);

    // User-group membership
    void addUserToGroup(@Nonnull UUID uuid, @Nonnull String group);
    void removeUserFromGroup(@Nonnull UUID uuid, @Nonnull String group);
    Set<String> getGroupsForUser(@Nonnull UUID uuid);
}
```

## Permission Syntax

### Permission Nodes

Permissions use a dot-separated hierarchical format:

```
namespace.category.action
```

Examples:
- `hytale.command.gamemode.self` - Change own game mode
- `hytale.command.gamemode.other` - Change another player's game mode
- `hytale.editor.brush.use` - Use brush tools
- `myplugin.admin.kick` - Custom plugin permission

### Wildcards

The system supports wildcard permissions for granting broad access:

| Pattern | Description |
|---------|-------------|
| `*` | All permissions (full access) |
| `hytale.*` | All hytale namespace permissions |
| `hytale.command.*` | All command permissions |
| `myplugin.admin.*` | All admin permissions for myplugin |

### Negation

Prefix permissions with `-` to explicitly deny:

| Pattern | Description |
|---------|-------------|
| `-*` | Deny all permissions |
| `-hytale.command.kick` | Explicitly deny kick permission |
| `-myplugin.admin.*` | Deny all admin permissions |

Negations take precedence and can override inherited group permissions.

## Built-in Permissions

### HytalePermissions Class

The `HytalePermissions` class defines standard permission constants:

```java
import com.hypixel.hytale.server.core.permissions.HytalePermissions;

public class HytalePermissions {
    public static final String NAMESPACE = "hytale";
    public static final String COMMAND_BASE = "hytale.command";

    // Asset editor permissions
    public static final String ASSET_EDITOR = "hytale.editor.asset";
    public static final String ASSET_EDITOR_PACKS_CREATE = "hytale.editor.packs.create";
    public static final String ASSET_EDITOR_PACKS_EDIT = "hytale.editor.packs.edit";
    public static final String ASSET_EDITOR_PACKS_DELETE = "hytale.editor.packs.delete";

    // Builder tools permissions
    public static final String BUILDER_TOOLS_EDITOR = "hytale.editor.builderTools";

    // Brush permissions
    public static final String EDITOR_BRUSH_USE = "hytale.editor.brush.use";
    public static final String EDITOR_BRUSH_CONFIG = "hytale.editor.brush.config";

    // Prefab permissions
    public static final String EDITOR_PREFAB_USE = "hytale.editor.prefab.use";
    public static final String EDITOR_PREFAB_MANAGE = "hytale.editor.prefab.manage";

    // Selection permissions
    public static final String EDITOR_SELECTION_USE = "hytale.editor.selection.use";
    public static final String EDITOR_SELECTION_CLIPBOARD = "hytale.editor.selection.clipboard";
    public static final String EDITOR_SELECTION_MODIFY = "hytale.editor.selection.modify";

    // History permission
    public static final String EDITOR_HISTORY = "hytale.editor.history";

    // Camera permission
    public static final String FLY_CAM = "hytale.camera.flycam";

    // Helper methods for command permissions
    @Nonnull
    public static String fromCommand(@Nonnull String name) {
        return "hytale.command." + name;
    }

    @Nonnull
    public static String fromCommand(@Nonnull String name, @Nonnull String subCommand) {
        return "hytale.command." + name + "." + subCommand;
    }
}
```

### Common Command Permissions

| Permission | Description |
|------------|-------------|
| `hytale.command.gamemode.self` | Change own game mode |
| `hytale.command.gamemode.other` | Change another player's game mode |
| `hytale.command.give.self` | Give items to self |
| `hytale.command.give.other` | Give items to others |
| `hytale.command.teleport.*` | All teleport commands |
| `hytale.command.kick` | Kick players |
| `hytale.command.op.add` | Add players to OP group |
| `hytale.command.op.remove` | Remove players from OP group |

## Permission Groups

### Default Groups

The system includes two built-in groups defined in `HytalePermissionsProvider`:

```java
public static final String DEFAULT_GROUP = "Default";
public static final Set<String> DEFAULT_GROUP_LIST = Set.of("Default");
public static final String OP_GROUP = "OP";

// Default group permissions
public static final Map<String, Set<String>> DEFAULT_GROUPS = Map.ofEntries(
    Map.entry("OP", Set.of("*")),      // OP has all permissions
    Map.entry("Default", Set.of())      // Default has no special permissions
);
```

- **OP**: Has the `*` wildcard, granting all permissions
- **Default**: All players belong to this group by default (no special permissions). If a user has no explicit groups assigned, `getGroupsForUser()` returns `DEFAULT_GROUP_LIST`.

### Virtual Groups (GameMode-based)

The system automatically assigns virtual permissions based on game mode. Virtual groups are initialized during the `start()` phase of `PermissionsModule`:

```java
// In PermissionsModule.start()
Map<String, Set<String>> virtualGroups = CommandManager.get().createVirtualPermissionGroups();
virtualGroups.computeIfAbsent(
    GameMode.Creative.toString(),
    k -> new HashSet()
).add("hytale.editor.builderTools");
this.setVirtualGroups(virtualGroups);
```

Virtual groups are checked after user permissions and group permissions when evaluating `hasPermission()`.

## Using the PermissionsModule

### Getting the Module

```java
import com.hypixel.hytale.server.core.permissions.PermissionsModule;

PermissionsModule permissions = PermissionsModule.get();
```

### Checking Permissions

```java
UUID playerUuid = player.getUuid();

// Basic check (returns false if not set)
boolean canTeleport = permissions.hasPermission(playerUuid, "hytale.command.teleport");

// With default value
boolean canBuild = permissions.hasPermission(playerUuid, "myplugin.build", true);
```

### Managing User Permissions

```java
UUID playerUuid = player.getUuid();

// Add permissions
permissions.addUserPermission(playerUuid, Set.of(
    "myplugin.feature.use",
    "myplugin.feature.configure"
));

// Remove permissions
permissions.removeUserPermission(playerUuid, Set.of("myplugin.feature.configure"));
```

### Managing Groups

```java
UUID playerUuid = player.getUuid();

// Add player to group
permissions.addUserToGroup(playerUuid, "VIP");

// Remove player from group
permissions.removeUserFromGroup(playerUuid, "VIP");

// Get player's groups
Set<String> groups = permissions.getGroupsForUser(playerUuid);
```

## Checking Permissions in Commands

### Using requirePermission()

Set a required permission in the command constructor:

```java
public class MyCommand extends CommandBase {
    public MyCommand() {
        super("mycommand", "server.commands.mycommand.desc");
        requirePermission(HytalePermissions.fromCommand("mycommand"));
    }

    @Override
    protected void executeSync(@Nonnull CommandContext context) {
        // Only executed if player has hytale.command.mycommand
    }
}
```

### Manual Permission Check

```java
@Override
protected void executeSync(@Nonnull CommandContext context) {
    if (context.sender().hasPermission("myplugin.admin")) {
        // Admin-only logic
        performAdminAction();
    } else {
        // Regular user logic
        performUserAction();
    }
}
```

## Permission Events

### PlayerPermissionChangeEvent

Fired when a player's individual permissions change. The base class provides `getPlayerUuid()` and has several inner classes for specific events:

```java
import com.hypixel.hytale.server.core.event.events.permissions.PlayerPermissionChangeEvent;

// Listen for permissions added
getEventRegistry().register(
    PlayerPermissionChangeEvent.PermissionsAdded.class,
    event -> {
        UUID playerUuid = event.getPlayerUuid();
        Set<String> added = event.getAddedPermissions();
        getLogger().info("Player " + playerUuid + " gained: " + added);
    }
);

// Listen for permissions removed
getEventRegistry().register(
    PlayerPermissionChangeEvent.PermissionsRemoved.class,
    event -> {
        UUID playerUuid = event.getPlayerUuid();
        Set<String> removed = event.getRemovedPermissions();
        getLogger().info("Player " + playerUuid + " lost: " + removed);
    }
);
```

### PlayerGroupEvent

Fired when a player is added to or removed from a group. Extends `PlayerPermissionChangeEvent`:

```java
import com.hypixel.hytale.server.core.event.events.permissions.PlayerGroupEvent;

getEventRegistry().register(
    PlayerGroupEvent.Added.class,
    event -> {
        UUID playerUuid = event.getPlayerUuid();
        String group = event.getGroupName();
        getLogger().info("Player " + playerUuid + " joined group: " + group);
    }
);

getEventRegistry().register(
    PlayerGroupEvent.Removed.class,
    event -> {
        UUID playerUuid = event.getPlayerUuid();
        String group = event.getGroupName();
        getLogger().info("Player " + playerUuid + " left group: " + group);
    }
);
```

### GroupPermissionChangeEvent

Fired when a group's permissions are modified:

```java
import com.hypixel.hytale.server.core.event.events.permissions.GroupPermissionChangeEvent;

getEventRegistry().register(
    GroupPermissionChangeEvent.Added.class,
    event -> {
        String group = event.getGroupName();
        Set<String> added = event.getAddedPermissions();
        getLogger().info("Group " + group + " gained: " + added);
    }
);

getEventRegistry().register(
    GroupPermissionChangeEvent.Removed.class,
    event -> {
        String group = event.getGroupName();
        Set<String> removed = event.getRemovedPermissions();
        getLogger().info("Group " + group + " lost: " + removed);
    }
);
```

## Permission Configuration File

Permissions are stored in `permissions.json` in the server directory:

```json
{
  "users": {
    "550e8400-e29b-41d4-a716-446655440000": {
      "permissions": ["myplugin.vip", "myplugin.special"],
      "groups": ["VIP", "Moderator"]
    }
  },
  "groups": {
    "OP": ["*"],
    "Default": [],
    "VIP": ["myplugin.vip.*"],
    "Moderator": ["myplugin.mod.*", "hytale.command.kick"]
  }
}
```

## Built-in Permission Commands

### /op Commands

```
/op self             - Toggle own OP status (in singleplayer or with --allow-op flag)
/op add <player>     - Add player to OP group (requires hytale.command.op.add)
/op remove <player>  - Remove player from OP group (requires hytale.command.op.remove)
```

Note: The `/op self` command has special restrictions:
- In singleplayer, only the world owner can use it
- In multiplayer, the server must be started with `--allow-op` flag
- Does not work if custom permission providers are installed

### /perm Commands

```
/perm group list <group>                    - List group permissions
/perm group add <group> <permissions...>    - Add permissions to group
/perm group remove <group> <permissions...> - Remove permissions from group
/perm user list <uuid>                      - List user permissions
/perm user add <uuid> <permissions...>      - Add permissions to user
/perm user remove <uuid> <permissions...>   - Remove permissions from user
/perm user group list <uuid>                - List user's groups
/perm user group add <uuid> <group>         - Add user to group
/perm user group remove <uuid> <group>      - Remove user from group
/perm test <permission>                     - Test if you have a permission
```

## Best Practices

1. **Use hierarchical naming** - Structure permissions logically: `myplugin.category.action`
2. **Provide granular permissions** - Separate `self` and `other` variants for player-targeting actions
3. **Use groups for roles** - Define groups like `Admin`, `Moderator`, `VIP` rather than individual permissions
4. **React to permission changes** - Listen to permission events to enforce changes immediately
5. **Default to restrictive** - Use `hasPermission(id, false)` to default to denying access
6. **Document your permissions** - Create clear documentation of what each permission allows
7. **Use constants** - Define permission strings as constants to avoid typos
