const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');

// @route   POST api/v1/auth/send-otp
// @desc    Send OTP to phone
router.post('/send-otp', authController.sendOTP);

// @route   POST api/v1/auth/verify-otp
// @desc    Verify OTP and login/register
router.post('/verify-otp', authController.verifyOTP);

// @route   GET api/v1/auth/me
// @desc    Get current user session
// router.get('/me', authMiddleware, authController.getCurrentUser);

module.exports = router;
