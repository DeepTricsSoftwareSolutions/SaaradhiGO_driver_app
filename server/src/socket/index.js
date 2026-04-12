const { Server } = require('socket.io');
const prisma = require('../lib/prisma');
const matchingService = require('../services/matchingService');

let io;

// In-memory stores (use Redis in production for multi-instance support)
const driverLocations = new Map();     // driverId → { lat, lng, timestamp }
const driverSockets = new Map();       // driverId → socket.id
const activeRideLocks = new Map();     // rideId   → driverId (prevents double-accept)

// ─── Location Update Batch (flush to DB every 10s) ────────────────────────
const locationUpdateQueue = new Map(); // driverId → { lat, lng }

setInterval(async () => {
    if (locationUpdateQueue.size === 0) return;
    const updates = Array.from(locationUpdateQueue.entries());
    locationUpdateQueue.clear();

    await Promise.allSettled(updates.map(([driverId, { lat, lng }]) =>
        prisma.driver.update({
            where: { id: driverId },
            data: { currentLat: lat, currentLng: lng, lastActiveTime: new Date() }
        }).catch(() => {})
    ));
}, 10_000);

// ─── Initialize Socket.io ──────────────────────────────────────────────────
const initSocket = (server) => {
    io = new Server(server, {
        cors: {
            origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
            methods: ['GET', 'POST'],
        },
        transports: ['websocket', 'polling'],
        pingTimeout: 20000,
        pingInterval: 10000,
    });

    io.on('connection', (socket) => {
        console.log(`[Socket] ✅ Connected: ${socket.id}`);

        // ── Register Driver Room ─────────────────────────────────────────
        socket.on('register_driver', async (driverId) => {
            if (!driverId) return;

            // Track socket↔driver mapping
            driverSockets.set(driverId, socket.id);
            socket.driverId = driverId;
            socket.join(`driver:${driverId}`);
            console.log(`[Socket] Driver ${driverId} registered in room driver:${driverId}`);

            // Update driver online status in DB
            try {
                await prisma.driver.update({
                    where: { id: driverId },
                    data: { isOnline: true, lastActiveTime: new Date() }
                });
            } catch (_) { /* Demo mode — no DB */ }
        });

        // ── Driver Status ────────────────────────────────────────────────
        socket.on('driver_status', async ({ driverId, isOnline }) => {
            if (!driverId) return;
            try {
                await prisma.driver.update({
                    where: { id: driverId },
                    data: { isOnline: !!isOnline }
                });
                console.log(`[Socket] Driver ${driverId} is now ${isOnline ? 'ONLINE' : 'OFFLINE'}`);
            } catch (_) {}
        });

        // ── Location Update ──────────────────────────────────────────────
        socket.on('update_location', ({ driverId, lat, lng, timestamp }) => {
            if (!driverId || !lat || !lng) return;

            // Validate coordinates
            if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return;

            // Validate timestamp (reject if > 10s old)
            if (timestamp && Date.now() - timestamp > 10_000) {
                console.warn(`[Socket] Stale location from ${driverId}, skipping`);
                return;
            }

            const prev = driverLocations.get(driverId);
            
            // Speed validation: flag if > 250 km/h
            if (prev) {
                const timeDeltaS = (Date.now() - prev.timestamp) / 1000;
                if (timeDeltaS > 0) {
                    const distM = haversineDistance(prev.lat, prev.lng, lat, lng);
                    const speedKmh = (distM / timeDeltaS) * 3.6;
                    if (speedKmh > 250) {
                        console.warn(`[Socket] ⚠️ Suspicious speed from ${driverId}: ${speedKmh.toFixed(0)} km/h`);
                        return; // Reject
                    }
                }
            }

            driverLocations.set(driverId, { lat, lng, timestamp: Date.now() });
            locationUpdateQueue.set(driverId, { lat, lng });

            // If driver is on an active trip, broadcast location to rider
            // (rider socket is in room rider:{riderId})
            const rideId = activeRideLocks.get(driverId.rideId); // simplified
            if (socket.activeRiderId) {
                io.to(`rider:${socket.activeRiderId}`).emit('driver_location', {
                    driverId,
                    lat,
                    lng,
                    timestamp: Date.now(),
                });
            }
        });

        // ── Accept Ride (first-accept wins) ─────────────────────────────
        socket.on('accept_ride', async ({ rideId, driverId }) => {
            if (!rideId || !driverId) return;

            // Atomic check — prevent multiple drivers accepting same ride
            if (activeRideLocks.has(rideId)) {
                socket.emit('ride_accept_failed', { rideId, reason: 'Already accepted by another driver' });
                console.log(`[Socket] Ride ${rideId} already locked. Rejecting ${driverId}`);
                return;
            }

            activeRideLocks.set(rideId, driverId);
            await matchingService.claimRide(rideId, driverId);
            console.log(`[Socket] ✅ Ride ${rideId} locked to driver ${driverId}`);

            socket.emit('ride_accept_confirmed', { rideId });
        });

        // ── Reject Ride ──────────────────────────────────────────────────
        socket.on('reject_ride', ({ rideId, driverId }) => {
            console.log(`[Socket] Driver ${driverId} rejected ride ${rideId}`);
            // Could implement: find next nearest driver and send request
        });

        // ── Trip Status Update ───────────────────────────────────────────
        socket.on('trip_update', async ({ rideId, status, riderId, driverId }) => {
            if (!rideId || !status) return;

            console.log(`[Socket] Trip ${rideId} status → ${status}`);

            // Broadcast to rider
            if (riderId) {
                io.to(`rider:${riderId}`).emit('trip_status', {
                    rideId,
                    status,
                    timestamp: Date.now(),
                });
            }

            // Update DB
            try {
                const dbStatus = {
                    'ARRIVED': 'ARRIVED',
                    'IN_PROGRESS': 'IN_PROGRESS',
                    'COMPLETED': 'COMPLETED',
                    'CANCELLED': 'CANCELLED',
                }[status] || status;

                const updateData = { status: dbStatus };
                if (status === 'IN_PROGRESS') updateData.startTime = new Date();
                if (status === 'COMPLETED' || status === 'CANCELLED') {
                    updateData.endTime = new Date();
                    activeRideLocks.delete(rideId);
                }

                if (status === 'IN_PROGRESS') {
                    socket.activeRiderId = riderId;
                }

                await prisma.ride.update({ where: { id: rideId }, data: updateData });
            } catch (err) {
                // Demo mode — ignore DB errors
            }
        });

        // ── Driver Offline (clean disconnect) ────────────────────────────
        socket.on('driver_offline', async ({ driverId }) => {
            if (!driverId) return;
            try {
                await prisma.driver.update({
                    where: { id: driverId },
                    data: { isOnline: false }
                });
            } catch (_) {}
            driverSockets.delete(driverId);
        });

        // ── Disconnect Handling ──────────────────────────────────────────
        socket.on('disconnect', async (reason) => {
            console.log(`[Socket] ❌ Disconnected: ${socket.id} (${reason})`);

            const driverId = socket.driverId;
            if (!driverId) return;

            // If driver disconnects mid-trip, alert ops team
            if (socket.activeRiderId) {
                console.warn(`[Socket] ⚠️ Driver ${driverId} disconnected DURING active trip!`);
                io.to(`rider:${socket.activeRiderId}`).emit('driver_disconnected', {
                    message: 'Driver connection lost. Reconnecting...'
                });
                // Do NOT cancel ride — driver may reconnect
            }

            // Only mark offline if socket doesn't reconnect within 30s
            setTimeout(async () => {
                const currentSocketId = driverSockets.get(driverId);
                if (currentSocketId === socket.id) {
                    // Socket hasn't reconnected
                    driverSockets.delete(driverId);
                    try {
                        await prisma.driver.update({
                            where: { id: driverId },
                            data: { isOnline: false }
                        });
                        console.log(`[Socket] Driver ${driverId} marked offline after timeout`);
                    } catch (_) {}
                }
            }, 30_000);
        });

        // ── Demo: Send test ride request ─────────────────────────────────
        // (Only in development)
        if (process.env.NODE_ENV !== 'production') {
            socket.on('_demo_trigger_ride', () => {
                const mockRide = {
                    id: 'RIDE_' + Math.floor(Math.random() * 9999),
                    riderId: 'RIDER_001',
                    riderName: 'Rahul Sharma',
                    riderRating: 4.7,
                    pickupAddr: 'Hi-Tech City, Hyderabad',
                    dropAddr: 'Gachibowli, Hyderabad',
                    fare: 350,
                    distanceKm: 8.5,
                    durationMin: 22,
                    pickupLat: 17.4483,
                    pickupLng: 78.3915,
                    pin: '7823',
                    paymentMode: 'UPI',
                };
                socket.emit('new_ride_request', mockRide);
                console.log(`[Demo] Sent mock ride to socket ${socket.id}`);
            });
        }
    });

    return io;
};

// ─── Broadcast Ride Request to Nearby Drivers ─────────────────────────────
const broadcastRideRequest = async (rideData, nearbyDriverIds) => {
    if (!io) return;
    nearbyDriverIds.forEach(driverId => {
        io.to(`driver:${driverId}`).emit('new_ride_request', rideData);
    });
    console.log(`[Socket] Broadcasted ride ${rideData.id} to ${nearbyDriverIds.length} drivers`);
};

// ─── Haversine Distance (meters) ──────────────────────────────────────────
function haversineDistance(lat1, lon1, lat2, lon2) {
    const R = 6371000;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a = Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function toRad(deg) { return deg * Math.PI / 180; }

const getIO = () => {
    if (!io) throw new Error('Socket.io not initialized');
    return io;
};

const getDriverLocation = (driverId) => driverLocations.get(driverId) || null;

module.exports = { initSocket, getIO, broadcastRideRequest, getDriverLocation };
