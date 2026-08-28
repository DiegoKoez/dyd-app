const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const { RoomManager } = require('./src/rooms');
const dgram = require('dgram');
const os = require('os');
const fs = require('fs');
const path = require('path');

// Declarar roomManager ANTES de usarlo en las rutas HTTP
const roomManager = new RoomManager();

const app = express();
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type'],
  credentials: true
}));

// Servir archivos web de Flutter
app.use(express.static(path.join(__dirname, '..', 'build', 'web')));

// Ruta principal - servir index.html
app.get('/', (_req, res) => {
  res.sendFile(path.join(__dirname, '..', 'build', 'web', 'index.html'));
});

// Endpoint para diagnosticar conexión Socket.IO
app.get('/socket-io-test', (req, res) => {
  console.log('[server] Socket.IO diagnostic test from IP:', req.ip);
  console.log('[server] User-Agent:', req.get('User-Agent'));
  console.log('[server] Accept-Encoding:', req.get('Accept-Encoding'));

  const accept = req.get('Accept');
  console.log('[server] Accept header:', accept);

  res.json({
    ok: true,
    message: 'Socket.IO Server Ready',
    supportsPolling: true,
    supportsWebSocket: true,
    version: '4.7.5',
    transports: ['polling', 'websocket'],
    timestamp: new Date().toISOString(),
    serverInfo: {
      ip: req.ip,
      port: 3000,
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage()
    }
  });
});

app.get('/health', (_req, res) => {
  console.log(`[server] Health check from ${_req.ip}`);
  res.json({ ok: true });
});
app.get('/test', (_req, res) => {
  res.json({ ok: true, socketIo: true, transports: ['polling', 'websocket'] });
});
app.get('/rooms', (_req, res) => {
  const rooms = [];
  for (const [code, room] of roomManager.rooms) {
    rooms.push({
      code,
      dm: room.dmSocketId,
      players: room.players.size,
      battleStarted: room.battleStarted,
    });
  }
  res.json({ rooms });
});
app.get('/search-rooms', (_req, res) => {
  const rooms = [];
  for (const [code, room] of roomManager.rooms) {
    rooms.push({
      code,
      players: room.players.size,
      battleStarted: room.battleStarted,
      created: room.created_at
    });
  }
  res.json({ rooms, server: { ip: getLocalIPv4(), port: PORT } });
});

const server = http.createServer(app);

const io = new Server(server, {
  cors: { origin: '*' },
  pingInterval: 25000,
  pingTimeout: 60000,
  transports: ['polling', 'websocket'],
});

const MONSTER_PHOTOS_FILE = path.join(__dirname, '..', 'data', 'monster_photos.json');
let monsterPhotos = {};
const dataDir = path.join(__dirname, '..', 'data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}
if (fs.existsSync(MONSTER_PHOTOS_FILE)) {
  try {
    monsterPhotos = JSON.parse(fs.readFileSync(MONSTER_PHOTOS_FILE, 'utf8'));
  } catch (e) {
    console.error('Error loading monster photos:', e.message);
  }
}

function saveMonsterPhotos() {
  try {
    fs.writeFileSync(MONSTER_PHOTOS_FILE, JSON.stringify(monsterPhotos));
  } catch (e) {
    console.error('Error saving monster photos:', e.message);
  }
}

io.on('connection_error', (error) => {
  console.log('[SERVER] CONNECTION ERROR: ' + error.code + ' ' + error.message);
});

// Log socket.io handshake attempts
io.engine.on('connection_error', (error) => {
  console.log('[SERVER] ENGINE CONNECTION ERROR: ' + error.code + ' ' + error.message + ' from ' + (error.req ? error.req.url : 'unknown'));
  console.log('[SERVER] ERROR CONTEXT: ' + JSON.stringify(error.context));
});

io.engine.on('initial_headers', (headers, req) => {
  console.log('[SERVER] ENGINE INITIAL HEADERS from ' + req.url);
  console.log('[SERVER] HEADERS: ' + JSON.stringify(headers).substring(0, 300));
});

io.engine.on('handshake', (data) => {
  console.log('[SERVER] ENGINE HANDSHAKE from ' + (data && data.req ? data.req.url : 'unknown'));
  console.log('[SERVER] HANDSHAKE DATA: ' + JSON.stringify(data).substring(0, 300));
});

io.engine.on('next_handshake', (data) => {
  console.log('[SERVER] ENGINE NEXT_HANDSHAKE');
});

io.engine.on('connection_error', (error) => {
  console.log('[SERVER] ENGINE CONNECTION ERROR: ' + error.code + ' ' + error.message + ' from ' + (error.req ? error.req.url : 'unknown'));
  console.log('[SERVER] ERROR CONTEXT: ' + JSON.stringify(error.context).substring(0, 300));
});

io.engine.on('session', (data) => {
  console.log('[SERVER] ENGINE SESSION created');
});

io.engine.on('packet', (packet) => {
  console.log('[SERVER] ENGINE PACKET: type=' + packet.type);
});

io.engine.on('packetCreate', (packet) => {
  console.log('[SERVER] ENGINE PACKET_CREATE: type=' + packet.type);
});

io.engine.on('data', (data) => {
  console.log('[SERVER] ENGINE DATA: ' + JSON.stringify(data).substring(0, 200));
});

io.engine.on('error', (err) => {
  console.log('[SERVER] ENGINE ERROR: ' + err);
  console.log('[SERVER] ENGINE ERROR STACK: ' + err.stack);
  console.log('[SERVER] ENGINE ERROR MESSAGE: ' + err.message);
});

io.engine.on('close', () => {
  console.log('[SERVER] ENGINE CLOSE');
});

io.on('connection', (socket) => {
  console.log('[SERVER] CLIENT CONNECTED! ID=' + socket.id + ' IP=' + socket.handshake.address);
  console.log('[SERVER] TRANSPORT: ' + socket.conn.transport.name);
  socket.on('disconnect', (reason) => {
    console.log('[SERVER] Client disconnected: ' + socket.id + ' reason=' + reason);
  });
  socket.on('connect_error', (error) => {
    console.log('[SERVER] Connection error for ' + socket.id + ': ' + error);
  });
  socket.onAny((event, ...args) => {
    console.log('[SERVER] Event received:', event, 'from', socket.id);
    if (args.length > 0) {
      console.log('   Data:', JSON.stringify(args[0]).substring(0, 200));
    }
  });
  socket.conn.on('packet', (packet) => {
    console.log('[SERVER] Packet received: type=' + packet.type);
  });
  socket.conn.on('packetCreate', (packet) => {
    console.log('[SERVER] Packet sent: type=' + packet.type);
  });
  socket.conn.on('drain', () => {
    console.log('[SERVER] Drain event');
  });
  socket.conn.on('error', (err) => {
    console.log('[SERVER] Connection error: ' + err);
  });
  socket.conn.on('close', (reason) => {
    console.log('[SERVER] Connection closed: ' + reason);
  });

  socket.on('dm:createRoom', (_data, ack) => {
    try {
      const room = roomManager.createRoom(socket.id);
      socket.join(room.code);
      ack?.({ code: room.code });
      console.log('[room] created room=' + room.code + ' dm=' + socket.id);
    } catch (err) {
      console.error('[room] createRoom error', err);
      ack?.({ success: false, error: 'Error al crear sala' });
    }
  });

  socket.on('player:joinRoom', ({ code, playerName, character, playerId }) => {
    try {
      console.log('[join] received join request code=' + code + ' playerName=' + playerName + ' socket=' + socket.id);
      const room = roomManager.getRoom(code);
      if (!room) {
        console.log('[join] room not found for code=' + code);
        socket.emit('player:joinResponse', { success: false, error: 'Sala no encontrada' });
        return;
      }
      console.log('[join] joining room=' + code + ' socket=' + socket.id);
      roomManager.joinRoom(code, socket.id, playerName, playerId);
      socket.join(code);
      if (character) {
        const player = room.players.get(socket.id);
        if (player) {
          player.character = character;
          player.customizing = false;
        }
      }
      const newPlayerId = room.players.get(socket.id)?.id ?? socket.id;
      console.log('[join] sending response to socket=' + socket.id + ' playerId=' + newPlayerId);
      // Enviar respuesta ANTES de emitir room:playersUpdated
      socket.emit('player:joinResponse', { success: true, playerId: newPlayerId });
      console.log('[join] emitting room:playersUpdated to room=' + code);
      io.to(room.code).emit('room:playersUpdated', roomManager.serializePlayers(room));
      console.log('[join] player joined room=' + code + ' socket=' + socket.id + ' playerId=' + newPlayerId);
    } catch (err) {
      console.error('[join] player:joinRoom error', err);
      socket.emit('player:joinResponse', { success: false, error: 'Error interno al unirse' });
    }
  });

  socket.on('player:setCharacter', ({ code, character }) => {
    const room = roomManager.getRoom(code);
    if (!room) return;
    const player = room.players.get(socket.id);
    if (!player) return;
    player.character = character;
    player.customizing = false;
    io.to(room.code).emit('room:playersUpdated', roomManager.serializePlayers(room));
  });

  socket.on('player:customizing', ({ code }) => {
    const room = roomManager.getRoom(code);
    if (!room) return;
    const player = room.players.get(socket.id);
    if (!player) return;
    player.customizing = true;
    io.to(room.code).emit('room:playersUpdated', roomManager.serializePlayers(room));
  });

  socket.on('dm:startBattle', ({ code, monsters, turnOrder }, ack) => {
    const room = roomManager.getRoom(code);
    if (!room) {
      ack?.({ success: false, error: 'Sala no encontrada' });
      return;
    }
    const customizingPlayers = Array.from(room.players.values()).filter((p) => p.customizing);
    if (customizingPlayers.length > 0) {
      const names = customizingPlayers.map((p) => p.name).join(', ');
      ack?.({
        success: false,
        error: 'Los siguientes jugadores aún no terminan de personalizar: ' + names,
      });
      return;
    }
    const playersWithoutCharacter = Array.from(room.players.values()).filter((p) => !p.character);
    if (playersWithoutCharacter.length > 0) {
      const names = playersWithoutCharacter.map((p) => p.name).join(', ');
      ack?.({
        success: false,
        error: 'Jugadores sin personaje: ' + names,
      });
      return;
    }
    const expandedMonsters = [];
    let instanceCounter = 0;
    for (const monster of monsters) {
      const quantity = monster.quantity || 1;
      for (let i = 0; i < quantity; i++) {
        expandedMonsters.push({
          ...monster,
          instanceId: `${monster.id}-${instanceCounter++}-${Date.now()}`,
          currentHp: monster.maxHp,
          name: quantity > 1 ? `${monster.name} ${i + 1}` : monster.name,
          photoBase64: monsterPhotos[monster.id] ?? monster.photoBase64 ?? null,
        });
      }
    }
    room.monsters = expandedMonsters;
    room.battleStarted = true;
    if (Array.isArray(turnOrder) && turnOrder.length > 0) {
      room.turnOrder = turnOrder.map((entry) =>
        entry.type === 'monster'
          ? room.monsters[entry.index]?.instanceId
          : entry.id
      ).filter(Boolean);
    } else {
      room.turnOrder = [...Array.from(room.players.values()).map((p) => p.id), ...room.monsters.map((m) => m.instanceId)];
    }
    room.currentTurnIndex = 0;
    ack?.({ success: true });
    console.log('dm:startBattle: emitiendo battle:started a sala', code, 'monstruos:', room.monsters.length, 'turnOrder:', room.turnOrder.length);
    io.to(code).emit('battle:started', {
      monsters: room.monsters,
      players: roomManager.serializePlayers(room),
      turnOrder: room.turnOrder,
      currentTurnId: room.turnOrder[0] ?? null,
    });
  });

  socket.on('dm:manualDamage', ({ code, targetType, targetId, damage }) => {
    try {
      const room = roomManager.getRoom(code);
      if (!room) {
        console.log('manualDamage: sala no encontrada', code);
        return;
      }
      let targetName = '';
      if (targetType === 'monster') {
        const monster = room.monsters.find((m) => m.instanceId === targetId);
        if (monster) {
          monster.currentHp = Math.max(0, monster.currentHp - damage);
          targetName = monster.name;
        }
      } else if (targetType === 'player') {
        const player = roomManager.findPlayerById(room, targetId);
        if (player && player.character) {
          const currentHp = player.character.currentHp ?? player.character.maxHp;
          const newHp = Math.max(0, currentHp - damage);
          player.character.currentHp = newHp;
          targetName = player.name;
          console.log('manualDamage: updated player', player.name, 'hp', currentHp, '->', newHp);
        } else {
          console.log('manualDamage: player not found or no character for', targetId, 'exists=', !!player, 'char=', !!player?.character);
        }
      }
      io.to(code).emit('battle:effect', {
        targetType,
        targetId,
        targetName,
        damage,
        isDamage: true,
      });
      io.to(code).emit('battle:update', {
        monsters: room.monsters,
        players: roomManager.serializePlayers(room),
      });
      console.log('manualDamage:', targetType, targetName, 'recibió', damage, 'de daño');
    } catch (err) {
      console.error('manualDamage error', err);
    }
  });

  socket.on('battle:action', ({ code, targetType, targetId, damage }) => {
    const room = roomManager.getRoom(code);
    if (!room) return;
    let targetName = '';
    if (targetType === 'monster') {
      const monster = room.monsters.find((m) => m.instanceId === targetId);
      if (monster) {
        monster.currentHp = Math.max(0, monster.currentHp - damage);
        targetName = monster.name;
      }
    } else if (targetType === 'player') {
      const player = roomManager.findPlayerById(room, targetId);
      if (player && player.character) {
        const currentHp = player.character.currentHp ?? player.character.maxHp;
        player.character.currentHp = Math.max(0, currentHp - damage);
        targetName = player.name;
      }
    }
    io.to(code).emit('battle:effect', {
      targetType,
      targetId,
      targetName,
      damage,
      isDamage: true,
    });
    io.to(code).emit('battle:update', {
      monsters: room.monsters,
      players: roomManager.serializePlayers(room),
    });
  });

  socket.on('battle:endTurn', ({ code }) => {
    const room = roomManager.getRoom(code);
    if (!room || room.turnOrder.length === 0) return;
    room.currentTurnIndex = (room.currentTurnIndex + 1) % room.turnOrder.length;
    io.to(code).emit('battle:turnChanged', {
      currentTurnId: room.turnOrder[room.currentTurnIndex],
    });
    io.to(code).emit('battle:update', {
      monsters: room.monsters,
      players: roomManager.serializePlayers(room),
    });
  });

  socket.on('dm:endBattle', ({ code }) => {
    const room = roomManager.getRoom(code);
    if (!room) return;
    room.battleStarted = false;
    room.turnOrder = [];
    room.currentTurnIndex = 0;
    room.monsters = [];
    io.to(code).emit('battle:ended');
  });

  socket.on('dm:assignWeapon', ({ code, playerId, weaponName, dice, icon, imageBase64 }, ack) => {
    try {
      const room = roomManager.getRoom(code);
      if (!room) {
        ack?.({ success: false, error: 'Sala no encontrada' });
        return;
      }
      const player = roomManager.findPlayerById(room, playerId);
      if (!player) {
        ack?.({ success: false, error: 'Jugador no encontrado' });
        return;
      }
      const weapon = {
        id: 'weapon_' + Date.now() + '_' + Math.floor(Math.random() * 10000),
        name: (weaponName || '').trim(),
        description: dice ? 'Daño: ' + dice.trim() : 'Arma asignada por el Dungeon Master',
        effect: 'fuego',
        damageDice: dice ? dice.trim() : null,
        icon: icon || null,
        imageBase64: imageBase64 || null,
      };
      player.weapons.push(weapon);
      const targetSocketId = roomManager.findSocketIdByPlayerId(room, playerId);
      if (targetSocketId) {
        io.to(targetSocketId).emit('weapon:assigned', weapon);
        io.to(targetSocketId).emit('weapon:received', weapon);
      }
      io.to(room.code).emit('room:playersUpdated', roomManager.serializePlayers(room));
      ack?.({ success: true });
    } catch (err) {
      console.error('assignWeapon error', err);
      ack?.({ success: false, error: 'Error interno' });
    }
  });

  socket.on('dm:giveItem', ({ code, playerId, item }) => {
    const room = roomManager.getRoom(code);
    if (!room) return;
    const player = roomManager.findPlayerById(room, playerId);
    if (!player) return;
    player.inventory.push(item);
    const targetSocketId = roomManager.findSocketIdByPlayerId(room, playerId);
    if (targetSocketId) {
      io.to(targetSocketId).emit('inventory:updated', player.inventory);
      io.to(targetSocketId).emit('item:received', item);
    }
    io.to(room.code).emit('room:playersUpdated', roomManager.serializePlayers(room));
  });

  socket.on('player:useItem', ({ code, itemId, targetType, targetId }) => {
    const room = roomManager.getRoom(code);
    if (!room) return;
    const player = room.players.get(socket.id);
    if (!player) return;
    const item = player.inventory.find((i) => i.id === itemId);
    if (!item) return;

    let targetName = 'sí mismo';
    if (targetType === 'player' && targetId) {
      const target = roomManager.findPlayerById(room, targetId);
      if (target) targetName = target.name;
    }

    io.to(room.dmSocketId).emit('item:useRequested', {
      playerId: socket.id,
      playerName: player.name,
      item,
      targetType: targetType ?? 'self',
      targetId: targetId ?? null,
      targetName,
    });
  });

  socket.on('dm:resolveItemUse', ({ code, playerId, itemId, approved, effectValue, targetType, targetId }) => {
    const room = roomManager.getRoom(code);
    if (!room) return;
    const player = roomManager.findPlayerById(room, playerId);
    if (!player) return;
    const index = player.inventory.findIndex((i) => i.id === itemId);
    if (index === -1) return;
    const item = player.inventory[index];

    if (approved && effectValue != null) {
      let targetPlayer = player;
      let targetName = player.name;
      if (targetType === 'player' && targetId) {
        const target = roomManager.findPlayerById(room, targetId);
        if (target) {
          targetPlayer = target;
          targetName = target.name;
        }
      }
      if (targetPlayer.character) {
        const currentHp = targetPlayer.character.currentHp ?? targetPlayer.character.maxHp;
        const isDamage = effectValue < 0;
        const absValue = effectValue.abs();
        targetPlayer.character.currentHp = Math.max(0, Math.min(currentHp + effectValue, targetPlayer.character.maxHp));
        io.to(code).emit('battle:effect', {
          targetType,
          targetId,
          targetName,
          damage: absValue,
          isDamage,
        });
      }
    }

    if (approved) {
      player.inventory.splice(index, 1);
    }

    const targetSocketId = roomManager.findSocketIdByPlayerId(room, playerId);
    if (targetSocketId) {
      io.to(targetSocketId).emit('inventory:updated', player.inventory);
      io.to(targetSocketId).emit('item:useResolved', { itemId, approved: Boolean(approved) });
    }

    let targetName = 'sí mismo';
    if (targetType === 'player' && targetId) {
      const target = roomManager.findPlayerById(room, targetId);
      if (target) targetName = target.name;
    }

    if (targetSocketId) {
      io.to(targetSocketId).emit('item:useResult', {
        itemId,
        itemName: item.name,
        targetType,
        targetName,
        approved: Boolean(approved),
      });
    }

    if (approved && targetType === 'player' && targetId) {
      const targetSocketId = roomManager.findSocketIdByPlayerId(room, targetId);
      if (targetSocketId) {
        io.to(targetSocketId).emit('item:usedOnYou', {
          playerName: player.name,
          itemName: item.name,
        });
      }
    }

    io.to(room.code).emit('room:playersUpdated', roomManager.serializePlayers(room));
  });

  socket.on('dm:setEntityHp', ({ code, targetType, targetId, hp }) => {
    const room = roomManager.getRoom(code);
    if (!room) return;
    if (targetType === 'monster') {
      const monster = room.monsters.find((m) => m.instanceId === targetId);
      if (monster) {
        monster.currentHp = Math.max(0, Math.min(hp, monster.maxHp || hp));
      }
    } else if (targetType === 'player') {
      const player = roomManager.findPlayerById(room, targetId);
      if (player && player.character) {
        player.character.currentHp = Math.max(0, Math.min(hp, player.character.maxHp || hp));
      }
    }
    io.to(code).emit('battle:update', {
      monsters: room.monsters,
      players: roomManager.serializePlayers(room),
    });
  });

  socket.on('dm:updatePlayer', ({ code, playerId, updates }) => {
    const room = roomManager.getRoom(code);
    if (!room) return;
    const player = roomManager.findPlayerById(room, playerId);
    if (!player) return;
    if (updates.name) player.name = updates.name;
    if (updates.character && player.character) {
      player.character = { ...player.character, ...updates.character };
    }
    io.to(code).emit('battle:update', {
      monsters: room.monsters,
      players: roomManager.serializePlayers(room),
    });
    io.to(room.code).emit('room:playersUpdated', roomManager.serializePlayers(room));
  });

  socket.on('dm:sharePhoto', ({ code, imageBase64 }) => {
    socket.to(code).emit('photo:shared', { imageBase64 });
  });

  socket.on('dm:setMonsterPhoto', ({ code, instanceId, imageBase64 }) => {
    const room = roomManager.getRoom(code);
    if (!room) return;
    const monster = room.monsters.find((m) => m.instanceId === instanceId);
    if (!monster) return;
    monster.photoBase64 = imageBase64;
    monsterPhotos[monster.id] = imageBase64;
    saveMonsterPhotos();
    io.to(code).emit('battle:update', {
      monsters: room.monsters,
      players: roomManager.serializePlayers(room),
    });
  });

  socket.on('disconnect', () => {
    const { rooms: affectedRooms, playerId } = roomManager.removeSocket(socket.id);
    for (const room of affectedRooms) {
      io.to(room.code).emit('room:playersUpdated', roomManager.serializePlayers(room));
      if (room.battleStarted) {
        io.to(room.code).emit('battle:update', {
          monsters: room.monsters,
          players: roomManager.serializePlayers(room),
        });
      }
    }
    setTimeout(() => {
      for (const room of affectedRooms) {
        const saved = roomManager.disconnectedPlayers.get(playerId);
        if (saved && saved.roomCode === room.code) {
          roomManager.disconnectedPlayers.delete(playerId);
          room.players.delete(socket.id);
          io.to(room.code).emit('room:playersUpdated', roomManager.serializePlayers(room));
          if (room.battleStarted) {
            io.to(room.code).emit('battle:update', {
              monsters: room.monsters,
              players: roomManager.serializePlayers(room),
            });
          }
        }
      }
    }, 3600000);
  });
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, '0.0.0.0', () => {
  const localIp = getLocalIPv4();
  console.log(`Servidor DYD escuchando en puerto ${PORT}`);
  console.log(`Accesible desde la red en http://${localIp}:${PORT}`);
  console.log(`Discovery UDP en puerto ${DISCOVERY_PORT}`);
  console.log(`IMPORTANTE: Permití el puerto ${PORT} en el firewall de Windows para conexiones externas.`);
});

app.get('/ip', (_req, res) => {
  console.log(`[server] IP request from ${_req.ip}`);
  res.json({ ip: getLocalIPv4(), port: PORT });
});

const DISCOVERY_PORT = 8081;
const DISCOVERY_MSG = 'DYD_SERVER';

function getLocalIPv4() {
  const interfaces = os.networkInterfaces();
  
  // Colección de IPs por rango de red local
  const ipRanges = {
    '192.168': [],
    '10': [],
    '172': []
  };
  
  // Reagrupar IPs por rango
  for (const iface of Object.values(interfaces)) {
    for (const addr of iface) {
      if (addr.family === 'IPv4' && !addr.internal) {
        const ip = addr.address;
        if (ip === '127.0.0.1') continue;
        
        // Determinar rango
        let range = '';
        if (ip.startsWith('192.168.')) {
          range = '192.168';
        } else if (ip.startsWith('10.')) {
          range = '10';
        } else if (ip.startsWith('172.16.') || ip.startsWith('172.17.') || ip.startsWith('172.18.') || ip.startsWith('172.19.') || ip.startsWith('172.20.') || ip.startsWith('172.21.') || ip.startsWith('172.22.') || ip.startsWith('172.23.') || ip.startsWith('172.24.') || ip.startsWith('172.25.') || ip.startsWith('172.26.') || ip.startsWith('172.27.') || ip.startsWith('172.28.') || ip.startsWith('172.29.') || ip.startsWith('172.30.') || ip.startsWith('172.31.')) {
          range = '172';
        }
        
        if (range) {
          ipRanges[range].push(ip);
        }
      }
    }
  }
  
  // Priorizar por rango: 192.168.x.x > 10.x.x.x > 172.x.x.x
  if (ipRanges['192.168'].length > 0) {
    return ipRanges['192.168'][0];
  }
  if (ipRanges['10'].length > 0) {
    return ipRanges['10'][0];
  }
  if (ipRanges['172'].length > 0) {
    return ipRanges['172'][0];
  }
  
  // Fallback: cualquier IP IPv4
  for (const iface of Object.values(interfaces)) {
    for (const addr of iface) {
      if (addr.family === 'IPv4' && addr.address !== '127.0.0.1' && !addr.address.includes('::')) {
        return addr.address;
      }
    }
  }
  
  return 'localhost';
}

function getBroadcastAddress() {
  const interfaces = os.networkInterfaces();
  for (const [name, iface] of Object.entries(interfaces)) {
    for (const addr of iface) {
      if (addr.family === 'IPv4' && !addr.internal) {
        const ip = addr.address.split('.').map(Number);
        const netmask = addr.netmask.split('.').map(Number);
        const broadcast = ip.map((octet, i) => octet | (~netmask[i] & 255));
        return broadcast.join('.');
      }
    }
  }
  return '255.255.255.255';
}

const udpSocket = dgram.createSocket('udp4');

udpSocket.on('listening', () => {
  console.log(`Discovery UDP escuchando en puerto ${DISCOVERY_PORT}`);
});

udpSocket.on('message', (_msg, _rinfo) => {
  // Ignoramos mensajes entrantes; el servidor solo anuncia.
});

udpSocket.on('error', (err) => {
  console.error('Discovery UDP error:', err.message);
});

  udpSocket.bind(DISCOVERY_PORT, () => {
    console.log(`Discovery UDP escuchando en puerto ${DISCOVERY_PORT}`);
  });
  
  // Desactivar broadcast en entornos que no lo soportan (Railway, etc.)
  const enableBroadcast = false;
  
  setInterval(() => {
    if (!enableBroadcast) return;
    const ip = getLocalIPv4();
  // Obtener salas disponibles
  const rooms = [];
  for (const [code, room] of roomManager.rooms) {
    rooms.push({
      code,
      players: room.players.size,
      battleStarted: room.battleStarted,
      created: room.created_at
    });
  }
  const message = Buffer.from(`${DISCOVERY_MSG}|${ip}|${PORT}|${JSON.stringify(rooms)}`);
  const broadcastAddress = getBroadcastAddress();
  udpSocket.send(message, DISCOVERY_PORT, broadcastAddress, (err) => {
    if (err) console.error('Error broadcasting discovery:', err.message);
  });
}, 60000);

// Catch uncaught exceptions
process.on('uncaughtException', (err) => {
  console.log('[SERVER] UNCAUGHT EXCEPTION: ' + err);
  console.log('[SERVER] STACK: ' + err.stack);
});

process.on('unhandledRejection', (reason, promise) => {
  console.log('[SERVER] UNHANDLED REJECTION: ' + reason);
});
