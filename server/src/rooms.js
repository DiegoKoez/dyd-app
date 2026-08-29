const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function generateCode() {
  let code = '';
  for (let i = 0; i < 5; i++) {
    code += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
  }
  return code;
}

class RoomManager {
  constructor() {
    /** @type {Map<string, object>} */
    this.rooms = new Map();
    /** @type {Map<string, {roomCode: string, player: object}>} */
    this.disconnectedPlayers = new Map();
  }

  createRoom(dmSocketId) {
    let code;
    do {
      code = generateCode();
    } while (this.rooms.has(code));

    const room = {
      code,
      dmSocketId,
      players: new Map(),
      monsters: [],
      battleStarted: false,
      turnOrder: [],
      currentTurnIndex: 0,
      created_at: Date.now(),
    };
    this.rooms.set(code, room);
    return room;
  }

  getRoom(code) {
    return this.rooms.get(code);
  }

  joinRoom(code, socketId, playerName, playerId) {
    const room = this.rooms.get(code);
    if (!room) return null;

    const saved = this.disconnectedPlayers.get(playerId ?? socketId);
    if (saved && saved.roomCode === code) {
      room.players.set(socketId, saved.player);
      this.disconnectedPlayers.delete(saved.player.id ?? playerId ?? socketId);
    } else {
      room.players.set(socketId, {
        id: playerId ?? socketId,
        name: playerName,
        character: null,
        inventory: [],
        weapons: [],
        customizing: true,
      });
    }
    return room;
  }

  serializePlayers(room) {
    return Array.from(room.players.values());
  }

  findPlayerById(room, playerId) {
    for (const player of room.players.values()) {
      if (player.id === playerId) return player;
    }
    return null;
  }

  findSocketIdByPlayerId(room, playerId) {
    for (const [socketId, player] of room.players) {
      if (player.id === playerId) return socketId;
    }
    return null;
  }

  removeSocket(socketId) {
    const affected = [];
    let playerId = socketId;
    for (const room of this.rooms.values()) {
      const wasInRoom = room.players.has(socketId);
      if (wasInRoom) {
        const player = room.players.get(socketId);
        playerId = player.id ?? socketId;
        
        // Marcar como desconectado pero NO eliminar inmediatamente
        // El jugador tiene 60 segundos para reconectar
        player.disconnected = true;
        player.disconnectTime = Date.now();
        
        this.disconnectedPlayers.set(playerId, {
          roomCode: room.code,
          player,
          socketId,
        });
        
        // No eliminar de room.players - esperar reconexión
        // room.players.delete(socketId);
        
        if (room.dmSocketId === socketId) {
          room.dmDisconnected = true;
        }
        // No eliminar de turnOrder
        affected.push(room);
      }
    }
    return { rooms: affected, playerId };
  }
  
  // Limpiar jugadores que no se reconectaron después de 60 segundos
  cleanupDisconnectedPlayers() {
    const now = Date.now();
    const timeout = 60000; // 60 segundos
    
    for (const [playerId, data] of this.disconnectedPlayers) {
      if (data.player.disconnectTime && now - data.player.disconnectTime > timeout) {
        // Eliminar jugador de la sala
        const room = this.rooms.get(data.roomCode);
        if (room) {
          // Eliminar de players
          for (const [sid, p] of room.players) {
            if ((p.id ?? sid) === playerId) {
              room.players.delete(sid);
              break;
            }
          }
          // Eliminar de turnOrder
          room.turnOrder = room.turnOrder.filter((id) => id !== playerId);
        }
        this.disconnectedPlayers.delete(playerId);
      }
    }
  }
}

module.exports = { RoomManager, generateCode };
