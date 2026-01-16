---
author: UnlimitedBytes
title: Server Configuration
description: Configure your Hytale server settings, worlds, authentication, and performance options.
sidebar:
  order: 1
human-verified: false
---

This section covers all aspects of configuring your Hytale dedicated server.

## Configuration Files

After first launch, your server generates several configuration files:

```
my-server/
├── HytaleServer.jar
├── config.json              # Main server configuration
└── universe/
    └── worlds/
        └── default/
            └── config.json  # World-specific settings
```

## Topics

<div class="card-grid">

### [Server Settings](./server-config/)
Configure server name, MOTD, player limits, rate limiting, and connection timeouts.

### [World Configuration](./world-config/)
Set up world-specific settings including game mode, PvP, spawn behavior, and chunk management.

### [Authentication](./authentication/)
Configure authentication modes: authenticated (default), offline, and insecure for development.

### [Performance Tuning](./performance/)
Optimize memory allocation, JVM arguments, view distance, and garbage collection.

### [Running as a Service](./service/)
Set up your server as a system service on Linux (systemd) or Windows (NSSM).

### [Backups](./backups/)
Configure automatic world backups with customizable frequency and retention.

</div>
