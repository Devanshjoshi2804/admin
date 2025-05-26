#!/bin/bash

# Freight Flow Booking System - Setup Script
# This script sets up the development environment

echo "🚀 Setting up Freight Flow Booking System..."

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ and try again."
    exit 1
fi

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter 3.0+ and try again."
    exit 1
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python is not installed. Please install Python 3.8+ and try again."
    exit 1
fi

# Check Docker (optional)
if ! command -v docker &> /dev/null; then
    echo "⚠️  Docker is not installed. Docker setup will be skipped."
fi

echo "✅ Prerequisites check completed!"

# Install root dependencies
echo "📦 Installing root dependencies..."
npm install

# Install backend API dependencies
echo "📦 Installing backend API dependencies..."
cd backend/api
npm install
cd ../..

# Install WebSocket server dependencies
echo "📦 Installing WebSocket server dependencies..."
cd websocket-server
npm install
cd ..

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
cd freight_flow_flutter
flutter pub get
cd ..

# Install ML service dependencies
echo "📦 Installing ML service dependencies..."
cd ml-service
pip3 install -r requirements.txt
cd ..

# Create environment files
echo "🔧 Creating environment files..."

# Backend API environment
cat > backend/api/.env << EOF
NODE_ENV=development
PORT=3000
DATABASE_URL=sqlite:./freight_flow.sqlite
JWT_SECRET=your-jwt-secret-key-change-in-production
JWT_EXPIRES_IN=7d
WEBSOCKET_URL=ws://localhost:3001
ML_SERVICE_URL=http://localhost:8000
EOF

# WebSocket server environment
cat > websocket-server/.env << EOF
NODE_ENV=development
PORT=3001
BACKEND_API_URL=http://localhost:3000
EOF

# ML service environment
cat > ml-service/.env << EOF
PYTHONPATH=/app
BACKEND_API_URL=http://localhost:3000
PORT=8000
EOF

echo "🔧 Environment files created!"

# Create shared directory structure
echo "📁 Creating shared directory structure..."
mkdir -p shared/types
mkdir -p shared/utils
mkdir -p shared/constants

# Create initial shared files
cat > shared/types/index.ts << EOF
// Shared TypeScript type definitions
export interface User {
  id: string;
  email: string;
  name: string;
  role: 'customer' | 'driver' | 'admin';
}

export interface Booking {
  id: string;
  userId: string;
  pickupLocation: Location;
  deliveryLocation: Location;
  status: 'pending' | 'confirmed' | 'in_transit' | 'delivered';
  createdAt: Date;
}

export interface Location {
  lat: number;
  lng: number;
  address: string;
}
EOF

echo "📁 Shared structure created!"

# Final setup message
echo "✅ Setup completed successfully!"
echo ""
echo "🎯 Next steps:"
echo "   1. Review the environment files in each service"
echo "   2. Run 'npm run dev' to start all services"
echo "   3. Visit http://localhost:3000 for the API"
echo "   4. The Flutter app can be run with 'flutter run' in the freight_flow_flutter directory"
echo ""
echo "📚 For more information, see README.md" 