---
author: UnlimitedBytes
title: Protocol & Packets
description: Understanding Hytale's networking protocol and packet handling.
sidebar:
  order: 1
---

The Hytale server uses a Netty-based networking layer supporting QUIC (UDP) and TCP transports.

## Wire Format

Each packet is framed with a header:

```
[4 bytes] Length (little-endian) - Payload size excluding header
[4 bytes] Packet ID (little-endian)
[...] Payload (may be Zstd-compressed)
```

### Key Characteristics

- **Byte Order**: Little-endian throughout
- **Compression**: Zstd for large packets
- **VarInt**: 7-bit encoding, max 5 bytes
- **Strings**: UTF-8 with VarInt length prefix
- **Transport**: QUIC (UDP) primary, TCP fallback
- **Max Payload**: 1,677,721,600 bytes (0x64000000)
- **Protocol Version**: 1
- **Total Packets**: 268
- **Total Structs**: 315
- **Total Enums**: 136

## Packet Structure

### Base Interface

```java
public interface Packet {
    int getId();
    void serialize(@Nonnull ByteBuf buffer);
    int computeSize();
}
```

### Example Implementation

```java
public class CustomPacket implements Packet {
    public static final int PACKET_ID = 999;
    private int fieldA;
    private String fieldB;

    @Override
    public int getId() { return PACKET_ID; }

    @Override
    public void serialize(@Nonnull ByteBuf buf) {
        buf.writeIntLE(fieldA);
        PacketIO.writeVarString(buf, fieldB, 1024);
    }

    @Override
    public int computeSize() {
        return 4 + PacketIO.stringSize(fieldB);
    }

    public static CustomPacket deserialize(@Nonnull ByteBuf buf, int offset) {
        CustomPacket packet = new CustomPacket();
        packet.fieldA = buf.getIntLE(offset);
        packet.fieldB = PacketIO.readVarString(buf, offset + 4);
        return packet;
    }
}
```

## Packet I/O Utilities

```java
import com.hypixel.hytale.protocol.io.PacketIO;
```

### String Operations

```java
// Variable-length strings (UTF-8)
String value = PacketIO.readVarString(buf, offset);
PacketIO.writeVarString(buf, value, maxLength);

// Variable-length ASCII strings
String ascii = PacketIO.readVarAsciiString(buf, offset);
PacketIO.writeVarAsciiString(buf, ascii, maxLength);

// Fixed-length strings (null-padded)
String fixed = PacketIO.readFixedAsciiString(buf, offset, length);
PacketIO.writeFixedAsciiString(buf, ascii, length);  // @Nullable value
String fixedUtf8 = PacketIO.readFixedString(buf, offset, length);
PacketIO.writeFixedString(buf, value, length);       // @Nullable value

// Size calculation
int byteLen = PacketIO.utf8ByteLength(str);  // UTF-8 byte count only
int totalSize = PacketIO.stringSize(str);    // VarInt prefix + UTF-8 bytes

// Raw bytes
byte[] bytes = PacketIO.readBytes(buf, offset, length);
PacketIO.writeFixedBytes(buf, data, length); // Null-padded if data.length < length
```

### UUID & Numeric Operations

```java
// UUIDs (16 bytes, big-endian - mostSigBits first, then leastSigBits)
UUID uuid = PacketIO.readUUID(buf, offset);
PacketIO.writeUUID(buf, uuid);

// Half-precision floats (16-bit, little-endian)
float half = PacketIO.readHalfLE(buf, index);
PacketIO.writeHalfLE(buf, value);

// Arrays (little-endian for multi-byte types)
byte[] bytes = PacketIO.readByteArray(buf, offset, length);
short[] shorts = PacketIO.readShortArrayLE(buf, offset, length);
float[] floats = PacketIO.readFloatArrayLE(buf, offset, length);
```

### VarInt Encoding

```java
import com.hypixel.hytale.protocol.io.VarInt;

// Writing and reading
VarInt.write(buf, value);        // Write VarInt to buffer
int value = VarInt.read(buf);    // Read VarInt from buffer (advances reader index)
int peeked = VarInt.peek(buf, index);  // Read VarInt without advancing reader index
int len = VarInt.length(buf, index);   // Get byte length of VarInt at index
int size = VarInt.size(value);   // Calculate byte size needed for value
```

Note: VarInt cannot encode negative values. Attempting to write a negative value will throw `IllegalArgumentException`.

## Packet Handlers

### Intercepting Packets

The `PacketAdapters` class provides methods for registering packet filters and watchers. There are two variants:
- **`PacketFilter`**: Works with `PacketHandler` (low-level connection handler)
- **`PlayerPacketFilter`**: Works with `PlayerRef` (player-specific, only fires for in-game players)

```java
import com.hypixel.hytale.server.core.io.adapter.PacketAdapters;
import com.hypixel.hytale.server.core.io.adapter.PacketFilter;
import com.hypixel.hytale.server.core.io.adapter.PlayerPacketFilter;

// Player-specific filter (recommended for gameplay logic)
PacketFilter filter = PacketAdapters.registerInbound(
    (PlayerPacketFilter) (PlayerRef player, Packet packet) -> {
        if (packet instanceof SomePacket) {
            return shouldBlock(packet); // true to consume
        }
        return false;
    }
);

// Watch outbound packets (watcher never blocks, always returns false)
PacketFilter outFilter = PacketAdapters.registerOutbound(
    (PlayerPacketFilter) (player, packet) -> false
);

// Cleanup
PacketAdapters.deregisterInbound(filter);
PacketAdapters.deregisterOutbound(outFilter);
```

## Sending Packets

### Via IPacketReceiver

```java
IPacketReceiver receiver = /* player connection */;
receiver.write(packet);
receiver.writeNoCache(packet); // Skip caching
```

### Cached Packets (Broadcast)

```java
import com.hypixel.hytale.protocol.CachedPacket;

try (CachedPacket<MyPacket> cached = CachedPacket.cache(new MyPacket(data))) {
    for (IPacketReceiver player : players) {
        player.write(cached);
    }
}
```

## Packet Categories

| Category | Description |
|----------|-------------|
| `connection` | Connect/disconnect |
| `auth` | Authentication |
| `player` | Movement, input |
| `entities` | Entity updates |
| `world` | Chunks, blocks |
| `inventory` | Inventory ops |
| `interface_` | UI, chat |

## Validation

```java
import com.hypixel.hytale.protocol.io.ValidationResult;

public record ValidationResult(boolean isValid, @Nullable String error) {
    public static final ValidationResult OK = new ValidationResult(true, null);

    @Nonnull
    public static ValidationResult error(@Nonnull String message) {
        return new ValidationResult(false, message);
    }

    public void throwIfInvalid() {
        if (!this.isValid) {
            throw new ProtocolException(this.error != null ? this.error : "Validation failed");
        }
    }
}
```

### Protocol Exceptions

```java
import com.hypixel.hytale.protocol.io.ProtocolException;

// Direct construction
throw new ProtocolException("Custom error message");
throw new ProtocolException("Message with cause", cause);

// Factory methods for common errors
ProtocolException.arrayTooLong(fieldName, actual, max);
ProtocolException.arrayTooShort(fieldName, actual, min);
ProtocolException.stringTooLong(fieldName, actual, max);
ProtocolException.stringTooShort(fieldName, actual, min);
ProtocolException.bufferTooSmall(fieldName, required, available);
ProtocolException.invalidEnumValue(enumName, value);
ProtocolException.invalidVarInt(fieldName);
ProtocolException.negativeLength(fieldName, value);
ProtocolException.invalidOffset(fieldName, offset, bufferLength);
ProtocolException.unknownPolymorphicType(typeName, typeId);
ProtocolException.duplicateKey(fieldName, key);
ProtocolException.dictionaryTooLarge(fieldName, actual, max);
ProtocolException.dictionaryTooSmall(fieldName, actual, min);
ProtocolException.valueOutOfRange(fieldName, value, min, max);
ProtocolException.valueBelowMinimum(fieldName, value, min);
ProtocolException.valueAboveMaximum(fieldName, value, max);
```

## Best Practices

1. **Validate structure first** - Check buffer size before deserializing
2. **Use VarInt** - Efficient for small values
3. **Cache broadcast packets** - Use `CachedPacket` for efficiency
4. **Handle errors gracefully** - Invalid packets close connections
5. **Use little-endian** - All numeric fields (except UUIDs which use big-endian)
6. **Release cached packets** - Always close to avoid leaks
7. **Deregister filters** - Clean up in plugin shutdown
