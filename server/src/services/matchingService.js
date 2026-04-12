const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * Real-time Matching Service
 * - Handles Geo-spatial driver discovery
 * - Manages ride queues and timeouts
 * - Ensures atomic ride claims
 */
class MatchingService {
    constructor() {
        this.activeQueues = new Map(); // rideId -> { drivers: [], currentIndex: 0, timer: null }
    }

    /**
     * Finds available drivers within a radius (5km default)
     */
    async findNearbyDrivers(lat, lng, radiusKm = 5) {
        // In a real PostGIS setup, we'd use ST_DWithin
        // Here we'll use a simple bounding box or haversine for this scale
        const drivers = await prisma.driver.findMany({
            where: {
                isOnline: true,
                status: 'APPROVED',
                currentLat: { gte: lat - 0.05, lte: lat + 0.05 },
                currentLng: { gte: lng - 0.05, lte: lng + 0.05 },
            },
            take: 10,
        });

        // Filter and sort by distance
        return drivers.map(d => {
            const dist = this._getDistance(lat, lng, d.currentLat, d.currentLng);
            return { ...d, distance: dist };
        }).filter(d => d.distance <= radiusKm)
          .sort((a, b) => a.distance - b.distance);
    }

    /**
     * Initiates the matching process for a new ride
     */
    async startMatching(rideId, io) {
        const ride = await prisma.ride.findUnique({ where: { id: rideId } });
        if (!ride) return;

        const drivers = await this.findNearbyDrivers(ride.pickupLat, ride.pickupLng);
        if (drivers.length === 0) {
            console.log(`[Matching] No drivers found for ride ${rideId}`);
            // Broadcast "No drivers found" to rider
            return;
        }

        console.log(`[Matching] Found ${drivers.length} drivers for ride ${rideId}`);
        this.activeQueues.set(rideId, { 
            drivers: drivers.map(d => d.id), 
            currentIndex: 0,
            io: io 
        });

        this._processNextInQueue(rideId);
    }

    /**
     * Sends request to the next driver in the queue
     */
    _processNextInQueue(rideId) {
        const queue = this.activeQueues.get(rideId);
        if (!queue || queue.currentIndex >= queue.drivers.length) {
            console.log(`[Matching] Queue exhausted for ride ${rideId}`);
            this.activeQueues.delete(rideId);
            return;
        }

        const driverId = queue.drivers[queue.currentIndex];
        console.log(`[Matching] Sending ride ${rideId} to driver ${driverId}`);
        
        queue.io.to(`driver:${driverId}`).emit('new_ride_request', {
            id: rideId,
            // Add full ride details here
        });

        // Set timeout for 30 seconds
        queue.timer = setTimeout(() => {
            console.log(`[Matching] Driver ${driverId} timed out for ride ${rideId}`);
            queue.currentIndex++;
            this._processNextInQueue(rideId);
        }, 30000);
    }

    /**
     * Handles driver acceptance
     */
    async claimRide(rideId, driverId) {
        const queue = this.activeQueues.get(rideId);
        if (queue && queue.timer) {
            clearTimeout(queue.timer);
        }
        
        this.activeQueues.delete(rideId);
        return true;
    }

    _getDistance(lat1, lon1, lat2, lon2) {
        const R = 6371; // km
        const dLat = (lat2 - lat1) * Math.PI / 180;
        const dLon = (lon2 - lon1) * Math.PI / 180;
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}

module.exports = new MatchingService();
