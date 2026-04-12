const express = require('express');
const router = express.Router();
const earningController = require('../controllers/earning.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

// @route   GET api/v1/earnings
// @desc    Get earnings summary and history
router.get('/', authMiddleware, earningController.getEarnings);

module.exports = router;
