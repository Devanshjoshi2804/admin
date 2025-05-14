// Simple event bus for application-wide events
type EventHandler = (...args: any[]) => void;

interface EventBus {
  [key: string]: EventHandler[];
}

const eventBus: EventBus = {};

// Higher priority events will get executed first
const PRIORITY_EVENTS = [
  'payment_status_changed', 
  'trip_status_changed'
];

export const events = {
  // Register an event handler
  on(event: string, callback: EventHandler) {
    if (!eventBus[event]) {
      eventBus[event] = [];
    }
    eventBus[event].push(callback);
    
    // Log registration for important events
    if (PRIORITY_EVENTS.includes(event)) {
      console.log(`🔔 Registered handler for priority event: ${event}`);
    }
  },

  // Unregister an event handler
  off(event: string, callback: EventHandler) {
    if (!eventBus[event]) return;
    
    const initialCount = eventBus[event].length;
    eventBus[event] = eventBus[event].filter(cb => cb !== callback);
    
    // Log removal for important events
    if (PRIORITY_EVENTS.includes(event) && eventBus[event].length < initialCount) {
      console.log(`🔕 Removed handler for priority event: ${event}, remaining: ${eventBus[event].length}`);
    }
  },

  // Trigger an event
  emit(event: string, ...args: any[]) {
    if (!eventBus[event]) return;
    
    // Log emissions for important events
    if (PRIORITY_EVENTS.includes(event)) {
      console.log(`📢 Emitting priority event: ${event}`, args[0] || {});
    }
    
    eventBus[event].forEach(callback => {
      try {
        callback(...args);
      } catch (error) {
        console.error(`Error in event handler for ${event}:`, error);
      }
    });
  }
};

// Event constants
export const EVENT_TYPES = {
  PAYMENT_STATUS_CHANGED: 'payment_status_changed',
  TRIP_STATUS_CHANGED: 'trip_status_changed',
  REFRESH_REQUIRED: 'refresh_required',
  FORCE_REFRESH_REQUIRED: 'force_refresh_required'
}; 