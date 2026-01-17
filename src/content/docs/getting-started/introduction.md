---
author: UnlimitedBytes
title: Introduction
description: Welcome to the Unofficial Hytale Server Documentation.
sidebar:
  order: 1
human-verified: true
---

Welcome to the **Unofficial Hytale Server Documentation**. This project is a community-driven initiative to provide technical documentation for Hytale's server architecture, configuration, and modding capabilities.

:::caution[Early Access & Unofficial Content]
**This site is not affiliated with Hytale or Hypixel Studios.**

Hytale is currently in development. These documents are created through community analysis, reverse engineering, and decompilation of early server binaries.
- **WIP Content**: Information is under heavy construction and may be incomplete.
- **Subject to Change**: Details may become outdated as Hytale updates.
- **Community Driven**: [Report errors or contribute on GitHub](https://github.com/vulpeslab/hytale-docs/issues).
:::

## Document Status Symbols

To help you navigate the reliability of this community-driven documentation, each page features a status badge next to the title and in the sidebar:

- ✅ **Human Verified**: This page has been manually reviewed, tested, and updated for accuracy by a human contributor.
- ❌ **Not Verified**: This page contains information generated via AI analysis or raw decompiler output. It has **not** been thoroughly reviewed by a human and may contain inaccuracies. Usage of this docs are at your own risk.

---

## What is a Hytale Server?

The Hytale Server is a standalone Java (`.jar`) application. While the Hytale client uses this same server internally to power single-player worlds, the dedicated server allows you to host multiplayer games independently of the game client.

To run a dedicated server, you need:
- **HytaleServer.jar**: The executable server application.
- **Assets.zip**: The game assets provided by Hypixel Studios, containing the world data, models, and scripts required for the server to function.

With your own server, you can:
- Host private games for friends and communities.
- Customize game rules, world settings, and gameplay mechanics.
- Configure multiple worlds within a single "Universe".
- Implement custom server-side modifications and plugins.
- Leverage Hytale's native multiserver architecture for scalable deployments.

## System Requirements

The Hytale server is designed to be efficient but its resource usage scales with player activity and world complexity.

- **Memory**: At least 4GB of RAM is required. (8GB+ recommended for production or high view distances).
- **Java**: **Java 25** or higher is required. We recommend [Adoptium Temurin](https://adoptium.net/temurin/releases).
- **Architecture**: Full support for both **x64** and **arm64**.
- **Network**: UDP port access (default **5520**). Hytale uses the **QUIC protocol** over UDP.
- **Storage**: Sufficient space for the `Assets.zip`, world data (`universe/`), and logs.

## Quick Start

1. **Install Java 25**: Download and install the latest Java 25 LTS from [Adoptium](https://adoptium.net/).
2. **Obtain Server Files**: 
   - **Manual**: Copy the `HytaleServer.jar` (found inside the `Server` folder) and `Assets.zip` from your Hytale launcher installation (typically found in the `package/game/latest` directory).
   - **Downloader**: Use the [Hytale Downloader CLI](https://downloader.hytale.com/hytale-downloader.zip) for production environments to keep files updated via OAuth2.
3. **Launch the Server**: Run the server using the following command:

```bash
java -Xms4G -Xmx4G -jar HytaleServer.jar --assets Assets.zip
```

4. **Authenticate**: On first launch, you must authorize your server. In the server console, use one of the following commands:
   - `auth login device`: Generates a code for `https://accounts.hytale.com/device`.
   - `auth login browser`: Opens your browser to authorize.

   **Note**: By default, login sessions are stored in memory and lost on restart. To persist your authentication, run:
   ```
   auth persistence Encrypted
   ```

5. **Connect**: Once authenticated, join your server at `localhost:5520` (or your server's IP).
