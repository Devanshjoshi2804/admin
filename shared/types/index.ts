// Shared TypeScript type definitions for Freight Flow Booking System

export interface User {
  id: string;
  email: string;
  name: string;
  phone?: string;
  role: 'customer' | 'driver' | 'admin';
  createdAt: Date;
  updatedAt: Date;
}

export interface Location {
  lat: number;
  lng: number;
  address: string;
  city?: string;
  state?: string;
  country?: string;
  zipCode?: string;
}

export interface Booking {
  id: string;
  userId: string;
  pickupLocation: Location;
  deliveryLocation: Location;
  status: BookingStatus;
  freight: FreightDetails;
  estimatedCost: number;
  actualCost?: number;
  estimatedDeliveryTime: Date;
  actualDeliveryTime?: Date;
  driverId?: string;
  vehicleId?: string;
  createdAt: Date;
  updatedAt: Date;
}

export type BookingStatus = 
  | 'pending'
  | 'confirmed'
  | 'assigned'
  | 'picked_up'
  | 'in_transit'
  | 'delivered'
  | 'cancelled';

export interface FreightDetails {
  weight: number;
  dimensions: {
    length: number;
    width: number;
    height: number;
  };
  type: FreightType;
  description?: string;
  specialInstructions?: string;
}

export type FreightType = 
  | 'general'
  | 'fragile'
  | 'hazardous'
  | 'perishable'
  | 'oversized';

export interface Vehicle {
  id: string;
  licensePlate: string;
  type: VehicleType;
  capacity: {
    weight: number;
    volume: number;
  };
  driverId?: string;
  currentLocation?: Location;
  status: VehicleStatus;
  createdAt: Date;
  updatedAt: Date;
}

export type VehicleType = 
  | 'van'
  | 'truck'
  | 'semi_truck'
  | 'container_truck';

export type VehicleStatus = 
  | 'available'
  | 'assigned'
  | 'in_transit'
  | 'maintenance'
  | 'offline';

export interface Route {
  id: string;
  bookingId: string;
  vehicleId: string;
  driverId: string;
  waypoints: Location[];
  estimatedDistance: number;
  estimatedDuration: number;
  actualDistance?: number;
  actualDuration?: number;
  status: RouteStatus;
  createdAt: Date;
  updatedAt: Date;
}

export type RouteStatus = 
  | 'planned'
  | 'active'
  | 'completed'
  | 'cancelled';

export interface TrackingData {
  id: string;
  bookingId: string;
  vehicleId: string;
  location: Location;
  timestamp: Date;
  speed?: number;
  heading?: number;
}

export interface Message {
  id: string;
  senderId: string;
  receiverId: string;
  bookingId?: string;
  content: string;
  type: MessageType;
  timestamp: Date;
  read: boolean;
}

export type MessageType = 
  | 'text'
  | 'image'
  | 'location'
  | 'system';

export interface Notification {
  id: string;
  userId: string;
  title: string;
  message: string;
  type: NotificationType;
  data?: any;
  read: boolean;
  createdAt: Date;
}

export type NotificationType = 
  | 'booking_update'
  | 'delivery_update'
  | 'message'
  | 'system'
  | 'promotion';

// API Response types
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
}

export interface PaginatedResponse<T = any> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// WebSocket event types
export interface WebSocketEvent {
  type: string;
  data: any;
  timestamp: Date;
}

export interface LocationUpdateEvent extends WebSocketEvent {
  type: 'location_update';
  data: {
    bookingId: string;
    vehicleId: string;
    location: Location;
  };
}

export interface BookingUpdateEvent extends WebSocketEvent {
  type: 'booking_update';
  data: {
    bookingId: string;
    status: BookingStatus;
    message?: string;
  };
}

export interface MessageEvent extends WebSocketEvent {
  type: 'message';
  data: Message;
} 