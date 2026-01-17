---
author: UnlimitedBytes
title: Installation
description: Install Java and set up your Hytale server files.
sidebar:
  order: 2
human-verified: true
---

This guide walks you through installing all prerequisites and setting up your Hytale dedicated server.

## 1. Installing Java 25

Hytale servers require **Java 25** or higher. We recommend using **Adoptium Temurin** for its stability and performance.

### Windows
1. Download the JDK installer from [Adoptium](https://adoptium.net/temurin/releases/?version=25).
2. Select **Temurin 25 (LTS)** for **Windows x64**.
3. Run the installer. **Important:** Ensure the "Add to PATH" and "Set JAVA_HOME variable" options are selected.

### macOS
If you have [Homebrew](https://brew.sh/) installed:
```bash
brew install --cask temurin@25
```
Otherwise, download the `.pkg` installer directly from [Adoptium](https://adoptium.net/temurin/releases/?version=25).

### Linux
#### Ubuntu/Debian
```bash
# Add Adoptium repository
wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo gpg --dearmor -o /usr/share/keyrings/adoptium.gpg
echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/adoptium.list

# Install Java 25
sudo apt update
sudo apt install temurin-25-jdk
```

#### Fedora/RHEL
```bash
sudo dnf install java-25-openjdk
```

### Verify Installation
Open your terminal or command prompt and run:
```bash
java -version
```
Expected output should mention `openjdk 25.x.x`.

---

## 2. Obtaining Server Files

There are two primary ways to get your server files.

### Method A: Manual Copy (Internal Testing)
Best for quick local tests.
1. Navigate to your Hytale Launcher installation folder.
   - **Windows:** `%appdata%\Hytale\install\release\package\game\latest`
   - **macOS:** `~/Library/Application\ Support/Hytale/install/release/package/game/latest/`
   - **Linux:** `$XDG_DATA_HOME/Hytale/install/release/package/game/latest`
2. Copy the `HytaleServer.jar` (found inside the `Server` folder) and the `Assets.zip` file to your new server project directory.

### Method B: Hytale Downloader (Production)
Best for dedicated servers and automated updates.
1. Download the [Hytale Downloader CLI](https://downloader.hytale.com/hytale-downloader.zip).
2. Extract and run it in your server folder to fetch the latest production binaries and assets:
   ```bash
   ./hytale-downloader
   ```

---

## 3. Launching the Server

### Directory Structure
Your server folder should look like this:
```text
server-root/
├── HytaleServer.jar      # The server executable
├── Assets.zip            # The game assets (Models, scripts, etc.)
└── universe/             # (Generated) World and player data
```

### First Launch
Allocate at least 4GB of RAM (recommended). Use the `--assets` flag to point to your `Assets.zip`.

```bash
java -Xms4G -Xmx4G -jar HytaleServer.jar --assets Assets.zip
```

### Initial Configuration & Authentication
On the first run, the server will start but won't be accessible until you authenticate. Use one of the following methods in the server console:

*   **Browser Flow**: Best for local development. Opens your default browser for authorization.
    ```text
    auth login browser
    ```
*   **Device Flow**: Recommended for remote or headless servers. Provides a link and a code to enter on another device.
    ```text
    auth login device
    ```

**Persistence Mode**
By default, login sessions are stored in memory and lost on restart. To persist your authentication securely on disk, run:
```text
auth persistence Encrypted
```

---

## Command-Line Reference

For a complete list of server command-line flags, see **Server → Command-Line Options**.

### Example: Custom Port
To run on a specific port (e.g., 25565):
```bash
java -Xms4G -Xmx4G -jar HytaleServer.jar --assets Assets.zip --bind 0.0.0.0:25565
```

---

## 4. Network & Firewall

Hytale uses the **QUIC protocol over UDP** by default. Ensure your firewall allows incoming traffic on your port (default `5520`).

### Firewall Configuration (UDP)

*   **Windows (PowerShell):**
    ```powershell
    netsh advfirewall firewall add rule name="Hytale Server" dir=in action=allow protocol=UDP localport=5520
    ```
*   **Linux (UFW):**
    ```bash
    sudo ufw allow 5520/udp
    ```
*   **Linux (firewalld):**
    ```bash
    sudo firewall-cmd --permanent --add-port=5520/udp
    sudo firewall-cmd --reload
    ```

### Port Forwarding
If hosting from home, you may need to forward UDP port `5520` on your router to allow external connections. Refer to your router's documentation for specific instructions.