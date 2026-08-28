const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
app.use(cors({ origin: '*' }));
app.get('/health', (_req, res) => res.json({ ok: true }));

const server = http.createServer(app);

const io = new Server(server, {
  cors: { origin: '*' },
  pingInterval: 10000,
  pingTimeout: 15000,
  transports: ['polling', 'websocket'],
});

io.on('connection', (socket) => {
  console.log('CLIENT CONNECTED!', socket.id);
  socket.on('disconnect', () => console.log('DISCONNECTED:', socket.id));
});

io.on('connection_error', (err) => {
  console.log('CONNECTION ERROR:', err.message);
});

io.engine.on('initial_headers', (headers, req) => {
  console.log('INITIAL HEADERS:', req.url);
});

io.engine.on('handshake', (data) => {
  console.log('HANDSHAKE');
});

io.engine.on('connection_error', (err) => {
  console.log('ENGINE ERROR:', err.code, err.message);
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, '0.0.0.0', () => {
  console.log('Minimal server on port ' + PORT);
});
