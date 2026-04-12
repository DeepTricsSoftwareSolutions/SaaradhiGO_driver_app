# SaaradhiGO Driver App — Product Requirements Document (PRD)

**Version:** 1.0.0  
**Last Updated:** April 2026  
**Status:** Production  
**Platform:** Android (primary) · iOS (secondary)  
**Project:** SaaradhiGO Ride-Hailing Platform

---

## TABLE OF CONTENTS

1. [Product Overview](#1-product-overview)
2. [Goals & Success Metrics](#2-goals--success-metrics)
3. [User Flow (End-to-End)](#3-user-flow-end-to-end)
4. [Feature Modules](#4-feature-modules)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Technical Architecture](#6-technical-architecture)
7. [Database Design](#7-database-design)
8. [API Design](#8-api-design)
9. [Real-Time Events (Sockets)](#9-real-time-events-sockets)
10. [UI/UX Requirements](#10-uiux-requirements)
11. [Testing Strategy](#11-testing-strategy)
12. [Deployment Plan](#12-deployment-plan)
13. [Future Enhancements](#13-future-enhancements)

---

# 1. PRODUCT OVERVIEW

## 1.1 Product Name
**SaaradhiGO Driver App**

## 1.2 Objective
Enable drivers to onboard, accept rides, navigate, complete trips, and receive earnings — all from a single mobile application — with production-grade reliability, real-time communication, and fraud protection.

## 1.3 Target Users

| User Type | Description |
|-----------|-------------|
| Taxi Drivers | Independent licensed drivers operating in metro cities |
| Fleet Drivers | Drivers employed under registered vehicle fleets |
| Gig Economy Drivers | Part-time drivers using personal vehicles |

## 1.4 Platforms

| Platform | Priority | Min Version |
|----------|----------|-------------|
| Android | Primary | Android 8.0 (API 26+) |
| iOS | Secondary | iOS 13.0+ |

## 1.5 Scope

This PRD covers the **Driver-side** application. Rider-side and Admin-side are documented separately.

---

# 2. GOALS & SUCCESS METRICS

## 2.1 Business Goals

- Maximize driver supply on the platform
- Minimize ride rejection rate
- Improve earnings per driver to improve retention
- Reduce fraudulent activity (GPS spoofing, fake accounts)

## 2.2 KPIs & Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|--------------------|
| Driver onboarding completion rate | ≥ 70% | Documents submitted → Approved |
| Ride acceptance rate | ≥ 85% | Accepted / Total received |
| Trip completion rate | ≥ 95% | Completed / Accepted |
| Average driver online time | ≥ 6 hrs/day | Server-side session tracking |
| Average earnings per driver | ≥ ₹800/day | Earnings DB aggregation |
| App crash rate | < 0.1% | Firebase Crashlytics |
| Real-time location latency | < 3 seconds | Socket.io monitoring |
| API response time (p99) | < 500ms | CloudWatch / Datadog |
| GPS spoofing detection rate | > 95% | Flagged drivers / Total spoofed |
| OTP conversion rate | ≥ 90% | OTP sent → Login complete |

---

# 3. USER FLOW (END-TO-END)

## 3.1 Primary Happy Path

```
[Phone Entry]
     │
     ▼
[OTP Verification]  ← Twilio SMS / Demo: any 6-digit
     │
     ├── Existing User ──→ [Dashboard]
     │
     └── New User ────────→ [Document Upload]
                                 │
                                 ▼
                          [Verification Pending]
                                 │
                          (Admin approves)
                                 │
                                 ▼
                            [Dashboard]
                                 │
                         [Toggle ONLINE]
                                 │
                                 ▼
                        [Ride Request Popup]
                          (30-second timer)
                                 │
                        ┌────────┴────────┐
                    [Accept]          [Reject / Expire]
                        │                 │
                        ▼                 └→ [Find next driver]
              [Navigate to Pickup]
                        │
                        ▼
              [Arrived at Pickup]
                        │
                        ▼
              [Rider PIN Verification]
                        │
                        ▼
              [Trip in Progress]   ← GPS tracking active
                        │
                        ▼
            [Slide to End Trip]
                        │
                        ▼
            [Fare Collection Screen]
                        │
                        ▼
            [Rate Passenger]
                        │
                        ▼
            [Earnings Updated] → [Back to Dashboard]
```

## 3.2 Alternate Flows

### Driver Rejects Ride
```
[Ride Request] → [Reject] → [Request forwarded to next driver] → [Status: idle]
```

### Driver Cancels After Acceptance
```
[Accepted] → [Cancel] → [₹25 penalty applied] → [Rider notified via socket] → [Re-broadcast to other drivers]
```

### Network Failure Recovery
```
[Socket disconnected]
     │
     ▼
[Exponential backoff reconnect]
  1s → 2s → 4s → 8s → … → 30s max
     │
     ▼
[If active trip: resume session]
[If idle: mark offline after 30s]
```

### Rider No-Show
```
[Arrived at Pickup] → [30s timer starts] → [No rider] → [Cancel: Rider no-show] → [No penalty for driver]
```

### GPS / Network Loss Mid-Trip
```
[GPS lost] → [Last known location held] → [Reconnect]
[Socket lost] → [30s grace window] → [Rider notified: "reconnecting"]
[Server: trip NOT cancelled automatically]
```

---

# 4. FEATURE MODULES

---

## 4.1 DRIVER ONBOARDING

### Overview
New drivers go through a structured onboarding funnel before being permitted to accept rides. The system enforces document verification as a gate to the driver dashboard.

### User Stories
- As a new driver, I want to register using only my phone number so I don't need to remember a password.
- As a driver, I want to upload my documents from my phone gallery so the process is frictionless.
- As a driver, I want to know the status of my verification so I'm not left guessing.

### Screens
| Screen | Description |
|--------|-------------|
| Login | Phone number entry with country selector |
| OTP Verification | 6-digit OTP input with 5-minute expiry |
| Register | Full name, date of birth, gender |
| Document Upload | 4 document types with image capture/gallery |
| Vehicle Registration | Vehicle type, model, color, number plate |
| Verification Pending | Status display (Pending / Under Review / Approved / Rejected) |

### Document Requirements

| Document | Type | Validation |
|----------|------|-----------|
| Driving License | Image (JPG/PNG/PDF) | Expiry date, number |
| RC (Registration Certificate) | Image | Matches vehicle number |
| Vehicle Insurance | Image | Expiry date |
| Profile Photo | Image | Face clearly visible |

### Backend Implementation
- `POST /api/auth/send-otp` — Generates 6-digit OTP, stores with 5-minute TTL
- `POST /api/auth/verify-otp` — Verifies OTP, creates user + driver record, returns JWT
- `POST /api/driver/documents` — Multipart upload to AWS S3, creates `Document` record
- Admin endpoint: `PATCH /api/admin/drivers/:id/status` — Approves/rejects driver

### Acceptance Criteria

| Criterion | Pass Condition |
|-----------|---------------|
| Driver cannot go online without approval | `status === 'APPROVED'` check before enabling toggle |
| OTP expires after 5 minutes | `expiresAt > Date.now()` check on verify |
| Documents stored securely | Private S3 bucket, pre-signed URL access only |
| Rejected documents show reason | `rejectionReason` field displayed on UI |
| Phone number must be unique | DB unique constraint on `users.phone` |

### Status Flow
```
PENDING → VERIFYING → APPROVED
                    ↘ REJECTED (with reason)
```

---

## 4.2 DRIVER STATUS

### Overview
Drivers control their availability via an Online/Offline toggle. When online, GPS tracking begins and the driver becomes eligible to receive ride requests.

### Features

| Feature | Description |
|---------|-------------|
| Online Toggle | Large, prominent button on dashboard |
| Break Mode | Pauses incoming requests without going fully offline |
| Location Permission | Handles all permission states gracefully |
| Background GPS | Continues tracking when app is backgrounded |
| Battery Optimization | Android battery whitelisting guidance shown to user |

### GPS Tracking Rules
- **Interval:** 3 seconds minimum (configurable via `AppConstants.locationIntervalMs`)
- **Minimum Movement:** 5 meters (avoids GPS jitter at standstill)
- **Accuracy:** High accuracy mode enabled
- **Background:** Enabled via `location.enableBackgroundMode(true)`

### Online Status Sync
```
[Driver toggles ONLINE]
  ├── Flutter: LocationService.startTracking()
  ├── Flutter: SocketService.setDriverStatus(true)
  ├── REST API: POST /api/driver/toggle-status { isOnline: true }
  └── DB: drivers.is_online = true
```

### Acceptance Criteria

| Criterion | Pass Condition |
|-----------|---------------|
| Driver must be APPROVED to go online | Check `driver.status === 'APPROVED'` |
| GPS updates every ≤ 3 seconds | `locationIntervalMs = 3000` in service |
| GPS continues in background | Android background mode enabled |
| Offline toggle stops GPS | `LocationService.stopTracking()` called |
| Status synced to server | REST + socket both updated on toggle |

---

## 4.3 REAL-TIME LOCATION SYSTEM

### Overview
The core of the system is a WebSocket-based real-time location pipeline that streams driver coordinates to the server every 3 seconds, with validation and smoothing applied before broadcasting.

### Architecture

```
Flutter LocationService (3s interval)
     │
     ├── Validation Layer
     │    ├── Reject: isMocked == true (GPS spoofing)
     │    ├── Reject: speed > 250 km/h (impossible movement)
     │    └── Reject: accuracy < 1m (suspicious precision)
     │
     ├── Smoothing Layer (Weighted average: last 3 readings)
     │    └── Weight: oldest=1, middle=2, latest=3
     │
     └── SocketService.updateLocation(lat, lng)
               │
               ▼
          Socket.io Server
               │
          ├── Speed re-validate (server-side)
          ├── Reject stale packets (> 10s old)
          ├── driverLocations.set(driverId, {lat, lng})
          └── Batch write to DB every 10 seconds
               │
               └── If in active trip → broadcast to rider socket
```

### Reconnect Logic
```
Connection lost
  │
  ├── Attempt 1: after 1 second
  ├── Attempt 2: after 2 seconds
  ├── Attempt 3: after 4 seconds
  ├── Attempt N: after min(2^N, 30) seconds
  └── Max attempts: 10
```

### Location Events

| Event | Direction | Payload |
|-------|-----------|---------|
| `update_location` | Client → Server | `{driverId, lat, lng, timestamp}` |
| `driver_location` | Server → Rider | `{driverId, lat, lng, timestamp}` |

### Acceptance Criteria

| Criterion | Pass Condition |
|-----------|---------------|
| Location updates < 3s | Timer set to 3000ms |
| Auto-reconnect on loss | Exponential backoff implemented |
| No GPS jitter | Weighted smoothing over 3 readings |
| Spoofing detected + rejected | isMocked check + speed check |
| Server doesn't overload DB | Batch writes every 10s, not per update |

---

## 4.4 RIDE REQUEST SYSTEM

### Overview
When a rider creates a booking, the backend matches nearby available drivers using PostGIS geo queries and broadcasts the request via Socket.io. The first driver to accept gets the ride.

### Request Display
The ride request appears as a bottom sheet overlay with:
- Rider's name and rating (⭐)
- Pickup distance from driver
- Estimated earnings (₹)
- Pickup + drop addresses
- Payment mode (UPI / Cash)
- Countdown timer (30 seconds)

### Matching Algorithm
```sql
-- PostGIS nearby driver query (server, 5km radius)
SELECT driver_id, full_name, distance_meters
FROM find_nearby_drivers(pickup_lng, pickup_lat, 5000)
WHERE status = 'APPROVED' AND is_online = TRUE
ORDER BY distance_meters ASC
LIMIT 10;
```

### Accept/Reject Flow
```
Server broadcasts to 10 nearest drivers
       │
       ▼
  Each driver sees 30s timer

  First to accept:
    ├── Socket: accept_ride → server locks ride (atomic Map)
    ├── REST: POST /api/rides/:id/accept → prisma.$transaction()
    └── Others: removed from consideration

  If no one accepts in 30s:
    └── Auto-reject (Flutter timer) → ride cancelled or re-broadcast
```

### Race Condition Prevention
- **In-memory lock:** `activeRideLocks.set(rideId, driverId)` checked atomically
- **DB lock:** `prisma.$transaction()` with ride status check
- **Result:** Only one driver wins even with simultaneous accepts

### Acceptance Criteria

| Criterion | Pass Condition |
|-----------|----------------|
| Request auto-cancels after 30s | Flutter `Timer.periodic` countdown |
| Only one driver accepts | Atomic lock + DB transaction |
| Rider info shown | Rating, name, payment mode visible |
| Earnings estimate shown | Fare displayed on request card |
| Sound/vibration on new request | System notification triggered |

---

## 4.5 TRIP EXECUTION

### Trip Lifecycle State Machine

```
REQUESTED ──[accept]──→ ACCEPTED ──[arrive]──→ ARRIVED
                                                  │
                                             [verify PIN]
                                                  │
                                              IN_PROGRESS ──[slide]──→ COMPLETED
                                                  │
                                           Any state ──[cancel]──→ CANCELLED
```

### State Descriptions

| State | Screen | Actions Available |
|-------|--------|------------------|
| `REQUESTED` | Ride Request Sheet | Accept, Reject |
| `ACCEPTED` | Active Trip (Nav to Pickup) | Arrived at Pickup, Cancel |
| `ARRIVED` | PIN Verification | Enter PIN, QR Scan, Cancel |
| `IN_PROGRESS` | Live Trip | Slide to End Trip |
| `COMPLETED` | Payment Screen | Collect Fare, Rate Rider |
| `CANCELLED` | Dashboard | — |

### PIN Verification
- Rider app generates 4-digit PIN at booking time
- Driver enters PIN when rider boards
- PIN verified client-side (from ride object) AND server-side (`POST /api/rides/:id/start`)
- Demo PIN: `1111` works universally in development mode

### Trip Tracking
- GPS tracking active throughout `IN_PROGRESS` state
- Location broadcast to rider every 3 seconds
- Route stored for audit and support purposes

### Acceptance Criteria

| Criterion | Pass Condition |
|-----------|---------------|
| States follow strict lifecycle | State machine in `RideProvider` |
| PIN required before trip start | `verifyPin()` returns bool |
| Slide action prevents accidental end | Must drag > 80% to trigger |
| GPS accurate during trip | High accuracy, smoothing active |
| DB updated on each transition | Socket `trip_update` + REST call |

---

## 4.6 DRIVER EARNINGS

### Overview
Drivers have a dedicated earnings dashboard with daily, weekly, and total breakdowns. All earnings are calculated server-side with full audit trail.

### Fare Calculation Formula

```
Gross Fare = BASE(₹30) + (distance_km × ₹14) + (duration_min × ₹1.5)
Commission = Gross Fare × 20%
Driver Earnings = Gross Fare − Commission
```

### Earnings Dashboard

| Section | Data Shown |
|---------|-----------|
| Today | Total fare collected today |
| This Week | Mon–Sun bar chart |
| Total | Lifetime earnings |
| Recent Trips | Last 10 trips with fare + route |
| Incentives | Bonus targets and progress |

### Acceptance Criteria

| Criterion | Pass Condition |
|-----------|---------------|
| Earnings update after each trip | `Driver.walletBalance` incremented |
| Commission deducted correctly | 20% deducted server-side |
| History persisted | `earnings` + `transactions` DB records |
| Daily/weekly aggregation | Query on `earnings.date` |

---

## 4.7 PAYMENTS & PAYOUTS

### Overview
Drivers collect fare from riders (cash or UPI). Platform commission is auto-deducted. Drivers can withdraw their wallet balance via UPI or bank transfer.

### Payment Flow

```
Trip Completed
     │
     ├── Fare = ₹185
     ├── Commission = ₹37 (20%)
     ├── Driver Earnings = ₹148
     │
     ├── DB: earnings.create({ amount: 148 })
     ├── DB: driver.walletBalance += 148
     └── DB: transactions.create({ type: CREDIT, amount: 148 })
```

### Payout Flow

```
Driver requests withdrawal
     │
     ├── Validate: amount ≥ ₹100
     ├── Validate: walletBalance ≥ amount
     ├── DB: driver.walletBalance -= amount
     ├── DB: transactions.create({ type: DEBIT })
     ├── DB: payouts.create({ status: PENDING })
     └── Razorpay API: createPayout({ upiId, amount })
          │
          ├── Success: payouts.status = SUCCESS
          └── Failure: payouts.status = FAILED → retry queue
```

### Acceptance Criteria

| Criterion | Pass Condition |
|-----------|---------------|
| Minimum withdrawal is ₹100 | Validated server-side |
| Insufficient balance rejected | Balance check before deduction |
| Failed payouts retried | `status = FAILED` → retry job |
| UPI ID stored (encrypted) | AES encryption before DB write |
| Commission formula consistent | Same constants across client + server |

---

## 4.8 SAFETY FEATURES

### Driver Identity
- Profile photo uploaded during onboarding
- National ID (Aadhaar) uploaded and verified
- Admin review before approval

### Vehicle Verification
- RC + Insurance documents required
- Vehicle number unique constraint in DB
- Admin cross-checks RC with vehicle number

### Emergency SOS
- SOS button visible on every active trip screen
- `POST /api/rides/:id/sos { lat, lng }` — alerts ops team
- Location captured at time of trigger
- Future: auto-SMS emergency contacts

### Acceptance Criteria

| Criterion | Pass Condition |
|-----------|---------------|
| SOS triggers server alert | POST logged with driver ID + location |
| SOS button accessible during trip | Always visible on active trip screens |
| Vehicle number unique | DB unique constraint on `vehicle_number` |

---

## 4.9 FRAUD DETECTION

### Detection Methods

| Fraud Type | Detection Method | Action |
|------------|-----------------|--------|
| GPS Spoofing | `isMocked = true` (Android) | Reject location update, flag driver |
| Impossible Speed | Speed > 250 km/h between updates | Reject update, log warning |
| Supernatural Accuracy | GPS accuracy < 1m | Reject update |
| Multiple Accounts | Phone number unique constraint | Registration blocked |
| Vehicle Mismatch | RC vehicle number ≠ registered | Reject at document review |
| Stale Location | Packet timestamp > 10s old | Reject silently |

### Flagging System
```javascript
// server/src/socket/index.js
if (speedKmh > 250) {
    console.warn(`⚠️ Suspicious speed: ${driverId}: ${speedKmh} km/h`);
    return; // Reject location update
}
```

```dart
// mobile_flutter/lib/services/location_service.dart
bool _detectSpoofing(LocationData data) {
    if (data.isMock == true) return true;
    if ((data.accuracy ?? 100) < 1.0) return true;
    return false;
}
```

### Acceptance Criteria

| Criterion | Pass Condition |
|-----------|---------------|
| Spoofed locations rejected | Both client + server checks |
| Duplicate accounts blocked | Phone unique constraint |
| Flagged drivers tracked | `isFlagged` + `flagReason` on Driver model |
| Speed violations logged | Server warning log with driver ID |

---

## 4.10 EDGE CASE HANDLING

| Scenario | Trigger | System Response |
|----------|---------|----------------|
| Driver cancels after accept | `POST /rides/:id/cancel` | ₹25 penalty debited; rider notified via socket; ride re-broadcast |
| Two drivers accept same ride | Concurrent `accept_ride` events | First-accept wins (atomic in-memory lock + DB transaction) |
| Driver starts trip early | `POST /rides/:id/start` without PIN | Rejected — PIN required |
| Rider no-show | Driver waits > N minutes | Driver initiates cancel with "no-show" reason; no penalty |
| Network disconnect | Socket `disconnect` event | 30s grace window; rider notified; trip preserved |
| Driver offline mid-trip | Socket timeout | Op team alerted; trip not auto-cancelled |
| Payment failure | Razorpay API failure | `payouts.status = FAILED`; retry scheduled; driver wallet preserved |
| Expired OTP | Verify called after 5min | 401 returned; new OTP required |
| DB down | All DB calls fail | Demo mode fallback returns mocked data |

---

# 5. NON-FUNCTIONAL REQUIREMENTS

## 5.1 Scalability

| Requirement | Target | Implementation |
|-------------|--------|----------------|
| Concurrent drivers | 100,000+ | PM2 cluster mode + horizontal EC2 scaling |
| Socket connections | 50,000+ | Socket.io with Redis adapter (multi-instance) |
| DB connections | Pooled (max 20 per instance) | Prisma connection pool |
| Location updates/sec | 30,000+ | Batch writes to DB every 10s |

## 5.2 Performance

| Metric | Target |
|--------|--------|
| API response time (p50) | < 100ms |
| API response time (p99) | < 500ms |
| Location update latency | < 3 seconds end-to-end |
| App cold start time | < 3 seconds |
| OTP delivery time | < 10 seconds |

## 5.3 Security

| Requirement | Implementation |
|-------------|---------------|
| Authentication | JWT (30-day expiry, 256-bit secret) |
| OTP Security | 6-digit, 5-minute TTL, in-memory store (Redis in prod) |
| Rate Limiting | 10 OTP requests/min, 200 API requests/min |
| HTTPS | SSL via Let's Encrypt / AWS ACM |
| Security Headers | `helmet` middleware on all responses |
| CORS | Whitelist production domains only |
| Document Storage | Private S3 bucket, pre-signed URLs |
| Sensitive Data | UPI/bank details AES-encrypted before DB write |

## 5.4 Reliability

| Requirement | Target |
|-------------|--------|
| API Uptime | 99.9% (< 8.7 hrs downtime/year) |
| Data Durability | RDS Multi-AZ, daily backups |
| Crash-free Sessions | > 99.9% |
| Retry on Failure | HTTP: 3 retries (exponential backoff); Payout: scheduled retry |

## 5.5 Logging & Monitoring

| Tool | Purpose |
|------|---------|
| PM2 Logs | Node.js stdout/stderr |
| CloudWatch | EC2 + RDS metrics, custom alarms |
| Firebase Crashlytics | Flutter crash reporting |
| Morgan | HTTP request logging (combined format in prod) |

---

# 6. TECHNICAL ARCHITECTURE

## 6.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET                                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                    [Route53 DNS]
                         │
              [Application Load Balancer]
                         │
              [EC2 t3.medium + PM2 Cluster]
               ┌─────────┴───────────┐
               │    Node.js API      │
               │    Express          │
               │     Port 3000       │
               │    ┌────────────┐   │
               │    │ Socket.io  │   │
               │    │ WebSockets │   │
               │    └────────────┘   │
               └────────┬────────────┘
                        │
          ┌─────────────┼─────────────┐
          │             │             │
    [RDS PostgreSQL]  [Redis]      [S3 Bucket]
    [+ PostGIS]      [Session     [Documents]
    [Multi-AZ]        & Socket]
```

## 6.2 Mobile Architecture

```
Flutter App (MVVM-like with Provider)
│
├── Presentation Layer
│    ├── Screens (UI widgets)
│    └── Widgets (reusable components)
│
├── State Layer
│    ├── AuthProvider (login, session)
│    └── RideProvider (lifecycle, socket bridge)
│
├── Service Layer
│    ├── LocationService (GPS tracking)
│    ├── SocketService (WebSocket client)
│    └── ApiClient (HTTP/REST via Dio)
│
└── Core
     ├── theme.dart (dark gold design system)
     └── constants.dart (URLs, config)
```

## 6.3 Data Flow — Ride Request

```
[Rider creates booking]
     │  POST /api/rides
     ▼
[Server: calculateFare()]
     │
     ▼
[PostGIS: find_nearby_drivers(lat, lng, 5000m)]
     │
     ▼
[Socket.io: broadcastRideRequest(rideData, driverIds)]
     │
     ▼
[Flutter: onRideRequest callback fires]
     │
     ▼
[RideRequestSheet shown with 30s timer]
     │
     ▼
[Driver taps Accept]
     │
     ├── Socket: emit('accept_ride', {rideId})
     ├── Server: atomic lock check
     └── REST: POST /api/rides/:id/accept (prisma.$transaction)
```

---

# 7. DATABASE DESIGN

## 7.1 Entity Relationship Summary

```
User (1) ──── (1) Driver
Driver (1) ── (M) Document
Driver (1) ── (M) Ride
Driver (1) ── (M) Earning
Driver (1) ── (M) Transaction
Driver (1) ── (M) Payout
Ride   (1) ── (1) Earning
```

## 7.2 Table Definitions

### `users`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, default uuid_generate_v4() |
| phone | VARCHAR(20) | UNIQUE, NOT NULL |
| role | VARCHAR(20) | DEFAULT 'DRIVER' |
| created_at | TIMESTAMP | DEFAULT NOW() |

### `drivers`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK → users.id, UNIQUE |
| full_name | VARCHAR(100) | |
| profile_pic | TEXT | S3 URL |
| status | driver_status | DEFAULT 'PENDING' |
| is_online | BOOLEAN | DEFAULT FALSE |
| current_lat / lng | DECIMAL(10,8) | |
| location | GEOGRAPHY(POINT) | PostGIS, GIST indexed |
| vehicle_type | VARCHAR(20) | AUTO / SEDAN / SUV |
| vehicle_number | VARCHAR(20) | UNIQUE |
| rating | DECIMAL(3,2) | DEFAULT 5.00 |
| wallet_balance | DECIMAL(12,2) | DEFAULT 0.00 |
| is_flagged | BOOLEAN | DEFAULT FALSE |
| upi_id | VARCHAR(100) | |

### `documents`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| driver_id | UUID | FK → drivers.id |
| type | document_type | LICENSE / RC / INSURANCE / AADHAR |
| url | TEXT | S3 URL |
| status | document_status | PENDING / VERIFIED / REJECTED |
| rejection_reason | TEXT | |
| expiry_date | DATE | |

### `rides`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| driver_id | UUID | FK → drivers.id, nullable |
| rider_id | VARCHAR(100) | NOT NULL |
| pickup_lat/lng | DECIMAL | NOT NULL |
| pickup_addr | TEXT | |
| drop_lat/lng | DECIMAL | |
| drop_addr | TEXT | |
| status | ride_status | REQUESTED / ACCEPTED / ARRIVED / IN_PROGRESS / COMPLETED / CANCELLED |
| fare | DECIMAL(8,2) | |
| distance_km | DECIMAL(6,2) | |
| duration_min | INT | |
| ride_pin | CHAR(4) | |
| payment_mode | VARCHAR(20) | CASH / UPI / CARD |
| start_time / end_time | TIMESTAMP | |
| cancelled_by | VARCHAR(10) | DRIVER / RIDER |

### `earnings`
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | PK |
| driver_id | UUID | FK → drivers.id |
| ride_id | UUID | FK → rides.id, UNIQUE |
| gross_fare | DECIMAL(8,2) | Full fare |
| commission | DECIMAL(8,2) | 20% platform fee |
| amount | DECIMAL(8,2) | Net driver earnings |
| date | TIMESTAMP | |

### `transactions`
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | PK |
| driver_id | UUID | FK |
| amount | DECIMAL(10,2) | Positive = credit |
| type | transaction_type | CREDIT / DEBIT |
| description | TEXT | |
| reference_id | UUID | ride_id or payout_id |

### `payouts`
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | PK |
| driver_id | UUID | FK |
| amount | DECIMAL(10,2) | |
| status | payout_status | PENDING / PROCESSING / SUCCESS / FAILED |
| upi_id | VARCHAR(100) | |
| gateway_payout_id | VARCHAR(100) | Razorpay payout ID |
| failure_reason | TEXT | |
| processed_at | TIMESTAMP | |

## 7.3 PostGIS Geo Function

```sql
-- Find drivers within radius (meters) of a point
SELECT * FROM find_nearby_drivers(
    pickup_lng  := 78.3915,   -- longitude first (PostGIS convention)
    pickup_lat  := 17.4448,
    radius_meters := 5000
);
-- Returns: driver_id, full_name, distance_meters, current_lat, current_lng
```

---

# 8. API DESIGN

## 8.1 Auth APIs

### POST `/api/auth/send-otp`
```json
// Request
{ "phone": "+919876543210" }

// Response 200
{
    "status": "OK",
    "message": "OTP sent successfully",
    "devOtp": "123456"  // DEV ONLY — removed in production
}
```

### POST `/api/auth/verify-otp`
```json
// Request
{ "phone": "+919876543210", "otp": "123456" }

// Response 200
{
    "status": "OK",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
        "id": "uuid",
        "driverId": "uuid",
        "phone": "+919876543210",
        "status": "APPROVED",
        "fullName": "Rahul Kumar"
    }
}

// Response 401
{ "status": "ERR", "message": "Incorrect OTP. Please try again." }
```

## 8.2 Driver APIs

All driver APIs require `Authorization: Bearer <token>` header.

### GET `/api/driver/profile`
```json
// Response 200
{
    "status": "OK",
    "name": "Rahul Kumar",
    "phone": "+919876543210",
    "rating": 4.8,
    "status": "APPROVED",
    "totalRides": 156,
    "walletBalance": 1250.00,
    "isOnline": false
}
```

### PUT `/api/driver/profile`
```json
// Request
{ "fullName": "Rahul Kumar", "profilePic": "s3://bucket/photo.jpg" }

// Response 200
{ "status": "OK", "message": "Profile updated successfully" }
```

### POST `/api/driver/toggle-status`
```json
// Request
{ "isOnline": true }

// Response 200
{ "status": "OK", "message": "Status updated to Online", "isOnline": true }
```

### POST `/api/driver/documents` (multipart/form-data)
```
Form fields:
  - documentType: "LICENSE" | "RC" | "INSURANCE" | "AADHAR"
  - file: <binary>

// Response 200
{ "status": "OK", "documentId": "uuid", "url": "https://s3.../file.jpg" }
```

## 8.3 Ride APIs

### GET `/api/rides/history`
```json
// Response 200
{
    "status": "OK",
    "history": [
        {
            "id": "uuid",
            "pickupAddr": "Hitech City",
            "dropAddr": "Banjara Hills",
            "fare": 185,
            "status": "COMPLETED",
            "createdAt": "2026-04-03T10:00:00Z"
        }
    ]
}
```

### POST `/api/rides/:rideId/accept`
```json
// Response 200
{ "status": "OK", "message": "Ride accepted", "ride": { "id": "...", "status": "ACCEPTED" } }

// Response 409 (race condition — another driver accepted first)
{ "status": "ERR", "message": "Already accepted by another driver" }
```

### POST `/api/rides/:rideId/start`
```json
// Request
{ "otp": "7823" }

// Response 200
{ "status": "OK", "message": "Trip started", "rideId": "uuid" }

// Response 400
{ "status": "ERR", "message": "Invalid OTP format" }
```

### POST `/api/rides/:rideId/complete`
```json
// Response 200
{
    "status": "OK",
    "message": "Ride completed",
    "driverEarnings": 148,
    "rideId": "uuid"
}
```

### POST `/api/rides/:rideId/cancel`
```json
// Request
{ "reason": "Rider no-show" }

// Response 200
{
    "status": "OK",
    "message": "Ride cancelled",
    "penaltyAmount": 0    // 25 if driver initiated post-accept
}
```

### POST `/api/rides/:rideId/sos`
```json
// Request
{ "lat": 17.4448, "lng": 78.3817 }

// Response 200
{ "status": "OK", "message": "SOS alert sent. Help is on the way." }
```

## 8.4 Earnings APIs

### GET `/api/earnings`
```json
// Response 200
{
    "status": "OK",
    "today": 1250,
    "week": 8500,
    "month": 32000,
    "total": 156000,
    "totalRides": 156,
    "history": [...]
}
```

## 8.5 Wallet APIs

### GET `/api/wallet/balance`
```json
{ "status": "OK", "balance": 1250.00, "currency": "INR" }
```

### POST `/api/wallet/withdraw`
```json
// Request
{ "amount": 500 }

// Response 200
{
    "status": "OK",
    "message": "Withdrawal of ₹500 initiated. Will reach your bank in 2-4 hours.",
    "newBalance": 750.00
}

// Response 400
{ "status": "ERR", "message": "Minimum withdrawal amount is ₹100" }
{ "status": "ERR", "message": "Insufficient balance" }
```

### GET `/api/wallet/transactions`
```json
{
    "status": "OK",
    "transactions": [
        { "id": "uuid", "amount": 148, "type": "CREDIT", "description": "Ride completed", "createdAt": "..." },
        { "id": "uuid", "amount": -500, "type": "DEBIT", "description": "Payout to bank", "createdAt": "..." }
    ]
}
```

---

# 9. REAL-TIME EVENTS (SOCKETS)

## 9.1 Connection

```
Client connects to: ws://api.domain.com
Auth: socket options { auth: { token: "Bearer <jwt>" } }
```

## 9.2 Event Reference

### Client → Server Events

| Event | Payload | Description |
|-------|---------|-------------|
| `register_driver` | `driverId: string` | Join driver room, mark online |
| `update_location` | `{driverId, lat, lng, timestamp}` | Stream GPS coordinates |
| `accept_ride` | `{rideId, driverId}` | Attempt to accept ride |
| `reject_ride` | `{rideId, driverId}` | Decline ride request |
| `trip_update` | `{rideId, status, riderId, driverId}` | Push trip lifecycle event |
| `driver_status` | `{driverId, isOnline}` | Toggle availability |
| `driver_offline` | `{driverId}` | Clean disconnect signal |

### Server → Client Events

| Event | Target | Payload | Description |
|-------|--------|---------|-------------|
| `new_ride_request` | Driver room | Full ride object | New ride available |
| `ride_accept_confirmed` | Accepting driver | `{rideId}` | Lock confirmed |
| `ride_accept_failed` | Losing driver | `{rideId, reason}` | Already taken |
| `trip_status` | Rider room | `{rideId, status}` | Driver's trip update |
| `driver_location` | Rider room | `{driverId, lat, lng}` | Live driver position |
| `ride_cancelled` | Rider/Driver | `{rideId, reason}` | Trip cancelled |
| `driver_disconnected` | Rider | `{message}` | Driver lost connection |

## 9.3 Room Architecture

```
Driver rooms:  "driver:{driverId}"   ← Receives ride requests
Rider rooms:   "rider:{riderId}"     ← Receives trip status + driver location
Admin rooms:   "admin:ops"           ← Receives SOS alerts + fraud flags
```

## 9.4 Event Sequence — Full Trip

```
1. Server → Driver:  new_ride_request
2. Driver → Server:  accept_ride
3. Server → Driver:  ride_accept_confirmed
4. Driver → Server:  update_location (every 3s)
5. Server → Rider:   driver_location (every 3s)
6. Driver → Server:  trip_update { status: ARRIVED }
7. Server → Rider:   trip_status { status: ARRIVED }
8. Driver → Server:  trip_update { status: IN_PROGRESS }
9. Server → Rider:   trip_status { status: IN_PROGRESS }
10. Driver → Server: trip_update { status: COMPLETED }
11. Server → Rider:  trip_status { status: COMPLETED }
```

---

# 10. UI/UX REQUIREMENTS

## 10.1 Design System

| Token | Value |
|-------|-------|
| Primary Color | Gold `#FFD700` |
| Background | Black `#000000` |
| Surface | Dark `#141414` |
| Success | Green `#22C55E` |
| Error | Red `#EF4444` |
| Text Primary | White `#FFFFFF` |
| Text Secondary | `#94A3B8` |
| Font | Google Fonts (Outfit / Inter) |
| Border radius | 24–44dp (glassmorphism cards) |
| Mode | Dark mode (primary) |

## 10.2 Safety-First UI Principles

| Principle | Implementation |
|-----------|---------------|
| Large buttons | Minimum 56dp height, full-width CTAs |
| High contrast | White on dark, gold accents |
| No small text | Minimum 14sp body, 20sp+ for critical info |
| Slide to confirm | Slide action for irreversible actions (End Trip) |
| PIN input | Large 48sp digits, auto-verify on 4th digit |
| Map-first layout | 80% screen real estate for map during navigation |

## 10.3 Screen Inventory

| Screen | Route | User State |
|--------|-------|-----------|
| Splash | / | Always |
| Login | /login | Unauthenticated |
| OTP | /otp | During login |
| Register | /register | New user |
| Onboarding | /onboarding | PENDING status |
| Verification Pending | /verification | VERIFYING status |
| Dashboard | /dashboard | APPROVED |
| Active Trip | /active-trip | During ride |
| Earnings | /earnings | Any |
| Profile | /profile | Any |
| Wallet | /wallet | Any |
| About | /about | Any |

## 10.4 Real-Time UX Rules

- Location dot on map updates smoothly (no jitter) via location smoothing
- Online/Offline state reflected instantly without page refresh
- Ride request appears as animated bottom sheet with pulsing countdown
- Trip status changes reflected immediately via socket
- Earnings update after each completed trip without manual refresh

---

# 11. TESTING STRATEGY

## 11.1 Testing Layers

| Layer | Tool | Coverage Target |
|-------|------|----------------|
| Unit Tests | Flutter `flutter_test`, Jest (Node.js) | Core logic functions |
| Widget Tests | Flutter `flutter_test` | Critical screens |
| Integration Tests | Flutter Integration Test | End-to-end flows |
| API Tests | Postman / REST Client | All endpoints |
| Load Testing | k6 / Artillery | 10K concurrent drivers |
| Security Testing | OWASP ZAP | Auth, injection, rate limits |

## 11.2 Test Scenarios

### Functional Testing
- [ ] OTP send → receive → verify → JWT issued
- [ ] Document upload → S3 stored → status PENDING
- [ ] Toggle online → GPS starts → location streamed
- [ ] Ride request received → accepted → trip completed lifecycle
- [ ] Earnings calculated correctly (fare − 20%)
- [ ] Withdrawal: balance deducted + transaction record

### Edge Case Testing
- [ ] Two drivers accept same ride simultaneously
- [ ] OTP entered after 5-minute expiry
- [ ] Withdraw more than wallet balance
- [ ] GPS returns mock location (spoofed)
- [ ] Socket disconnects during active trip
- [ ] Backend returns 500 (demo fallback)

### GPS/Network Testing
- [ ] App background → GPS continues (Android)
- [ ] Flight mode → socket reconnects on restore
- [ ] Slow network (3G sim) → retries work
- [ ] Location smoothing removes jitter
- [ ] Speed > 250 km/h rejected

### Security Testing
- [ ] JWT without valid secret rejected (401)
- [ ] Rate limit: 11th OTP request in 60s → 429
- [ ] SQL injection in API params → sanitized
- [ ] CORS: request from unknown origin → blocked
- [ ] S3 document: direct URL access without token → denied

### Payment Testing
- [ ] ₹99 withdrawal → rejected (below minimum)
- [ ] Withdrawal with 0 balance → rejected
- [ ] Razorpay payout failure → status FAILED, wallet not deducted
- [ ] Commission calculation: exactly 20% deducted

---

# 12. DEPLOYMENT PLAN

## 12.1 Environments

| Environment | URL | Purpose |
|-------------|-----|---------|
| Development | localhost:3000 | Active development |
| Staging | staging-api.saaradhigo.com | QA + integration testing |
| Production | api.saaradhigo.com | Live users |

## 12.2 CI/CD Pipeline

```
[Push to main branch]
     │
     ▼
[GitHub Actions / GitLab CI]
     │
     ├── Run linters (ESLint, Dart analyze)
     ├── Run unit tests (Jest + flutter test)
     ├── Build Docker image
     └── Push to ECR
          │
          ▼
     [Deploy to Staging (EC2)]
          │
          ├── Smoke tests
          ├── Integration tests (Postman collection)
          └── Manual QA sign-off
               │
               ▼
          [Deploy to Production]
               │
               ├── pm2 reload (zero-downtime)
               ├── npx prisma migrate deploy
               └── Health check: GET /health
```

## 12.3 Release Checklist

- [ ] `JWT_SECRET` is 256-bit random string
- [ ] Twilio SMS configured and tested
- [ ] `ALLOWED_ORIGINS` set to production domains only
- [ ] RDS Multi-AZ enabled
- [ ] S3 bucket is private (public access blocked)
- [ ] HTTPS certificate active (Let's Encrypt / ACM)
- [ ] PM2 cluster mode (`instances: 'max'`)
- [ ] `pm2 save` + `pm2 startup` run
- [ ] Rate limiting enabled
- [ ] Flutter app `apiUrl` pointing to production
- [ ] Flutter release build signed with keystore
- [ ] Firebase Crashlytics initialized
- [ ] CloudWatch alarms configured (CPU > 80%, 5XX errors)

## 12.4 Monitoring

| Tool | Monitors |
|------|---------|
| PM2 Monit | CPU, memory per Node.js instance |
| CloudWatch | EC2 system metrics, RDS connections |
| Firebase Crashlytics | Flutter crash stack traces |
| Morgan (prod) | Every HTTP request logged |
| Socket.io Admin UI | Active connections, rooms |

---

# 13. FUTURE ENHANCEMENTS

## Phase 2 (Q3 2026)

| Feature | Description |
|---------|-------------|
| AI Ride Prediction | ML model predicting demand areas by time of day |
| Driver Heatmaps | Visual map showing high-demand zones in real time |
| Gamification | Daily streaks, completion bonuses, leaderboards |
| Voice Navigation | Turn-by-turn audio directions during trip |
| Redis Pub/Sub | Replace in-memory socket state for multi-server scaling |
| PostGIS Full Integration | Replace haversine fallback with DB-native geo queries |

## Phase 3 (Q4 2026)

| Feature | Description |
|---------|-------------|
| Driver Ratings Analytics | Trend charts for ratings over time |
| Auto Payout | Automatic daily payout at EOD if balance > ₹500 |
| Vehicle Tracking (Fleet) | Fleet manager dashboard with all drivers on map |
| Referral System | Driver refers new driver → both get bonus |
| Multi-language | Hindi, Telugu, Tamil support |
| Accessibility | Screen reader support, high contrast mode |

---

*Document maintained by the SaaradhiGO Platform Team.*  
*For questions, contact: tech@saaradhigo.com*
