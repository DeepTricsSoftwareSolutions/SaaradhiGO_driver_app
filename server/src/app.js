const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');

const path = require('path');

// Load environment variables
dotenv.config();

const app = express();

// Serve static uploads
app.use('/uploads', express.static(path.join(__dirname, '../../uploads')));

// ─── Security Middleware ───────────────────────────────────────────────────
app.use(helmet({
    crossOriginResourcePolicy: false, // Allow S3 image loading
}));

// ─── CORS ─────────────────────────────────────────────────────────────────
const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [
    'http://localhost:3000',
    'http://localhost:5173',
    'http://127.0.0.1:5173',
];

app.use(cors({
    origin: (origin, callback) => {
        // Universal allowance in local development to prevent Flutter Web / Chrome port bugs crashing the server.
        callback(null, true);
    },
    credentials: true,
}));

// ─── Rate Limiting ─────────────────────────────────────────────────────────
const authLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 10,             // 10 OTP requests per minute
    message: { status: 'ERR', message: 'Too many requests. Please try again after a minute.' },
    skipSuccessfulRequests: false,
});

const generalLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 200,            // 200 API requests per minute
    message: { status: 'ERR', message: 'Rate limit exceeded.' },
});

// ─── Body Parsers ──────────────────────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ─── Logging ──────────────────────────────────────────────────────────────
if (process.env.NODE_ENV !== 'test') {
    app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
}

// ─── Health Check ─────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
    res.json({
        status: 'OK',
        service: 'SaaradhiGO Driver API',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        env: process.env.NODE_ENV || 'development',
    });
});

// ─── Import Routes ────────────────────────────────────────────────────────
const authRoutes = require('./routes/auth.routes');
const driverRoutes = require('./routes/driver.routes');
const rideRoutes = require('./routes/ride.routes');
const earningRoutes = require('./routes/earning.routes');
const walletRoutes = require('./routes/wallet.routes');

// ─── Mount Routes ─────────────────────────────────────────────────────────
// Support both /api/v1 and /api for backwards compatibility
const mountRoutes = (prefix) => {
    app.use(`${prefix}/auth`, authLimiter, authRoutes);
    app.use(`${prefix}/driver`, generalLimiter, driverRoutes);
    app.use(`${prefix}/rides`, generalLimiter, rideRoutes);
    app.use(`${prefix}/earnings`, generalLimiter, earningRoutes);
    app.use(`${prefix}/wallet`, generalLimiter, walletRoutes);
    app.get(prefix, (req, res) => res.json({ status: 'OK', message: 'SaaradhiGO API is running', version: '1.0.0' }));
};

mountRoutes('/api/v1');
mountRoutes('/api'); // Flutter app uses /api

// ─── 404 Handler ──────────────────────────────────────────────────────────
app.use('*', (req, res) => {
    res.status(404).json({ status: 'ERR', message: `Route ${req.originalUrl} not found` });
});

// ─── Global Error Handler ─────────────────────────────────────────────────
app.use((err, req, res, next) => {
    // Don't leak stack traces in production
    const isDev = process.env.NODE_ENV !== 'production';
    console.error('[ERROR]', err.message);
    if (isDev) console.error(err.stack);

    res.status(err.status || 500).json({
        status: 'ERR',
        message: err.message || 'Internal server error',
        ...(isDev && { stack: err.stack }),
    });
});

module.exports = app;
