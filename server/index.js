const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const { Server } = require('socket.io');
const http = require('http');
const multer = require('multer');
const upload = multer();

const app = express();
const server = http.createServer(app);
const PORT = 8000;
const JWT_SECRET = 'your_secret_key';

app.use(express.json());
app.use(cors());

// --- SOCKET.IO SETUP ---
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

io.on('connection', (socket) => {
    console.log(`[Socket] ✅ Connected: ${socket.id}`);
    
    socket.on('register_driver', (driverId) => {
        console.log(`[Socket] Driver ${driverId} registered`);
        socket.join(`driver:${driverId}`);
    });

    socket.on('update_location', (data) => {
        // console.log(`[Socket] Location update from ${data.driverId}: ${data.lat}, ${data.lng}`);
    });

    socket.on('accept_ride', (data) => {
        console.log(`[Socket] Driver accepted ride: ${data.rideId}`);
        socket.emit('ride_accept_confirmed', { rideId: data.rideId });
    });

    socket.on('disconnect', () => {
        console.log(`[Socket] ❌ Disconnected: ${socket.id}`);
    });
});

// --- MOCK RIDE GENERATOR ---
// Sends a ride request every 15 seconds to all connected clients
setInterval(() => {
    if (io.engine.clientsCount > 0) {
        const mockRide = {
            id: 'RIDE_' + Math.floor(Math.random() * 9999),
            riderId: 'RIDER_123',
            riderName: 'Rahul Sharma',
            riderRating: 4.8,
            pickupAddr: 'Hi-Tech City, Hyderabad',
            dropAddr: 'Gachibowli, Hyderabad',
            fare: 350.0,
            distanceKm: 8.5,
            durationMin: 22,
            pickupLat: 17.4483,
            pickupLng: 78.3915,
            pin: '1234',
            paymentMode: 'CASH',
        };
        io.emit('new_ride_request', mockRide);
        console.log(`[Mock] 🚗 Sent ride request ${mockRide.id} to ${io.engine.clientsCount} clients`);
    }
}, 15000);

// --- MOCK AUTH ENDPOINTS ---

app.post('/api/v1/auth/send-otp', (req, res) => {
    const { phone } = req.body;
    console.log(`--- [MOCK OTP] Sent to ${phone}: 123456 ---`);
    res.status(200).json({ 
        status: 'OK', 
        message: 'OTP sent successfully',
        otp: '123456'
    });
});

app.post('/api/v1/auth/verify-otp', (req, res) => {
    const { phone, otp } = req.body;
    if (otp === '123456') {
        const token = jwt.sign({ phone, userId: 'demo_user', driverId: 'demo_driver' }, JWT_SECRET, { expiresIn: '30d' });
        res.status(200).json({
            status: 'OK',
            token: token,
            user: {
                id: 'demo_user',
                phone: phone,
                status: 'APPROVED', // Skip onboarding for demo
            }
        });
    } else {
        res.status(401).json({ status: 'ERR', message: 'Invalid OTP (use 123456)' });
    }
});

// --- MOCK DRIVER ENDPOINTS ---

app.post('/api/v1/driver/documents', upload.any(), (req, res) => {
    console.log('--- [MOCK] Received document upload request ---');
    console.log('[Mock] Body:', req.body);
    console.log('[Mock] Files:', req.files ? req.files.length : 0);
    res.status(200).json({ status: 'OK', message: 'Documents uploaded successfully' });
});

app.get('/api/v1/driver/profile', (req, res) => {
    res.status(200).json({ status: 'OK', data: { fullName: 'Demo Driver', walletBalance: 1250 } });
});

app.patch('/api/v1/driver/status', (req, res) => {
    const { status } = req.body;
    console.log(`[Mock] Driver status updated to: ${status}`);
    res.status(200).json({ status: 'OK', message: `Status updated to ${status}` });
});

app.get('/api/v1/earnings', (req, res) => {
    res.status(200).json({
        status: 'OK',
        today_earned: "1250.00",
        total_earned: "45000.00",
        total_trips: "128",
        history: [
            { id: '1', amount: 350, date: '2023-10-27', pickup: 'Hi-Tech City', drop: 'Gachibowli' }
        ]
    });
});

// --- MOCK RIDE LIFECYCLE ---

app.get('/api/v1/rides/active', (req, res) => {
    // Return null mostly, or a mock active ride if needed for testing recovery
    res.status(200).json({ status: 'OK', ride: null });
});

app.post('/api/v1/rides/:id/accept', (req, res) => {
    console.log(`[Mock] Ride accepted: ${req.params.id}`);
    res.status(200).json({ status: 'OK', message: 'Ride accepted', rideId: req.params.id });
});

app.post('/api/v1/rides/:id/reject', (req, res) => {
    console.log(`[Mock] Ride rejected: ${req.params.id}`);
    res.status(200).json({ status: 'OK', message: 'Ride rejected' });
});

app.post('/api/v1/rides/:id/start', (req, res) => {
    console.log(`[Mock] Ride started: ${req.params.id}`);
    res.status(200).json({ status: 'OK', message: 'Ride started' });
});

app.post('/api/v1/rides/:id/complete', (req, res) => {
    console.log(`[Mock] Ride completed: ${req.params.id}`);
    res.status(200).json({ status: 'OK', message: 'Ride completed' });
});

server.listen(PORT, () => {
    console.log(`--- MOCK SERVER RUNNING ON PORT ${PORT} ---`);
});
