import React, { useState, useEffect, ReactNode } from "react";
import { useToast } from '@/hooks/use-toast';
import { clients } from "@/data/mockData";
import api, { stateStore } from "@/lib/api";
import { useDocuments } from "@/hooks/use-documents";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Link, useLocation } from "react-router-dom";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { FileActions, FileData } from "@/components/ui/file-actions";
import { Search, Download, Info, X, Inbox, Trash2 } from "lucide-react";
import { StatusDropdown } from "@/components/ui/status-dropdown";
import { cn, synchronizeStatuses } from "@/lib/utils";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Loader2 } from "lucide-react";
import { AlertCircle } from "lucide-react";
import { RefreshCw } from "lucide-react";
import StatusBadge from "@/components/ui/status-badge";
import PaymentActionButton from "@/components/ui/payment-action-button";
import { events, EVENT_TYPES } from "@/lib/events";

// Define the Trip interface for proper typing
interface Trip {
  id: string;
  orderNumber: string;
  lrNumbers: string[];
  clientId: string;
  clientName: string;
  clientAddress: string;
  clientAddressType: string;
  clientCity: string;
  destinationAddress: string;
  destinationCity: string;
  destinationAddressType: string;
  supplierId: string;
  supplierName: string;
  vehicleId: string;
  vehicleNumber: string;
  driverName: string;
  driverPhone: string;
  vehicleType: string;
  vehicleSize: string;
  vehicleCapacity: string;
  axleType: string;
  pickupDate: string;
  pickupTime: string;
  clientFreight: number;
  supplierFreight: number;
  advancePercentage: number;
  advanceSupplierFreight: number;
  balanceSupplierFreight: number;
  status: string;
  advancePaymentStatus: string;
  balancePaymentStatus: string;
  podUploaded: boolean;
}

// Define the Trip Filters interface
interface TripFilters {
  orderId: string;
  lrNumber: string;
  clientId: string;
  status: string;
  // Add other filters like date range if needed
}

interface TripsListProps {
  setDynamicSidebarContent?: (content: ReactNode | null) => void;
}

// Available statuses
const tripStatuses = ["Booked", "In Transit", "Delivered", "Completed"];
const paymentStatuses = ["Not Started", "Initiated", "Pending", "Paid"];

const TripsList = ({ setDynamicSidebarContent }: TripsListProps) => {
  const { toast } = useToast();
  const location = useLocation(); // Add location hook to detect navigation
  const { getDocuments, addDocument } = useDocuments();
  const [searchTerm, setSearchTerm] = useState(""); // Kept for main search bar if needed, but primary filtering is via sidebar
  const [trips, setTrips] = useState<Trip[]>([]);
  const [filteredTrips, setFilteredTrips] = useState<Trip[]>([]);
  const [filters, setFilters] = useState<TripFilters>({
    orderId: "",
    lrNumber: "",
    clientId: "",
    status: "",
  });
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);

  // Fetch trips function
  const fetchTrips = async (showToast = false) => {
    if (isRefreshing) return; // Prevent multiple simultaneous fetches
    
    setIsRefreshing(true);
    if (!showToast) setIsLoading(true);
    setError(null);

    try {
      console.log(`Fetching trips data at ${new Date().toISOString()}`);
      
      // Use the API to fetch trips
      const response = await api.trips.getAll();
      console.log(`Successfully fetched ${response.length} trips`);
      
      // Synchronize payment and trip statuses for consistency
      const synchronizedTrips = response.map(trip => {
        // First synchronize statuses using the utility function
        const synchronized = synchronizeStatuses(trip);
        
        // Then check localStorage for any saved payment statuses
        try {
          const advanceKey = `payment_${trip.id}_advance`;
          const balanceKey = `payment_${trip.id}_balance`;
          
          // Restore advance payment status if saved
          const savedAdvanceStatus = localStorage.getItem(advanceKey);
          if (savedAdvanceStatus) {
            synchronized.advancePaymentStatus = savedAdvanceStatus;
            console.log(`Restored advance payment status for ${trip.orderNumber}: ${savedAdvanceStatus}`);
          }
          
          // Restore balance payment status if saved
          const savedBalanceStatus = localStorage.getItem(balanceKey);
          if (savedBalanceStatus) {
            synchronized.balancePaymentStatus = savedBalanceStatus;
            console.log(`Restored balance payment status for ${trip.orderNumber}: ${savedBalanceStatus}`);
          }
          
          // Re-synchronize trip status based on restored payment statuses
          return synchronizeStatuses(synchronized);
        } catch (err) {
          console.error("Error restoring payment statuses from localStorage:", err);
          return synchronized;
        }
      });
      
      setTrips(synchronizedTrips);
      // Apply filters directly instead of using the function return value
      const filteredResults = applyCurrentFilters(synchronizedTrips);
      setFilteredTrips(filteredResults);
      
      if (showToast) {
        toast({
          title: "Data Refreshed",
          description: `Trip data updated (${synchronizedTrips.length} trips)`,
        });
      }
    } catch (e) {
      console.error("Error fetching trips:", e);
      setError("Failed to fetch trips. Please try again later.");
      
      if (showToast) {
        toast({
          title: "Refresh Failed",
          description: "Could not refresh trip data. Please try again.",
          variant: "destructive"
        });
      }
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  // Add a helper function for applying current filters
  const applyCurrentFilters = (tripsToFilter) => {
    let filtered = [...tripsToFilter];
    
    // Apply filters if any are set
    if (filters.orderId) {
      filtered = filtered.filter(trip => 
        trip.orderNumber.toLowerCase().includes(filters.orderId.toLowerCase())
      );
    }
    if (filters.lrNumber) {
      filtered = filtered.filter(trip => 
        trip.lrNumbers.some(lr => lr.toLowerCase().includes(filters.lrNumber.toLowerCase()))
      );
    }
    if (filters.clientId && filters.clientId !== "all") {
      filtered = filtered.filter(trip => trip.clientId === filters.clientId);
    }
    if (filters.status && filters.status !== "all") {
      filtered = filtered.filter(trip => trip.status === filters.status);
    }
    
    // Apply search term if present
    if (searchTerm.trim()) {
      const lowerCaseTerm = searchTerm.toLowerCase();
      filtered = filtered.filter(
        (trip) =>
          trip.orderNumber.toLowerCase().includes(lowerCaseTerm) ||
          trip.lrNumbers.some(lr => lr.toLowerCase().includes(lowerCaseTerm)) ||
          trip.clientName.toLowerCase().includes(lowerCaseTerm) ||
          trip.supplierName.toLowerCase().includes(lowerCaseTerm)
      );
    }
    
    // Update the filtered trips state
    setFilteredTrips(filtered);
    
    // Return the filtered trips for use in the calling function
    return filtered;
  };

  // Setup periodic data refresh (every 5 seconds)
  useEffect(() => {
    // Initial fetch
    fetchTrips();
    
    // Setup auto-refresh interval
    const refreshInterval = setInterval(() => {
      console.log("Auto-refreshing trips data");
      fetchTrips(false); // Don't show toast for auto-refresh
    }, 5000); // Refresh every 5 seconds to ensure payment status changes are reflected quickly
    
    // Cleanup on unmount
    return () => {
      clearInterval(refreshInterval);
    };
  }, []);

  // Force refresh when component mounts or when navigating back to this page
  useEffect(() => {
    console.log("TripsList mounted or navigation occurred - refreshing data");
    fetchTrips(false);
  }, [location.pathname]);

  // Listen for refresh events with improved handling
  useEffect(() => {
    // Define the general refresh handler
    const handleRefreshEvent = () => {
      console.log("TripsList received general refresh event");
      fetchTrips(false);
    };
    
    // Define force refresh handler for more urgent updates
    const handleForceRefreshEvent = (event) => {
      console.log("TripsList received FORCE refresh event", event);
      forceRefreshTrips();
    };
    
    // Define payment status change handler for immediate updates
    const handlePaymentStatusChanged = (event) => {
      console.log("TripsList received payment status changed event:", event);
      
      // For Paid status changes, update UI immediately for better responsiveness
      if (event.newStatus === "Paid") {
        console.log(`⚡ Payment marked as PAID - updating local state for ${event.tripId}`);
        
        // Store payment status in localStorage to preserve across refreshes
        try {
          const paymentKey = `payment_${event.tripId}_${event.paymentType}`;
          localStorage.setItem(paymentKey, "Paid");
          console.log(`Saved payment status to localStorage: ${paymentKey} = Paid`);
        } catch (err) {
          console.error("Failed to save payment status to localStorage:", err);
        }
        
        // Update trips state immediately
        setTrips(prevTrips => {
          return prevTrips.map(trip => {
            if (trip.id === event.tripId || trip.orderNumber === event.tripId) {
              console.log(`Found trip to update: ${trip.orderNumber}`);
              
              // Create updated trip with new payment and trip status
              const updatedTrip = { ...trip };
              
              // Update the payment status
              if (event.paymentType === "advance") {
                updatedTrip.advancePaymentStatus = "Paid";
                
                // If advance payment is paid, trip status should be In Transit
                if (trip.status === "Booked") {
                  updatedTrip.status = "In Transit";
                  console.log(`Updated trip status: ${trip.status} → In Transit`);
                }
              } else if (event.paymentType === "balance") {
                updatedTrip.balancePaymentStatus = "Paid";
                
                // If balance payment is paid, trip status should be Completed
                if (trip.status === "In Transit" || trip.status === "Delivered") {
                  updatedTrip.status = "Completed";
                  console.log(`Updated trip status: ${trip.status} → Completed`);
                }
              }
              
              return updatedTrip;
            }
            return trip;
          });
        });
        
        // Also update filtered trips for immediate UI update
        setFilteredTrips(prevTrips => {
          return prevTrips.map(trip => {
            if (trip.id === event.tripId || trip.orderNumber === event.tripId) {
              // Create updated trip with new payment and trip status
              const updatedTrip = { ...trip };
              
              // Update the payment status
              if (event.paymentType === "advance") {
                updatedTrip.advancePaymentStatus = "Paid";
                
                // If advance payment is paid, trip status should be In Transit
                if (trip.status === "Booked") {
                  updatedTrip.status = "In Transit";
                }
              } else if (event.paymentType === "balance") {
                updatedTrip.balancePaymentStatus = "Paid";
                
                // If balance payment is paid, trip status should be Completed
                if (trip.status === "In Transit" || trip.status === "Delivered") {
                  updatedTrip.status = "Completed";
                }
              }
              
              return updatedTrip;
            }
            return trip;
          });
        });
        
        // Then do a full refresh to ensure data consistency
        setTimeout(() => {
          console.log("Performing full refresh after local state update");
          forceRefreshTrips();
        }, 300);
      } else {
        // For other status changes, a normal refresh is fine
        fetchTrips(false);
      }
    };
    
    // Enhanced trip status change handler
    const handleTripStatusChange = (event) => {
      console.log(`TripsList detected trip status change:`, event);
      
      // Update immediately if status has changed
      if (event.oldStatus !== event.newStatus) {
        console.log("Trip status changed - updating local state");
        
        // Update trips state
        setTrips(prevTrips => {
          return prevTrips.map(trip => {
            if (trip.id === event.tripId || trip.orderNumber === event.tripId) {
              return { ...trip, status: event.newStatus };
            }
            return trip;
          });
        });
        
        // Also update filtered trips
        setFilteredTrips(prevTrips => {
          return prevTrips.map(trip => {
            if (trip.id === event.tripId || trip.orderNumber === event.tripId) {
              return { ...trip, status: event.newStatus };
            }
            return trip;
          });
        });
        
        // Also perform a full refresh to ensure data consistency
        setTimeout(() => {
          fetchTrips(false);
        }, 300);
      }
    };
    
    // Register event listeners
    events.on(EVENT_TYPES.REFRESH_REQUIRED, handleRefreshEvent);
    events.on(EVENT_TYPES.FORCE_REFRESH_REQUIRED, handleForceRefreshEvent);
    events.on(EVENT_TYPES.PAYMENT_STATUS_CHANGED, handlePaymentStatusChanged);
    events.on(EVENT_TYPES.TRIP_STATUS_CHANGED, handleTripStatusChange);
    
    console.log("TripsList: Registered all event handlers");
    
    // Clean up the event listeners when the component unmounts
    return () => {
      console.log("TripsList: Removing event handlers");
      events.off(EVENT_TYPES.REFRESH_REQUIRED, handleRefreshEvent);
      events.off(EVENT_TYPES.FORCE_REFRESH_REQUIRED, handleForceRefreshEvent);
      events.off(EVENT_TYPES.PAYMENT_STATUS_CHANGED, handlePaymentStatusChanged);
      events.off(EVENT_TYPES.TRIP_STATUS_CHANGED, handleTripStatusChange);
    };
  }, []);

  // Replace the stateStore listener with this enhanced version:
  useEffect(() => {
    // Function to handle trip status changes directly from the state store
    const handleTripStatusChange = (tripId, oldStatus, newStatus, context) => {
      console.log(`TripsList detected status change via stateStore for ${tripId}: ${oldStatus} → ${newStatus}`);
      
      // Always update local state immediately for responsive UI
      if (oldStatus !== newStatus) {
        console.log(`Updating local state immediately: ${oldStatus} → ${newStatus}`);
        
        // Update main trips state
        setTrips(prevTrips => {
          return prevTrips.map(trip => {
            if (trip.id === tripId || trip.orderNumber === tripId) {
              console.log(`Updating trip ${trip.orderNumber} status to ${newStatus}`);
              return { ...trip, status: newStatus };
            }
            return trip;
          });
        });
        
        // Also update filtered trips to ensure UI consistency
        setFilteredTrips(prevTrips => {
          return prevTrips.map(trip => {
            if (trip.id === tripId || trip.orderNumber === tripId) {
              return { ...trip, status: newStatus };
            }
            return trip;
          });
        });
        
        // Perform a background refresh for data consistency
        setTimeout(() => {
          console.log("Performing background refresh after status change");
          fetchTrips(false);
        }, 500);
      }
    };
    
    // Register with stateStore if available
    if (stateStore && typeof stateStore.onTripStatusChange === 'function') {
      console.log("Registering trip status change listener with stateStore");
      const unsubscribe = stateStore.onTripStatusChange(handleTripStatusChange);
      
      // Clean up the listener when the component unmounts
      return () => {
        console.log("Unregistering trip status change listener");
        unsubscribe();
      };
    }
    
    return undefined;
  }, []);

  // Unique values for filter dropdowns - computed from current trips
  const uniqueClients = React.useMemo(() => {
    return Array.from(new Set(trips.map(trip => trip.clientName))).sort();
  }, [trips]);
  
  const uniqueStatuses = React.useMemo(() => {
    return Array.from(new Set(trips.map(trip => trip.status))).sort();
  }, [trips]);

  const handleFilterChange = (field: keyof TripFilters, value: string) => {
    setFilters(prev => ({ ...prev, [field]: value }));
  };

  const applyFilters = () => {
    let tempTrips = trips;

    if (filters.orderId) {
      tempTrips = tempTrips.filter(trip => 
        trip.orderNumber.toLowerCase().includes(filters.orderId.toLowerCase())
      );
    }
    if (filters.lrNumber) {
      tempTrips = tempTrips.filter(trip => 
        trip.lrNumbers.some(lr => lr.toLowerCase().includes(filters.lrNumber.toLowerCase()))
      );
    }
    if (filters.clientId) {
      tempTrips = tempTrips.filter(trip => trip.clientId === filters.clientId);
    }
    if (filters.status) {
      tempTrips = tempTrips.filter(trip => trip.status === filters.status);
    }

    // Apply search term if present
    if (searchTerm) {
      const searchLower = searchTerm.toLowerCase();
      tempTrips = tempTrips.filter(trip => (
        trip.orderNumber.toLowerCase().includes(searchLower) ||
        trip.lrNumbers.some(lr => lr.toLowerCase().includes(searchLower)) ||
        trip.clientName.toLowerCase().includes(searchLower) ||
        trip.vehicleNumber.toLowerCase().includes(searchLower)
      ));
    }

    setFilteredTrips(tempTrips);
  };

  const clearFilters = () => {
    setFilters({
      orderId: "",
      lrNumber: "",
      clientId: "",
      status: "",
    });
    setSearchTerm("");
    setFilteredTrips(trips); // Reset table to show all trips
  };

  // Apply filters whenever filter state changes or trips change
  useEffect(() => {
    applyFilters();
  }, [filters, trips, searchTerm]);

  // Render sidebar filters
  const renderSidebarFilters = () => (
    <div className="space-y-4">
      <div>
        <Label htmlFor="filter-orderId" className="text-xs font-medium">Order ID</Label>
        <Input 
          id="filter-orderId" 
          placeholder="Search Order ID..."
          value={filters.orderId}
          onChange={(e) => handleFilterChange("orderId", e.target.value)}
          className="h-9 text-sm mt-1"
        />
      </div>
      <div>
        <Label htmlFor="filter-lrNumber" className="text-xs font-medium">LR Number</Label>
        <Input 
          id="filter-lrNumber" 
          placeholder="Search LR..."
          value={filters.lrNumber}
          onChange={(e) => handleFilterChange("lrNumber", e.target.value)}
          className="h-9 text-sm mt-1"
        />
      </div>
      <div>
        <Label htmlFor="filter-client" className="text-xs font-medium">Client</Label>
        <Select 
          value={filters.clientId}
          onValueChange={(value) => handleFilterChange("clientId", value)}
        >
          <SelectTrigger id="filter-client" className="h-9 text-sm mt-1">
            <SelectValue placeholder="All Clients" />
          </SelectTrigger>
          <SelectContent>
            {clients.map(client => (
              <SelectItem key={client.id} value={client.id} className="text-sm">
                {client.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <div>
        <Label htmlFor="filter-status" className="text-xs font-medium">Status</Label>
        <Select 
          value={filters.status}
          onValueChange={(value) => handleFilterChange("status", value)}
        >
          <SelectTrigger id="filter-status" className="h-9 text-sm mt-1">
            <SelectValue placeholder="All Statuses" />
          </SelectTrigger>
          <SelectContent>
            {uniqueStatuses.map(status => (
              <SelectItem key={status} value={status} className="text-sm">
                {status}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <Button variant="ghost" size="sm" onClick={clearFilters} className="w-full text-sm h-9 mt-2">
        <X className="h-4 w-4 mr-1.5"/> Clear Filters
      </Button>
    </div>
  );

  // Set dynamic sidebar content on mount and when filters change (to re-render with latest values)
  useEffect(() => {
    if (setDynamicSidebarContent) {
      setDynamicSidebarContent(renderSidebarFilters());
    }
    // Cleanup function to remove content when component unmounts
    return () => {
      if (setDynamicSidebarContent) {
        setDynamicSidebarContent(null);
      }
    };
  }, [setDynamicSidebarContent, filters, uniqueStatuses]); // Re-render sidebar when filters or statuses change

  const handleExportToExcel = () => {
    toast({
      title: "Export Initiated",
      description: "Your trip details are being exported to Excel.",
    });
    
    // Create a fake blob for download demonstration
    const blob = new Blob(['Fake Excel Data'], { type: 'application/vnd.ms-excel' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'trips_export.xlsx';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  };

  // Handle document upload without initiating balance payment
  const handleDocumentUpload = (tripId: string, fileData: FileData) => {
    try {
      // First add document to local storage
      addDocument(tripId, fileData);
      
      // Check if the uploaded document is a POD
      const isPodUpload = fileData.type.toLowerCase().includes("pod") || 
                          fileData.name.toLowerCase().includes("pod");
      
      if (isPodUpload) {
        console.log("POD document detected, updating trip:", tripId);
        
        // Update local state to mark POD as uploaded only (without changing payment status)
        const updatedTrips = filteredTrips.map(t => {
          if (t.id === tripId) {
            return { ...t, podUploaded: true };
          }
          return t;
        });
        setFilteredTrips(updatedTrips);
        
        // Also update the trips state for consistency
        setTrips(prevTrips => prevTrips.map(t => {
          if (t.id === tripId) {
            return { ...t, podUploaded: true };
          }
          return t;
        }));
        
        // Create proper payload
        const payload = { podUploaded: true };
        
        // Make API call to update POD status only
        api.trips.update(tripId, payload)
          .then(response => {
            console.log("POD status updated successfully:", response);
            toast({
              title: "POD Uploaded",
              description: "Proof of Delivery uploaded successfully.",
            });
          })
          .catch(error => {
            console.error("Error updating POD status:", error);
            let errorMsg = "Could not update POD status on server. Please try again.";
            if (error.response && error.response.data && error.response.data.message) {
              errorMsg = error.response.data.message;
            }
            toast({
              title: "POD Status Update Error",
              description: errorMsg,
              variant: "destructive"
            });
          });
      } else {
        toast({
          title: "Document Uploaded",
          description: `${fileData.name} has been uploaded successfully.`,
        });
      }
    } catch (error) {
      console.error("Error handling document upload:", error);
      toast({
        title: "Upload Error",
        description: "There was an unexpected error processing your upload.",
        variant: "destructive"
      });
    }
  };

  // Handle status change with automatic balance payment initiation
  const handleStatusChange = async (entityId: string, newStatus: string, field: string) => {
    try {
      // Update the status in the filteredTrips state for immediate UI feedback
      const updatedTrips = filteredTrips.map(trip => {
        if (trip.id === entityId) {
          // If setting trip status to "Completed" or "Shipped", automatically mark balance payment as "Initiated"
          if (field === 'status' && (newStatus === 'Completed' || newStatus === 'Delivered')) {
            return { ...trip, [field]: newStatus, balancePaymentStatus: "Initiated" };
          }
          return { ...trip, [field]: newStatus };
        }
        return trip;
      });
      setFilteredTrips(updatedTrips);
      
      // Update the status in the main trips state for consistency
      setTrips(prevTrips => prevTrips.map(trip => {
        if (trip.id === entityId) {
          // If setting trip status to "Completed" or "Shipped", automatically mark balance payment as "Initiated"
          if (field === 'status' && (newStatus === 'Completed' || newStatus === 'Delivered')) {
            return { ...trip, [field]: newStatus, balancePaymentStatus: "Initiated" };
          }
          return { ...trip, [field]: newStatus };
        }
        return trip;
      }));
      
      // Call the API to update the status
      if (field === 'status') {
        const result = await api.trips.updateStatus(entityId, newStatus);
        
        // If trip is marked as completed or delivered, also update balance payment status
        if (newStatus === 'Completed' || newStatus === 'Delivered') {
          await api.trips.updatePaymentStatus(entityId, { balancePaymentStatus: "Initiated" });
          
          toast({
            title: "Balance Payment Initiated",
            description: `Trip ${newStatus.toLowerCase()} and balance payment has been queued for processing`,
          });
        }
      } else {
        // For payment statuses
        const paymentData = { [field]: newStatus };
        await api.trips.updatePaymentStatus(entityId, paymentData);
      }
      
      // Show confirmation toast
      toast({
        title: "Status Updated",
        description: `${field === 'status' ? 'Trip' : field.replace('PaymentStatus', '')} status updated to ${newStatus}`,
      });
    } catch (error) {
      console.error("Error updating status:", error);
    toast({
        title: "Update Failed",
        description: "Failed to update status. Please try again.",
        variant: "destructive"
      });
      
      // Refresh data to ensure consistency
      fetchTrips(false);
    }
  };

  const handleGeneralSearch = (value: string) => {
    setSearchTerm(value);
  };

  // Add a refresh function that users can manually trigger
  const refreshTrips = () => {
    fetchTrips(true); // Show toast when manually refreshed
  };

  // Modify the forceRefreshTrips function to use the status synchronization utility:
  const forceRefreshTrips = async () => {
    console.log("Force refreshing trips data");
    setIsRefreshing(true);
    setIsLoading(true);
    
    try {
      // Clear the current trip data
      setTrips([]);
      setFilteredTrips([]);
      
      // Wait a moment for UI to update
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Fetch new data with a cache-busting timestamp parameter
      const timestamp = Date.now();
      console.log(`Fetching fresh data at ${new Date().toISOString()} with timestamp ${timestamp}`);
      
      const freshTrips = await api.trips.getAll();
      console.log(`Received ${freshTrips.length} trips from server`);
      
      // Synchronize payment and trip statuses for consistency
      const synchronizedTrips = freshTrips.map(trip => synchronizeStatuses(trip));
      
      // Log the trips for debugging
      synchronizedTrips.forEach(trip => {
        console.log(`Trip ${trip.orderNumber}: Status=${trip.status}, Advance=${trip.advancePaymentStatus}, Balance=${trip.balancePaymentStatus}`);
      });
      
      // Update with fresh data
      setTrips(synchronizedTrips);
      
      // Apply current filters
      applyCurrentFilters(synchronizedTrips);
      
      toast({
        title: "Data Refreshed",
        description: "Trip data has been completely reloaded.",
        duration: 3000,
      });
    } catch (error) {
      console.error("Force refresh error:", error);
      toast({
        title: "Refresh Failed",
        description: "Could not refresh trip data. Please try again.",
        variant: "destructive"
      });
    } finally {
      setIsRefreshing(false);
      setIsLoading(false);
    }
  };

  // Add a new function to handle trip deletion
  const handleDeleteTrip = async (tripId: string) => {
    try {
      setIsLoading(true);
      await api.trips.delete(tripId);
      
      toast({
        title: "Trip Deleted",
        description: `Trip has been permanently deleted`,
        variant: "default",
      });
      
      // Refresh the trips list after deletion
      fetchTrips();
    } catch (error) {
      console.error("Error deleting trip:", error);
      toast({
        title: "Delete Failed",
        description: "Could not delete the trip. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-4">
      {/* Search and actions header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 mb-2">
        <div className="relative w-full sm:w-auto">
          <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
            type="search"
            placeholder="Search trips (Order ID, LR, Client)..."
            className="w-full sm:w-[240px] pl-9 h-9 text-sm"
                value={searchTerm}
            onChange={(e) => handleGeneralSearch(e.target.value)}
              />
        </div>
        <div className="flex gap-2 w-full sm:w-auto">
              <Button
            variant="outline" 
                size="sm"
            className="h-9 w-full sm:w-auto" 
            onClick={refreshTrips}
            disabled={isRefreshing}
              >
            <RefreshCw className={`mr-1.5 h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} /> 
            {isRefreshing ? 'Refreshing...' : 'Refresh'}
              </Button>
            <Button
              variant="default"
              size="sm"
              className="h-9 w-full sm:w-auto bg-blue-600 hover:bg-blue-700" 
              onClick={forceRefreshTrips}
              disabled={isRefreshing}
            >
              <RefreshCw className={`mr-1.5 h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} /> 
              Force Reload
            </Button>
            <Button
              variant="outline"
              size="sm"
            className="h-9 w-full sm:w-auto" 
              onClick={handleExportToExcel}
            >
            <Download className="mr-1.5 h-4 w-4" /> Export
          </Button>
        </div>
      </div>

      {/* Mobile filter button - only shown on small screens */}
      <div className="lg:hidden">
        <Dialog>
          <DialogTrigger asChild>
            <Button variant="outline" size="sm" className="w-full">
              <Search className="mr-1.5 h-4 w-4" /> Filters & Info
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Filter Options</DialogTitle>
              <DialogDescription>
                Apply filters to narrow down your search
              </DialogDescription>
            </DialogHeader>
            {renderSidebarFilters()}
          </DialogContent>
        </Dialog>
      </div>
      
      {isLoading ? (
        <div className="flex flex-col items-center justify-center p-8">
          <Loader2 className="h-8 w-8 animate-spin text-primary mb-4" />
          <p className="text-sm text-muted-foreground">Loading trips data...</p>
        </div>
      ) : error ? (
        <div className="flex flex-col items-center justify-center p-8 border rounded-lg bg-destructive/5">
          <AlertCircle className="h-8 w-8 text-destructive mb-4" />
          <p className="text-sm text-destructive font-medium mb-2">{error}</p>
          <Button variant="outline" size="sm" onClick={refreshTrips}>
            <RefreshCw className="mr-1.5 h-4 w-4" /> Try Again
          </Button>
        </div>
      ) : filteredTrips.length === 0 ? (
        <div className="flex flex-col items-center justify-center p-8 border rounded-lg">
          <Inbox className="h-8 w-8 text-muted-foreground mb-4" />
          <p className="text-sm text-muted-foreground mb-2">No trips match your current filters</p>
          <Button variant="outline" size="sm" onClick={clearFilters}>
            <X className="mr-1.5 h-4 w-4" /> Clear Filters
            </Button>
          </div>
      ) : (
          <div className="rounded-md border overflow-hidden">
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                  <TableHead>TRIP DATE</TableHead>
                  <TableHead className="w-[100px]">ORDER ID</TableHead>
                  <TableHead className="w-[100px]">LR NUMBER</TableHead>
                  <TableHead>CLIENT</TableHead>
                  <TableHead className="text-right">CLIENT FREIGHT (₹)</TableHead>
                  <TableHead className="text-right">SUPPLIER FREIGHT (₹)</TableHead>
                  <TableHead className="text-right">MARGIN (₹) (%)</TableHead>
                  <TableHead>SOURCE - DEST</TableHead>
                  <TableHead>VEHICLE</TableHead>
                  <TableHead>STATUS</TableHead>
                  <TableHead>ADVANCE</TableHead>
                  <TableHead>BALANCE</TableHead>
                  <TableHead className="w-[150px]">ACTIONS</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                {filteredTrips.map((trip) => (
                      <TableRow key={trip.id}>
                        <TableCell>{new Date(trip.pickupDate).toLocaleDateString()}</TableCell>
                        <TableCell className="font-medium">
                      <Link 
                        to={`/trips/${trip.orderNumber}`} 
                        className="text-primary hover:underline"
                      >
                            {trip.orderNumber}
                      </Link>
                    </TableCell>
                    <TableCell>{trip.lrNumbers[0]}</TableCell>
                    <TableCell>{trip.clientName}</TableCell>
                    <TableCell className="text-right">₹{trip.clientFreight.toLocaleString()}</TableCell>
                    <TableCell className="text-right">₹{trip.supplierFreight.toLocaleString()}</TableCell>
                    <TableCell className="text-right">
                      <div className="flex flex-col items-end">
                        <span>₹{(trip.clientFreight - trip.supplierFreight).toLocaleString()}</span>
                        <span className="text-xs text-muted-foreground">
                          {((trip.clientFreight - trip.supplierFreight) / trip.clientFreight * 100).toFixed(1)}%
                        </span>
                      </div>
                        </TableCell>
                    <TableCell>
                      {trip.clientCity} <span className="text-muted-foreground">→</span> {trip.destinationCity}
                        </TableCell>
                        <TableCell>{trip.vehicleNumber}</TableCell>
                        <TableCell>
                      <StatusBadge status={trip.status} />
                        </TableCell>
                        <TableCell>
                      <StatusBadge status={trip.advancePaymentStatus} />
                        </TableCell>
                        <TableCell>
                          <StatusBadge status={trip.balancePaymentStatus} />
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center space-x-2">
                            <FileActions
                              id={trip.id}
                              type="trip"
                              entityName={trip.orderNumber}
                              documentType="POD"
                              existingFiles={getDocuments(trip.id)}
                              onSuccess={(fileData) => handleDocumentUpload(trip.id, fileData)}
                            />
                            
                            <AlertDialog>
                              <AlertDialogTrigger asChild>
                                <Button size="icon" variant="outline" className="h-8 w-8 text-destructive hover:bg-destructive/10">
                                  <Trash2 className="h-4 w-4" />
                            </Button>
                              </AlertDialogTrigger>
                              <AlertDialogContent>
                                <AlertDialogHeader>
                                  <AlertDialogTitle>Delete Trip</AlertDialogTitle>
                                  <AlertDialogDescription>
                                    Are you sure you want to delete trip {trip.orderNumber}? This action cannot be undone.
                                  </AlertDialogDescription>
                                </AlertDialogHeader>
                                <AlertDialogFooter>
                                  <AlertDialogCancel>Cancel</AlertDialogCancel>
                                  <AlertDialogAction 
                                    onClick={() => handleDeleteTrip(trip.id)}
                                    className="bg-destructive hover:bg-destructive/90"
                                  >
                                    Delete
                                  </AlertDialogAction>
                                </AlertDialogFooter>
                              </AlertDialogContent>
                            </AlertDialog>
                          </div>
                        </TableCell>
                      </TableRow>
                ))}
                </TableBody>
              </Table>
            </div>
          </div>
      )}
    </div>
  );
};

export default TripsList;
