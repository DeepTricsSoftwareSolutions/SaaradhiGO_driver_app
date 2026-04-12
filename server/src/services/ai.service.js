const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Haversine formula to calculate distance between two points in KM
function getDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of the earth in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

exports.findNearestDrivers = async (pickupLat, pickupLng, radiusKm = 5) => {
    // 1. Get all online and approved drivers
    const onlineDrivers = await prisma.driver.findMany({
        where: { isOnline: true, status: 'APPROVED' },
        select: { id: true, currentLat: true, currentLng: true, rating: true, userId: true }
    });

    // 2. Filter by radius and sort by (distance + rating weight)
    const nearbyDrivers = onlineDrivers
        .map(driver => {
            const distance = getDistance(pickupLat, pickupLng, driver.currentLat, driver.currentLng);
            return { ...driver, distance };
        })
        .filter(driver => driver.distance <= radiusKm)
        .sort((a, b) => (a.distance - b.distance) - (a.rating - b.rating) * 0.1); // Proximity weighted slightly towards rating

    return nearbyDrivers;
};

exports.detectGPSFraud = (prevLat, prevLng, newLat, newLng, timeDiffMs) => {
    if (timeDiffMs <= 0) return false;

    const distance = getDistance(prevLat, prevLng, newLat, newLng);
    const speedKmh = (distance / (timeDiffMs / 3600000));

    // If speed is more than 150km/h, it's suspicious
    if (speedKmh > 150) {
        console.warn(`--- [FRAUD_ALERT] Possible GPS Jump detected: Speed ${speedKmh.toFixed(2)} km/h ---`);
        return true;
    }
    return false;
};
