# FreightFlow Booking System

A comprehensive freight and logistics management application for booking, tracking, and managing shipments.

## Project Structure

The project is organized into two main parts:

- **Frontend**: React-based web application (root directory)
- **Backend**: NestJS API with SQLite database (`/backend/api`)

### Frontend Technologies

- Vite
- TypeScript
- React
- shadcn-ui
- Tailwind CSS

### Backend Technologies

- NestJS
- TypeORM
- SQLite database
- TypeScript

## Database Schema

The database schema is fully documented in [FreightFlow_Database_Schema.md](./FreightFlow_Database_Schema.md). The system uses:

- SQLite with TypeORM
- Entity-relationship model with proper constraints
- Four main entities: Clients, Suppliers, Vehicles, and Trips

## Getting Started

### Prerequisites

- Node.js & npm installed - [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating)
- Bun package manager (optional)

### Running the Frontend

```sh
# Install dependencies
npm install
# or with Bun
bun install

# Start the development server
npm run dev
# or with Bun
bun run dev
```

### Running the Backend

```sh
# Navigate to the backend directory
cd backend/api

# Install dependencies
npm install

# Start the backend in development mode
npm run start:dev
```

## Development

The application follows a modular structure:

- `/src/components` - Reusable UI components
- `/src/pages` - Main application pages
- `/src/trips`, `/src/clients`, etc. - Feature-specific modules
- `/backend/api/src` - API endpoints and business logic

## Docker Support

The backend includes Docker configuration. To run with Docker:

```sh
cd backend
docker-compose up -d
```

## Database

The SQLite database is located at `/backend/api/freight_flow.sqlite`. This file is git-ignored.

For database schema details, see [FreightFlow_Database_Schema.md](./FreightFlow_Database_Schema.md).

## Contributing

1. Create a new branch for your feature
2. Make your changes
3. Submit a pull request

Please ensure all code follows the established patterns and passes linting.

## License

Proprietary - All rights reserved.
#   a d m i n  
 