import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

/**
 * Ensures that trip status and payment statuses are consistent
 * 
 * Payment status → Trip status rules:
 * 1. If advance payment is "Paid" and trip status is "Booked" → update to "In Transit"
 * 2. If balance payment is "Paid" and trip status is "In Transit" or "Delivered" → update to "Completed"
 * 
 * @param trip The trip object to synchronize
 * @returns A new trip object with synchronized statuses
 */
export function synchronizeStatuses(trip: any) {
  const synchronized = { ...trip };
  
  // Ensure payment statuses are preserved and not reset
  if (!synchronized.advancePaymentStatus) {
    synchronized.advancePaymentStatus = "Not Started";
  }
  
  if (!synchronized.balancePaymentStatus) {
    synchronized.balancePaymentStatus = "Not Started";
  }
  
  // Rule 1: If advance is paid and trip is still in Booked status
  if (synchronized.advancePaymentStatus === "Paid" && synchronized.status === "Booked") {
    synchronized.status = "In Transit";
    console.log(`Synchronized trip ${trip.orderNumber} status: Booked → In Transit (advance paid)`);
  }
  
  // Rule 2: If balance is paid and trip is in In Transit or Delivered
  if (synchronized.balancePaymentStatus === "Paid" && 
     (synchronized.status === "In Transit" || synchronized.status === "Delivered")) {
    synchronized.status = "Completed";
    console.log(`Synchronized trip ${trip.orderNumber} status: ${trip.status} → Completed (balance paid)`);
  }
  
  return synchronized;
}
