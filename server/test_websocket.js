const { io } = require('socket.io-client');

const SERVER_URL = 'http://localhost:8080';

async function testCreateRoom() {
  console.log('=== TEST: Crear sala (WebSocket) ===');
  console.log('Conectando a:', SERVER_URL);
  
  const socket = io(SERVER_URL, {
    transports: ['websocket'],
    timeout: 30000,
  });

  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      socket.disconnect();
      reject(new Error('Timeout de conexión'));
    }, 30000);

    socket.on('connect', () => {
      console.log('✓ Conectado! Socket ID:', socket.id);
      console.log('Creando sala...');
      socket.emit('dm:createRoom', {}, (response) => {
        console.log('✓ Sala creada! Código:', response.code);
        clearTimeout(timeout);
        resolve({ socket, code: response.code });
      });
    });

    socket.on('connect_error', (err) => {
      console.log('✗ Error de conexión:', err.message);
      clearTimeout(timeout);
      reject(err);
    });
  });
}

async function testJoinRoom(code) {
  console.log('\n=== TEST: Unirse a sala (WebSocket) ===');
  console.log('Conectando a:', SERVER_URL);
  
  const socket = io(SERVER_URL, {
    transports: ['websocket'],
    timeout: 30000,
  });

  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      socket.disconnect();
      reject(new Error('Timeout de conexión'));
    }, 30000);

    socket.on('connect', () => {
      console.log('✓ Conectado! Socket ID:', socket.id);
      console.log('Uniéndose a sala:', code);
      socket.emit('player:joinRoom', {
        code: code,
        playerName: 'JugadorTest'
      });
    });

    socket.on('player:joinResponse', (response) => {
      console.log('✓ Respuesta de unión:', response);
      if (response.success) {
        console.log('✓ ¡Unido exitosamente! PlayerID:', response.playerId);
        clearTimeout(timeout);
        resolve({ socket, playerId: response.playerId });
      } else {
        console.log('✗ Error al unirse:', response.error);
        clearTimeout(timeout);
        reject(new Error(response.error));
      }
    });

    socket.on('connect_error', (err) => {
      console.log('✗ Error de conexión:', err.message);
      clearTimeout(timeout);
      reject(err);
    });

    socket.on('disconnect', (reason) => {
      console.log('Desconectado:', reason);
    });
  });
}

async function main() {
  try {
    const { socket: creatorSocket, code } = await testCreateRoom();
    creatorSocket.disconnect();
    
    const { socket: playerSocket, playerId } = await testJoinRoom(code);
    playerSocket.disconnect();
    
    console.log('\n=== RESULTADO ===');
    console.log('✓ Todos los tests pasaron!');
    console.log('  - Sala creada con código:', code);
    console.log('  - Jugador unido con ID:', playerId);
  } catch (e) {
    console.log('\n=== RESULTADO ===');
    console.log('✗ Error:', e.message);
  }
  
  process.exit(0);
}

main();
