// Shared constants for Freight Flow Booking System

export const API_ENDPOINTS = {
  AUTH: '/api/v1/auth',
  USERS: '/api/v1/users',
  BOOKINGS: '/api/v1/bookings',
  ROUTES: '/api/v1/routes',
  VEHICLES: '/api/v1/vehicles',
  TRACKING: '/api/v1/tracking',
  MESSAGES: '/api/v1/messages',
  NOTIFICATIONS: '/api/v1/notifications',
} as const;

export const WEBSOCKET_EVENTS = {
  CONNECTION: 'connection',
  DISCONNECT: 'disconnect',
  LOCATION_UPDATE: 'location_update',
  BOOKING_UPDATE: 'booking_update',
  MESSAGE: 'message',
  NOTIFICATION: 'notification',
  JOIN_ROOM: 'join_room',
  LEAVE_ROOM: 'leave_room',
} as const;

export const BOOKING_STATUSES = {
  PENDING: 'pending',
  CONFIRMED: 'confirmed',
  ASSIGNED: 'assigned',
  PICKED_UP: 'picked_up',
  IN_TRANSIT: 'in_transit',
  DELIVERED: 'delivered',
  CANCELLED: 'cancelled',
} as const;

export const USER_ROLES = {
  CUSTOMER: 'customer',
  DRIVER: 'driver',
  ADMIN: 'admin',
} as const;

export const VEHICLE_TYPES = {
  VAN: 'van',
  TRUCK: 'truck',
  SEMI_TRUCK: 'semi_truck',
  CONTAINER_TRUCK: 'container_truck',
} as const;

export const FREIGHT_TYPES = {
  GENERAL: 'general',
  FRAGILE: 'fragile',
  HAZARDOUS: 'hazardous',
  PERISHABLE: 'perishable',
  OVERSIZED: 'oversized',
} as const;

export const MESSAGE_TYPES = {
  TEXT: 'text',
  IMAGE: 'image',
  LOCATION: 'location',
  SYSTEM: 'system',
} as const;

export const NOTIFICATION_TYPES = {
  BOOKING_UPDATE: 'booking_update',
  DELIVERY_UPDATE: 'delivery_update',
  MESSAGE: 'message',
  SYSTEM: 'system',
  PROMOTION: 'promotion',
} as const;

export const HTTP_STATUS_CODES = {
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  INTERNAL_SERVER_ERROR: 500,
} as const;

export const PAGINATION = {
  DEFAULT_PAGE: 1,
  DEFAULT_LIMIT: 10,
  MAX_LIMIT: 100,
} as const;

export const VALIDATION = {
  MIN_PASSWORD_LENGTH: 8,
  MAX_NAME_LENGTH: 100,
  MAX_ADDRESS_LENGTH: 255,
  MAX_DESCRIPTION_LENGTH: 500,
} as const;

export const TRACKING = {
  UPDATE_INTERVAL: 30000, // 30 seconds
  MAX_SPEED: 120, // km/h
  GEOFENCE_RADIUS: 100, // meters
} as const; 