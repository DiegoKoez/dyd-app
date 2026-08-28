const { io } = require('socket.io-client');

const SERVER_URL = 'https://dyd-server-production.up.railway.app';

async function testCreateRoom() {
  console.log('=== TEST: Crear sala ===');
  console.log('Conectando a:', SERVER_URL);
  
  const socket = io(SERVER_URL, {
    transports: ['polling'],
    timeout: 120000,
  });

  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      socket.disconnect();
      reject(new Error('Timeout de conexión'));
    }, 120000);

    socket.on('connect', () => {
      console.log('✓ Conectado! Socket ID:', socket.id);
      
      // Crear sala
      console.log('Creando sala...');
      socket.emitWithAck('dm:createRoom', {}).then((response) => {
        console.log('✓ Sala creada! Código:', response.code);
        clearTimeout(timeout);
        resolve({ socket, code: response.code });
      }).catch((err) => {
        console.log('✗ Error al crear sala:', err);
        clearTimeout(timeout);
        // Intentar con emit normal
        socket.emit('dm:createRoom', {});
        setTimeout(() => {
          clearTimeout(timeout);
          resolve({ socket, code: 'MANUAL' });
        }, 5000);
      });
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

async function testJoinRoom(code) {
  console.log('\n=== TEST: Unirse a sala ===');
  console.log('Conectando a:', SERVER_URL);
  
  const socket = io(SERVER_URL, {
    transports: ['polling'],
    timeout: 120000,
  });

  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      socket.disconnect();
      reject(new Error('Timeout de conexión'));
    }, 120000);

    socket.on('connect', () => {
      console.log('✓ Conectado! Socket ID:', socket.id);
      
      // Unirse a sala
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
    // Test 1: Crear sala
    const { socket: creatorSocket, code } = await testCreateRoom();
    creatorSocket.disconnect();
    
    if (code && code !== 'MANUAL') {
      // Test 2: Unirse a sala
      const { socket: playerSocket, playerId } = await testJoinRoom(code);
      playerSocket.disconnect();
      
      console.log('\n=== RESULTADO ===');
      console.log('✓ Todos los tests pasaron!');
      console.log('  - Sala creada con código:', code);
      console.log('  - Jugador unido con ID:', playerId);
    } else {
      console.log('\n=== RESULTADO ===');
      console.log('⚠ La sala no se creó correctamente');
    }
  } catch (e) {
    console.log('\n=== RESULTADO ===');
    console.log('✗ Error:', e.message);
  }
  
  process.exit(0);
}

main();
