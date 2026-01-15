---
author: UnlimitedBytes
title: Running as a Service
description: Set up your Hytale server as a system service for automatic startup.
sidebar:
  order: 6
---

Run your Hytale server as a system service for automatic startup, crash recovery, and easier management.

## Linux (systemd)

### Create Service File

Create `/etc/systemd/system/hytale.service`:

```ini
[Unit]
Description=Hytale Server
After=network.target

[Service]
User=hytale
WorkingDirectory=/opt/hytale
ExecStart=/usr/bin/java -Xms4G -Xmx4G -jar HytaleServer.jar --assets ../HytaleAssets
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### Configuration Options

| Option | Description |
|--------|-------------|
| `User` | System user to run the server as |
| `WorkingDirectory` | Server installation directory |
| `Restart=on-failure` | Auto-restart on crashes |
| `RestartSec=10` | Wait 10 seconds before restart |

### Service Commands

```bash
# Enable service to start on boot
sudo systemctl enable hytale

# Start the server
sudo systemctl start hytale

# Stop the server
sudo systemctl stop hytale

# Restart the server
sudo systemctl restart hytale

# Check status
sudo systemctl status hytale
```

### View Logs

```bash
# Follow live logs
sudo journalctl -u hytale -f

# View last 100 lines
sudo journalctl -u hytale -n 100

# View logs since boot
sudo journalctl -u hytale -b

# View logs from specific time
sudo journalctl -u hytale --since "2024-01-01 00:00:00"
```

### Advanced systemd Configuration

For production servers with optimized JVM:

```ini
[Unit]
Description=Hytale Server
After=network.target
Wants=network-online.target

[Service]
User=hytale
Group=hytale
WorkingDirectory=/opt/hytale
ExecStart=/usr/bin/java \
    -Xms8G -Xmx8G \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=200 \
    -jar HytaleServer.jar \
    --assets ../HytaleAssets

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/hytale

# Resource limits
LimitNOFILE=65536

# Restart behavior
Restart=on-failure
RestartSec=10
StartLimitIntervalSec=300
StartLimitBurst=5

StandardOutput=journal
StandardError=journal
SyslogIdentifier=hytale

[Install]
WantedBy=multi-user.target
```

## Windows Service

### Using NSSM (Non-Sucking Service Manager)

1. **Download NSSM** from [nssm.cc](https://nssm.cc/download)

2. **Install the service:**
```powershell
nssm install HytaleServer "C:\Program Files\Java\jdk-25\bin\java.exe"
nssm set HytaleServer AppParameters "-Xms4G -Xmx4G -jar HytaleServer.jar --assets ..\HytaleAssets"
nssm set HytaleServer AppDirectory "C:\hytale-server"
```

3. **Configure logging:**
```powershell
nssm set HytaleServer AppStdout "C:\hytale-server\logs\stdout.log"
nssm set HytaleServer AppStderr "C:\hytale-server\logs\stderr.log"
nssm set HytaleServer AppRotateFiles 1
nssm set HytaleServer AppRotateBytes 10485760
```

4. **Start the service:**
```powershell
nssm start HytaleServer
```

### NSSM Commands

```powershell
# Start service
nssm start HytaleServer

# Stop service
nssm stop HytaleServer

# Restart service
nssm restart HytaleServer

# Check status
nssm status HytaleServer

# Edit service configuration
nssm edit HytaleServer

# Remove service
nssm remove HytaleServer confirm
```

### Using Windows Task Scheduler

For simpler setups, use Task Scheduler:

1. Open Task Scheduler
2. Create Basic Task
3. Set trigger to "When the computer starts"
4. Action: Start a program
5. Program: `C:\Program Files\Java\jdk-25\bin\java.exe`
6. Arguments: `-Xms4G -Xmx4G -jar HytaleServer.jar --assets ..\HytaleAssets`
7. Start in: `C:\hytale-server`

## Docker (Optional)

### Basic Dockerfile

```dockerfile
FROM eclipse-temurin:25-jre

WORKDIR /server

COPY HytaleServer.jar .
COPY HytaleAssets ../HytaleAssets

EXPOSE 5520/udp

CMD ["java", "-Xms4G", "-Xmx4G", "-jar", "HytaleServer.jar", "--assets", "../HytaleAssets"]
```

### Docker Compose

```yaml
version: '3.8'
services:
  hytale:
    build: .
    ports:
      - "5520:5520/udp"
    volumes:
      - ./universe:/server/universe
      - ./config.json:/server/config.json
      - ./mods:/server/mods
    restart: unless-stopped
    environment:
      - JAVA_OPTS=-Xms4G -Xmx4G
```

## Best Practices

1. **Use dedicated user** - Don't run as root/Administrator
2. **Enable auto-restart** - Recover from crashes automatically
3. **Configure logging** - Rotate logs to prevent disk fill
4. **Set resource limits** - Prevent runaway memory usage
5. **Monitor the service** - Use monitoring tools for alerts
