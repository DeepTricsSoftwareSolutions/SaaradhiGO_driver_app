const http = require('http');
const app = require('./app');
const config = require('./config');
const { initSocket } = require('./socket');

const PORT = config.PORT || 3000;
const server = http.createServer(app);

// Initialize Socket.io with the HTTP server
initSocket(server);

// ─── Start Server ─────────────────────────────────────────────────────────
server.listen(PORT, '0.0.0.0', () => {
    const isDev = process.env.NODE_ENV !== 'production';
    console.log('\n╔══════════════════════════════════════════════╗');
    console.log('║       🚀  SaaradhiGO Driver API             ║');
    console.log('╠══════════════════════════════════════════════╣');
    console.log(`║  Port   : ${PORT}`);
    console.log(`║  Mode   : ${process.env.NODE_ENV || 'development'}`);
    console.log(`║  API    : http://localhost:${PORT}/api`);
    console.log(`║  Health : http://localhost:${PORT}/health`);
    if (isDev) {
        console.log(`║  Studio : npx prisma studio`);
    }
    console.log('╚══════════════════════════════════════════════╝\n');
});

// ─── Graceful Shutdown ────────────────────────────────────────────────────
const gracefulShutdown = (signal) => {
    console.log(`\n[Server] Received ${signal}. Shutting down gracefully...`);
    server.close((err) => {
        if (err) {
            console.error('[Server] Error during shutdown:', err);
            process.exit(1);
        }
        console.log('[Server] HTTP server closed.');
        process.exit(0);
    });

    // Force close after 10 seconds
    setTimeout(() => {
        console.error('[Server] Forcing exit after 10s timeout');
        process.exit(1);
    }, 10_000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// ─── Error Handlers ───────────────────────────────────────────────────────
process.on('uncaughtException', (err) => {
    console.error('[CRITICAL] Uncaught Exception:', err);
    gracefulShutdown('uncaughtException');
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('[ERROR] Unhandled Rejection at:', promise, 'reason:', reason);
    // Don't exit — log and continue (PM2 will restart if it crashes)
});
