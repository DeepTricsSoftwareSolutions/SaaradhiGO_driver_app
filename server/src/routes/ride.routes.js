const express = require('express');
const router = express.Router();
const rideController = require('../controllers/ride.controller');
const { authMiddleware, approvedMiddleware } = require('../middleware/auth.middleware');

// Apply both middlewares to all ride routes so only APPROVED drivers can accept/complete
router.use(authMiddleware);
router.use(approvedMiddleware);

// ── GET /api/rides/history ────────────────────────────────────────────────
router.get('/history', authMiddleware, rideController.getHistory);

// ── GET /api/rides/active ─────────────────────────────────────────────────
router.get('/active', authMiddleware, rideController.getActiveRide);

// ── GET /api/rides/heatmap ────────────────────────────────────────────────
router.get('/heatmap', authMiddleware, rideController.getHeatmap);

// ── GET /api/rides/requests (demo: pending ride offers) ────────────────────
router.get('/requests', authMiddleware, rideController.getDriverRequests);

// ── POST /api/rides (create ride — for rider app or testing) ──────────────
router.post('/', authMiddleware, rideController.createRide);

// ── POST /api/rides/:rideId/accept ────────────────────────────────────────
router.post('/:rideId/accept', authMiddleware, rideController.acceptRide);

// ── POST /api/rides/:rideId/reject ────────────────────────────────────────
router.post('/:rideId/reject', authMiddleware, rideController.rejectRide);

// ── POST /api/rides/:rideId/start ─────────────────────────────────────────
router.post('/:rideId/start', authMiddleware, rideController.startRide);

// ── POST /api/rides/:rideId/complete ──────────────────────────────────────
router.post('/:rideId/complete', authMiddleware, rideController.completeRide);

// ── POST /api/rides/:rideId/cancel ────────────────────────────────────────
router.post('/:rideId/cancel', authMiddleware, rideController.cancelRide);

// ── POST /api/rides/:rideId/no-show ───────────────────────────────────────
router.post('/:rideId/no-show', authMiddleware, rideController.noShowTrip);

// ── POST /api/rides/:rideId/sos ───────────────────────────────────────────
router.post('/:rideId/sos', authMiddleware, rideController.sosTrigger);

// ── POST /api/rides/:rideId/rate ──────────────────────────────────────────
router.post('/:rideId/rate', authMiddleware, rideController.rateTrip);

module.exports = router;
