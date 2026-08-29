const { io } = require('socket.io-client');

const SERVER_URL = 'http://localhost:8080';

async function test() {
  console.log('=== TEST: Crear sala y unirse ===');
  
  let roomCode;
  
  // Crear sala (DM)
  const dmSocket = io(SERVER_URL, { transports: ['websocket'] });
  
  await new Promise((resolve) => {
    dmSocket.on('connect', () => {
      console.log('✓ DM conectado:', dmSocket.id);
      dmSocket.emit('dm:createRoom', {}, (response) => {
        roomCode = response.code;
        console.log('✓ Sala creada:', roomCode);
        resolve();
      });
    });
  });
  
  // Escuchar actualizaciones de jugadores
  dmSocket.on('room:playersUpdated', (players) => {
    console.log('✓ DM ve jugadores:', players.length);
    players.forEach(p => console.log('  -', p.name, p.id, p.disconnected ? '(desconectado)' : ''));
  });
  
  await new Promise((resolve) => setTimeout(resolve, 500));
  
  // Unirse a la sala (Jugador)
  const playerSocket = io(SERVER_URL, { transports: ['websocket'] });
  
  playerSocket.on('connect', () => {
    console.log('✓ Jugador conectado:', playerSocket.id);
    playerSocket.emit('player:joinRoom', {
      code: roomCode,
      playerName: 'JugadorTest',
    });
  });
  
  playerSocket.on('player:joinResponse', (response) => {
    console.log('✓ Respuesta de unión:', response);
  });
  
  playerSocket.on('room:playersUpdated', (players) => {
    console.log('✓ Jugador ve jugadores:', players.length);
    players.forEach(p => console.log('  -', p.name, p.id, p.disconnected ? '(desconectado)' : ''));
  });
  
  // Esperar 3 segundos
  await new Promise((resolve) => setTimeout(resolve, 3000));
  
  console.log('\n=== TEST: Minimizar jugador (desconectar) ===');
  playerSocket.disconnect();
  
  await new Promise((resolve) => setTimeout(resolve, 2000));
  
  console.log('\n=== TEST: Jugador vuelve (reconectar) ===');
  const playerSocket2 = io(SERVER_URL, { transports: ['websocket'] });
  
  playerSocket2.on('connect', () => {
    console.log('✓ Jugador reconectado:', playerSocket2.id);
    // Intentar unirse de nuevo con el mismo playerId
    playerSocket2.emit('player:joinRoom', {
      code: roomCode,
      playerName: 'JugadorTest',
      playerId: 'test-player-id',
    });
  });
  
  playerSocket2.on('player:joinResponse', (response) => {
    console.log('✓ Respuesta de unión (reconexión):', response);
  });
  
  await new Promise((resolve) => setTimeout(resolve, 3000));
  
  dmSocket.disconnect();
  playerSocket2.disconnect();
  process.exit(0);
}

test();
