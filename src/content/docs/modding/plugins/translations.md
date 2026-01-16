---
author: UnlimitedBytes
title: Translation System
description: Learn how to add translations to your Hytale plugins.
sidebar:
    order: 7
---

## File Structure

Translation files must be placed in:
```
src/main/resources/Server/Languages/<locale>/<filename>.lang
```

At runtime, the server scans `Server/Languages` inside each plugin's asset pack root (mounted as a filesystem). Ensure your build copies these resources so they end up under that path in the final plugin pack.

Supported locales include:
- `en-US` - English (United States)
- `de-DE` - German (Germany)
- And other standard locale codes

### Example Structure
```
src/main/resources/
└── Server/
    └── Languages/
        ├── en-US/
        │   └── showcase.lang
        └── de-DE/
            └── showcase.lang
```

## File Format

Translation files use a simple key-value format:

```properties
# Comments start with #
key.name = Translation text here
key.with.params = Hello {name}, you have {count} messages
```

### Key Naming Convention

**Important**: Keys are automatically prefixed by any subdirectories between `<locale>` and the file, plus the filename (without `.lang`).

For example, if your file is `Server/Languages/en-US/showcase.lang` and contains:
```properties
command.info.desc = Shows plugin information
```
The actual translation key becomes: `showcase.command.info.desc`

If the file is nested, e.g. `Server/Languages/en-US/admin/showcase.lang`, then keys are prefixed with the directory path as well: `admin.showcase.command.info.desc`.

### Parameters

Use `{paramName}` syntax for dynamic values:
```properties
info.version = Version: {version}
info.greeting = Hello {name}!
```

Formatting directives supported inside placeholders:
- `upper` / `lower`: `{name, upper}` → uppercase; `{name, lower}` → lowercase
- `number` with `integer` or `decimal`: `{count, number, integer}` or `{value, number, decimal}`
- `plural`: `{count, plural, one {1 message} other {{count} messages}}`

Escaping and multiline values:
- Use `{{` and `}}` to render literal `{` or `}`
- End a line with `\` to continue onto the next line
- Keys and values must be non-empty; duplicate keys in the same file cause a parse error

## Using Translations in Code

### Basic Translation

```java
import com.hypixel.hytale.server.core.Message;

// Simple translation without parameters
commandContext.sendMessage(Message.translation("showcase.command.info.header"));
```

### Translation with Parameters

Use the fluent `.param()` method to add parameters:

```java
// Single parameter
commandContext.sendMessage(
    Message.translation("showcase.command.info.version")
        .param("version", "1.0.0")
);

// Multiple parameters
commandContext.sendMessage(
    Message.translation("showcase.greeting")
        .param("name", playerName)
        .param("count", messageCount)
);
```

### Available Parameter Types

The `param()` method supports multiple types:
- `param(String key, String value)`
- `param(String key, int value)`
- `param(String key, long value)`
- `param(String key, float value)`
- `param(String key, double value)`
- `param(String key, boolean value)`
- `param(String key, Message value)` - for nested messages

### Message Styling

Messages can be styled using fluent methods:

```java
Message.translation("showcase.important")
    .bold(true)
    .color("#FF0000")
    .italic(true)
    .monospace(true);
```

## Command Descriptions

When creating commands, use translation keys for descriptions:

```java
public class InfoCommand extends AbstractCommand {
    public InfoCommand() {
        // The description parameter is a translation key
        super("info", "showcase.command.info.desc", false);
    }
}
```

## How It Works Internally

1. **Loading**: On startup and asset pack registration, `I18nModule` scans the `Server/Languages/` directory inside each plugin's asset pack root
2. **Parsing**: Each `.lang` file is parsed, and keys are prefixed with the directory path (if any) and filename
3. **Caching**: Translations are cached by locale in memory
4. **Resolution**: When `Message.translation()` is called, the server creates a `FormattedMessage` with the key
5. **Client-side**: The actual text resolution happens client-side, allowing each player to see their preferred language
6. **Live updates**: For non-immutable packs, changes to `.lang` files are detected and incremental updates are pushed to clients

### Fallbacks

Optionally provide a `fallback.lang` at `Server/Languages/fallback.lang` to map locales to fallbacks, e.g.:
```
fr-FR = en-US
de-DE = en-US
```
If a key is missing in the target locale, the fallback locale's value is used.

## Best Practices

1. **Organize by feature**: Group related translations in the same file section
2. **Use descriptive keys**: `command.showcase.info.desc` is better than `cmd1`
3. **Provide all locales**: Always include translations for all supported languages
4. **Document parameters**: Add comments explaining what parameters are expected

```properties
# Info command messages
# Parameters: {version} - The plugin version string
command.showcase.info.version = Version: {version}
```

## Debugging

To verify translations are loaded, check the server console for:
```
Loaded X entries for 'en-US' from <path-to-Server/Languages>
```

If translations show as keys instead of text:
1. Verify the file is in the correct location (`Server/Languages/<locale>/`)
2. Check that key names include the directory+filename prefix
3. Ensure the `.lang` file uses `=` as the separator (not `:`)
4. Ensure values aren’t empty and keys aren’t duplicated
