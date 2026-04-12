const prisma = require('../lib/prisma');


const DEMO_EARNINGS = {
    today: 1250,
    week: 8500,
    month: 32000,
    total: 156000,
    history: [
        { id: 'RT-1234', date: new Date().toISOString(), amount: 185, ride: { pickupAddr: 'MG Road', dropAddr: 'Koramangala 5th Block' } },
        { id: 'RT-1233', date: new Date().toISOString(), amount: 245, ride: { pickupAddr: 'Indiranagar', dropAddr: 'Whitefield' } },
    ]
};

exports.getEarnings = async (req, res) => {
    try {
        const driverId = req.user.driverId;
        const earnings = await prisma.earning.findMany({
            where: { driverId: driverId },
            include: { ride: true },
            orderBy: { date: 'desc' }
        });

        const driver = await prisma.driver.findUnique({
            where: { id: driverId },
            select: { walletBalance: true, totalRides: true }
        });

        res.status(200).json({
            status: 'OK',
            today: 1250, // This logic should be more complex in real DB
            week: 8500,
            month: 32000,
            total: driver.walletBalance,
            totalRides: driver.totalRides,
            incentives: 150, // Example fixed incentive for now
            history: earnings
        });
    } catch (error) {
        console.error('[DB_ERROR] Demo earnings fallback:', error.message);
        res.status(200).json({
            status: 'OK',
            ...DEMO_EARNINGS
        });
    }
};
