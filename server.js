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

  // Serve valid UTF-8 HTML with HTML entity for the shopping cart icon
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>SecureCart</title>
    </head>
    <body>
      <h1>&#128722; Welcome to SecureCart</h1>
      <p>Application tier successfully running inside Docker!</p>
    </body>
    </html>
  `);
});

server.listen(PORT, () => {
  console.log(`SecureCart server is running on port ${PORT}`);
});
