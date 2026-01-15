---
author: UnlimitedBytes
title: Backup Configuration
description: Configure automatic backups for your Hytale server.
sidebar:
  order: 7
---

Protect your server data with automatic backups.

## Command Line Options

Enable automatic backups with command-line arguments:

```bash
java -Xms4G -Xmx4G -jar HytaleServer.jar \
  --assets ../HytaleAssets \
  --backup \
  --backup-dir ./backups \
  --backup-frequency 30 \
  --backup-max-count 5
```

## Backup Options

| Option | Description | Default |
|--------|-------------|---------|
| `--backup` | Enable automatic backups | disabled |
| `--backup-dir <path>` | Backup directory (required when `--backup` is enabled) | none |
| `--backup-frequency <minutes>` | Minutes between backups (minimum: 1) | 30 |
| `--backup-max-count <count>` | Maximum backups to keep in each directory | 5 |

## Example Configurations

### Frequent Backups (High Activity Server)

```bash
java -Xms4G -Xmx4G -jar HytaleServer.jar \
  --assets ../HytaleAssets \
  --backup \
  --backup-dir ./backups \
  --backup-frequency 15 \
  --backup-max-count 10
```

Backs up every 15 minutes, keeps last 10 backups (2.5 hours of history).

### Hourly Backups (Low Activity Server)

```bash
java -Xms4G -Xmx4G -jar HytaleServer.jar \
  --assets ../HytaleAssets \
  --backup \
  --backup-dir ./backups \
  --backup-frequency 60 \
  --backup-max-count 24
```

Backs up every hour, keeps last 24 backups (24 hours of history).

### Extended History

```bash
java -Xms4G -Xmx4G -jar HytaleServer.jar \
  --assets ../HytaleAssets \
  --backup \
  --backup-dir /mnt/backup-drive/hytale \
  --backup-frequency 30 \
  --backup-max-count 48
```

Backs up every 30 minutes to external drive, keeps 48 backups (24 hours of history).

## Backup Format and Storage

Backups are stored as **ZIP archives** with filenames in the format `yyyy-MM-dd_HH-mm-ss.zip` (e.g., `2024-01-15_14-30-00.zip`).

The backup directory structure:
```
backups/
├── 2024-01-15_14-30-00.zip    # Recent backups
├── 2024-01-15_14-00-00.zip
├── 2024-01-15_13-30-00.zip
└── archive/                    # Archived backups (automatic)
    └── 2024-01-14_12-00-00.zip
```

### Automatic Archiving

The server automatically archives older backups before deletion:
- Every 12 hours, the oldest backup is moved to the `archive/` subdirectory instead of being deleted
- The archive directory also respects `--backup-max-count`

### Backup Contents

Each backup ZIP contains the entire `universe/` directory:
- All world data and chunk files
- Player data
- World configurations

## Manual Backup Command

Use the `/backup` command in-game or from the console to trigger an immediate backup:

```
/backup
```

Note: This command requires `--backup-dir` to be configured, even if `--backup` is not enabled.

## Manual Backup (Server Stopped)

For manual backups when the server is stopped:

```bash
# Stop server first, then:
cp -r universe/ backups/manual-backup-$(date +%Y%m%d-%H%M%S)/
```

## Restore from Backup

1. Stop the server
2. Extract the backup ZIP
3. Replace the `universe/` directory
4. Start the server

```bash
# Stop server
sudo systemctl stop hytale

# Restore backup
rm -rf universe/
unzip backups/2024-01-15_14-30-00.zip -d .

# Start server
sudo systemctl start hytale
```

## Permissions

| Permission | Description |
|------------|-------------|
| `hytale.status.backup.error` | Receive in-game notifications when a backup fails |

Players with the `hytale.status.backup.error` permission will be notified in-game if a backup operation fails.

## Best Practices

1. **Test restores regularly** - Verify backups work
2. **Store off-site copies** - Protect against hardware failure
3. **Monitor disk space** - Ensure room for backups
4. **Document backup schedule** - Know your recovery point
5. **Automate notifications** - Alert on backup failures

## External Backup Solutions

Consider combining with:
- **Cloud storage** (AWS S3, Google Cloud Storage)
- **Rsync** to remote servers
- **Scheduled cron jobs** for additional copies
- **RAID storage** for redundancy
