---
author: UnlimitedBytes
title: Authentication
description: Configure server authentication modes for Hytale.
sidebar:
  order: 4
human-verified: false
---

Hytale supports multiple authentication modes to accommodate different server use cases.

## Authentication Modes

### Authenticated Mode (Default)

Players must have valid Hytale accounts. This is the recommended mode for public servers:

```bash
java -jar HytaleServer.jar --assets ../HytaleAssets --auth-mode authenticated
```

**Features:**
- Account verification through Hytale authentication servers
- UUIDs are consistent and tied to player accounts
- Required for public-facing servers
- Best security against unauthorized access

### Offline Mode

No account verification. Use for private/LAN servers only:

```bash
java -jar HytaleServer.jar --assets ../HytaleAssets --auth-mode offline
```

**Features:**
- No internet connection required for authentication
- Players can join without Hytale accounts
- UUIDs are generated based on username (not consistent across servers)
- Suitable for private testing or LAN parties

:::caution
Offline mode allows anyone to join with any username. Do not use for public servers.
:::

### Insecure Mode

Similar to offline mode but with additional relaxed security. Only use for development:

```bash
java -jar HytaleServer.jar --assets ../HytaleAssets --auth-mode insecure
```

**Features:**
- All security checks disabled
- Useful for development and testing
- Never use in production

:::danger
Never use `insecure` mode on public servers. This mode disables important security features and exposes your server to attacks.
:::

## Server Operator Authentication

To authenticate as a server operator, use one of the authentication commands:

### Device Flow (Headless Servers)

For servers without a browser or display:

```
/auth login device
```

This initiates the OAuth 2.0 device authorization flow:

1. Run the command on the server console
2. You'll receive a verification URL and user code
3. Open the URL in a browser on any device
4. Enter the code to authenticate
5. The server will automatically complete authentication

### Browser Flow (Local Development)

For servers with browser access:

```
/auth login browser
```

This opens a browser window for direct OAuth authentication.

### Profile Selection

If your Hytale account has multiple game profiles, you'll be prompted to select one:

```
/auth select <number>
```

## Authentication Persistence

By default, the Hytale server stores authentication sessions in **Memory**. This means that every time the server restarts, you will need to re-authenticate using the commands above.

To persist your authentication across restarts, you can configure the persistence mode:

### Encrypted Persistence (Recommended)

To store your authentication securely on disk:

```
auth persistence Encrypted
```

This will save an encrypted session file in the server directory, allowing the server to automatically log in upon restart.

### Persistence Options

| Mode | Description |
| ---- | ----------- |
| `Memory` | (Default) Session is lost on server shutdown. |
| `Encrypted` | Session is encrypted and stored locally. |
| `Plaintext` | Session is stored unencrypted (not recommended). |

Where `<number>` corresponds to the profile listed after login.

### Additional Auth Commands

| Command | Description |
|---------|-------------|
| `/auth status` | View current authentication status and token expiry |
| `/auth logout` | Clear authentication and log out |
| `/auth cancel` | Cancel an in-progress authentication flow |
| `/auth persistence` | Configure credential storage options |

## Player Authentication Flow

When a player connects to a server running in `authenticated` mode, the following authentication flow occurs:

```
┌─────────────┐     ┌─────────────┐     ┌───────────────────────────┐
│   Client    │     │   Server    │     │ sessions.hytale.com       │
└─────────────┘     └─────────────┘     └───────────────────────────┘
       │                   │                         │
       │  1. Connect with  │                         │
       │  identity token   │                         │
       │──────────────────▶│                         │
       │                   │  2. Request auth grant  │
       │                   │────────────────────────▶│
       │                   │                         │
       │                   │  3. Auth grant response │
       │                   │◀────────────────────────│
       │                   │                         │
       │  4. Server sends  │                         │
       │  auth grant       │                         │
       │◀──────────────────│                         │
       │                   │                         │
       │  5. Client sends  │                         │
       │  auth token       │                         │
       │──────────────────▶│                         │
       │                   │  6. Exchange for        │
       │                   │  access token           │
       │                   │────────────────────────▶│
       │                   │                         │
       │                   │  7. Access token        │
       │                   │◀────────────────────────│
       │  8. Join Success  │                         │
       │◀──────────────────│                         │
```

The authentication process uses JWT tokens validated against the Session Service's JWKS (JSON Web Key Set) endpoint.

## Command Line Options

### Authentication Mode

| Option | Description |
|--------|-------------|
| `--auth-mode authenticated` | Require Hytale account (default) |
| `--auth-mode offline` | No authentication required |
| `--auth-mode insecure` | Development mode, all security disabled |

### Token Configuration

For automated deployments, you can provide authentication tokens directly:

| Option | Description |
|--------|-------------|
| `--session-token <token>` | Provide a session token for Session Service API |
| `--identity-token <token>` | Provide an identity token (JWT) |

Alternatively, tokens can be provided via environment variables:

| Environment Variable | Description |
|---------------------|-------------|
| `HYTALE_SERVER_SESSION_TOKEN` | Session token for Session Service API |
| `HYTALE_SERVER_IDENTITY_TOKEN` | Identity token (JWT) |

### Singleplayer Mode

For singleplayer/integrated servers:

| Option | Description |
|--------|-------------|
| `--singleplayer` | Run in singleplayer mode |
| `--owner-uuid <uuid>` | Set the owner UUID for the server |
| `--owner-name <name>` | Set the owner name for the server |

## Technical Details

### Key Classes

The authentication system is implemented in the following classes:

| Class | Description |
|-------|-------------|
| `ServerAuthManager` | Manages server-side authentication state and OAuth flows |
| `SessionServiceClient` | HTTP client for communicating with `sessions.hytale.com` |
| `JWTValidator` | Validates JWT tokens against the Session Service JWKS |
| `PlayerAuthentication` | Holds player UUID and username after authentication |
| `HandshakeHandler` | Handles the client-server authentication handshake |

### Internal Auth Modes

The `ServerAuthManager` uses internal auth modes to track how authentication was established:

| Mode | Description |
|------|-------------|
| `NONE` | No authentication configured |
| `SINGLEPLAYER` | Running in singleplayer mode |
| `EXTERNAL_SESSION` | Tokens provided via CLI or environment |
| `OAUTH_BROWSER` | Authenticated via browser OAuth flow |
| `OAUTH_DEVICE` | Authenticated via device OAuth flow |
| `OAUTH_STORE` | Authenticated from stored credentials |

### Credential Storage

The server supports different credential storage providers:

- **Memory**: Credentials stored in memory only (default)
- **Encrypted**: Credentials encrypted and persisted to disk

Use `/auth persistence` to configure credential storage.

### Token Refresh

The server automatically refreshes tokens before expiration (with a 5-minute buffer). If the primary session refresh fails, it falls back to OAuth token refresh for modes that support it.

## Security Best Practices

1. **Always use authenticated mode for public servers**
2. **Keep server JARs updated** for security patches
3. **Use strong server passwords** when needed
4. **Monitor login attempts** through server logs
5. **Use firewalls** to restrict access to trusted IP ranges
6. **Use encrypted credential storage** for production servers
7. **Never share session or identity tokens** - they grant server access
