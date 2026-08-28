const { io } = require('socket.io-client');

const SERVER_URL = 'https://dyd-server-production.up.railway.app';

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
      console.log('Evento enviado, esperando respuesta...');
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
      console.log('✗ Desconectado:', reason);
      if (!socket._responseReceived) {
        clearTimeout(timeout);
        reject(new Error('Desconectado antes de recibir respuesta: ' + reason));
      }
    });

    socket.on('error', (err) => {
      console.log('✗ Error de socket:', err);
    });

    socket.onAny((event, ...args) => {
      console.log('Evento recibido:', event, JSON.stringify(args).substring(0, 200));
    });
  });
}

async function main() {
  try {
    const result = await testJoinRoom('TZ6AJ');
    console.log('\n=== RESULTADO ===');
    console.log('✓ Test pasó!', result);
    result.socket.disconnect();
  } catch (e) {
    console.log('\n=== RESULTADO ===');
    console.log('✗ Error:', e.message);
  }
  
  process.exit(0);
}

main();
