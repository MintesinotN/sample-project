console.log("LiveView debug initialized");

const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  debug: true // Enable verbose logging
});

// Log all LiveView events
liveSocket.enableDebug();
liveSocket.enableLatencySim(1000 + Math.random() * 1000);

liveSocket.connect();