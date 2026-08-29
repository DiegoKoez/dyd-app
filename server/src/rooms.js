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

  // Reconectar jugador con nuevo socket ID
  reconnectPlayer(code, newSocketId, playerId) {
    const room = this.rooms.get(code);
    if (!room) return null;
    
    // Buscar al jugador en la sala por su playerId
    let foundPlayer = null;
    let oldSocketId = null;
    for (const [sid, player] of room.players) {
      if ((player.id ?? sid) === playerId) {
        foundPlayer = player;
        oldSocketId = sid;
        break;
      }
    }
    
    if (foundPlayer) {
      // Actualizar socket ID
      room.players.delete(oldSocketId);
      room.players.set(newSocketId, foundPlayer);
      foundPlayer.disconnected = false;
      foundPlayer.disconnectTime = null;
      
      // Limpiar de disconnectedPlayers
      this.disconnectedPlayers.delete(playerId);
      
      return { room, player: foundPlayer, reconnected: true };
    }
    
    // No encontrado, verificar en disconnectedPlayers
    const saved = this.disconnectedPlayers.get(playerId);
    if (saved && saved.roomCode === code) {
      room.players.set(newSocketId, saved.player);
      saved.player.disconnected = false;
      saved.player.disconnectTime = null;
      this.disconnectedPlayers.delete(playerId);
      return { room, player: saved.player, reconnected: true };
    }
    
    return null;
  }

  // Verificar si un jugador está en alguna sala
  findRoomByPlayerId(playerId) {
    for (const [code, room] of this.rooms) {
      for (const [sid, player] of room.players) {
        if ((player.id ?? sid) === playerId) {
          return { room, code, socketId: sid };
        }
      }
    }
    // Verificar en disconnectedPlayers
    const saved = this.disconnectedPlayers.get(playerId);
    if (saved) {
      return { room: this.rooms.get(saved.roomCode), code: saved.roomCode, socketId: saved.socketId };
    }
    return null;
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
