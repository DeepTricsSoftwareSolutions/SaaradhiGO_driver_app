const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');

// ── Legacy endpoints (existing Flutter builds) ───────────────────────────────
// @route   POST /api/v1/auth/send-otp  (also mounted under /api/auth/send-otp)
// @desc    Send OTP to phone
router.post('/send-otp', authController.sendOTP);

// @route   POST /api/v1/auth/verify-otp (also mounted under /api/auth/verify-otp)
// @desc    Verify OTP and login/register
router.post('/verify-otp', authController.verifyOTP);

// ── V2 endpoints (API_Documentation_V2.md) ───────────────────────────────────
// These are mounted at:
// - /api/v1/auth/otp/   and /api/auth/otp/
// - /api/v1/auth/login/ and /api/auth/login/
router.post('/otp', authController.requestOtpV2);
router.post('/login', authController.loginWithOtpV2);

// @route   GET api/v1/auth/me
// @desc    Get current user session
// router.get('/me', authMiddleware, authController.getCurrentUser);

module.exports = router;
