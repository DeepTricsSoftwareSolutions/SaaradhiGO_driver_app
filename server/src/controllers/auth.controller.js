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

// ─── V2: Request OTP (matches API_Documentation_V2.md) ───────────────────────
exports.requestOtpV2 = async (req, res) => {
    const { phone_number, role } = req.body || {};

    if (!phone_number) {
        return res.status(400).json({
            status: 'error',
            message: 'phone_number is required',
            field: 'phone_number',
        });
    }

    // The v2 API expects E.164; we store the normalized phone as-is (+91...)
    const cleanPhone = String(phone_number).replace(/\s/g, '');
    const otp = generateOTP();
    const expiresInSeconds = 600;
    const expiresAt = Date.now() + expiresInSeconds * 1000;

    otpStore.set(cleanPhone, { otp, expiresAt });

    if (twilioClient && config.TWILIO_PHONE_NUMBER) {
        try {
            await twilioClient.messages.create({
                body: `Your SaaradhiGO verification code is: ${otp}. Valid for 10 minutes.`,
                from: config.TWILIO_PHONE_NUMBER,
                to: cleanPhone,
            });
        } catch (err) {
            console.error('[OTP] Twilio send failed:', err.message);
        }
    } else {
        console.log(`\n=============================`);
        console.log(`[DEV OTP] Phone: ${cleanPhone}`);
        console.log(`[DEV OTP] Code : ${otp}`);
        console.log(`Role     : ${role || 'driver'}`);
        console.log(`=============================\n`);
    }

    return res.status(200).json({
        status: 'success',
        data: {
            message: 'OTP sent successfully',
            task_id: `mem_${Date.now()}`,
            // In real production you should NOT return OTP.
            ...(config.NODE_ENV !== 'production' && { otp }),
            expires_in: expiresInSeconds,
        },
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
                            status: 'PENDING', 
                            walletBalance: 0.00,
                            totalRides: 0,
                            isOnline: false
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

// ─── V2: Login & Token Generation (verify OTP) ───────────────────────────────
exports.loginWithOtpV2 = async (req, res) => {
    const { phone_number, otp, device_token } = req.body || {};

    if (!phone_number || !otp) {
        return res.status(400).json({
            status: 'error',
            message: 'phone_number and otp are required',
        });
    }

    const cleanPhone = String(phone_number).replace(/\s/g, '');
    const record = otpStore.get(cleanPhone);

    if (!record || String(otp) !== record.otp) {
        return res.status(401).json({ status: 'error', message: 'Invalid OTP' });
    }

    if (Date.now() > record.expiresAt) {
        otpStore.delete(cleanPhone);
        return res.status(401).json({ status: 'error', message: 'OTP expired' });
    }

    otpStore.delete(cleanPhone);

    try {
        // --- REAL DB FLOW ---
        let user = await prisma.user.findUnique({
            where: { phone: cleanPhone },
            include: { driver: true },
        });

        if (!user) {
            user = await prisma.user.create({
                data: {
                    phone: cleanPhone,
                    role: 'DRIVER',
                    // NOTE: DB schema uses Driver model under user.driver
                    driver: {
                        create: {
                            fullName: null,
                            status: 'PENDING',
                            walletBalance: 0.0,
                            totalRides: 0,
                            isOnline: false,
                        },
                    },
                },
                include: { driver: true },
            });
        }

        // Optional: store device token if your schema supports it (safe no-op if not)
        if (device_token) {
            // If you add fcmToken field later, wire it here.
            console.log('[AUTH] device_token received (not persisted):', String(device_token).slice(0, 16), '...');
        }

        const token = jwt.sign(
            { userId: user.id, driverId: user.driver?.id, role: user.role },
            config.JWT_SECRET,
            { expiresIn: '30d' },
        );

        // Simple refresh token (rotate properly in production)
        const refresh_token = jwt.sign(
            { userId: user.id, type: 'refresh' },
            config.JWT_SECRET,
            { expiresIn: '90d' },
        );

        return res.status(200).json({
            status: 'success',
            data: {
                token,
                refresh_token,
                user: {
                    id: user.id,
                    username: `user_${user.id}`,
                    full_name: user.driver?.fullName ?? null,
                    phone_number: user.phone,
                    email: null,
                    gender: null,
                    dob: null,
                    house_no: null,
                    street: null,
                    city: null,
                    zip_code: null,
                    emergency_contact: null,
                    role: 'driver',
                    avatar: null,
                    fcm_token: device_token ?? null,
                    updated_at: new Date().toISOString(),
                    created_at: new Date().toISOString(),
                    is_updated: false,
                },
            },
        });
    } catch (error) {
        console.error('[AUTH] DB error in loginWithOtpV2:', error.message);

        // Demo-safe fallback so mobile can proceed even if DB is down
        const token = jwt.sign(
            { userId: 'demo-id', driverId: 'demo-driver-id', role: 'DRIVER' },
            config.JWT_SECRET,
            { expiresIn: '30d' },
        );
        const refresh_token = jwt.sign(
            { userId: 'demo-id', type: 'refresh' },
            config.JWT_SECRET,
            { expiresIn: '90d' },
        );

        return res.status(200).json({
            status: 'success',
            data: {
                token,
                refresh_token,
                user: {
                    id: 'demo-id',
                    username: 'user_demo',
                    full_name: 'Demo Driver',
                    phone_number: cleanPhone,
                    email: null,
                    gender: null,
                    dob: null,
                    house_no: null,
                    street: null,
                    city: null,
                    zip_code: null,
                    emergency_contact: null,
                    role: 'driver',
                    avatar: null,
                    fcm_token: device_token ?? null,
                    updated_at: new Date().toISOString(),
                    created_at: new Date().toISOString(),
                    is_updated: false,
                },
            },
        });
    }
};
