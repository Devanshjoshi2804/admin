# Freight Flow Booking System

A comprehensive freight management and booking system built with modern technologies.

## 🏗️ Architecture

This is a multi-service application consisting of:

- **Backend API** (`backend/api/`) - NestJS REST API with TypeScript
- **Flutter Mobile App** (`freight_flow_flutter/`) - Cross-platform mobile application
- **WebSocket Server** (`websocket-server/`) - Real-time communication service
- **ML Service** (`ml-service/`) - Route optimization and machine learning features

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- Flutter SDK 3.0+
- Python 3.8+
- Docker and Docker Compose (optional)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd freight-flow-booking-system
   ```

2. **Install dependencies for all services**
   ```bash
   npm run install:all
   ```

3. **Start all services**
   ```bash
   npm run dev
   ```

   Or using Docker:
   ```bash
   docker-compose up -d
   ```

## 📁 Project Structure

```
freight-flow-booking-system/
├── backend/                    # Backend services
│   ├── api/                   # Main REST API (NestJS)
│   └── docker-compose.yml     # Backend services orchestration
├── freight_flow_flutter/       # Flutter mobile application
├── websocket-server/          # WebSocket server for real-time features
├── ml-service/               # Machine learning and route optimization
├── shared/                   # Shared types and utilities
│   ├── dto/                 # Data Transfer Objects
│   └── schemas/             # Database schemas
├── docs/                    # Project documentation
├── scripts/                 # Build and deployment scripts
└── docker-compose.yml       # Full stack orchestration
```

## 🛠️ Development

### Backend API
```bash
cd backend/api
npm install
npm run start:dev
```

### Flutter App
```bash
cd freight_flow_flutter
flutter pub get
flutter run
```

### WebSocket Server
```bash
cd websocket-server
npm install
npm start
```

### ML Service
```bash
cd ml-service
pip install -r requirements.txt
python route_optimizer.py
```

## 📱 Features

- 🚚 Freight booking and management
- 📍 Real-time tracking
- 🤖 AI-powered route optimization
- 💬 Real-time messaging
- 📊 Analytics and reporting
- 🔐 Secure authentication
- 📱 Cross-platform mobile app

## 🧪 Testing

Run all tests:
```bash
npm run test:all
```

Individual service tests:
```bash
# Backend API
cd backend/api && npm test

# Flutter App
cd freight_flow_flutter && flutter test
```

## 🚀 Deployment

### Using Docker
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Manual Deployment
See individual service README files for deployment instructions.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support, email support@freightflow.com or join our Slack channel.

## 🔗 Links

- [API Documentation](./backend/api/README.md)
- [Flutter App Documentation](./freight_flow_flutter/README.md)
- [Architecture Documentation](./docs/architecture.md) 