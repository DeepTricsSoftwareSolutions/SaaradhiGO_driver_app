const express = require('express');
const router = express.Router();
const driverController = require('../controllers/driver.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

// @route   GET api/v1/driver/profile
// @desc    Get current driver profile
router.get('/profile', authMiddleware, driverController.getProfile);

// @route   PATCH api/v1/driver/profile
// @desc    Update current driver profile
router.patch('/profile', authMiddleware, driverController.updateProfile);

// @route   POST api/v1/driver/documents
// @desc    Upload documents and register vehicle details
router.post('/documents', authMiddleware, require('../middleware/upload.middleware').uploadMiddleware, driverController.uploadDocuments);

// @route   GET api/v1/driver/documents
// @desc    Get current driver documents status
router.get('/documents', authMiddleware, driverController.getDocuments);

// @route   PATCH api/v1/driver/status
// @desc    Toggle Online/Offline status
router.patch('/status', authMiddleware, driverController.toggleOnlineStatus);

// @route   POST api/v1/driver/fraud-report
// @desc    Report driver fraud (e.g. mocked GPS)
router.post('/fraud-report', authMiddleware, driverController.reportFraud);

// @route   POST api/v1/driver/rider-report
// @desc    Report rider misconduct or safety concerns
router.post('/rider-report', authMiddleware, driverController.reportRiderMisconduct);

// @route   PATCH api/v1/driver/break
// @desc    Toggle Break Mode
router.patch('/break', authMiddleware, driverController.toggleBreakMode);

// @route   POST api/v1/driver/sos
// @desc    Trigger Emergency SOS
router.post('/sos', authMiddleware, driverController.triggerSOS);

module.exports = router;
