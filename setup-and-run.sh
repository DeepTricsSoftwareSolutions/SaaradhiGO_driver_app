#!/bin/bash
# SaaradhiGO Driver App - Setup & Run Script

echo "==============================================="
echo "  🚀 SaaradhiGO Driver App - Setup & Run"
echo "==============================================="

# Function to print status
print_status() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Check prerequisites
print_status "Step 1: Checking Prerequisites"

if ! command -v node &> /dev/null; then
    echo "❌ Node.js not installed. Please install Node.js v18+"
    exit 1
fi
echo "✅ Node.js $(node --version) found"

if ! command -v npm &> /dev/null; then
    echo "❌ npm not installed."
    exit 1
fi
echo "✅ npm $(npm --version) found"

# Install dependencies
print_status "Step 2: Installing Dependencies"

if [ ! -d "node_modules" ]; then
    echo "📦 Installing root dependencies..."
    npm install
else
    echo "✅ Root dependencies already installed"
fi

if [ ! -d "server/node_modules" ]; then
    echo "📦 Installing backend dependencies..."
    cd server && npm install && cd ..
else
    echo "✅ Backend dependencies already installed"
fi

echo "📦 Installing Flutter dependencies..."
cd mobile_flutter
if ! flutter pub get &> /dev/null; then
    echo "⚠️  Flutter not found - skipping mobile deps. Install Flutter to run mobile app."
else
    echo "✅ Flutter dependencies installed"
fi
cd ..

# Database setup
print_status "Step 3: Setting Up Database"

if command -v docker &> /dev/null; then
    read -p "Do you want to start PostgreSQL with Docker? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🐳 Starting Docker containers..."
        docker-compose -f server/docker-compose.yml up -d
        echo "✅ Database started (5432)"
        sleep 2
    fi
else
    echo "⚠️  Docker not found - using existing database"
    echo "Make sure PostgreSQL is running on localhost:5432"
fi

# Run migrations
print_status "Step 4: Database Migrations"

cd server
if npm run migrate; then
    echo "✅ Migrations completed"
else
    echo "⚠️  Migration warning - database may not be ready yet"
fi
cd ..

# Start server
print_status "Step 5: Starting Services"

echo ""
echo "Choose what to run:"
echo "1) Backend only (Port 8000)"
echo "2) Mobile (Flutter web on Chrome)"
echo "3) Both (Backend + Mobile)"
echo "4) Exit"

read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo "🚀 Starting Backend Server..."
        npm run backend
        ;;
    2)
        echo "🚀 Starting Flutter Web App..."
        npm run mobile
        ;;
    3)
        echo "🚀 Starting All Services..."
        npm run dev
        ;;
    4)
        echo "👋 Setup complete! Run 'npm run dev' to start"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac
