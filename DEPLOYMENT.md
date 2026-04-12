# 🌐 Deployment Guide: SaaradhiGO on AWS

This document outlines the steps to deploy the SaaradhiGO Backend and Driver App on AWS.

## 🏗️ Architecture
- **Backend (API):** AWS EC2 / Fargate (Managed Container).
- **Database:** AWS RDS for PostgreSQL.
- **Cache (Redis):** AWS ElastiCache.
- **Static Assets:** AWS S3 for profile pictures and document uploads.
- **CI/CD:** AWS CodePipeline.

---

## 🔐 1. Database Setup
1.  **Create an RDS Instance:** Choose PostgreSQL 15.
2.  **Configure Connectivity:** Ensure the EC2 security group has inbound access to Port 5432.
3.  **Run Migrations:**
    ```bash
    npx prisma migrate deploy
    ```

## 🚀 2. Backend Deployment (EC2/Elastic Beanstalk)
1.  **Environment Variables:** Configure the following in AWS SSM Parameter Store:
    - `DATABASE_URL` (RDS URL)
    - `JWT_SECRET`
    - `TWILIO_SID`/`AUTH_TOKEN` (for SMS)
    - `FIREBASE_ADMIN_CONF` (JSON)
2.  **Containerize (Optional but Recommended):**
    ```dockerfile
    FROM node:18-alpine
    WORKDIR /app
    COPY . .
    RUN npm install --production
    CMD ["npm", "start"]
    ```
3.  **Deploy using AWS App Runner or CodeDeploy.**

## 📱 3. Mobile App Deployment (Android/iOS)
- **Firebase Setup:** Create a Firebase project and add Android/iOS apps. Download and add `google-services.json` and `GoogleService-Info.plist` to the Flutter project.
- **Google Maps Key:** Enable Maps SDK for Android & iOS and add the API key to `AndroidManifest.xml` and `AppDelegate.swift`.
- **Flutter Build (Production):**
    ```bash
    flutter build apk --release
    flutter build ios --release
    ```

---

## ⚡ 4. Advanced: Auto-Scaling & Load Balancing
1.  **Configure Application Load Balancer (ALB):** Port 80/443 pointing to Port 8000.
2.  **Auto Scaling Group (ASG):** Min 2, Max 10 instances based on CPU usage.
3.  **Real-time (Sticky Sessions):** Ensure "Sticky Sessions" are enabled on the ALB for Socket.io stability.

---
*Environment Setup Guide can be found in [SETUP_GUIDE.md](file:///d:/SAARADHI%20GO%20%20DRIVER%20APP/SETUP_GUIDE.md).*
