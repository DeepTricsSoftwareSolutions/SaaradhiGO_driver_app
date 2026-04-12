require('dotenv').config();

module.exports = {
    PORT: process.env.PORT || 8000,
    DATABASE_URL: process.env.DATABASE_URL,
    REDIS_URL: process.env.REDIS_URL || 'redis://localhost:6379',
    JWT_SECRET: process.env.JWT_SECRET || 'your_super_secret_key_change_in_production',
    NODE_ENV: process.env.NODE_ENV || 'development',
    GOOGLE_MAPS_API_KEY: process.env.GOOGLE_MAPS_API_KEY,

    // Twilio SMS (for real OTP)
    TWILIO_ACCOUNT_SID: process.env.TWILIO_ACCOUNT_SID,
    TWILIO_AUTH_TOKEN: process.env.TWILIO_AUTH_TOKEN,
    TWILIO_PHONE_NUMBER: process.env.TWILIO_PHONE_NUMBER,
};
