const http = require('http');
const { Server } = require('socket.io');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ ok: true }));
});

const io = new Server(server, {
  cors: { origin: '*' },
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
  console.log('Minimal config server on port ' + PORT);
});
