# 🛠️ Environment Setup Guide: SaaradhiGO

This document provides steps to set up the SaaradhiGO Driver App and Backend for local development.

---

## 🏗️ 1. Prerequisites
- **Node.js:** 18+ (LTS)
- **Database:** PostgreSQL (Cloud or Local)
- **Cache:** Redis Server (optional for local, required for production)
- **Flutter:** 3.x+ (Mobile App)
- **Mobile Emulators:** Android Studio (Android) or Xcode (iOS)

---

## 🌐 2. Backend Setup (`server/`)
1.  **Clone & Install:**
    ```bash
    cd server
    npm install
    ```
2.  **Environment Variables:** Create a `.env` file with:
    ```env
    DATABASE_URL="postgresql://user:password@localhost:5432/saaradhigo"
    PORT=8000
    JWT_SECRET="your-super-secret-key"
    REDIS_URL="redis://localhost:6379"
    TWILIO_SID="ACxxx"
    TWILIO_TOKEN="xxxx"
    TWILIO_PHONE="+1xxx"
    ```
3.  **Database Initialisation (Prisma):**
    ```bash
    npx prisma migrate dev --name init
    npx prisma generate
    ```
4.  **Start Server:**
    ```bash
    npm start
    ```

---

## 📱 3. Mobile App Setup (`mobile_flutter/`)
1.  **Install Gems & Dependencies:**
    ```bash
    cd mobile_flutter
    flutter pub get
    ```
2.  **Firebase Config:**
    - Place `google-services.json` in `android/app/`.
    - Place `GoogleService-Info.plist` in `ios/Runner/`.
3.  **Google Maps Key:**
    - **Android:** Add your API key to `android/app/src/main/AndroidManifest.xml`:
      ```xml
      <meta-data android:name="com.google.android.geo.API_KEY" android:value="your_api_key"/>
      ```
4.  **Launch App:**
    ```bash
    flutter run
    ```

---

## 🔍 4. Troubleshooting
- **No Google Maps?** Ensure your API Key has the "Maps SDK" enabled and unrestricted during development.
- **Database Connection Error?** Check if PostgreSQL is running locally and your `.env` credentials are correct.
- **Redis Error?** The app will fallback to a local Map during development, but `redis-server` must be started in production for real-time tracking.

---
*Follow the [API Documentation](file:///d:/SAARADHI%20GO%20%20DRIVER%20APP/API_DOCUMENTATION.md) for endpoint details and testing scripts.*
