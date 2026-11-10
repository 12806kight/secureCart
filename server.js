const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  // ALB Health Check Endpoint
  if (req.url === '/health' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ status: 'UP', timestamp: new Date().toISOString() }));
  }

  // Fallback serving a simple message
  res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end('<h1>🛒 Welcome to SecureCart</h1><p>Application tier successfully running inside Docker!</p>');
});

server.listen(PORT, () => {
  console.log(`SecureCart server is running on port ${PORT}`);
});
