---
title: Introduction
description: Get started with running and configuring your own Hytale server.
sidebar:
  order: 1
---

:::caution[Early Access & Work in Progress]
**Hytale is currently in early access.** This documentation is unofficial and created through community decompilation and analysis.

- Content is under heavy construction and may be incomplete or change frequently
- Some details may become outdated as Hytale updates
- Found an error or want to contribute? [Report it on GitHub](https://github.com/vulpeslab/hytale-docs/issues)
:::

Welcome to the Hytale Server documentation! This guide will help you get started with running your own Hytale dedicated server.

## What is a Hytale Server?

A Hytale dedicated server allows you to host multiplayer games for yourself and others. With your own server, you can:

- Host private games for friends and communities
- Customize game rules and world settings
- Configure multiple worlds with different game modes
- Integrate with server mesh architecture for scalable deployments
- Implement custom server-side modifications

## System Requirements

Before setting up your server, ensure your system meets these requirements:

- **Memory**: At least 4GB of RAM (8GB+ recommended for larger servers)
- **Java**: Java 25 or higher (Adoptium/Temurin recommended)
- **Architecture**: x64 or arm64 supported
- **Network**: UDP port access (default port 5520) - uses QUIC protocol
- **Storage**: Sufficient disk space for world data, backups, and assets

## Quick Start

1. **Install Java 25** - Download from [Adoptium](https://adoptium.net/)
2. **Get Server Files** - Copy the Server folder and assets from your Hytale installation
3. **Launch the Server** - Run with the command:

```bash
java -Xms4G -Xmx4G -jar HytaleServer.jar --assets ../HytaleAssets
```

The `--assets` flag accepts either a directory path or a `.zip` archive containing your game assets.

4. **Connect** - Join your server at `localhost:5520` (or your server's IP address)

## Documentation Structure

This documentation covers everything you need to run a Hytale server:

### Getting Started
Step-by-step guides to install Java, set up your server, and configure basic settings.

### Server Configuration
Detailed information about server.json, world configuration, and command-line arguments.

### Server Administration
Learn about server commands, permissions, authentication, and player management.

### Advanced Topics
Server mesh architecture, backup systems, and performance optimization.

## Network Protocol

Hytale servers use the **QUIC protocol over UDP**, not TCP. When configuring firewalls and port forwarding, make sure to:

- Open UDP port 5520 (or your custom port)
- Configure your firewall to allow UDP traffic
- Set up port forwarding for UDP if behind NAT

## Next Steps

Ready to set up your server? Head to the [Installation](/getting-started/installation/) guide to install all prerequisites.
