const http = require('http');
const { createProxyMiddleware } = require('http-proxy-middleware');
const express = require('express');

const app = express();

// Proxy configuration for Kubernetes Ingress
const proxy = createProxyMiddleware({
  target: 'http://localhost:80',
  changeOrigin: true,
  onProxyReq: (proxyReq, req, res) => {
    // Add Host header for Kubernetes Ingress
    proxyReq.setHeader('Host', 'cinemaabyss.example.com');
    console.log(`[PROXY] ${req.method} ${req.url} -> localhost:80 (Host: cinemaabyss.example.com)`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`[RESPONSE] ${proxyRes.statusCode} ${req.url}`);
  },
  onError: (err, req, res) => {
    console.error(`[ERROR] ${req.url}:`, err.message);
    res.writeHead(500, {
      'Content-Type': 'text/plain'
    });
    res.end('Proxy error: ' + err.message);
  }
});

// Use proxy for all requests
app.use('/', proxy);

const PORT = 3000;
const server = app.listen(PORT, () => {
  console.log(`🌐 CinemaAbyss Proxy Server started on port ${PORT}`);
  console.log(`📡 Proxying cinemaabyss.example.com -> localhost:80 with Host header`);
  console.log(`🎯 Test URL: http://localhost:${PORT}/api/movies`);
  console.log(`🔄 All requests will be forwarded to Kubernetes Ingress with proper Host header`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 Shutting down proxy server...');
  server.close(() => {
    console.log('✅ Proxy server shut down gracefully');
  });
});

process.on('SIGINT', () => {
  console.log('🛑 Shutting down proxy server...');
  server.close(() => {
    console.log('✅ Proxy server shut down gracefully');
  });
});