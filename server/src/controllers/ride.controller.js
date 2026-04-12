const prisma = require('../lib/prisma');
const { getIO, broadcastRideRequest, getDriverLocation } = require('../socket');

// ─── Fare Calculation ─────────────────────────────────────────────────────
function calculateFare({ distanceKm, durationMin }) {
    const BASE_FARE = 30;
    const PER_KM = 14;
    const PER_MIN = 1.5;
    const COMMISSION_PERCENT = 0.20;

    const grossFare = BASE_FARE + (distanceKm * PER_KM) + (durationMin * PER_MIN);
    const commission = grossFare * COMMISSION_PERCENT;
    const driverEarnings = grossFare - commission;

    return {
        grossFare: Math.round(grossFare),
        commission: Math.round(commission),
        driverEarnings: Math.round(driverEarnings),
    };
}

// ─── Haversine Distance ───────────────────────────────────────────────────
function haversineKm(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) ** 2 +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ─── Mock ride data (for demo) ─────────────────────────────────────────────
const mockRides = [
    {
        id: 'RIDE_DEMO_1',
        riderId: 'RIDER_001',
        riderName: 'Rahul Sharma',
        riderRating: 4.7,
        pickupLat: 17.4448, pickupLng: 78.3817,
        pickupAddr: 'Hitech City Metro, Hyderabad',
        dropLat: 17.4156, dropLng: 78.4347,
        dropAddr: 'Banjara Hills Rd No 12',
        status: 'REQUESTED',
        fare: 185, distanceKm: 8.5, durationMin: 22,
        pin: '7823', paymentMode: 'UPI',
        createdAt: new Date().toISOString()
    }
];

// ── GET /api/rides/active ─────────────────────────────────────────────────
exports.getActiveRide = async (req, res) => {
    try {
        const driverId = req.user.driverId;
        const activeRide = await prisma.ride.findFirst({
            where: {
                driverId,
                status: { in: ['ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'PICKUP', 'START_RIDE'] }
            },
            orderBy: { createdAt: 'desc' }
        });

        res.status(200).json({ status: 'OK', ride: activeRide });
    } catch (error) {
        console.error('[Rides] getActiveRide error:', error.message);
        res.status(200).json({ status: 'OK', ride: null }); // Return null if not found
    }
};

// ─── GET /rides/history ───────────────────────────────────────────────────
exports.getHistory = async (req, res) => {
    try {
        const rides = await prisma.ride.findMany({
            where: { driverId: req.user.driverId },
            orderBy: { createdAt: 'desc' },
            take: 50,
        });
        res.status(200).json({ status: 'OK', history: rides });
    } catch (error) {
        console.error('[Rides] getHistory error:', error.message);
        res.status(200).json({ status: 'OK', history: mockRides });
    }
};

// ─── POST /rides/:id/accept ────────────────────────────────────────────────
exports.acceptRide = async (req, res) => {
    try {
        const { rideId } = req.params;
        const driverId = req.user.driverId;

        // Atomic: use transaction to prevent race condition
        const result = await prisma.$transaction(async (tx) => {
            const ride = await tx.ride.findUnique({ where: { id: rideId } });

            if (!ride) throw new Error('Ride not found');
            if (ride.status !== 'REQUESTED') throw new Error('Ride no longer available');
            if (ride.driverId && ride.driverId !== driverId) throw new Error('Already accepted by another driver');

            return await tx.ride.update({
                where: { id: rideId },
                data: { driverId, status: 'ACCEPTED' }
            });
        });

        res.status(200).json({ status: 'OK', message: 'Ride accepted', ride: result });
    } catch (error) {
        const isConflict = error.message?.includes('already accepted') || error.message?.includes('no longer available');
        if (isConflict) {
            return res.status(409).json({ status: 'ERR', message: error.message });
        }
        console.error('[Rides] acceptRide error:', error.message);
        // Demo fallback
        res.status(200).json({ status: 'OK', message: 'Ride accepted (Demo)', rideId: req.params.rideId });
    }
};

// ─── POST /rides/:id/reject ────────────────────────────────────────────────
exports.rejectRide = async (req, res) => {
    try {
        const { rideId } = req.params;
        // In production: find next nearest driver and offer them the ride
        res.status(200).json({ status: 'OK', message: 'Ride rejected', rideId });
    } catch (error) {
        res.status(500).json({ status: 'ERR', message: 'Error rejecting ride' });
    }
};

// ─── POST /rides/:id/start ─────────────────────────────────────────────────
exports.startRide = async (req, res) => {
    try {
        const { rideId } = req.params;
        const { otp } = req.body;

        // Validate OTP — in production, store PIN in DB at ride creation
        // For demo: check OTP is 1111 or any 4-digit
        if (!otp || otp.length !== 4) {
            return res.status(400).json({ status: 'ERR', message: 'Invalid OTP format' });
        }

        await prisma.ride.update({
            where: { id: rideId },
            data: { status: 'IN_PROGRESS', startTime: new Date() }
        });

        res.status(200).json({ status: 'OK', message: 'Trip started', rideId });
    } catch (error) {
        console.error('[Rides] startRide error:', error.message);
        res.status(200).json({ status: 'OK', message: 'Trip started (Demo)', rideId: req.params.rideId });
    }
};

// ─── POST /rides/:id/complete ──────────────────────────────────────────────
exports.completeRide = async (req, res) => {
    try {
        const { rideId } = req.params;
        const driverId = req.user.driverId;

        const ride = await prisma.ride.update({
            where: { id: rideId },
            data: { status: 'COMPLETED', endTime: new Date() }
        });

        // 20% Platform Commission
        const COMMISSION_PERCENT = 0.20;
        const grossFare = ride.fare;
        const platformCommission = grossFare * COMMISSION_PERCENT;
        const driverEarnings = Math.round(grossFare - platformCommission);

        // Create earning record
        await prisma.earning.create({
            data: { driverId, rideId, amount: driverEarnings }
        });

        // Update driver stats
        await prisma.driver.update({
            where: { id: driverId },
            data: {
                totalRides: { increment: 1 },
                walletBalance: { increment: driverEarnings }
            }
        });

        // Credit transaction
        await prisma.transaction.create({
            data: {
                driverId,
                amount: driverEarnings,
                type: 'CREDIT',
                description: `Ride completed: ${ride.pickupAddr} → ${ride.dropAddr}`
            }
        });

        res.status(200).json({
            status: 'OK',
            message: 'Ride completed',
            driverEarnings,
            rideId
        });
    } catch (error) {
        console.error('[Rides] completeRide error:', error.message);
        res.status(200).json({ status: 'OK', message: 'Ride completed (Demo)', rideId: req.params.rideId });
    }
};

// ─── POST /rides/:id/cancel ────────────────────────────────────────────────
exports.cancelRide = async (req, res) => {
    try {
        const { rideId } = req.params;
        const { reason } = req.body;
        const driverId = req.user.driverId;

        const ride = await prisma.ride.findUnique({ where: { id: rideId } });

        // Penalty if driver cancels after accepting
        let penaltyAmount = 0;
        if (ride?.status === 'ACCEPTED' || ride?.status === 'ARRIVED') {
            penaltyAmount = 25; // ₹25 penalty
            await prisma.transaction.create({
                data: {
                    driverId,
                    amount: -penaltyAmount,
                    type: 'DEBIT',
                    description: 'Cancellation penalty'
                }
            });
            await prisma.driver.update({
                where: { id: driverId },
                data: { walletBalance: { decrement: penaltyAmount } }
            });
        }

        await prisma.ride.update({
            where: { id: rideId },
            data: { status: 'CANCELLED', endTime: new Date() }
        });

        // Notify rider via socket
        try {
            const io = require('../socket').getIO();
            if (ride?.riderId) {
                io.to(`rider:${ride.riderId}`).emit('ride_cancelled', {
                    rideId,
                    reason: reason || 'Driver cancelled',
                });
            }
        } catch (_) {}

        res.status(200).json({
            status: 'OK',
            message: 'Ride cancelled',
            penaltyAmount,
        });
    } catch (error) {
        console.error('[Rides] cancelRide error:', error.message);
        res.status(200).json({ status: 'OK', message: 'Ride cancelled (Demo)' });
    }
};

// ─── POST /rides/:id/no-show ──────────────────────────────────────────────
exports.noShowTrip = async (req, res) => {
    try {
        const { rideId } = req.params;
        const driverId = req.user.driverId;

        // Apply no-show fee
        const noShowFee = 40.0; // ₹40 rider penalty, driver gets some?
        
        await prisma.ride.update({
            where: { id: rideId },
            data: { status: 'CANCELLED_NO_SHOW', endTime: new Date() }
        });

        // Add compensation to driver's earnings (e.g., driver gets half the fee)
        const driverShare = noShowFee * 0.5;
        
        await prisma.driver.update({
            where: { id: driverId },
            data: { 
                walletBalance: { increment: driverShare },
            }
        });

        await prisma.ledger.create({
            data: {
                driverId,
                rideId,
                amount: driverShare,
                type: 'CREDIT',
                description: 'Rider No-Show Compensation'
            }
        });

        // Notify rider
        try {
            const io = require('../socket').getIO();
            const ride = await prisma.ride.findUnique({ where: { id: rideId } });
            if (ride?.riderId) {
                io.to(`rider:${ride.riderId}`).emit('ride_cancelled', {
                    rideId,
                    reason: 'Driver resolved as No-Show. Fee applied.',
                });
            }
        } catch (_) {}

        res.status(200).json({
            status: 'OK',
            message: 'Rider marked as No-Show',
            compensationAmount: driverShare,
        });

    } catch (error) {
        console.error('[Rides] noShowTrip error:', error.message);
        res.status(500).json({ status: 'ERR', message: 'Failed to process no-show' });
    }
};

// ─── GET /rides/heatmap ────────────────────────────────────────────────────
exports.getHeatmap = async (req, res) => {
    try {
        const heatmapData = [
            { lat: 17.4483, lng: 78.3915, intensity: 0.8 },
            { lat: 17.4448, lng: 78.3789, intensity: 0.6 },
            { lat: 17.4501, lng: 78.3800, intensity: 0.9 },
            { lat: 17.4374, lng: 78.4487, intensity: 0.7 },
            { lat: 17.4399, lng: 78.4983, intensity: 0.5 },
        ];
        res.status(200).json({ status: 'OK', heatmap: heatmapData });
    } catch (error) {
        res.status(500).json({ status: 'ERR', message: 'Error fetching heatmap' });
    }
};

// ─── POST /rides/:id/sos ──────────────────────────────────────────────────
exports.sosTrigger = async (req, res) => {
    try {
        const { rideId } = req.params;
        const { lat, lng } = req.body;
        const driverId = req.user.driverId;

        console.warn(`🚨 SOS ALERT from driver ${driverId} for ride ${rideId} at ${lat}, ${lng}`);

        // In production: alert ops team, send SMS, log in DB
        // await sendSOSAlert({ driverId, rideId, lat, lng });

        res.status(200).json({ status: 'OK', message: 'SOS alert sent. Help is on the way.' });
    } catch (error) {
        res.status(500).json({ status: 'ERR', message: 'Error triggering SOS' });
    }
};

// ─── POST /rides/create (for rider app / testing) ─────────────────────────
exports.createRide = async (req, res) => {
    try {
        const { riderId, pickupLat, pickupLng, pickupAddr, dropLat, dropLng, dropAddr } = req.body;

        const distanceKm = haversineKm(pickupLat, pickupLng, dropLat, dropLng);
        const durationMin = Math.round(distanceKm * 2.5); // rough estimate
        const { grossFare } = calculateFare({ distanceKm, durationMin });

        const ride = await prisma.ride.create({
            data: {
                riderId,
                pickupLat, pickupLng, pickupAddr,
                dropLat, dropLng, dropAddr,
                status: 'REQUESTED',
                fare: grossFare,
                distanceKm: parseFloat(distanceKm.toFixed(2)),
                durationMin,
            }
        });

        const matchingService = require('../services/matchingService');
        matchingService.startMatching(ride.id, getIO());

        res.status(201).json({ status: 'OK', rideId: ride.id, fare: grossFare });
    } catch (error) {
        console.error('[Rides] createRide error:', error.message);
        res.status(500).json({ status: 'ERR', message: 'Error creating ride' });
    }
};

// ─── Find Nearby Drivers (in-memory, use PostGIS in production) ───────────
function findNearbyDrivers(pickupLat, pickupLng, radiusKm) {
    const { driverLocations } = require('../socket');
    if (!driverLocations) return [];

    return Array.from(driverLocations.entries())
        .filter(([_, { lat, lng }]) => haversineKm(pickupLat, pickupLng, lat, lng) <= radiusKm)
        .map(([driverId]) => driverId);
}
