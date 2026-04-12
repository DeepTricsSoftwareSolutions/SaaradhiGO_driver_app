const express = require('express');
const router = express.Router();
const walletController = require('../controllers/wallet.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

// ── GET /api/wallet/balance ───────────────────────────────────────────────
router.get('/balance', authMiddleware, walletController.getBalance);

// ── GET /api/wallet/transactions ──────────────────────────────────────────
router.get('/transactions', authMiddleware, walletController.getTransactions);

// ── POST /api/wallet/withdraw ─────────────────────────────────────────────
router.post('/withdraw', authMiddleware, walletController.requestWithdrawal);

// ── POST /api/wallet/create-contact ───────────────────────────────────────
router.post('/create-contact', authMiddleware, walletController.createContact);

// ── POST /api/wallet/create-fund-account ──────────────────────────────────
router.post('/create-fund-account', authMiddleware, walletController.createFundAccount);

// ── POST /api/wallet/retry-payout ─────────────────────────────────────────
router.post('/retry-payout', authMiddleware, walletController.retryPayout);

module.exports = router;
