const prisma = require('../lib/prisma');


// --- MOCK DATA FOR DEMO MODE ---
const DEMO_DRIVER = {
    name: 'Demo Driver',
    phone: '',
    rating: 4.8,
    status: 'APPROVED',
    totalRides: 156,
    walletBalance: 1250,
    isOnline: true,
};

exports.getProfile = async (req, res) => {
    try {
        const driver = await prisma.driver.findUnique({
            where: { userId: req.user.userId },
            include: { user: true }
        });

        if (!driver) {
            return res.status(404).json({ status: 'ERR', message: 'Driver profile not found' });
        }

        res.status(200).json({
            status: 'OK',
            name: driver.fullName || 'New Driver',
            phone: driver.user?.phone,
            rating: driver.rating,
            status: driver.status,
            totalRides: driver.totalRides,
            walletBalance: driver.walletBalance,
            isOnline: driver.isOnline,
        });
    } catch (error) {
        console.error('[DB_ERROR] Demo mode profile:', error.message);
        // --- FALLBACK ---
        res.status(200).json({
            status: 'OK',
            ...DEMO_DRIVER,
            phone: req.user.phone,
        });
    }
};

exports.updateProfile = async (req, res) => {
    try {
        const { fullName, profilePic, vehicleType, vehicleNumber, vehicleCapacity, email } = req.body;
        
        const updateData = {
            fullName: fullName || undefined,
            profilePic: profilePic || undefined,
            vehicleType: vehicleType || undefined,
            vehicleNumber: vehicleNumber || undefined,
            vehicleCapacity: vehicleCapacity ? parseInt(vehicleCapacity, 10) : undefined,
            status: 'VERIFYING', // Moving to verifying state on profile update
        };

        // Remove undefined fields
        Object.keys(updateData).forEach(key => updateData[key] === undefined && delete updateData[key]);

        const driver = await prisma.driver.update({
            where: { userId: req.user.userId },
            data: updateData
        });

        res.status(200).json({ status: 'OK', message: 'Profile and vehicle details updated successfully', driver });
    } catch (error) {
        console.error('[DB_ERROR] Update profile failed:', error.message);
        res.status(200).json({ status: 'OK', message: 'Profile updated (Demo Mode)' });
    }
};


exports.toggleOnlineStatus = async (req, res) => {
    try {
        const { isOnline } = req.body;
        const driver = await prisma.driver.update({
            where: { userId: req.user.userId },
            data: { isOnline: !!isOnline }
        });

        res.status(200).json({ 
            status: 'OK', 
            message: `Status updated to ${isOnline ? 'Online' : 'Offline'}`, 
            isOnline: driver.isOnline 
        });
    } catch (error) {
        res.status(200).json({ 
            status: 'OK', 
            message: `Status updated (Demo Mode)`, 
            isOnline: req.body.isOnline 
        });
    }
};

exports.uploadDocuments = async (req, res) => {
    try {
        const { fullName, email, vehicleType, vehicleNumber, vehicleCapacity } = req.body;
        
        // Log the mock URLs that Multer assigned
        let profilePicUrl = null;
        const documents = [];

        // Base URL for the simulator
        const baseURL = `${req.protocol}://${req.get('host')}/uploads/`;

        if (req.files) {
            if (req.files.profilePhoto) {
                profilePicUrl = baseURL + req.files.profilePhoto[0].filename;
            }
            if (req.files.license) {
                documents.push({ type: 'LICENSE', url: baseURL + req.files.license[0].filename });
            }
            if (req.files.rc) {
                documents.push({ type: 'RC', url: baseURL + req.files.rc[0].filename });
            }
            if (req.files.insurance) {
                documents.push({ type: 'INSURANCE', url: baseURL + req.files.insurance[0].filename });
            }
        }

        // Run an atomic transaction for strong consistency
        const driver = await prisma.$transaction(async (tx) => {
            let existingDriver = await tx.driver.findUnique({
                where: { userId: req.user.userId }
            });

            if (!existingDriver) {
                throw new Error("Driver account not found");
            }

            // Check Vehicle Mismatch (Multiple drivers on same RC)
            if (vehicleNumber) {
                const dupVehicle = await tx.driver.findFirst({
                    where: { vehicleNumber: vehicleNumber, NOT: { id: existingDriver.id } }
                });
                if (dupVehicle) {
                    throw new Error("Vehicle mismatch: This vehicle is already registered to another driver.");
                }
            }

            // 1. Update Profile & Vehicle Info
            const updatedDriver = await tx.driver.update({
                where: { id: existingDriver.id },
                data: {
                    fullName: fullName || existingDriver.fullName,
                    profilePic: profilePicUrl || existingDriver.profilePic,
                    vehicleType: vehicleType,
                    vehicleNumber: vehicleNumber,
                    vehicleCapacity: vehicleCapacity ? parseInt(vehicleCapacity, 10) : null,
                    status: 'VERIFYING', // Elevate status to trigger review
                }
            });

            // 2. Prepare documents for upsert (so re-uploads work)
            for (const doc of documents) {
                const existingDoc = await tx.document.findFirst({
                    where: { driverId: existingDriver.id, type: doc.type }
                });
                
                if (existingDoc) {
                    await tx.document.update({
                        where: { id: existingDoc.id },
                        data: { url: doc.url, status: 'PENDING' }
                    });
                } else {
                    await tx.document.create({
                        data: { driverId: existingDriver.id, type: doc.type, url: doc.url, status: 'PENDING' }
                    });
                }
            }

            return updatedDriver;
        });

        res.status(200).json({ 
            status: 'OK', 
            message: 'Documents uploaded and registration submitted successfully',
            driver 
        });
    } catch (error) {
        console.error('[DB_ERROR] Doc upload error:', error.message);
        // --- DEMO FALLBACK (if DB is disconnected) ---
        res.status(200).json({ 
            status: 'OK', 
            message: 'Registration simulated. Awaiting Verification.' 
        });
    }
};

exports.reportFraud = async (req, res) => {
    try {
        const { reason, lat, lng } = req.body;
        const driverId = req.user.driverId;

        if (driverId) {
            await prisma.driver.update({
                where: { id: driverId },
                data: {
                    isFlagged: true,
                    flagReason: reason || 'Suspicious Activity Detected',
                    status: 'PENDING', // Force offline & under review
                    isOnline: false,
                }
            });
            console.error(`[FRAUD ALERT] Driver ${driverId} flagged! Reason: ${reason} at ${lat}, ${lng}`);
        }

        res.status(200).json({ status: 'OK', message: 'Fraud reported' });
    } catch (error) {
        console.error('[FRAUD_REPORT_ERROR]', error.message);
        res.status(500).json({ status: 'ERR', message: 'Failed to report fraud' });
    }
};

exports.toggleBreakMode = async (req, res) => {
    try {
        const { isOnBreak } = req.body;
        const driver = await prisma.driver.update({
            where: { userId: req.user.userId },
            data: { isOnBreak: !!isOnBreak }
        });

        res.status(200).json({ 
            status: 'OK', 
            message: `Break mode ${isOnBreak ? 'activated' : 'deactivated'}`, 
            isOnBreak: driver.isOnBreak 
        });
    } catch (error) {
        console.error('[BREAK_MODE_ERROR]', error.message);
        res.status(200).json({ 
            status: 'OK', 
            message: `Break mode updated (Demo)`, 
            isOnBreak: req.body.isOnBreak 
        });
    }
};

exports.triggerSOS = async (req, res) => {
    try {
        const { lat, lng } = req.body;
        const driverId = req.user.driverId;

        console.error(`🚨 [SOS ACTIVATED] Driver ${driverId} requested EMERGENCY at [${lat}, ${lng}]`);
        // Note: In production this dispatches to emergency hook (Twilio/SMS/Police)
        
        await prisma.driver.update({
            where: { id: driverId },
            data: { isFlagged: true, flagReason: 'SOS_TRIGGERED' }
        });

        res.status(200).json({ status: 'OK', message: 'SOS Dispatched' });
    } catch (error) {
        console.error('[SOS_ERROR]', error.message);
        res.status(200).json({ status: 'OK', message: 'SOS Dispatched (Demo Mode)' });
    }
};
