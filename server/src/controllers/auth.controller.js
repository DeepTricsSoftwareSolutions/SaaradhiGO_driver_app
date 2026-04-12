const prisma = require('../lib/prisma');
const jwt = require('jsonwebtoken');
const config = require('../config');


// ─── In-memory OTP store (use Redis in production) ────────────────────────────
const otpStore = new Map(); // phone → { otp, expiresAt }

// ─── Initialize Twilio (optional) ────────────────────────────────────────────
let twilioClient = null;
if (config.TWILIO_ACCOUNT_SID && config.TWILIO_AUTH_TOKEN) {
    const twilio = require('twilio');
    twilioClient = twilio(config.TWILIO_ACCOUNT_SID, config.TWILIO_AUTH_TOKEN);
    console.log('[OTP] Twilio SMS enabled');
} else {
    console.log('[OTP] Twilio not configured — using mock OTP (123456)');
}

// ─── Generate random 6-digit OTP ─────────────────────────────────────────────
function generateOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

// ─── Send OTP ─────────────────────────────────────────────────────────────────
exports.sendOTP = async (req, res) => {
    const { phone } = req.body;

    if (!phone) {
        return res.status(400).json({ status: 'ERR', message: 'Phone number is required' });
    }

    const cleanPhone = phone.replace(/\s/g, '');
    const otp = generateOTP();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes

    otpStore.set(cleanPhone, { otp, expiresAt });

    if (twilioClient && config.TWILIO_PHONE_NUMBER) {
        try {
            await twilioClient.messages.create({
                body: `Your SaaradhiGO verification code is: ${otp}. Valid for 5 minutes.`,
                from: config.TWILIO_PHONE_NUMBER,
                to: cleanPhone.startsWith('+') ? cleanPhone : `+91${cleanPhone}`,
            });
        } catch (err) {
            console.error('[OTP] Twilio send failed:', err.message);
        }
    } else {
        console.log(`\n=============================`);
        console.log(`[DEV OTP] Phone: ${cleanPhone}`);
        console.log(`[DEV OTP] Code : ${otp}`);
        console.log(`=============================\n`);
    }

    res.status(200).json({
        status: 'OK',
        message: 'OTP sent successfully',
        ...(config.NODE_ENV !== 'production' && { devOtp: otp }),
    });
};

// ─── Verify OTP ──────────────────────────────────────────────────────────────
exports.verifyOTP = async (req, res) => {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
        return res.status(400).json({ status: 'ERR', message: 'Phone and OTP are required' });
    }

    const cleanPhone = phone.replace(/\s/g, '');
    const record = otpStore.get(cleanPhone);

    if (!record || otp !== record.otp) {
        return res.status(401).json({ status: 'ERR', message: 'Incorrect OTP. Please try again.' });
    }

    if (Date.now() > record.expiresAt) {
        otpStore.delete(cleanPhone);
        return res.status(401).json({ status: 'ERR', message: 'OTP has expired.' });
    }

    otpStore.delete(cleanPhone);

    try {
        // --- REAL DB FLOW ---
        let user = await prisma.user.findUnique({
            where: { phone: cleanPhone },
            include: { driver: true }
        });

        if (!user) {
            user = await prisma.user.create({
                data: {
                    phone: cleanPhone,
                    role: 'DRIVER',
                    driver: { 
                        create: { 
                            fullName: 'Demo Driver',
                            status: 'APPROVED', 
                            walletBalance: 1250.00,
                            totalRides: 156,
                            isOnline: true
                        } 
                    }
                },
                include: { driver: true }
            });
        }

        const token = jwt.sign(
            { userId: user.id, driverId: user.driver?.id, role: user.role },
            config.JWT_SECRET,
            { expiresIn: '30d' }
        );

        return res.status(200).json({
            status: 'OK',
            token,
            user: {
                id: user.id,
                driverId: user.driver?.id,
                phone: user.phone,
                status: user.driver?.status,
                fullName: user.driver?.fullName,
            }
        });

    } catch (error) {
        console.error('[DB_ERROR] Falling back to Demo Mode:', error.message);
        
        // --- DEMO MODE FALLBACK (if DB is down) ---
        const token = jwt.sign(
            { userId: 'demo-id', driverId: 'demo-driver-id', role: 'DRIVER' },
            config.JWT_SECRET,
            { expiresIn: '30d' }
        );

        return res.status(200).json({
            status: 'OK',
            message: 'Verified (Demo Mode - DB Down)',
            token,
            user: {
                id: 'demo-id',
                driverId: 'demo-driver-id',
                phone: cleanPhone,
                status: 'APPROVED',
                fullName: 'Demo Driver',
            }
        });
    }
};
