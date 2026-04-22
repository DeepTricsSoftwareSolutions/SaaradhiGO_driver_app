# 🚀 Quick Start Guide - SaaradhiGO Driver App

## System Requirements

- **Node.js:** v18+ ([Download](https://nodejs.org/))
- **npm:** 9+ (comes with Node.js)
- **Flutter:** v3.0+ (optional, for mobile app)
- **Docker Desktop:** (optional, for PostgreSQL)
- **PostgreSQL:** 14+ (or use Docker)

---

## ⚡ Quick Setup (5 Minutes)

### Windows Users
```bash
# 1. Run the setup script
setup-and-run.bat

# Then follow the on-screen menu
```

### Mac/Linux Users
```bash
# 1. Make script executable
chmod +x setup-and-run.sh

# 2. Run the setup script
./setup-and-run.sh

# Then follow the on-screen menu
```

---

## 📋 Manual Setup Steps

### Step 1: Install Dependencies
```bash
npm run install:all
```

### Step 2: Setup Database

**Option A: Using Docker (Recommended)**
```bash
docker-compose -f server/docker-compose.yml up -d
```

**Option B: Using Local PostgreSQL**
1. Create a database:
   ```sql
   CREATE DATABASE saaradhi_db;
   CREATE USER saaradhigo WITH PASSWORD 'password123';
   ALTER DEFAULT PRIVILEGES GRANT ALL ON TABLES TO saaradhigo;
   ```

2. Update `server/.env`:
   ```
   DATABASE_URL=postgresql://saaradhigo:password123@localhost:5432/saaradhi_db
   ```

### Step 3: Run Migrations
```bash
cd server
npm run migrate
cd ..
```

### Step 4: Start the Application

**Backend Only:**
```bash
npm run backend
# Runs on http://localhost:8000
```

**Mobile App (Web):**
```bash
npm run mobile
# Runs on http://localhost:5173 (with Flutter web)
```

**Both Together (Recommended):**
```bash
npm run dev
# Runs both services concurrently
```

---

## 🌐 Access Points

Once running, access these URLs:

| Service | URL | Purpose |
|---------|-----|---------|
| Frontend | http://localhost:5173 | Web application |
| Backend API | http://localhost:8000/api | API endpoints |
| API Health | http://localhost:8000/health | Server status |
| Prisma Studio | `npm run studio` (in server/) | Database GUI |

---

## 📱 Testing the App

### 1. **Login**
   - Use any phone number (mock OTP mode enabled)
   - OTP will be printed in console

### 2. **Complete Registration**
   - Fill driver details
   - Upload documents (can be test images)
   - System will show "Verification Pending"

### 3. **Dashboard**
   - Toggle Online/Offline
   - View mock earnings
   - Check ride history

### 4. **Test Real-time Features**
   - Open 2 browser tabs (driver + rider simulator)
   - Ride requests appear in real-time via WebSocket

---

## ⚙️ Environment Configuration

### Backend (.env)
```bash
# Server
PORT=8000
NODE_ENV=development

# Database
DATABASE_URL=postgresql://saaradhigo:password123@localhost:5432/saaradhi_db

# Security
JWT_SECRET=your-super-secret-key-minimum-32-characters

# Optional: Google Maps API
GOOGLE_MAPS_API_KEY=your_api_key_here

# Optional: SMS (Twilio)
TWILIO_ACCOUNT_SID=your_sid
TWILIO_AUTH_TOKEN=your_token
TWILIO_PHONE_NUMBER=your_number
```

---

## 🔧 Common Commands

```bash
# Development
npm run dev              # Run all services
npm run backend          # Backend only
npm run mobile           # Flutter web only
npm run mobile:windows   # Flutter desktop (Windows)

# Database
npm run migrate          # Apply migrations
npm run migrate:prod     # Production migrations
npm run studio           # Open Prisma Studio

# Installation
npm install              # Root dependencies
npm run install:all      # All dependencies
```

---

## 🐛 Troubleshooting

### "Connection refused" error
```bash
# PostgreSQL not running
docker-compose -f server/docker-compose.yml up -d
```

### "Port 8000 already in use"
```bash
# Kill existing process on port 8000
# Windows:
netstat -ano | findstr :8000

# Mac/Linux:
lsof -i :8000
```

### "Cannot find flutter"
```bash
# Install Flutter from https://flutter.dev
# Then add to PATH
```

### "Socket.io connection failed"
```bash
# Make sure backend is running:
npm run backend

# Check CORS in server/src/config
```

### Database migration fails
```bash
# Reset database (caution: deletes data)
cd server
npx prisma migrate reset
cd ..
```

---

## 📊 Project Structure

```
SaaradhiGo-Driver/
├── server/                 # Node.js Backend
│   ├── src/
│   │   ├── app.js         # Express app
│   │   ├── server.js      # Server entry
│   │   ├── routes/        # API routes
│   │   ├── controllers/   # Route handlers
│   │   └── socket/        # WebSocket events
│   ├── prisma/
│   │   └── schema.prisma  # Database schema
│   └── .env               # Environment config
│
├── src/                    # React Frontend
│   ├── app/
│   │   ├── screens/       # Page components
│   │   ├── components/    # Reusable components
│   │   └── App.tsx        # Main component
│   └── styles/            # TailwindCSS
│
├── mobile_flutter/        # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart      # App entry
│   │   ├── features/      # Feature modules
│   │   └── core/          # Services & utilities
│   └── pubspec.yaml       # Dependencies
│
└── docs/                  # Documentation
```

---

## ✅ Verification Checklist

- [ ] Node.js v18+ installed
- [ ] All dependencies installed (`npm run install:all`)
- [ ] PostgreSQL running (Docker or local)
- [ ] Database migrations completed
- [ ] Backend starts without errors
- [ ] Can access http://localhost:8000/health
- [ ] Frontend loads at http://localhost:5173
- [ ] Can log in with test phone number

---

## 🆘 Getting Help

Check these files for more information:
- `PROJECT_HEALTH_CHECK.md` - Detailed system status
- `README.md` - Project overview
- `SETUP_GUIDE.md` - Advanced setup
- `DRIVER_APP_GUIDE.md` - Feature documentation

---

## 🚀 Next Steps

1. ✅ Run `npm run install:all`
2. ✅ Start database: `docker-compose -f server/docker-compose.yml up -d`
3. ✅ Run migrations: `cd server && npm run migrate`
4. ✅ Start app: `npm run dev`
5. ✅ Open http://localhost:5173

**Happy coding! 🎉**
