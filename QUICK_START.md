# 🚀 DYD App - Quick Start Guide

## The Fastest Way to Get Your Multiplayer RPG Running

### Prerequisites
- Node.js 24+ installed (check: `node --version`)
- Flutter SDK installed (check: `flutter --version`)
- Two devices or emulators (one for DM, one for Player) - or use localhost + emulator

---

## ⚡ 5-Minute Setup

### Step 1: Start the Backend (Terminal 1)
```bash
cd d:\proyectos\DYDAndroid
start-server.bat
```

**Expected output:**
```
Servidor DYD escuchando en el puerto 3000
```

✅ Backend is now running on `http://localhost:3000`

---

### Step 2: Run the Flutter App (Terminal 2)
```bash
cd d:\proyectos\DYDAndroid
flutter run
```

**App opens on your device/emulator**

---

### Step 3: DM Side (Device/Emulator 1)
1. **Enter Server URL**: `http://localhost:3000`
   - (If on LAN, use your IP: `http://192.168.1.10:3000`)
2. **Click "Crear sala"** → Copy the room code that appears
3. **Choose Monsters** → Select 2-3 from the list
4. **Click "Iniciar partida"** → Battle screen opens

---

### Step 4: Player Side (Device/Emulator 2 or another machine)
1. **Enter Same Server URL**: `http://localhost:3000`
2. **Click "Unirse a sala"**
3. **Paste Room Code** from DM
4. **Enter Player Name** (e.g., "Aragorn")
5. **Create Character**:
   - Pick Race (Elfo, Enano, etc.)
   - Pick Class (Guerrero, Mago, etc.)
   - Customize appearance (hair, height)
   - Confirm name
6. **Wait for Battle** → Automatically enters battle screen when DM starts

---

### Step 5: Play!
- **DM**: Click monsters to attack them (rolls damage automatically)
- **Players**: On your turn, click monsters to attack
- Use the end-turn button
- Photos: DM can share photos from the physical table
- Items: DM can give items; check your Mochila tab

---

## 📍 Connection Reference

| Scenario | Server URL |
|----------|------------|
| Same Computer (localhost) | `http://localhost:3000` |
| Same WiFi / Local Network | `http://192.168.1.10:3000` (replace with your IP) |
| Different Network / Internet | Deploy backend first, then use public URL |

**To find your IP:**
- **Windows**: `ipconfig` → look for IPv4 Address (e.g., 192.168.1.10)
- **Mac/Linux**: `ifconfig` → look for inet

---

## 🎮 Game Controls

### DM Battle Screen
- **Attack Monster**: Click monster → choose damage roll (appears in dialog)
- **Give Item**: Click player → select item from list
- **Share Photo**: Camera icon → pick image → auto-sends to all players
- **End Turn**: "Terminar turno" button

### Player Battle Screen
- **Attack Monster**: Click monster (only available on your turn)
- **View Inventory**: Mochila tab while waiting
- **End Turn**: "Terminar turno" button (after your action)

---

## ✅ Verification Checklist

Before starting:
```bash
# 1. Check backend health
Invoke-RestMethod http://localhost:3000/health

# Expected output: {ok: true}

# 2. Check flutter analysis
flutter analyze

# Expected output: No issues found!

# 3. Check tests
flutter test

# Expected output: +4: All tests passed!
```

---

## 🐛 Troubleshooting

### "Connection refused" when trying to connect
- Ensure `start-server.bat` is running (should see "Servidor DYD...")
- Try `http://localhost:3000` (if on same computer)

### "Failed to connect" in app
- Check backend is running: `Invoke-RestMethod http://localhost:3000/health`
- Try a different server URL format
- Ensure both devices are on same WiFi (for LAN testing)

### "Port 3000 already in use"
```bash
# Windows: Kill the process
Get-Process | Where-Object {$_.Port -eq 3000}
Stop-Process -Name node

# Or use a different port
PORT=5000 npm start
# (then use http://localhost:5000 in app)
```

### Player doesn't see DM's room
- DM must click "Iniciar partida" first
- Ensure room code is correct (copy/paste carefully)

### App crashes on character creation
- Check Flutter console for error
- Run `flutter pub get` to refresh dependencies
- Try `flutter clean && flutter run`

---

## 📚 Learn More

- **Full Setup Guide**: See `SERVER_SETUP.md`
- **Project Overview**: See `COMPLETION_SUMMARY.md`
- **Architecture**: See `README.md`

---

## 🎯 Next Steps

1. ✅ Start backend with `start-server.bat`
2. ✅ Run app with `flutter run`
3. ✅ Test on two devices
4. 🔮 (Future) Deploy backend to cloud (Heroku, AWS, etc.)
5. 🔮 (Future) Customize game content (races, classes, monsters)

---

**Happy gaming! 🎲**

Need help? Check the full docs in `README.md` and `SERVER_SETUP.md`.
