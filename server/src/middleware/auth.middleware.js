const jwt = require('jsonwebtoken');
const config = require('../config');
const prisma = require('../lib/prisma');

exports.authMiddleware = (req, res, next) => {
    const token = req.header('Authorization')?.split(' ')[1] || req.body.token;

    if (!token) {
        return res.status(401).json({ status: 'ERR', message: 'Unauthorized: No token provided' });
    }

    try {
        const decoded = jwt.verify(token, config.JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        console.error('AUTH_MIDDLEWARE_ERROR:', error);
        res.status(401).json({ status: 'ERR', message: 'Unauthorized: Invalid token' });
    }
};

exports.approvedMiddleware = async (req, res, next) => {
    try {
        if (!req.user || !req.user.driverId) {
             return res.status(401).json({ status: 'ERR', message: 'Unauthorized' });
        }
        const driver = await prisma.driver.findUnique({
             where: { id: req.user.driverId },
             select: { status: true }
        });
        if (driver?.status !== 'APPROVED') {
             return res.status(403).json({ status: 'ERR', message: 'Account is under review' });
        }
        next();
    } catch (e) {
        res.status(500).json({ status: 'ERR', message: 'Auth check failed' });
    }
};
