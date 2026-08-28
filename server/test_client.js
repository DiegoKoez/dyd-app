const { io } = require('socket.io-client');

const socket = io('https://dyd-server-production.up.railway.app', {
  transports: ['websocket'],
  timeout: 10000,
});

socket.on('connect', () => {
  console.log('CONNECTED!', socket.id);
  process.exit(0);
});

socket.on('connect_error', (err) => {
  console.log('CONNECT ERROR:', err.message);
});

socket.on('disconnect', (reason) => {
  console.log('DISCONNECTED:', reason);
});

// Log all events
socket.onAny((event, ...args) => {
  console.log('EVENT:', event, args);
});

setTimeout(() => {
  console.log('TIMEOUT - forcing exit');
  process.exit(1);
}, 15000);
