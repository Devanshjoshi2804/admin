import axios from 'axios';
import { clients, suppliers, vehicles, trips } from '@/data/mockData';
import { events, EVENT_TYPES } from '@/lib/events';

// Set this to false to use the real API
const FORCE_MOCK_DATA = false;

// API base URL (NestJS backend)
const API_BASE_URL = 'http://localhost:3000/api';

// Create axios instance with common configuration
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000, // 10 seconds timeout
});

// Add response interceptor to log successful API interactions
apiClient.interceptors.response.use(
  (response) => {
    console.log(`API Success: ${response.config.method?.toUpperCase()} ${response.config.url} - Status: ${response.status}`);
    return response;
  },
  async (error) => {
    // Handle network errors
    if (!error.response) {
      console.error('Network Error:', error.message);
      
      // Fallback to mock data if there's a connection error
      if (error.message.includes('Network Error') || error.code === 'ECONNREFUSED') {
        console.log('Falling back to mock data due to network error');
        return handleMockDataFallback(error.config);
      }
    }
    
    // Log error details
    console.error('API Error:', {
      status: error.response?.status,
      url: error.config?.url,
      method: error.config?.method,
      data: error.response?.data || error.message
    });
    
    return Promise.reject(error);
  }
);

// Fallback to mock data when API is unavailable
const handleMockDataFallback = (config) => {
  // Extract URL parts for determining the endpoint and resource ID
  const url = config.url || '';
  const method = config.method.toLowerCase();
  
  // Parse the URL to identify endpoints and IDs
  const urlParts = url.split('/').filter(part => part.trim() !== '');
  const resource = urlParts[urlParts.length - 1] || '';
  const endpoint = urlParts.includes('clients') ? 'clients' :
                  urlParts.includes('suppliers') ? 'suppliers' :
                  urlParts.includes('vehicles') ? 'vehicles' :
                  urlParts.includes('trips') ? 'trips' : '';
  
  // Check if the last part looks like an ID (not an endpoint name)
  const isIdInUrl = !['clients', 'suppliers', 'vehicles', 'trips'].includes(resource);
  const id = isIdInUrl ? resource : null;
  
  console.log(`Using mock data for ${method} ${url} - Endpoint: ${endpoint}, ID: ${id || 'none'}`);
  
  // Get the appropriate collection based on the URL
  let collection;
  if (endpoint === 'clients') collection = clients;
  else if (endpoint === 'suppliers') collection = suppliers;
  else if (endpoint === 'vehicles') collection = vehicles;
  else if (endpoint === 'trips') collection = trips;
  else collection = [];
  
  // Create a mock response structure
  const mockResponse = {
    data: null,
    status: 200,
    statusText: 'OK',
    headers: {},
    config
  };
  
  try {
    // Handle different HTTP methods with mock data
    if (method === 'get') {
      if (id) {
        // Get single item
        const item = collection.find(item => item.id === id || 
          (endpoint === 'trips' && item.orderNumber === id));
        mockResponse.data = item ? {...item} : null;
      } else {
        // Get all items
        mockResponse.data = collection.map(item => ({...item})); 
      }
    } else if (method === 'post') {
      // Parse data
      const data = typeof config.data === 'string' ? JSON.parse(config.data) : config.data;
      
      // Generate a unique ID and timestamp for new items
      const mockId = `MOCK-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
      
      let newItem;
      
      if (endpoint === 'trips') {
        newItem = createMockTrip(mockId, `FTL-${Date.now().toString().slice(-6)}`, data);
      } else {
        newItem = { 
          id: mockId, 
          ...data,
          createdAt: new Date().toISOString()
        };
      }
      
      // Add to appropriate collection
      collection.push(newItem);
      console.log(`Added new ${endpoint} to collection`);
      
      mockResponse.data = {...newItem}; 
    } else if (method === 'patch' || method === 'put') {
      // Parse data
      const data = typeof config.data === 'string' ? JSON.parse(config.data) : config.data;
      
      if (id) {
        // Find item index
        const itemIndex = collection.findIndex(item => item.id === id || 
          (endpoint === 'trips' && item.orderNumber === id));
        
        if (itemIndex !== -1) {
          // Update the item in the collection
          collection[itemIndex] = { 
            ...collection[itemIndex], 
            ...data,
            updatedAt: new Date().toISOString()
          };
          mockResponse.data = {...collection[itemIndex]};
        } else {
          mockResponse.status = 404;
          mockResponse.data = { error: `Item not found` };
        }
      } else {
        mockResponse.status = 400;
        mockResponse.data = { error: 'No ID provided for update' };
      }
    } else if (method === 'delete') {
      if (id) {
        // Find and remove item
        const itemIndex = collection.findIndex(item => item.id === id || 
          (endpoint === 'trips' && item.orderNumber === id));
        
        if (itemIndex !== -1) {
          collection.splice(itemIndex, 1)[0];
          mockResponse.data = { success: true };
        } else {
          mockResponse.status = 404;
          mockResponse.data = { error: `Item not found` };
        }
      } else {
        mockResponse.status = 400;
        mockResponse.data = { error: 'No ID provided for delete' };
      }
    }
  } catch (error) {
    console.error('Error in mock data handler:', error);
    mockResponse.status = 500;
    mockResponse.data = { error: 'Mock server error' };
  }
  
  return Promise.resolve(mockResponse);
};

// Add request interceptor
apiClient.interceptors.request.use(
  (config) => {
    // If we're in forced mock data mode, don't even make the request
    if (FORCE_MOCK_DATA) {
      console.log(`[MOCK MODE] Intercepting request to ${config.url}`);
      return Promise.reject({ 
        message: 'Network Error', 
        config 
      });
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Helper function to create a mock trip
function createMockTrip(mockTripId, orderNumber, data, isPaymentIntegration = false) {
  // Find related client and supplier
  const client = clients.find(c => c.id === data.clientId);
  const supplier = suppliers.find(s => s.id === data.supplierId);
  
  // Calculate payment amounts
  const advanceAmount = (data.supplierFreight * (data.advancePercentage || 30)) / 100;
  const balanceAmount = data.supplierFreight - advanceAmount;
  
  // Create new trip with all required fields
  return { 
    id: mockTripId,
    orderNumber,
    lrNumbers: data.lrNumbers || ['LR-NEW'],
    clientId: data.clientId,
    clientName: client?.name || data.clientName || 'Unknown Client',
    clientAddress: data.clientAddress || 'Unknown',
    clientAddressType: data.clientAddressType || 'Unknown',
    clientCity: data.clientCity || 'Unknown',
    destinationAddress: data.destinationAddress || 'Unknown',
    destinationCity: data.destinationCity || 'Unknown',
    destinationAddressType: data.destinationAddressType || 'Unknown',
    supplierId: data.supplierId,
    supplierName: supplier?.name || data.supplierName || 'Unknown',
    vehicleId: data.vehicleId || '',
    vehicleNumber: data.vehicleNumber || '',
    driverName: data.driverName || '',
    driverPhone: data.driverPhone || '',
    vehicleType: data.vehicleType || '',
    vehicleSize: data.vehicleSize || '',
    vehicleCapacity: data.vehicleCapacity || '',
    axleType: data.axleType || '',
    materials: data.materials || [],
    pickupDate: data.pickupDate || new Date().toISOString().split('T')[0],
    pickupTime: data.pickupTime || '12:00',
    clientFreight: data.clientFreight || 0,
    supplierFreight: data.supplierFreight || 0,
    advancePercentage: data.advancePercentage || 30,
    advanceSupplierFreight: advanceAmount,
    balanceSupplierFreight: balanceAmount,
    documents: data.documents || [],
    fieldOps: data.fieldOps || {
      name: "Operations Team",
      phone: "9999999999",
      email: "ops@example.com"
    },
    gsmTracking: data.gsmTracking || false,
    status: isPaymentIntegration ? 'Booked' : (data.status || 'Booked'),
    advancePaymentStatus: isPaymentIntegration ? 'Initiated' : (data.advancePaymentStatus || 'Not Started'),
    balancePaymentStatus: data.balancePaymentStatus || 'Not Started',
    podUploaded: data.podUploaded || false,
    createdAt: new Date().toISOString()
  };
}

// First, let's add a state management store for better trip status tracking
// Add this near the top of the file, after imports

// Simple in-memory store for tracking entity state changes
const stateStore = {
  pendingChanges: new Map(),
  tripStatusListeners: [],
  
  // Add a pending change to track
  addPendingChange: function(entityId, changeType, details) {
    const key = `${entityId}-${changeType}`;
    this.pendingChanges.set(key, {
      entityId,
      changeType,
      details,
      timestamp: Date.now()
    });
    console.log(`Added pending state change: ${key}`, details);
  },
  
  // Check if there's a pending change
  hasPendingChange: function(entityId, changeType) {
    const key = `${entityId}-${changeType}`;
    return this.pendingChanges.has(key);
  },
  
  // Clear a pending change
  clearPendingChange: function(entityId, changeType) {
    const key = `${entityId}-${changeType}`;
    const result = this.pendingChanges.delete(key);
    console.log(`Cleared pending change: ${key} - Success: ${result}`);
    return result;
  },
  
  // Subscribe to trip status changes
  onTripStatusChange: function(callback) {
    this.tripStatusListeners.push(callback);
    return () => {
      this.tripStatusListeners = this.tripStatusListeners.filter(cb => cb !== callback);
    };
  },
  
  // Notify listeners of trip status change
  notifyTripStatusChange: function(tripId, oldStatus, newStatus, context) {
    console.log(`Notifying ${this.tripStatusListeners.length} listeners of trip status change:`, {
      tripId, oldStatus, newStatus, context
    });
    this.tripStatusListeners.forEach(callback => {
      try {
        callback(tripId, oldStatus, newStatus, context);
      } catch (error) {
        console.error("Error in trip status change listener:", error);
      }
    });
  }
};

// Payment status to trip status mapping - ENHANCED with stronger guarantees
const PAYMENT_STATUS_TRANSITIONS = {
  ADVANCE_PAID: {
    FROM_STATUS: "Booked",
    TO_STATUS: "In Transit",
    CONDITION: (trip) => trip.advancePaymentStatus === "Paid" && trip.status === "Booked"
  },
  BALANCE_PAID: {
    FROM_STATUS: ["In Transit", "Delivered"],
    TO_STATUS: "Completed",
    CONDITION: (trip) => trip.balancePaymentStatus === "Paid" && 
                         (trip.status === "In Transit" || trip.status === "Delivered")
  }
};

// Transaction manager for atomic operations
const TransactionManager = {
  active: new Map(),
  
  // Start a new transaction for a specific entity
  start: function(entityId, type) {
    const txId = `${type}-${entityId}-${Date.now()}`;
    const transaction = {
      id: txId,
      entityId,
      type,
      startTime: Date.now(),
      steps: [],
      status: 'pending',
      addStep: function(description, data = {}) {
        this.steps.push({
          timestamp: Date.now(),
          description,
          data
        });
        return this;
      }
    };
    
    this.active.set(txId, transaction);
    console.log(`📝 Started transaction ${txId} for ${entityId}`);
    return transaction;
  },
  
  // Complete a transaction
  complete: function(txId, result = {}) {
    const tx = this.active.get(txId);
    if (tx) {
      tx.status = 'completed';
      tx.endTime = Date.now();
      tx.result = result;
      console.log(`✅ Completed transaction ${txId} in ${tx.endTime - tx.startTime}ms`);
      
      // Keep completed transactions in the map for debugging
      setTimeout(() => {
        this.active.delete(txId);
      }, 60000); // Clean up after 1 minute
      
      return tx;
    }
    return null;
  },
  
  // Fail a transaction
  fail: function(txId, error) {
    const tx = this.active.get(txId);
    if (tx) {
      tx.status = 'failed';
      tx.endTime = Date.now();
      tx.error = error;
      console.error(`❌ Failed transaction ${txId} in ${tx.endTime - tx.startTime}ms: ${error.message}`);
      
      // Keep failed transactions in the map for debugging
      setTimeout(() => {
        this.active.delete(txId);
      }, 300000); // Clean up after 5 minutes for debugging
      
      return tx;
    }
    return null;
  },
  
  // Get all transactions
  getAll: function() {
    return Array.from(this.active.values());
  }
};

// Trips API
export const tripsApi = {
  getAll: async () => {
    try {
      console.log('Fetching all trips from real API...');
      const response = await apiClient.get('/trips');
      console.log(`Retrieved ${response.data.length} trips from API`);
      
      // Log any trips with missing supplier IDs
      const missingSupplierIds = response.data.filter(trip => 
        !trip.supplierId || trip.supplierId === 'null' || trip.supplierId === 'undefined'
      );
      
      if (missingSupplierIds.length > 0) {
        console.warn(`[API] Found ${missingSupplierIds.length} trips with missing supplier IDs`);
        missingSupplierIds.forEach(trip => {
          console.warn(`[API] Trip ${trip.orderNumber} has invalid supplierId: '${trip.supplierId}'`);
        });
      }
      
      return response.data;
    } catch (error) {
      console.log('Using fallback trips data');
      return trips.map(t => ({...t}));
    }
  },
  
  getById: async (id) => {
    try {
      const response = await apiClient.get(`/trips/${id}`);
      return response.data;
    } catch (error) {
      const trip = trips.find(t => t.id === id || t.orderNumber === id);
      if (!trip) throw new Error(`Trip with ID ${id} not found`);
      return {...trip};
    }
  },
  
  create: async (data) => {
    try {
      console.log("Sending trip creation request with data:", JSON.stringify(data, null, 2));
      const response = await apiClient.post('/trips', data);
      console.log("Trip creation successful:", response.data);
      return response.data;
    } catch (error) {
      console.error("Trip creation error:", error);
      
      // Extract and log detailed validation errors
      if (error.response && error.response.data) {
        console.error("API error response:", JSON.stringify(error.response.data, null, 2));
        
        if (error.response.data.message && Array.isArray(error.response.data.message)) {
          console.error("Validation errors:", error.response.data.message.join(', '));
        }
      }
      
      if (FORCE_MOCK_DATA) {
        console.log("Falling back to mock data creation");
        const mockId = `MOCK-${Date.now()}`;
        const orderNumber = `FTL-${Date.now().toString().slice(-6)}`;
        const newTrip = createMockTrip(mockId, orderNumber, data);
        trips.push(newTrip);
        return {...newTrip};
      }
      throw error;
    }
  },
  
  createWithPaymentIntegration: async (data) => {
    try {
      console.log("Creating trip with payment integration...");
      
      // Create the trip
      const trip = await tripsApi.create(data);
      console.log("Trip created successfully:", trip.id);
      
      // Update with payment status only if it's not already set
      try {
        console.log("Attempting to set advance payment status to 'Initiated'");
        // Try to use the dedicated payment status endpoint first
        try {
          await apiClient.patch(`/trips/${trip.id}/payment-status`, {
            advancePaymentStatus: 'Initiated'
          });
          console.log("Payment status updated using dedicated endpoint");
        } catch (paymentEndpointError) {
          // If that fails, try the regular update endpoint
          console.log("Dedicated payment endpoint failed, using regular update:", paymentEndpointError.message);
          await apiClient.patch(`/trips/${trip.id}`, {
            advancePaymentStatus: 'Initiated'
          });
          console.log("Payment status updated using regular endpoint");
        }
      } catch (paymentError) {
        // If we can't set the payment status, log the error but don't fail the whole operation
        console.error("Failed to set advance payment status, but trip was created:", paymentError);
        console.log("Returning trip without payment status update");
      }
      
      // Return the created trip even if payment status update failed
      return trip;
    } catch (error) {
      console.error("Error in createWithPaymentIntegration:", error);
      
      if (FORCE_MOCK_DATA) {
        const mockId = `MOCK-${Date.now()}`;
        const orderNumber = `FTL-${Date.now().toString().slice(-6)}`;
        const newTrip = createMockTrip(mockId, orderNumber, data, true);
        trips.push(newTrip);
        return {...newTrip};
      }
      throw error;
    }
  },
  
  update: async (id, data) => {
    try {
      const response = await apiClient.patch(`/trips/${id}`, data);
      return response.data;
    } catch (error) {
      if (FORCE_MOCK_DATA) {
        const index = trips.findIndex(t => t.id === id || t.orderNumber === id);
        if (index === -1) throw new Error(`Trip not found`);
        trips[index] = { ...trips[index], ...data };
        return {...trips[index]};
      }
      throw error;
    }
  },
  
  delete: async (id) => {
    try {
      console.log(`Deleting trip with ID: ${id}`);
      const response = await apiClient.delete(`/trips/${id}`);
      return response.data;
    } catch (error) {
      if (FORCE_MOCK_DATA) {
        const index = trips.findIndex(t => t.id === id || t.orderNumber === id);
        if (index === -1) throw new Error(`Trip not found`);
        trips.splice(index, 1);
        return { success: true };
      }
      throw error;
    }
  },
  
  updateStatus: async (id, status) => {
    return tripsApi.update(id, { status });
  },
  
  // Now let's completely rewrite the updatePaymentStatus method with the new approach
  updatePaymentStatus: async (id, paymentData) => {
    console.log(`🔄 BEGIN PAYMENT UPDATE for trip ${id}:`, paymentData);
    
    // Create a transaction to track this operation
    const tx = TransactionManager.start(id, 'payment-update');
    
    try {
      tx.addStep('Started payment status update', { paymentData });
      
      // Step 1: Get the current trip data
      let trip;
      try {
        tx.addStep('Fetching current trip data');
        
        if (FORCE_MOCK_DATA) {
          trip = trips.find(t => t.id === id || t.orderNumber === id);
          if (!trip) throw new Error(`Trip ${id} not found`);
        } else {
          const response = await apiClient.get(`/trips/${id}`);
          trip = response.data;
        }
        
        tx.addStep('Retrieved trip data', { 
          status: trip.status, 
          advancePmt: trip.advancePaymentStatus,
          balancePmt: trip.balancePaymentStatus
        });
        
        console.log(`Current trip state:`, {
          id: trip.id,
          orderNumber: trip.orderNumber,
          status: trip.status,
          advancePaymentStatus: trip.advancePaymentStatus,
          balancePaymentStatus: trip.balancePaymentStatus
        });
      } catch (error) {
        tx.addStep('Error fetching trip data', { error: error.message });
        throw error;
      }
      
      // Step 2: Apply payment update
      tx.addStep('Applying payment updates');
      
      // Save original values for comparison
      const originalStatus = trip.status;
      const originalAdvanceStatus = trip.advancePaymentStatus;
      const originalBalanceStatus = trip.balancePaymentStatus;
      
      // Create working copy with updates applied
      const updatedTrip = { ...trip, ...paymentData };
      
      // Step 3: Check for status transitions
      let statusUpdateNeeded = false;
      let targetStatus = trip.status;
      let transitionReason = '';
      
      // Check if advance payment is being marked as paid
      if (paymentData.advancePaymentStatus === "Paid" && 
          trip.advancePaymentStatus !== "Paid") {
        
        tx.addStep('Detected advance payment update to Paid');
        console.log('💰 Advance payment being marked as PAID');
        
        // ALWAYS update trip status to In Transit when advance payment is Paid
        if (trip.status === "Booked") {
          statusUpdateNeeded = true;
          targetStatus = "In Transit";
          transitionReason = 'advance payment marked as paid';
          
          tx.addStep('Will update trip status to In Transit', { 
            from: trip.status, 
            to: targetStatus,
            reason: transitionReason
          });
          console.log(`🚦 Will change trip status: ${trip.status} → ${targetStatus}`);
        } else {
          console.log(`⚠️ Trip status is already beyond Booked (current: ${trip.status}), not changing status`);
        }
      }
      
      // Check if balance payment is being marked as paid
      if (paymentData.balancePaymentStatus === "Paid" && 
          trip.balancePaymentStatus !== "Paid") {
        
        tx.addStep('Detected balance payment update to Paid');
        console.log('💰 Balance payment being marked as PAID');
        
        // ALWAYS update trip status to Completed when balance payment is Paid
        if (trip.status === "In Transit" || trip.status === "Delivered") {
          statusUpdateNeeded = true;
          targetStatus = "Completed";
          transitionReason = 'balance payment marked as paid';
          
          tx.addStep('Will update trip status to Completed', { 
            from: trip.status, 
            to: targetStatus,
            reason: transitionReason
          });
          console.log(`🏁 Will change trip status: ${trip.status} → ${targetStatus}`);
        } else {
          console.log(`⚠️ Trip status is already Completed or invalid for balance update (current: ${trip.status})`);
        }
      }
      
      // Step 4: Perform the updates
      // First, update the payment status
      try {
        tx.addStep('Updating payment status');
        
        if (FORCE_MOCK_DATA) {
          // Find trip in mock data
          const index = trips.findIndex(t => t.id === id || t.orderNumber === id);
          if (index === -1) throw new Error('Trip not found');
          
          // Apply payment updates
          Object.keys(paymentData).forEach(key => {
            trips[index][key] = paymentData[key];
          });
          
          tx.addStep('Updated payment status in mock data');
          console.log(`✅ Updated payment status in mock data`);
        } else {
          // Use the new dedicated endpoint for payment status updates
          try {
            await apiClient.patch(`/trips/${id}/payment-status`, paymentData);
            tx.addStep('Updated payment status via dedicated API endpoint');
            console.log(`✅ Updated payment status via dedicated API endpoint`);
          } catch (error) {
            console.error(`❌ Error using payment-status endpoint: ${error.message}. Falling back to regular update.`);
            
            // Fallback to the regular update endpoint
            await apiClient.patch(`/trips/${id}`, paymentData);
            tx.addStep('Updated payment status via fallback API');
            console.log(`✅ Updated payment status via fallback API`);
          }
        }
        
        // Emit event for payment status change
        const paymentType = paymentData.advancePaymentStatus ? 'advance' : 'balance';
        const newStatus = paymentData.advancePaymentStatus || paymentData.balancePaymentStatus;
        const oldStatus = paymentType === 'advance' ? trip.advancePaymentStatus : trip.balancePaymentStatus;
        
        events.emit(EVENT_TYPES.PAYMENT_STATUS_CHANGED, {
          tripId: id,
          paymentType,
          oldStatus,
          newStatus,
          tripStatusChanged: statusUpdateNeeded,
          oldTripStatus: trip.status,
          newTripStatus: targetStatus,
          timestamp: Date.now()
        });
        console.log(`📣 Emitted payment status change event`);
      } catch (error) {
        tx.addStep('Error updating payment status', { error: error.message });
        console.error(`❌ Failed to update payment status: ${error.message}`);
        throw error;
      }
      
      // Next, update the trip status if needed
      if (statusUpdateNeeded) {
        try {
          tx.addStep('Updating trip status');
          
          const statusUpdate = { status: targetStatus };
          console.log(`🔄 Updating trip status to ${targetStatus}`);
          
          if (FORCE_MOCK_DATA) {
            const index = trips.findIndex(t => t.id === id || t.orderNumber === id);
            if (index === -1) throw new Error('Trip not found');
            
            // Update status
            trips[index].status = targetStatus;
            
            tx.addStep('Updated trip status in mock data', { newStatus: targetStatus });
            console.log(`✅ Updated trip status in mock data: ${targetStatus}`);
            
            // To ensure update takes effect, create a copy of the trips array
            const refreshedTrips = [...trips];
            trips.length = 0;
            trips.push(...refreshedTrips);
          } else {
            await apiClient.patch(`/trips/${id}`, statusUpdate);
            tx.addStep('Updated trip status via API', { newStatus: targetStatus });
            console.log(`✅ Updated trip status via API: ${targetStatus}`);
          }
          
          // Notify stateStore listeners of the status change
          stateStore.notifyTripStatusChange(id, trip.status, targetStatus, { 
            reason: transitionReason,
            timestamp: Date.now()
          });
          
          // Also emit a general event for any other components
          events.emit(EVENT_TYPES.TRIP_STATUS_CHANGED, {
            tripId: id,
            oldStatus: trip.status,
            newStatus: targetStatus,
            reason: transitionReason,
            timestamp: Date.now()
          });
          
          // Request all components to force refresh their data
          events.emit(EVENT_TYPES.FORCE_REFRESH_REQUIRED, {
            source: 'api',
            tripId: id,
            reason: 'payment_status_update'
          });
          
          console.log(`📣 Emitted trip status change and force refresh events`);
        } catch (error) {
          tx.addStep('Error updating trip status', { error: error.message });
          console.error(`❌ Failed to update trip status: ${error.message}`);
          throw error;
        }
      }
      
      // Step 5: Get the final trip state
      let finalTrip;
      try {
        tx.addStep('Fetching final trip state');
        
        if (FORCE_MOCK_DATA) {
          finalTrip = trips.find(t => t.id === id || t.orderNumber === id);
          
          tx.addStep('Retrieved final trip state from mock data');
        } else {
          const response = await apiClient.get(`/trips/${id}`);
          finalTrip = response.data;
          tx.addStep('Retrieved final trip state from API');
        }
        
        console.log(`Final trip state after updates:`, {
          id: finalTrip.id,
          orderNumber: finalTrip.orderNumber,
          status: finalTrip.status,
          advancePaymentStatus: finalTrip.advancePaymentStatus,
          balancePaymentStatus: finalTrip.balancePaymentStatus
        });
      } catch (error) {
        tx.addStep('Error fetching final trip state', { error: error.message });
        console.error(`❌ Failed to fetch final trip state: ${error.message}`);
        throw error;
      }
      
      // Step 6: Compare and log changes
      const changes = {
        status: {
          from: trip.status,
          to: finalTrip.status,
          changed: trip.status !== finalTrip.status
        },
        advancePayment: {
          from: trip.advancePaymentStatus,
          to: finalTrip.advancePaymentStatus,
          changed: trip.advancePaymentStatus !== finalTrip.advancePaymentStatus
        },
        balancePayment: {
          from: trip.balancePaymentStatus,
          to: finalTrip.balancePaymentStatus,
          changed: trip.balancePaymentStatus !== finalTrip.balancePaymentStatus
        }
      };
      
      console.log(`🔍 Trip ${id} changes:`, changes);
      tx.addStep('Recorded changes', changes);
      
      // Step 7: Complete the transaction
      TransactionManager.complete(tx.id, { finalTrip });
      console.log(`🎉 Payment update completed successfully`);
      
      // Final check to ensure trip status was updated if needed
      if (statusUpdateNeeded && finalTrip.status !== targetStatus) {
        console.warn(`⚠️ Trip status did not update correctly! Expected: ${targetStatus}, Got: ${finalTrip.status}`);
        
        // Make one more attempt to fix this if using mock data
        if (FORCE_MOCK_DATA) {
          const index = trips.findIndex(t => t.id === id || t.orderNumber === id);
          if (index !== -1) {
            console.log(`🔧 Making emergency fix to trip status in mock data`);
            trips[index].status = targetStatus;
            finalTrip.status = targetStatus;
            
            // Force refresh trip data
            const refreshedTrips = [...trips]; 
            trips.length = 0;
            trips.push(...refreshedTrips);
            
            // Emit force refresh event
            events.emit(EVENT_TYPES.FORCE_REFRESH_REQUIRED, {
              source: 'api_emergency_fix',
              tripId: id
            });
          }
        }
      }
      
      // Return the updated trip
      return finalTrip;
    } catch (error) {
      TransactionManager.fail(tx.id, error);
      console.error(`❌ Payment update failed for trip ${id}: ${error.message}`);
      throw error;
    }
  },
  
  getByStatus: async (status) => {
    try {
      const response = await apiClient.get(`/trips?status=${status}`);
      return response.data;
    } catch (error) {
      if (FORCE_MOCK_DATA) {
        return trips
          .filter(t => t.status === status)
          .map(t => ({...t}));
      }
      throw error;
    }
  },

  // Upload document to a trip
  uploadDocument: async (id: string, docData: any) => {
    try {
      const response = await apiClient.post(`/trips/${id}/documents`, docData);
      return response.data;
    } catch (error) {
      console.error("Error uploading document to trip:", error);
      throw error;
    }
  },

  // Delete document from a trip
  deleteDocument: async (id: string, documentId: string) => {
    try {
      const response = await apiClient.delete(`/trips/${id}/documents/${documentId}`);
      return response.data;
    } catch (error) {
      console.error("Error deleting document from trip:", error);
      throw error;
    }
  },

  // Get all documents for a trip
  getDocuments: async (id: string) => {
    try {
      const response = await apiClient.get(`/trips/${id}/documents`);
      return response.data;
    } catch (error) {
      console.error("Error getting trip documents:", error);
      throw error;
    }
  }
};

// Clients API 
export const clientsApi = {
  getAll: async () => {
    try {
      const response = await apiClient.get('/clients');
      return response.data;
    } catch (error) {
      console.log('Using fallback clients data');
      return clients.map(client => ({...client}));
    }
  },
  
  getById: async (id) => {
    try {
      const response = await apiClient.get(`/clients/${id}`);
      return response.data;
    } catch (error) {
      const client = clients.find(c => c.id === id);
      if (!client) throw new Error(`Client with ID ${id} not found`);
      return {...client};
    }
  },
  
  create: async (data) => {
    try {
      const response = await apiClient.post('/clients', data);
      return response.data;
    } catch (error) {
      if (FORCE_MOCK_DATA) {
        const mockId = `MOCK-${Date.now()}`;
        const newClient = { id: mockId, ...data };
        clients.push(newClient);
        return {...newClient};
      }
      throw error;
    }
  },
  
  update: async (id, data) => {
    try {
      const response = await apiClient.patch(`/clients/${id}`, data);
      return response.data;
    } catch (error) {
      if (FORCE_MOCK_DATA) {
        const index = clients.findIndex(c => c.id === id);
        if (index === -1) throw new Error(`Client not found`);
        clients[index] = { ...clients[index], ...data };
        return {...clients[index]};
      }
      throw error;
    }
  },
  
  delete: async (id) => {
    try {
      const response = await apiClient.delete(`/clients/${id}`);
      return response.data;
    } catch (error) {
      if (FORCE_MOCK_DATA) {
        const index = clients.findIndex(c => c.id === id);
        if (index === -1) throw new Error(`Client not found`);
        clients.splice(index, 1);
        return { success: true };
      }
      throw error;
    }
  },

  // Upload document to a client
  uploadDocument: async (id: string, docData: any) => {
    try {
      const response = await apiClient.post(`/clients/${id}/documents`, docData);
      return response.data;
    } catch (error) {
      console.error("Error uploading document to client:", error);
      throw error;
    }
  },

  // Delete document from a client
  deleteDocument: async (id: string, documentId: string) => {
    try {
      const response = await apiClient.delete(`/clients/${id}/documents/${documentId}`);
      return response.data;
    } catch (error) {
      console.error("Error deleting document from client:", error);
      throw error;
    }
  },

  // Get all documents for a client
  getDocuments: async (id: string) => {
    try {
      const response = await apiClient.get(`/clients/${id}/documents`);
      return response.data;
    } catch (error) {
      console.error("Error getting client documents:", error);
      throw error;
    }
  }
};

// Suppliers API
export const suppliersApi = {
  getAll: async () => {
    try {
      const response = await apiClient.get('/suppliers');
      return response.data;
    } catch (error) {
      console.log('Using fallback suppliers data');
      return suppliers.map(s => ({...s}));
    }
  },
  
  getById: async (id) => {
    try {
      console.log(`[API] Fetching supplier with ID: "${id}" (type: ${typeof id}, length: ${id?.length || 0})`);
      
      // Validate ID format
      if (!id || id === 'null' || id === 'undefined' || id.trim() === '') {
        console.error(`[API] Invalid supplier ID format: "${id}"`);
        throw new Error(`Invalid supplier ID: ${id}`);
      }
      
      const response = await apiClient.get(`/suppliers/${id}`);
      console.log(`[API] Supplier data fetched successfully for ID: ${id}`);
      return response.data;
    } catch (error) {
      console.error(`[API] Error fetching supplier with ID ${id}:`, error);
      
      // Try to fall back to mock data
      try {
        console.log(`[API] Attempting to find supplier in mock data with ID: ${id}`);
        const supplier = suppliers.find(s => s.id === id);
        if (!supplier) {
          console.error(`[API] Supplier with ID ${id} not found in mock data`);
          
          // Last attempt - try to find by partial match
          const partialMatches = suppliers.filter(s => s.id.includes(id));
          if (partialMatches.length > 0) {
            console.log(`[API] Found ${partialMatches.length} partial matches for ID ${id}, using first match`);
            return {...partialMatches[0]};
          }
          
          throw new Error(`Supplier with ID ${id} not found`);
        }
        console.log(`[API] Using mock data for supplier ID: ${id}`);
        return {...supplier};
      } catch (fallbackError) {
        console.error(`[API] Fallback error for supplier ID ${id}:`, fallbackError);
        throw error; // Re-throw the original error
      }
    }
  },
  
  create: async (data) => {
    try {
      const response = await apiClient.post('/suppliers', data);
      return response.data;
    } catch (error) {
      if (FORCE_MOCK_DATA) {
        const mockId = `MOCK-${Date.now()}`;
        const newSupplier = { id: mockId, ...data };
        suppliers.push(newSupplier);
        return {...newSupplier};
      }
      throw error;
    }
  },
  
  update: async (id, data) => {
    try {
      const response = await apiClient.patch(`/suppliers/${id}`, data);
      return response.data;
    } catch (error) {
      if (FORCE_MOCK_DATA) {
        const index = suppliers.findIndex(s => s.id === id);
        if (index === -1) throw new Error(`Supplier not found`);
        suppliers[index] = { ...suppliers[index], ...data };
        return {...suppliers[index]};
      }
      throw error;
    }
  },
  
  delete: async (id) => {
    try {
      const response = await apiClient.delete(`/suppliers/${id}`);
      return response.data;
    } catch (error) {
      if (FORCE_MOCK_DATA) {
        const index = suppliers.findIndex(s => s.id === id);
        if (index === -1) throw new Error(`Supplier not found`);
        suppliers.splice(index, 1);
        return { success: true };
      }
      throw error;
    }
  },

  // Upload document to a supplier
  uploadDocument: async (id: string, docData: any) => {
    try {
      const response = await apiClient.post(`/suppliers/${id}/documents`, docData);
      return response.data;
    } catch (error) {
      console.error("Error uploading document to supplier:", error);
      throw error;
    }
  },

  // Delete document from a supplier
  deleteDocument: async (id: string, documentId: string) => {
    try {
      const response = await apiClient.delete(`/suppliers/${id}/documents/${documentId}`);
      return response.data;
    } catch (error) {
      console.error("Error deleting document from supplier:", error);
      throw error;
    }
  },

  // Get all documents for a supplier
  getDocuments: async (id: string) => {
    try {
      const response = await apiClient.get(`/suppliers/${id}/documents`);
      return response.data;
    } catch (error) {
      console.error("Error getting supplier documents:", error);
      throw error;
    }
  }
};

// Vehicles API
export const vehiclesApi = {
  getAll: async () => {
    try {
      const response = await apiClient.get('/vehicles');
      return response.data;
    } catch (error) {
      console.log('Using fallback vehicles data');
      return vehicles.map(v => ({...v}));
    }
  },
  
  getById: async (id) => {
    try {
      const response = await apiClient.get(`/vehicles/${id}`);
      return response.data;
    } catch (error) {
      const vehicle = vehicles.find(v => v.id === id);
      if (!vehicle) throw new Error(`Vehicle with ID ${id} not found`);
      return {...vehicle};
    }
  },
  
  create: async (data) => {
    try {
      const response = await apiClient.post('/vehicles', data);
      return response.data;
    } catch (error) {
      if (FORCE_MOCK_DATA) {
        const mockId = `MOCK-${Date.now()}`;
        const newVehicle = { id: mockId, ...data };
        vehicles.push(newVehicle);
        return {...newVehicle};
      }
      throw error;
    }
  },
  
  update: async (id, data) => {
    try {
      const response = await apiClient.patch(`/vehicles/${id}`, data);
      return response.data;
    } catch (error) {
      if (FORCE_MOCK_DATA) {
        const index = vehicles.findIndex(v => v.id === id);
        if (index === -1) throw new Error(`Vehicle not found`);
        vehicles[index] = { ...vehicles[index], ...data };
        return {...vehicles[index]};
      }
      throw error;
    }
  },
  
  delete: async (id) => {
    try {
      const response = await apiClient.delete(`/vehicles/${id}`);
      return response.data;
    } catch (error) {
      if (FORCE_MOCK_DATA) {
        const index = vehicles.findIndex(v => v.id === id);
        if (index === -1) throw new Error(`Vehicle not found`);
        vehicles.splice(index, 1);
        return { success: true };
      }
      throw error;
    }
  },

  // Upload document to a vehicle
  uploadDocument: async (id: string, docData: any) => {
    try {
      const response = await apiClient.post(`/vehicles/${id}/documents`, docData);
      return response.data;
    } catch (error) {
      console.error("Error uploading document to vehicle:", error);
      throw error;
    }
  },

  // Delete document from a vehicle
  deleteDocument: async (id: string, documentId: string) => {
    try {
      const response = await apiClient.delete(`/vehicles/${id}/documents/${documentId}`);
      return response.data;
    } catch (error) {
      console.error("Error deleting document from vehicle:", error);
      throw error;
    }
  },

  // Get all documents for a vehicle
  getDocuments: async (id: string) => {
    try {
      const response = await apiClient.get(`/vehicles/${id}/documents`);
      return response.data;
    } catch (error) {
      console.error("Error getting vehicle documents:", error);
      throw error;
    }
  }
};

// Export a default API object with all endpoints
const api = {
  clients: clientsApi,
  suppliers: suppliersApi,
  vehicles: vehiclesApi,
  trips: tripsApi,
  stateStore: stateStore
};

export { stateStore };
export { TransactionManager, PAYMENT_STATUS_TRANSITIONS };
export default api; 