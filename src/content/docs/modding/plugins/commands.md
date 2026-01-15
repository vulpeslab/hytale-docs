---
author: UnlimitedBytes
title: Command System
description: Create custom server commands for your Hytale plugin.
sidebar:
  order: 4
---

Create custom server commands for your plugin. The command system provides a flexible API for defining commands with required and optional arguments, subcommands, permissions, and more.

## Architecture

```
CommandManager (Singleton via CommandManager.get())
├── System Commands (server built-ins)
└── Plugin Commands (per-plugin via CommandRegistry)
    └── AbstractCommand
        ├── RequiredArg (positional arguments)
        ├── OptionalArg (--name value)
        ├── DefaultArg (--name value with default)
        ├── FlagArg (--flag boolean switches)
        ├── SubCommands (nested commands via addSubCommand)
        └── UsageVariants (commands with different argument counts via addUsageVariant)
```

## Creating Commands

### Simple Command

Commands extend `AbstractCommand` and implement the `execute` method which receives a `CommandContext`. The `execute` method returns a `CompletableFuture<Void>` (which can be `null` for synchronous commands):

```java
import com.hypixel.hytale.server.core.command.system.AbstractCommand;
import com.hypixel.hytale.server.core.command.system.CommandContext;
import com.hypixel.hytale.server.core.Message;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import java.util.concurrent.CompletableFuture;

public class HelloCommand extends AbstractCommand {

    public HelloCommand() {
        super("hello", "Says hello to a player");
    }

    @Override
    @Nullable
    protected CompletableFuture<Void> execute(@Nonnull CommandContext context) {
        context.sender().sendMessage(
            Message.raw("Hello, " + context.sender().getDisplayName() + "!")
        );
        return CompletableFuture.completedFuture(null);
    }
}
```

### Register Command

Register commands in your plugin's `setup()` method:

```java
@Override
protected void setup() {
    getCommandRegistry().registerCommand(new HelloCommand());
}
```

## Command Arguments

Arguments are registered in the constructor using fluent builder methods.

### Required Arguments

Required arguments are positional and must be provided by the user. Argument types are provided via the `ArgTypes` class:

```java
import com.hypixel.hytale.server.core.command.system.arguments.system.RequiredArg;
import com.hypixel.hytale.server.core.command.system.arguments.types.ArgTypes;

public class GiveCommand extends AbstractCommand {

    private final RequiredArg<String> playerArg;
    private final RequiredArg<String> itemArg;
    private final RequiredArg<Integer> amountArg;

    public GiveCommand() {
        super("give", "Give items to a player");

        // Register required arguments (order matters for positional args)
        playerArg = withRequiredArg("player", "Target player", ArgTypes.STRING);
        itemArg = withRequiredArg("item", "Item ID", ArgTypes.STRING);
        amountArg = withRequiredArg("amount", "Quantity", ArgTypes.INTEGER);
    }

    @Override
    @Nullable
    protected CompletableFuture<Void> execute(@Nonnull CommandContext context) {
        String player = playerArg.get(context);
        String item = itemArg.get(context);
        int amount = amountArg.get(context);

        context.sender().sendMessage(
            Message.raw("Gave " + amount + "x " + item + " to " + player)
        );
        return CompletableFuture.completedFuture(null);
    }
}
```

### Optional Arguments

Optional arguments use `--name value` syntax:

```java
import com.hypixel.hytale.server.core.command.system.arguments.system.OptionalArg;
import com.hypixel.hytale.server.core.command.system.arguments.system.RequiredArg;
import com.hypixel.hytale.server.core.command.system.arguments.types.ArgTypes;

public class TeleportCommand extends AbstractCommand {

    private final RequiredArg<Double> xArg;
    private final RequiredArg<Double> yArg;
    private final RequiredArg<Double> zArg;
    private final OptionalArg<String> worldArg;

    public TeleportCommand() {
        super("tp", "Teleport to coordinates");

        xArg = withRequiredArg("x", "X coordinate", ArgTypes.DOUBLE);
        yArg = withRequiredArg("y", "Y coordinate", ArgTypes.DOUBLE);
        zArg = withRequiredArg("z", "Z coordinate", ArgTypes.DOUBLE);

        // Optional argument: --world <name>
        worldArg = withOptionalArg("world", "Target world", ArgTypes.STRING);
    }

    @Override
    @Nullable
    protected CompletableFuture<Void> execute(@Nonnull CommandContext context) {
        double x = xArg.get(context);
        double y = yArg.get(context);
        double z = zArg.get(context);

        // Check if optional arg was provided and get value
        String world = worldArg.provided(context) ? worldArg.get(context) : "default";

        // Teleport implementation
        return CompletableFuture.completedFuture(null);
    }
}
```

### Default Arguments

Default arguments have a fallback value when not provided:

```java
import com.hypixel.hytale.server.core.command.system.arguments.system.DefaultArg;

public class SpawnCommand extends AbstractCommand {

    private final DefaultArg<Integer> radiusArg;

    public SpawnCommand() {
        super("spawn", "Spawn entities");

        // Default argument: --radius <value> (defaults to 10)
        radiusArg = withDefaultArg("radius", "Spawn radius",
            IntArgumentType.ranged(1, 100), 10, "10 blocks");
    }

    @Override
    @Nonnull
    protected CompletableFuture<Void> execute(@Nonnull CommandContext context) {
        int radius = context.get(radiusArg);  // Returns 10 if not specified
        // Implementation
        return CompletableFuture.completedFuture(null);
    }
}
```

### Flag Arguments

Flags are boolean switches that don't take values:

```java
import com.hypixel.hytale.server.core.command.system.arguments.system.FlagArg;

public class DebugCommand extends AbstractCommand {

    private final FlagArg verboseFlag;
    private final FlagArg allFlag;

    public DebugCommand() {
        super("debug", "Toggle debug mode");

        // Boolean flags: --verbose or --all
        verboseFlag = withFlagArg("verbose", "Enable verbose output");
        allFlag = withFlagArg("all", "Show all information");
    }

    @Override
    @Nonnull
    protected CompletableFuture<Void> execute(@Nonnull CommandContext context) {
        boolean verbose = context.has(verboseFlag);
        boolean all = context.has(allFlag);

        if (verbose) {
            // Verbose output
        }
        return CompletableFuture.completedFuture(null);
    }
}
```

## SubCommands

### Command Collection

Use `AbstractCommandCollection` for grouping related subcommands:

```java
import com.hypixel.hytale.server.core.command.system.basecommands.AbstractCommandCollection;
import com.hypixel.hytale.server.core.command.system.basecommands.AbstractAsyncCommand;

public class AdminCommands extends AbstractCommandCollection {

    public AdminCommands() {
        super("admin", "Admin commands");

        addSubCommand(new KickSubCommand());
        addSubCommand(new BanSubCommand());
        addSubCommand(new MuteSubCommand());
    }
}

class KickSubCommand extends AbstractAsyncCommand {

    private final RequiredArg<String> playerArg;

    public KickSubCommand() {
        super("kick", "Kick a player");
        playerArg = withRequiredArg("player", "Player to kick", StringArgumentType.INSTANCE);
    }

    @Override
    @Nonnull
    protected CompletableFuture<Void> executeAsync(@Nonnull CommandContext context) {
        String player = context.get(playerArg);
        // Kick implementation
        return CompletableFuture.completedFuture(null);
    }
}
```

Usage: `/admin kick PlayerName`

## Command Sender

### CommandSender Interface

The `CommandSender` interface extends `IMessageReceiver` and `PermissionHolder`:

```java
public interface CommandSender extends IMessageReceiver, PermissionHolder {
    String getDisplayName();
    UUID getUuid();
}

// From IMessageReceiver:
// void sendMessage(@Nonnull Message message);

// From PermissionHolder:
// boolean hasPermission(@Nonnull String id);
// boolean hasPermission(@Nonnull String id, boolean def);
```

### Check Sender Type

The `Player` component implements `CommandSender`. Console commands use `ConsoleSender`:

```java
@Override
@Nonnull
protected CompletableFuture<Void> execute(@Nonnull CommandContext context) {
    CommandSender sender = context.sender();

    if (sender instanceof Player) {
        Player player = (Player) sender;
        // Player-specific logic
    } else if (sender instanceof ConsoleSender) {
        // Console-specific logic
    }
    return CompletableFuture.completedFuture(null);
}
```

### ConsoleSender

The console sender always has all permissions:

```java
// Singleton instance - always has all permissions
ConsoleSender console = ConsoleSender.INSTANCE;
console.sendMessage(Message.raw("Console message"));

// hasPermission always returns true for ConsoleSender
console.hasPermission("any.permission"); // true
```

## Permissions

### Automatic Permission Generation

Commands auto-generate permission nodes from the plugin's base permission:

```
Plugin group: com.example
Plugin name: MyPlugin
Command: mycommand

Generated permission: com.example.myplugin.command.mycommand
```

For subcommands, permissions chain: `com.example.myplugin.command.admin.kick`

### Custom Permission

Override `generatePermissionNode()` to customize:

```java
public class ProtectedCommand extends AbstractCommand {

    public ProtectedCommand() {
        super("protected", "A protected command");
    }

    @Override
    @Nullable
    protected String generatePermissionNode() {
        return "custom.permission.node";
    }

    @Override
    @Nonnull
    protected CompletableFuture<Void> execute(@Nonnull CommandContext context) {
        // Only executed if sender has custom.permission.node
        return CompletableFuture.completedFuture(null);
    }
}
```

### Disable Permission Check

```java
@Override
protected boolean canGeneratePermission() {
    return false;  // Anyone can use this command
}
```

### Manual Permission Check

```java
@Override
@Nonnull
protected CompletableFuture<Void> execute(@Nonnull CommandContext context) {
    if (!context.sender().hasPermission("special.action")) {
        context.sender().sendMessage(Message.raw("You don't have permission!"));
        return CompletableFuture.completedFuture(null);
    }
    // Continue with action
    return CompletableFuture.completedFuture(null);
}
```

### Require Specific Permission

```java
public class SecureCommand extends AbstractCommand {

    public SecureCommand() {
        super("secure", "A secure command");
        requirePermission("my.custom.permission");  // Explicit permission
    }
}
```

## Command Aliases

```java
public class TeleportCommand extends AbstractCommand {

    public TeleportCommand() {
        super("teleport", "Teleport to location");

        // Add multiple aliases at once
        addAliases("tp", "warp", "goto");
    }
}
```

## Confirmation Required

For dangerous commands that require `--confirm` flag:

```java
public class ResetCommand extends AbstractCommand {

    public ResetCommand() {
        super("reset", "Reset all data", true);  // true = requires confirmation
    }

    @Override
    @Nonnull
    protected CompletableFuture<Void> execute(@Nonnull CommandContext context) {
        // Only called after user adds --confirm flag
        resetAllData();
        return CompletableFuture.completedFuture(null);
    }
}
```

Usage: `/reset --confirm`

## Running Commands Programmatically

```java
// Single command - returns CompletableFuture<Void>
CommandManager.get().handleCommand(sender, "give Player stone 64");

// With PlayerRef
CommandManager.get().handleCommand(playerRef, "teleport 0 64 0");

// Multiple commands in sequence
Deque<String> commands = new ArrayDeque<>();
commands.add("command1");
commands.add("command2");
CommandManager.get().handleCommands(sender, commands);

// From console
CommandManager.get().handleCommand(ConsoleSender.INSTANCE, "stop");
```

## Messages

### Raw Message

```java
context.sender().sendMessage(Message.raw("Hello World"));
```

### Translation Message

```java
// Uses translation key with parameter substitution
context.sender().sendMessage(
    Message.translation("server.commands.give.success")
        .param("player", playerName)
        .param("amount", amount)
);
```

## Argument Types

| Type | Description |
|------|-------------|
| `StringArgumentType` | Text string |
| `IntArgumentType` | Integer with optional min/max via `ranged(min, max)` |
| `DoubleArgumentType` | Double with optional min/max |
| `BooleanArgumentType` | true/false |
| `ListArgumentType<T>` | List of values (e.g., multiple players) |

## Built-in Commands

| Command | Description |
|---------|-------------|
| `help` | List available commands |
| `stop` | Stop the server |
| `kick <player>` | Kick a player |
| `who` | List online players |
| `gamemode <mode>` | Change game mode |
| `give <player> <item> [--amount]` | Give items |
| `tp <x> <y> <z>` | Teleport |
| `entity` | Entity management subcommands |
| `chunk` | Chunk management subcommands |
| `worldgen` | World generation commands |

## Base Command Classes

| Class | Description |
|-------|-------------|
| `AbstractCommand` | Base class for all commands |
| `AbstractAsyncCommand` | For async operations with `executeAsync()` |
| `AbstractCommandCollection` | Groups subcommands together |
| `AbstractPlayerCommand` | Requires player sender |
| `AbstractWorldCommand` | Commands operating on a world |
| `AbstractTargetPlayerCommand` | Commands targeting another player |
| `AbstractTargetEntityCommand` | Commands targeting entities |

## Best Practices

1. **Use typed arguments** - Store `RequiredArg`/`OptionalArg` as fields for type safety
2. **Return CompletableFuture** - Commands run asynchronously on worker threads
3. **Use descriptive help** - Good descriptions help users understand commands
4. **Validate input** - Check argument values before use
5. **Handle errors gracefully** - Send clear error messages via `Message`
6. **Use permissions** - Protect sensitive commands with proper permission nodes
7. **Use subcommands** - Group related functionality under command collections
8. **Use AbstractAsyncCommand** - For commands that perform I/O or long operations
