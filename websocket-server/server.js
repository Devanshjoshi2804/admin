const WebSocket = require('ws');
const http = require('http');

// Create HTTP server
const server = http.createServer();

// Create WebSocket server
const wss = new WebSocket.Server({ 
  server,
  path: '/ws',
  verifyClient: (info) => {
    // Allow connections from localhost and your app
    const origin = info.origin;
    return true; // For development, allow all origins
  }
});

// Store connected clients
const clients = new Set();

// Broadcast message to all connected clients
function broadcast(message) {
  const messageStr = JSON.stringify(message);
  clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      try {
        client.send(messageStr);
        console.log('✅ Broadcasted message:', message.type);
      } catch (error) {
        console.error('❌ Error sending message to client:', error);
        clients.delete(client);
      }
    }
  });
}

// WebSocket connection handler
wss.on('connection', (ws, request) => {
  console.log('🔗 New WebSocket connection from:', request.socket.remoteAddress);
  
  // Add client to set
  clients.add(ws);
  
  // Send welcome message
  ws.send(JSON.stringify({
    type: 'CONNECTED',
    message: 'Real-time updates enabled',
    timestamp: new Date().toISOString()
  }));

  // Handle client messages
  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data);
      console.log('📨 Received message:', message);
      
      // Echo message back for testing
      ws.send(JSON.stringify({
        type: 'ECHO',
        data: message,
        timestamp: new Date().toISOString()
      }));
    } catch (error) {
      console.error('❌ Error parsing message:', error);
    }
  });

  // Handle client disconnect
  ws.on('close', (code, reason) => {
    console.log('🔌 Client disconnected:', code, reason?.toString());
    clients.delete(ws);
  });

  // Handle errors
  ws.on('error', (error) => {
    console.error('❌ WebSocket error:', error);
    clients.delete(ws);
  });
});

// Simulate real-time updates for demo
setInterval(() => {
  // Simulate trip updates
  if (Math.random() > 0.7) {
    broadcast({
      type: 'TRIP_UPDATED',
      data: {
        tripId: `TRIP${Math.floor(Math.random() * 1000)}`,
        orderNumber: `ORD${Math.floor(Math.random() * 10000)}`,
        status: ['In Transit', 'Delivered', 'Completed'][Math.floor(Math.random() * 3)],
        timestamp: new Date().toISOString()
      }
    });
  }

  // Simulate payment updates
  if (Math.random() > 0.8) {
    broadcast({
      type: 'PAYMENT_STATUS_CHANGED',
      data: {
        tripId: `TRIP${Math.floor(Math.random() * 1000)}`,
        paymentType: Math.random() > 0.5 ? 'advance' : 'balance',
        newStatus: ['Initiated', 'Pending', 'Paid'][Math.floor(Math.random() * 3)],
        timestamp: new Date().toISOString()
      }
    });
  }

  // Simulate balance changes
  if (Math.random() > 0.9) {
    const oldAmount = Math.floor(Math.random() * 50000) + 10000;
    const newAmount = oldAmount + Math.floor(Math.random() * 10000);
    
    broadcast({
      type: 'BALANCE_AMOUNT_CHANGED',
      data: {
        tripId: `TRIP${Math.floor(Math.random() * 1000)}`,
        oldAmount,
        newAmount,
        reason: 'Additional charges applied',
        timestamp: new Date().toISOString()
      }
    });
  }
}, 15000); // Send updates every 15 seconds

// Server status endpoint
server.on('request', (req, res) => {
  if (req.url === '/status') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'active',
      clients: clients.size,
      uptime: process.uptime(),
      timestamp: new Date().toISOString()
    }));
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});

// Start server
const PORT = process.env.WS_PORT || 3001;
server.listen(PORT, () => {
  console.log(`🚀 WebSocket server running on port ${PORT}`);
  console.log(`📡 WebSocket endpoint: ws://localhost:${PORT}/ws`);
  console.log(`📊 Status endpoint: http://localhost:${PORT}/status`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 Shutting down WebSocket server...');
  wss.close(() => {
    server.close(() => {
      console.log('✅ WebSocket server closed');
      process.exit(0);
    });
  });
});

// Export broadcast function for external use
module.exports = { broadcast }; 