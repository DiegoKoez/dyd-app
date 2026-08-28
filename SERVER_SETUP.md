# DYD Backend Setup Guide

## Prerequisites

- **Node.js 24+** (or any recent version with ES6 module support)
- **npm** (comes with Node.js)

If you don't have Node.js:
- **Windows**: Download from https://nodejs.org/ or use `winget install OpenJS.NodeJS`
- **macOS**: `brew install node`
- **Linux**: Use your package manager (apt, yum, etc.)

Verify installation:
```bash
node --version   # Should show v24.x.x or higher
npm --version    # Should show 11.x.x or higher
```

## Quick Start

### Option 1: Using Start Scripts (Recommended)

**Windows**:
```cmd
start-server.bat
```

**Linux/macOS**:
```bash
bash start-server.sh
```

The server will:
1. Install dependencies (if not already installed)
2. Start on `http://localhost:3000`
3. Log "Servidor DYD escuchando en el puerto 3000"

### Option 2: Manual Start

```bash
cd server
npm install
npm start
```

## Configuration

### Change Port

By default, the server listens on port **3000**. To use a different port:

```bash
PORT=5000 npm start
```

### Accessible from Other Devices

The Flutter app needs to connect to the backend. If you're testing on:

- **Same computer** (emulator): Use `http://localhost:3000`
- **LAN device** (phone/tablet on WiFi): Use `http://<YOUR_IP>:3000`
  - Find your IP:
    - Windows: `ipconfig` → look for "IPv4 Address" (e.g., `192.168.1.10`)
    - macOS/Linux: `ifconfig` → look for `inet` (e.g., `192.168.1.10`)
- **Public internet**: Deploy to a cloud provider (Heroku, AWS, DigitalOcean)

## Testing the Server

Once started, test the health endpoint:

```bash
# Windows PowerShell
Invoke-RestMethod http://localhost:3000/health

# or curl (any platform)
curl http://localhost:3000/health

# Should return: {"ok": true}
```

## Troubleshooting

### Port 3000 Already in Use

Find and kill the process:

```bash
# Windows PowerShell
Get-Process | Where-Object {$_.Handles -match "3000"}
# Then: Stop-Process -Id <PID> -Force

# Linux/macOS
lsof -i :3000
# Then: kill -9 <PID>

# Or use a different port
PORT=5001 npm start
```

### Node/npm Not Found

Ensure Node.js is in PATH:

```bash
# Windows: Add to PATH manually or reinstall Node.js with "Add to PATH" option

# Linux/macOS: Use a version manager (nvm, brew)
# nvm example:
nvm install 24
nvm use 24
```

### Dependencies Won't Install

Clear npm cache and retry:

```bash
npm cache clean --force
npm install
```

## Server Architecture

The backend uses:
- **Express.js**: HTTP server
- **Socket.IO 4.7.5**: Real-time WebSocket communication
- **In-memory state**: Rooms, players, monsters (no database yet)

Key files:
- `index.js`: Main server entry, Socket.IO setup
- `src/rooms.js`: Room and player management logic

## Socket.IO Events (For Reference)

**DM events** (client → server):
- `dm:createRoom` → returns room code
- `dm:startBattle({code, monsters})` → initializes combat
- `dm:giveItem({code, playerId, item})` → gives item to player
- `dm:sharePhoto({code, imageBase64})` → broadcasts photo

**Player events** (client → server):
- `player:joinRoom({code, playerName})` → joins session
- `player:setCharacter({code, character})` → sends character data
- `player:customizing({code})` → signals the player is still in character creation

**Battle events** (client → server):
- `dm:startBattle({code, monsters, turnOrder})` → initializes combat (uses ack to return success/error)
- `battle:action({code, targetType, targetId, damage})` → performs action
- `battle:endTurn({code})` → ends current turn

**Broadcast events** (server → all clients in room):
- `room:playersUpdated` → updated player list
- `battle:started` → battle initialized
- `battle:update` → monster/player HP changed
- `battle:turnChanged` → turn changed
- `inventory:updated` → player got an item
- `photo:shared` → new photo available

## Next Steps

1. Start the server with `start-server.bat` or `bash start-server.sh`
2. Run the Flutter app: `flutter run`
3. Enter the server URL in the app (e.g., `http://192.168.1.10:3000`)
4. Test creating and joining rooms

## Deployment (Future)

To make the app accessible from the internet:

1. **Heroku** (free tier sunsetted, paid option available)
2. **AWS Lambda** + API Gateway (with WebSocket support)
3. **DigitalOcean App Platform** (~$5/month)
4. **Firebase Realtime DB** (serverless alternative)
5. **ngrok** (for testing over internet on local machine)

For now, test locally on LAN. Once deployed, update the Flutter app with the public URL.
