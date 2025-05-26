// Shared utility functions for Freight Flow Booking System

import { Location } from '../types';

/**
 * Calculate distance between two locations using Haversine formula
 * @param loc1 First location
 * @param loc2 Second location
 * @returns Distance in kilometers
 */
export function calculateDistance(loc1: Location, loc2: Location): number {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRadians(loc2.lat - loc1.lat);
  const dLng = toRadians(loc2.lng - loc1.lng);
  
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(loc1.lat)) * Math.cos(toRadians(loc2.lat)) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Convert degrees to radians
 */
function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}

/**
 * Format currency amount
 * @param amount Amount in cents
 * @param currency Currency code (default: USD)
 * @returns Formatted currency string
 */
export function formatCurrency(amount: number, currency: string = 'USD'): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
  }).format(amount / 100);
}

/**
 * Format date to readable string
 * @param date Date object or ISO string
 * @returns Formatted date string
 */
export function formatDate(date: Date | string): string {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(dateObj);
}

/**
 * Generate unique ID
 * @returns Unique identifier string
 */
export function generateId(): string {
  return Math.random().toString(36).substr(2, 9) + Date.now().toString(36);
}

/**
 * Validate email format
 * @param email Email string to validate
 * @returns True if valid email format
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Validate phone number format
 * @param phone Phone number string to validate
 * @returns True if valid phone format
 */
export function isValidPhone(phone: string): boolean {
  const phoneRegex = /^\+?[\d\s\-\(\)]{10,}$/;
  return phoneRegex.test(phone);
}

/**
 * Debounce function calls
 * @param func Function to debounce
 * @param wait Wait time in milliseconds
 * @returns Debounced function
 */
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: ReturnType<typeof setTimeout>;
  return (...args: Parameters<T>) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
}

/**
 * Throttle function calls
 * @param func Function to throttle
 * @param limit Time limit in milliseconds
 * @returns Throttled function
 */
export function throttle<T extends (...args: any[]) => any>(
  func: T,
  limit: number
): (...args: Parameters<T>) => void {
  let inThrottle: boolean;
  return (...args: Parameters<T>) => {
    if (!inThrottle) {
      func(...args);
      inThrottle = true;
      setTimeout(() => (inThrottle = false), limit);
    }
  };
}

/**
 * Deep clone an object
 * @param obj Object to clone
 * @returns Deep cloned object
 */
export function deepClone<T>(obj: T): T {
  if (obj === null || typeof obj !== 'object') return obj;
  if (obj instanceof Date) return new Date(obj.getTime()) as any;
  if (obj instanceof Array) return obj.map(item => deepClone(item)) as any;
  if (typeof obj === 'object') {
    const clonedObj = {} as any;
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        clonedObj[key] = deepClone(obj[key]);
      }
    }
    return clonedObj;
  }
  return obj;
}

/**
 * Calculate estimated delivery time based on distance
 * @param distance Distance in kilometers
 * @param averageSpeed Average speed in km/h (default: 60)
 * @returns Estimated delivery time in hours
 */
export function calculateEstimatedDeliveryTime(
  distance: number,
  averageSpeed: number = 60
): number {
  return distance / averageSpeed;
}

/**
 * Format weight to readable string
 * @param weight Weight in kilograms
 * @returns Formatted weight string
 */
export function formatWeight(weight: number): string {
  if (weight >= 1000) {
    return `${(weight / 1000).toFixed(1)} tons`;
  }
  return `${weight} kg`;
}

/**
 * Format dimensions to readable string
 * @param dimensions Object with length, width, height in cm
 * @returns Formatted dimensions string
 */
export function formatDimensions(dimensions: {
  length: number;
  width: number;
  height: number;
}): string {
  return `${dimensions.length} × ${dimensions.width} × ${dimensions.height} cm`;
}

/**
 * Check if location is within geofence
 * @param location Current location
 * @param center Geofence center
 * @param radius Radius in meters
 * @returns True if within geofence
 */
export function isWithinGeofence(
  location: Location,
  center: Location,
  radius: number
): boolean {
  const distance = calculateDistance(location, center) * 1000; // Convert to meters
  return distance <= radius;
} 