const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Map field names to document types for strict validation
const ALLOWED_FIELDS = [
    { name: 'profilePhoto', maxCount: 1 },
    { name: 'license', maxCount: 1 },
    { name: 'rc', maxCount: 1 },
    { name: 'insurance', maxCount: 1 }
];

// Configure local disk storage as simulaton for S3
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname);
        // Clean filename formatting: driverId_docType_uuid.ext
        const prefix = req.user?.userId || 'unknown';
        const docType = file.fieldname;
        const filename = `${prefix}_${docType}_${uuidv4()}${ext}`;
        cb(null, filename);
    }
});

// File filter to allow only secure image types
const fileFilter = (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error(`Invalid file type for ${file.fieldname}. Only JPG, PNG, WEBP, and PDF are allowed.`), false);
    }
};

const upload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5 MB max per file
    }
});

// We accept up to 1 of each required onboarding document
exports.uploadMiddleware = upload.fields(ALLOWED_FIELDS);
