const http = require('http');

const server = http.createServer((req, res) => {
  console.log('REQUEST:', req.method, req.url, 'from', req.socket.remoteAddress);
  res.writeHead(200, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
  });
  res.end(JSON.stringify({ ok: true, url: req.url }));
});

server.listen(3000, '0.0.0.0', () => {
  console.log('HTTP test server on port 3000');
});

server.on('error', (err) => {
  console.log('SERVER ERROR:', err);
});
