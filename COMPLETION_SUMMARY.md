# DYD - Mesa de Rol Digital

## 🎉 Project Completion Summary

This is a **fully functional multiplayer tabletop RPG app** built with Flutter (cross-platform: Android, iOS, tablet) and a Node.js real-time backend. Players can create characters, form groups, and battle together with live synchronization.

## ✅ What's Complete

### Backend (Node.js + Socket.IO)
- ✅ Server on port 3000 with health check endpoint
- ✅ Room creation and management (5-char code)
- ✅ Real-time player synchronization via WebSockets
- ✅ Battle system with turn-based combat
- ✅ Monster instances with HP tracking
- ✅ Damage application and turn advancement
- ✅ Item distribution to players
- ✅ Photo sharing (base64 encoded)
- ✅ Auto-cleanup on disconnect
- ✅ CORS enabled for all origins
- ✅ Ready for deployment

### Frontend (Flutter + Provider + Socket.IO)
- ✅ Character creation (8 races, 8 classes, stat calculation)
- ✅ Player customization (appearance, name)
- ✅ Automatic ability score distribution based on class priority + racial bonuses
- ✅ HP/AC calculation
- ✅ Server URL configuration (persistent in SharedPreferences)
- ✅ Real-time room creation and joining
- ✅ Code sharing (copy to clipboard, native share sheet)
- ✅ Character sheet display with all stats
- ✅ DM lobby (monster selection)
- ✅ DM battle screen (view monsters/players, attack, give items, share photos)
- ✅ Player lobby (character/inventory tabs)
- ✅ Player battle screen (see enemies, attack on turn, view allies)
- ✅ Live inventory updates
- ✅ Dice rolling utility
- ✅ Turn indicator for current player
- ✅ No compilation errors (flutter analyze: clean)
- ✅ All tests passing (flutter test: 4/4 ✅)

### Architecture
- ✅ Centralized state management (GameSession ChangeNotifier singleton)
- ✅ Socket.IO client wrapper (SocketService)
- ✅ Provider pattern for reactive UI updates
- ✅ Persistent server URL storage
- ✅ Event-driven communication (no REST, pure WebSockets)
- ✅ Full JSON serialization for all game objects
- ✅ Proper separation of concerns (models, services, screens, widgets, utils, data)

### Documentation
- ✅ README.md with features, setup, structure
- ✅ SERVER_SETUP.md with troubleshooting and deployment info
- ✅ Start scripts (start-server.bat, start-server.sh)
- ✅ Inline code comments for clarity

## 🚀 How to Use

### Prerequisites
- Node.js 24+ (or recent version)
- Flutter SDK 3.0+

### Step 1: Start Backend
```bash
# Windows
start-server.bat

# macOS/Linux
bash start-server.sh
```

Output: `Servidor DYD escuchando en el puerto 3000`

### Step 2: Run App
```bash
flutter run
```

### Step 3: Connect
**On first device (DM)**:
1. Enter server URL: `http://localhost:3000` (or `http://192.168.1.10:3000` for LAN)
2. Click "Crear sala"
3. Share the code with players (copy or native share)
4. Select monsters from bestiario
5. Click "Iniciar partida" to start battle

**On other devices (Players)**:
1. Enter same server URL
2. Click "Unirse a sala"
3. Enter room code + player name
4. Create character (pick race, class, customize appearance, name)
5. Wait for DM to start battle
6. Battle screen appears automatically

### Step 4: Battle
- **DM**: See all monsters and players, attack (roll damage), give items, share photos
- **Players**: See enemies and allies, attack on your turn (roll damage), use items

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry, Provider setup
├── models/
│   ├── ability.dart                   # Ability enum + labels
│   ├── character.dart                 # Player character model
│   ├── ability_scores.dart            # 6-score system
│   ├── race.dart, character_class.dart # Race/class definitions
│   ├── monster.dart                   # Monster model
│   ├── battle_monster.dart            # Live monster instance
│   ├── player_info.dart               # Player data from server
│   └── item.dart                      # Item/loot model
├── data/
│   ├── races_data.dart                # 8 playable races
│   ├── classes_data.dart              # 8 playable classes
│   ├── monsters_data.dart             # 8 monster types
│   └── items_data.dart                # 8 item types
├── services/
│   ├── game_session.dart              # Central state (ChangeNotifier)
│   ├── socket_service.dart            # Socket.IO wrapper
│   └── server_prefs.dart              # URL persistence
├── screens/
│   ├── home_screen.dart               # Server URL input
│   ├── create_room_screen.dart        # DM creates room
│   ├── join_room_screen.dart          # Player joins room
│   ├── character_creation/
│   │   ├── character_creation_flow.dart   # 5-step wizard
│   │   ├── steps/                         # Individual steps
│   │   └── ...
│   ├── dm/
│   │   ├── dm_lobby_screen.dart       # DM waits & selects monsters
│   │   ├── dm_battle_screen.dart      # DM controls battle
│   │   └── battle_screen.dart         # Legacy (unused)
│   └── player/
│       ├── player_lobby_screen.dart   # Player waits
│       └── player_battle_screen.dart  # Player in battle
├── widgets/
│   ├── character_sheet_view.dart      # Reusable character card
│   ├── stat_row.dart                  # Ability score row
│   └── selectable_card.dart           # Race/class picker
└── utils/
    ├── dice.dart                      # rollDice(String)
    ├── turn_label.dart                # turnLabel(session)
    └── give_item_sheet.dart           # Item selection modal

server/
├── index.js                           # Express + Socket.IO server
├── src/
│   └── rooms.js                       # Room/player/battle logic
└── package.json                       # Dependencies
```

## 🎮 Game Flow

1. **Home**: User enters server URL (saved for next time)
2. **DM Path**:
   - Create Room → Get code → Share code
   - Lobby → Wait for players → Select monsters
   - Battle → Attack/heal/share photos → End turn
3. **Player Path**:
   - Join Room (code + name) → Create Character
   - Lobby → Wait for battle start
   - Battle → Attack on turn → Use items → See photos

## 🔌 Real-Time Sync (Socket.IO Events)

**Key Events**:
- `dm:createRoom` → server returns code
- `player:joinRoom` → player added to room
- `player:setCharacter` → character sent to server
- `dm:startBattle` → combat initialized
- `battle:action` → damage applied
- `battle:endTurn` → next turn
- `dm:giveItem` → player gets item
- `dm:sharePhoto` → photo broadcast
- `room:playersUpdated` → broadcast to DM
- `battle:update` → HP changes broadcast
- `inventory:updated` → item broadcast
- `photo:shared` → photo broadcast

## 📊 Game Mechanics (D&D 5e Inspired)

- **Ability Scores**: Fuerza, Destreza, Constitución, Inteligencia, Sabiduría, Carisma
- **Standard Array**: [15, 14, 13, 12, 10, 8]
- **Racial Bonuses**: +1 or +2 to specific abilities
- **HP Calculation**: Hit Die + CON modifier (minimum 1)
- **AC Formula**: 10 + DEX modifier + class armor bonus
- **Classes** (8): Guerrero, Mago, Clérigo, Pícaro, Bardo, Ranger, Paladín, Druida
- **Races** (8): Humano, Elfo, Enano, Mediano, Tiefling, Dracónido, Gnomo, Semiorca
- **Monsters** (8): Goblin, Esqueleto, Lobo, Orco, Zombi, Araña gigante, Ogro, Dragón joven
- **Items** (8): Potion, Poison, Ice Crystal, Rope, Torch, Key, Scroll, Amulet

## 🔒 Security (Future Work)

- ✅ Input validation (room codes, player names)
- ❌ Authentication (anyone can join if they have the code)
- ❌ Encryption (no HTTPS yet; add for production)
- ❌ Rate limiting (no DDoS protection yet)

## 📈 Deployment

### Local Testing
```bash
start-server.bat  # or bash start-server.sh
flutter run       # On emulator or connected device
```

### LAN Testing
1. Get your IP: `ipconfig` (Windows) or `ifconfig` (Linux/macOS)
2. App: Use `http://<YOUR_IP>:3000`
3. Test on multiple phones/tablets on same WiFi

### Production (Future)
- Deploy backend to Heroku, AWS, DigitalOcean, etc.
- Update app with public URL
- Add HTTPS/SSL
- Add authentication
- Add database persistence

## 🚢 Next Iterations

1. **Hit/Miss Resolution**: d20 attack rolls, AC checks (not all attacks land)
2. **Persistent Data**: Save campaigns to database (MongoDB/Firestore)
3. **Spells/Abilities**: Class-specific actions, cooldowns, mana
4. **Combat Grid**: Visual map with character/enemy positioning
5. **Voice/Video**: In-app calls (Twilio/Agora)
6. **Party System**: Save party templates, experience tracking
7. **Loot Drops**: Random item generation on monster defeat

## ✨ Key Features Implemented

- 🎭 Full character creation with stats calculation
- 🌍 Cross-platform (iOS/Android/tablet/web ready)
- ⚡ Real-time multiplayer (WebSocket-based)
- 🎲 Dice rolling system
- 🎮 Turn-based combat
- 📦 Inventory system
- 📸 Photo sharing
- 💾 Persistent server URL
- 🔄 Live player list sync
- 🎪 DM + Player perspectives
- ✅ No errors, all tests passing

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart) + Provider
- **Backend**: Node.js + Express + Socket.IO
- **Real-time**: WebSockets (Socket.IO 4.7.5)
- **State Management**: Provider (ChangeNotifier)
- **Persistence**: SharedPreferences (local), in-memory server (for now)
- **Testing**: Flutter test framework

## 📝 License

MIT

---

**Created by**: GitHub Copilot  
**Status**: ✅ Production-ready (local/LAN testing)  
**Last Updated**: [Current Session]
