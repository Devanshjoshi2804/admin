import React, { useState, useEffect, ReactNode } from "react";
import { Trip, suppliers } from "@/data/mockData"; // Remove trips import
import { useToast } from "@/hooks/use-toast";
import { useDocuments } from "@/hooks/use-documents";
import api, { TransactionManager } from "@/lib/api"; // Import the TransactionManager
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Link, useNavigate } from "react-router-dom";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { FileActions, FileData } from "@/components/ui/file-actions";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { 
  Search, 
  Download, 
  CreditCard, 
  X, 
  Inbox, 
  RefreshCw, 
  ChevronsUpDown, 
  DollarSign,
  Filter,
  Layers,
  BadgeIndianRupee,
  Package,
  FileText,
  Building,
  Info
} from "lucide-react";
import { StatusDropdown } from "@/components/ui/status-dropdown";
import { cn, synchronizeStatuses } from "@/lib/utils";
import StatusBadge from "@/components/ui/status-badge";
import PaymentActionButton from "@/components/ui/payment-action-button";
import { events, EVENT_TYPES } from "@/lib/events";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import SupplierInfoDialog from "@/components/ui/supplier-info-dialog";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogClose
} from "@/components/ui/dialog";

interface PaymentFilters {
  orderId: string;
  lrNumber: string;
  supplierId: string;
  paymentStatus: string;
}

interface PaymentDashboardProps {
  setDynamicSidebarContent?: (content: ReactNode | null) => void;
}

// First, add a new interface for the adjustment dialog
interface AmountAdjustmentDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  tripId: string;
  originalAmount: number;
  newAmount: number;
  onConfirm: () => void;
}

// Add the AmountAdjustmentDialog component definition
const AmountAdjustmentDialog = ({ 
  open, 
  onOpenChange, 
  tripId, 
  originalAmount, 
  newAmount, 
  onConfirm 
}: AmountAdjustmentDialogProps) => {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle className="text-amber-600">Balance Amount Changed</DialogTitle>
          <DialogDescription>
            The balance payment amount has increased. Please confirm the new amount.
          </DialogDescription>
        </DialogHeader>
        <div className="py-4">
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-muted-foreground">Original Amount:</span>
              <span className="font-medium">₹{originalAmount.toLocaleString()}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">New Amount:</span>
              <span className="font-bold text-amber-600">₹{newAmount.toLocaleString()}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Difference:</span>
              <span className="font-medium text-amber-600">+₹{(newAmount - originalAmount).toLocaleString()}</span>
            </div>
            <div className="mt-4 bg-amber-50 p-3 rounded-md text-sm text-amber-800 border border-amber-200">
              <Info className="h-4 w-4 inline-block mr-2" />
              This adjustment is needed due to changes in platform fees, LR charges, or deduction charges.
            </div>
          </div>
        </div>
        <div className="flex justify-end gap-2">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button 
            variant="default" 
            className="bg-amber-600 hover:bg-amber-700"
            onClick={() => {
              onConfirm();
              onOpenChange(false);
            }}
          >
            Confirm New Amount
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
};

/**
 * Payment Dashboard Component
 * 
 * This component manages the centralized payment flow for the application with these key features:
 * 
 * 1. Centralized Payment Management:
 *    - All payment status changes must happen in this dashboard
 *    - Trip status changes are automatically triggered by payment status changes
 *    
 * 2. Payment Status Flow:
 *    - Not Started → Initiated → Pending → Paid
 * 
 * 3. Trip Status Automation:
 *    - When Advance payment is marked as Paid: Trip status changes to "In Transit"
 *    - When Balance payment is marked as Paid: Trip status changes to "Completed"
 * 
 * 4. Once a payment is marked as "Paid", it will never appear in the payment queue again
 * 
 * This ensures a consistent workflow: Booked → Advance Payment → In Transit → Delivery → Balance Payment → Completed
 */
const PaymentDashboard = ({ setDynamicSidebarContent }: PaymentDashboardProps) => {
  const { toast } = useToast();
  const { getDocuments, addDocument } = useDocuments();
  const navigate = useNavigate(); // Add useNavigate hook
  const [searchTerm, setSearchTerm] = useState(""); // General search
  const [allTrips, setAllTrips] = useState<Trip[]>([]); // Initialize with empty array
  const [filteredTrips, setFilteredTrips] = useState<Trip[]>([]); // Initialize with empty array
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false); // Separate state for refresh button
  const [filters, setFilters] = useState<PaymentFilters>({
    orderId: "",
    lrNumber: "",
    supplierId: "all",
    paymentStatus: "all",
  });
  const [adjustmentDialogOpen, setAdjustmentDialogOpen] = useState(false);
  const [adjustmentTripId, setAdjustmentTripId] = useState<string>("");
  const [originalAmount, setOriginalAmount] = useState<number>(0);
  const [newAmount, setNewAmount] = useState<number>(0);

  // Fetch trips on component mount
  useEffect(() => {
    const fetchTrips = async () => {
      setIsLoading(true);
      try {
        const fetchedTrips = await api.trips.getAll();
        
        // Debug log for supplier IDs
        fetchedTrips.forEach(trip => {
          console.log(`Trip ${trip.orderNumber}: supplierId=${trip.supplierId} (type: ${typeof trip.supplierId})`);
          if (!trip.supplierId || trip.supplierId === 'null' || trip.supplierId === 'undefined') {
            console.warn(`⚠️ Trip ${trip.orderNumber} has invalid supplierId: ${trip.supplierId}`);
          }
        });
        
        // Synchronize payment and trip statuses for consistency
        const synchronizedTrips = fetchedTrips.map(trip => {
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
        
        console.log(`Successfully fetched and synchronized ${synchronizedTrips.length} trips`);
        
        // Log payment statuses for debugging
        synchronizedTrips.forEach(trip => {
          console.log(`Trip ${trip.orderNumber}: Status=${trip.status}, Advance=${trip.advancePaymentStatus}, Balance=${trip.balancePaymentStatus}`);
        });
        
        // Check for trips with balance amount changes
        const tripsWithChangedAmounts = synchronizedTrips.filter(newTrip => {
          const oldTrip = allTrips.find(t => t.id === newTrip.id);
          if (!oldTrip) return false;
          
          // Only consider trips where balance payment is not yet paid
          if (newTrip.balancePaymentStatus === "Paid") return false;
          
          // Check if balance amount has increased
          return newTrip.balanceSupplierFreight > oldTrip.balanceSupplierFreight;
        });

        if (tripsWithChangedAmounts.length > 0) {
          console.log(`Found ${tripsWithChangedAmounts.length} trips with increased balance amounts:`, 
            tripsWithChangedAmounts.map(t => `${t.orderNumber}: ${t.balanceSupplierFreight}`));
          
          // Add badge indicators to these trips
          synchronizedTrips.forEach(trip => {
            if (tripsWithChangedAmounts.some(t => t.id === trip.id)) {
              trip.amountChanged = true;
            }
          });
          
          // Show toast notification if balance amounts have changed
          if (!isRefreshing) { // Only show on initial load, not during refresh button press
            toast({
              title: "Balance Amounts Changed",
              description: `${tripsWithChangedAmounts.length} trips have increased balance payment amounts.`,
              variant: "default",
              duration: 5000,
            });
          }
        }
        
        setAllTrips(synchronizedTrips);
        setFilteredTrips(synchronizedTrips);
      } catch (error) {
        console.error("Error fetching trips for payment dashboard:", error);
        toast({
          title: "Error Loading Payments",
          description: "Failed to load payment data. Please try again.",
          variant: "destructive",
        });
      } finally {
        setIsLoading(false);
      }
    };
    
    // Initial fetch
    fetchTrips();
    
    // Set up periodic refresh to check for updates (every 15 seconds)
    const refreshInterval = setInterval(async () => {
      try {
        const latestTrips = await api.trips.getAll();
        
        // Synchronize payment and trip statuses for consistency
        const synchronizedTrips = latestTrips.map(trip => synchronizeStatuses(trip));
        
        // If there are new or updated trips, update our state
        if (JSON.stringify(synchronizedTrips) !== JSON.stringify(allTrips)) {
          console.log("New or updated trips detected. Refreshing payment dashboard data.");
          setAllTrips(synchronizedTrips);
          
          // Find any trips with newly initiated payments
          const newPayments = synchronizedTrips.filter(newTrip => {
            const oldTrip = allTrips.find(t => t.id === newTrip.id);
            return !oldTrip || (
              oldTrip.advancePaymentStatus !== newTrip.advancePaymentStatus ||
              oldTrip.balancePaymentStatus !== newTrip.balancePaymentStatus
            );
          });
          
          // Show notifications for any payment status changes
          newPayments.forEach(trip => {
            const oldTrip = allTrips.find(t => t.id === trip.id);
            
            // Show notification if this is a new trip
            if (!oldTrip) {
              toast({
                title: `New Trip Added`,
                description: `Trip ${trip.orderNumber} has been added to the system.`,
              });
              return;
            }
            
            // Show notifications for payment status changes
            if (oldTrip.advancePaymentStatus !== trip.advancePaymentStatus) {
              toast({
                title: `Advance Payment Updated`,
                description: `Trip ${trip.orderNumber} advance payment status: ${trip.advancePaymentStatus}`,
              });
            }
            
            if (oldTrip.balancePaymentStatus !== trip.balancePaymentStatus) {
              toast({
                title: `Balance Payment Updated`,
                description: `Trip ${trip.orderNumber} balance payment status: ${trip.balancePaymentStatus}`,
              });
            }
          });
          
          // Re-apply filters to ensure filtered view is updated
          applyFilters();
        }
      } catch (error) {
        console.error("Error checking for payment updates:", error);
        // Don't show error toast on background refresh to avoid spamming the user
      }
    }, 15000); // Check every 15 seconds
    
    // Clean up on unmount
    return () => clearInterval(refreshInterval);
  }, [toast]); // Only include toast in deps to avoid recreating interval on data changes

  // Unique values for filters - now derived from fetched data
  const uniquePaymentStatuses = React.useMemo(() => Array.from(new Set([
    ...allTrips.map(t => t.advancePaymentStatus),
    ...allTrips.map(t => t.balancePaymentStatus)
  ])).sort(), [allTrips]);

  // Available statuses
  const paymentStatuses = ["Not Started", "Initiated", "Pending", "Paid"];

  const handleFilterChange = (field: keyof PaymentFilters, value: string) => {
    setFilters(prev => ({ ...prev, [field]: value }));
  };

  const applyFilters = () => {
    let tempTrips = allTrips; // Start with the full, potentially updated list

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
    if (filters.supplierId && filters.supplierId !== "all") {
      tempTrips = tempTrips.filter(trip => trip.supplierId === filters.supplierId);
    }
    if (filters.paymentStatus && filters.paymentStatus !== "all") {
      tempTrips = tempTrips.filter(trip => 
        trip.advancePaymentStatus === filters.paymentStatus || 
        trip.balancePaymentStatus === filters.paymentStatus
      );
    }

    // Apply general search on top of filters if present
    if (searchTerm.trim()) {
      const lowerCaseTerm = searchTerm.toLowerCase();
      tempTrips = tempTrips.filter(
        (trip) =>
          trip.orderNumber.toLowerCase().includes(lowerCaseTerm) ||
          trip.lrNumbers.some(lr => lr.toLowerCase().includes(lowerCaseTerm)) ||
          trip.clientName.toLowerCase().includes(lowerCaseTerm) ||
          trip.supplierName.toLowerCase().includes(lowerCaseTerm)
      );
    }

    setFilteredTrips(tempTrips);
  };

  const clearFilters = () => {
    setFilters({
      orderId: "",
      lrNumber: "",
      supplierId: "all",
      paymentStatus: "all",
    });
    setFilteredTrips(allTrips); // Reset to all trips
    setSearchTerm(""); // Clear general search too
  };

  // Apply filters when filter state changes
  useEffect(() => {
    applyFilters();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters, allTrips]); // Also re-run if allTrips changes (due to status update)

  // --- General Search (applied on top of filters) ---
  const handleGeneralSearch = (term: string, baseList: Trip[] = filteredTrips) => {
    setSearchTerm(term);
    let searchFiltered = baseList; // Start with the list provided (either currently filtered or filter-applied)

    if (term.trim()) {
      const lowerCaseTerm = term.toLowerCase();
      searchFiltered = baseList.filter(
        (trip) =>
          trip.orderNumber.toLowerCase().includes(lowerCaseTerm) ||
          trip.lrNumbers.some(lr => lr.toLowerCase().includes(lowerCaseTerm)) ||
          trip.clientName.toLowerCase().includes(lowerCaseTerm) ||
          trip.supplierName.toLowerCase().includes(lowerCaseTerm)
      );
    }
    setFilteredTrips(searchFiltered);
  };
  // ---------------------------------------------------

  // Filter trips for display in tabs (based on the finally filtered trips)
  const advancePayments = filteredTrips.filter(
    (trip) => ["Initiated", "Pending"].includes(trip.advancePaymentStatus)
  );
  const podPayments = filteredTrips.filter(
    (trip) => ["Initiated", "Pending"].includes(trip.balancePaymentStatus) ||
    // Also include trips with Paid advance but Not Started/Initiated/Pending balance payments
    (trip.advancePaymentStatus === "Paid" && 
     ["Not Started", "Initiated", "Pending"].includes(trip.balancePaymentStatus))
  );
  
  // Add this for Payment History tab
  const completedPayments = filteredTrips.filter(
    (trip) => trip.advancePaymentStatus === "Paid" || trip.balancePaymentStatus === "Paid"
  );

  // Helper function to check if a trip has amount changes (type guard)
  const hasAmountChanged = (trip: Trip): boolean => {
    return Boolean((trip as any).amountChanged);
  };

  const renderSidebarFilters = () => (
    <div className="space-y-5 p-1">
      <div className="flex items-center justify-between mb-2">
        <h3 className="text-sm font-semibold text-slate-900 dark:text-slate-100">Payment Filters</h3>
        <Button 
          variant="ghost" 
          size="sm" 
          onClick={clearFilters} 
          className="h-8 px-2 text-blue-600 dark:text-blue-400 hover:text-blue-700 hover:bg-blue-50 dark:hover:bg-blue-900/20"
        >
          <X className="h-3.5 w-3.5 mr-1"/> Clear All
        </Button>
      </div>
      
      <div className="border-b border-slate-200 dark:border-slate-700 pb-4">
        <Label htmlFor="filter-orderId" className="text-xs font-medium flex items-center mb-1.5">
          <Package className="h-3.5 w-3.5 mr-1.5 text-slate-500 dark:text-slate-400" />
          Order ID
        </Label>
        <Input 
          id="filter-orderId" 
          placeholder="Enter order ID..."
          value={filters.orderId}
          onChange={(e) => handleFilterChange("orderId", e.target.value)}
          className="h-9 text-sm border-slate-200 dark:border-slate-700 focus-visible:ring-blue-500"
        />
        {filters.orderId && (
          <div className="mt-1.5 flex">
            <Badge 
              variant="outline" 
              className="text-xs py-0 bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800 text-blue-700 dark:text-blue-300 gap-1"
            >
              {filters.orderId}
              <button 
                onClick={() => handleFilterChange("orderId", "")}
                className="rounded-full text-blue-500 dark:text-blue-400 hover:bg-blue-100 dark:hover:bg-blue-800/40"
              >
                <X className="h-3 w-3" />
              </button>
            </Badge>
          </div>
        )}
      </div>

      <div className="border-b border-slate-200 dark:border-slate-700 pb-4">
        <Label htmlFor="filter-lrNumber" className="text-xs font-medium flex items-center mb-1.5">
          <FileText className="h-3.5 w-3.5 mr-1.5 text-slate-500 dark:text-slate-400" />
          LR Number
        </Label>
        <Input 
          id="filter-lrNumber" 
          placeholder="Enter LR number..."
          value={filters.lrNumber}
          onChange={(e) => handleFilterChange("lrNumber", e.target.value)}
          className="h-9 text-sm border-slate-200 dark:border-slate-700 focus-visible:ring-blue-500"
        />
        {filters.lrNumber && (
          <div className="mt-1.5 flex">
            <Badge 
              variant="outline" 
              className="text-xs py-0 bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800 text-amber-700 dark:text-amber-300 gap-1"
            >
              {filters.lrNumber}
              <button 
                onClick={() => handleFilterChange("lrNumber", "")}
                className="rounded-full text-amber-500 dark:text-amber-400 hover:bg-amber-100 dark:hover:bg-amber-800/40"
              >
                <X className="h-3 w-3" />
              </button>
            </Badge>
          </div>
        )}
      </div>

      <div className="border-b border-slate-200 dark:border-slate-700 pb-4">
        <Label htmlFor="filter-supplier" className="text-xs font-medium flex items-center mb-1.5">
          <Building className="h-3.5 w-3.5 mr-1.5 text-slate-500 dark:text-slate-400" />
          Supplier
        </Label>
        <Select 
          value={filters.supplierId}
          onValueChange={(value) => handleFilterChange("supplierId", value)}
        >
          <SelectTrigger 
            id="filter-supplier" 
            className="h-9 text-sm border-slate-200 dark:border-slate-700 focus:ring-blue-500"
          >
            <SelectValue placeholder="All Suppliers" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all" className="text-sm">All Suppliers</SelectItem>
            {suppliers.map(supplier => (
              <SelectItem key={supplier.id} value={supplier.id} className="text-sm">
                {supplier.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        {filters.supplierId !== "all" && (
          <div className="mt-1.5 flex">
            <Badge 
              variant="outline" 
              className="text-xs py-0 bg-indigo-50 dark:bg-indigo-900/20 border-indigo-200 dark:border-indigo-800 text-indigo-700 dark:text-indigo-300 gap-1"
            >
              {suppliers.find(s => s.id === filters.supplierId)?.name || 'Selected Supplier'}
              <button 
                onClick={() => handleFilterChange("supplierId", "all")}
                className="rounded-full text-indigo-500 dark:text-indigo-400 hover:bg-indigo-100 dark:hover:bg-indigo-800/40"
              >
                <X className="h-3 w-3" />
              </button>
            </Badge>
          </div>
        )}
      </div>

      <div>
        <Label htmlFor="filter-paymentStatus" className="text-xs font-medium flex items-center mb-1.5">
          <BadgeIndianRupee className="h-3.5 w-3.5 mr-1.5 text-slate-500 dark:text-slate-400" />
          Payment Status
        </Label>
        <Select 
          value={filters.paymentStatus}
          onValueChange={(value) => handleFilterChange("paymentStatus", value)}
        >
          <SelectTrigger 
            id="filter-paymentStatus" 
            className="h-9 text-sm border-slate-200 dark:border-slate-700 focus:ring-blue-500"
          >
            <SelectValue placeholder="All Statuses" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all" className="text-sm">All Statuses</SelectItem>
            {paymentStatuses.map(status => (
              <SelectItem key={status} value={status} className="text-sm">
                {status}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        {filters.paymentStatus !== "all" && (
          <div className="mt-1.5 flex">
            <Badge 
              variant="outline" 
              className={cn(
                "text-xs py-0 gap-1",
                filters.paymentStatus === "Paid" ? 
                  "bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800 text-green-700 dark:text-green-300" :
                filters.paymentStatus === "Pending" ?
                  "bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800 text-amber-700 dark:text-amber-300" :
                filters.paymentStatus === "Initiated" ?
                  "bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800 text-blue-700 dark:text-blue-300" :
                  "bg-slate-50 dark:bg-slate-900/20 border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-300"
              )}
            >
              {filters.paymentStatus}
              <button 
                onClick={() => handleFilterChange("paymentStatus", "all")}
                className="rounded-full hover:bg-slate-100 dark:hover:bg-slate-800/40"
              >
                <X className="h-3 w-3" />
              </button>
            </Badge>
          </div>
        )}
      </div>

      {/* Summary Section */}
      {(filters.orderId || filters.lrNumber || filters.supplierId !== "all" || filters.paymentStatus !== "all") && (
        <div className="mt-6 pt-4 border-t border-slate-200 dark:border-slate-700">
          <div className="flex justify-between text-xs text-slate-500 dark:text-slate-400 mb-1">
            <span>Results:</span>
            <span className="font-medium text-slate-700 dark:text-slate-300">{filteredTrips.length} trips</span>
          </div>
          <div className="flex justify-between text-xs text-slate-500 dark:text-slate-400">
            <span>Active Filters:</span>
            <span className="font-medium text-slate-700 dark:text-slate-300">
              {(filters.orderId ? 1 : 0) + 
               (filters.lrNumber ? 1 : 0) + 
               (filters.supplierId !== "all" ? 1 : 0) + 
               (filters.paymentStatus !== "all" ? 1 : 0)}
            </span>
          </div>
        </div>
      )}
    </div>
  );

  useEffect(() => {
    // Only set the sidebar content if the function is provided
    if (setDynamicSidebarContent) {
      // Generate the sidebar content
      const sidebarContent = renderSidebarFilters();
      // Set it
      setDynamicSidebarContent(sidebarContent);
    }
    
    // Cleanup function to remove content when component unmounts
    return () => {
      if (setDynamicSidebarContent) {
        setDynamicSidebarContent(null);
      }
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [setDynamicSidebarContent, filters]); // Re-run only when filters change

  // Handle payment actions
  const handlePaymentAction = async (tripId: string, paymentType: "advance" | "balance") => {
    try {
      // Find the trip in our current data
      const trip = allTrips.find(t => t.id === tripId);
      if (!trip) {
        toast({
          title: "Trip Not Found",
          description: "Could not find trip details for payment processing.",
          variant: "destructive"
        });
        return;
      }
      
      // Determine the appropriate field to update
      const paymentField = paymentType === "advance" ? "advancePaymentStatus" : "balancePaymentStatus";
      
      // Get the current status
      const currentStatus = trip[paymentField];
      let newStatus;
      
      // Determine the next status based on current status
      if (currentStatus === "Not Started") {
        newStatus = "Initiated";
      } else if (currentStatus === "Initiated") {
        newStatus = "Pending";
      } else if (currentStatus === "Pending") {
        newStatus = "Paid";
      } else {
        toast({
          title: "Cannot Process Payment",
          description: `Payment status '${currentStatus}' cannot be updated further.`,
          variant: "destructive"
        });
        return;
      }
      
      // Show processing indicator
      toast({
        title: "Processing Payment",
        description: `Updating ${paymentType} payment to ${newStatus}...`,
        duration: 2000,
      });
      
      console.log(`Processing ${paymentType} payment for trip ${tripId}: ${currentStatus} → ${newStatus}`);
      
      // Predict trip status change based on payment type and new status
      let expectedNewTripStatus = trip.status;
      if (paymentType === "advance" && newStatus === "Paid" && trip.status === "Booked") {
        expectedNewTripStatus = "In Transit";
      } else if (paymentType === "balance" && newStatus === "Paid" && (trip.status === "In Transit" || trip.status === "Delivered")) {
        expectedNewTripStatus = "Completed";
      }
      
      // First, update the local state immediately for better responsiveness
      const updatedLocalTrips = allTrips.map(t => {
        if (t.id === tripId) {
          const updatedTrip = { ...t };
          updatedTrip[paymentField] = newStatus;
          
          // Also update trip status for immediate UI feedback if payment is marked as Paid
          if (paymentType === "advance" && newStatus === "Paid" && t.status === "Booked") {
            updatedTrip.status = "In Transit";
            
            // If balance payment is Not Started, set it to ready for processing
            if (updatedTrip.balancePaymentStatus === "Not Started") {
              // Don't auto-initiate balance payment, just keep it in Not Started
              // This ensures it will appear in the Balance Payment queue
              console.log(`Trip ${updatedTrip.orderNumber}: Advance marked as Paid, Balance payment ready for processing`);
            }
          } else if (paymentType === "balance" && newStatus === "Paid" && (t.status === "In Transit" || t.status === "Delivered")) {
            updatedTrip.status = "Completed";
          }
          
          return updatedTrip;
        }
        return t;
      });
      
      // Update local state for UI responsiveness
      setAllTrips(updatedLocalTrips);
      
      // Also update filtered trips for immediate UI feedback
      setFilteredTrips(prev => prev.map(t => {
        if (t.id === tripId) {
          const updatedTrip = { ...t };
          updatedTrip[paymentField] = newStatus;
          
          // Also update trip status for immediate UI feedback if payment is marked as Paid
          if (paymentType === "advance" && newStatus === "Paid" && t.status === "Booked") {
            updatedTrip.status = "In Transit";
            
            // If balance payment is Not Started, set it to ready for processing
            if (updatedTrip.balancePaymentStatus === "Not Started") {
              // Don't auto-initiate balance payment, just keep it in Not Started
              // This ensures it will appear in the Balance Payment queue
              console.log(`Trip ${updatedTrip.orderNumber}: Advance marked as Paid, Balance payment ready for processing`);
            }
          } else if (paymentType === "balance" && newStatus === "Paid" && (t.status === "In Transit" || t.status === "Delivered")) {
            updatedTrip.status = "Completed";
          }
          
          return updatedTrip;
        }
        return t;
      }));
      
      // Create the payment update
      const paymentUpdate = { [paymentField]: newStatus };
      
      // Store payment status in localStorage for persistence across refreshes
      try {
        const paymentKey = `payment_${tripId}_${paymentType}`;
        localStorage.setItem(paymentKey, newStatus);
        console.log(`Saved payment status to localStorage: ${paymentKey} = ${newStatus}`);
      } catch (err) {
        console.error("Failed to save payment status to localStorage:", err);
      }
      
      // Let the API handle the transaction
      try {
        console.log(`Calling API to update payment status to ${newStatus}`);
        const updatedTrip = await api.trips.updatePaymentStatus(tripId, paymentUpdate);
        
        console.log(`Payment update successful:`, updatedTrip);
        
        // Verify expected trip status change was applied if payment was marked as Paid
        if (newStatus === "Paid" && expectedNewTripStatus !== trip.status && updatedTrip.status !== expectedNewTripStatus) {
          console.warn(`⚠️ Trip status was not updated as expected! Expected: ${expectedNewTripStatus}, Got: ${updatedTrip.status}`);
          
          // Try to fix it with a direct status update
          try {
            console.log(`Attempting to fix trip status with direct update to ${expectedNewTripStatus}`);
            await api.trips.updateStatus(tripId, expectedNewTripStatus);
            updatedTrip.status = expectedNewTripStatus;
          } catch (statusError) {
            console.error("Failed to fix trip status:", statusError);
          }
        }
        
        // Check what changed and show appropriate toast messages
        let changes = [];
        
        // Check if payment status changed
        if (trip[paymentField] !== updatedTrip[paymentField]) {
          changes.push(`${paymentType} payment marked as ${updatedTrip[paymentField]}`);
        }
        
        // Check if trip status changed
        if (trip.status !== updatedTrip.status) {
          changes.push(`trip status changed to ${updatedTrip.status}`);
        }
        
        // Announce the changes
        toast({
          title: "Payment Processed",
          description: changes.join(', '),
          duration: 4000,
        });
        
        // Emit special FORCE_REFRESH event to ensure all components update
        events.emit(EVENT_TYPES.FORCE_REFRESH_REQUIRED, {
          source: "PaymentDashboard",
          action: "payment_processed",
          tripId,
          paymentType,
          timestamp: Date.now()
        });
        
        // Emit event to notify other components
        events.emit(EVENT_TYPES.PAYMENT_STATUS_CHANGED, {
          tripId,
          paymentType,
          oldStatus: trip[paymentField],
          newStatus: newStatus,
          tripStatusChanged: trip.status !== updatedTrip.status,
          oldTripStatus: trip.status,
          newTripStatus: updatedTrip.status,
          timestamp: Date.now()
        });
        
        // Do a full refresh of our data after a short delay
        setTimeout(async () => {
          await forceRefreshPayments();
        }, 300);
      } catch (error) {
        console.error("Error processing payment update:", error);
        
        // Reset the local state to match the server
        toast({
          title: "Payment Processing Error",
          description: "There was an error processing the payment. Refreshing data...",
          variant: "destructive",
          duration: 3000,
        });
        
        forceRefreshPayments();
        throw error; // Let the outer catch handle it
      }
    } catch (error) {
      console.error(`Error processing payment:`, error);
      
      let errorMessage = "Payment processing failed. Please try again.";
      if (error.response?.data?.message) {
        errorMessage = error.response.data.message;
      } else if (error.message) {
        errorMessage = error.message;
      }
      
      toast({
        title: "Payment Error",
        description: errorMessage,
        variant: "destructive",
        duration: 5000,
      });
    }
  };
  
  // Helper function to apply all filters to a trips array
  const applyAllFilters = (tripsArray: Trip[]) => {
    let tempTrips = tripsArray;
    
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
    if (filters.supplierId) {
      tempTrips = tempTrips.filter(trip => trip.supplierId === filters.supplierId);
    }
    if (filters.paymentStatus) {
      tempTrips = tempTrips.filter(trip => 
        trip.advancePaymentStatus === filters.paymentStatus || 
        trip.balancePaymentStatus === filters.paymentStatus
      );
    }
    
    // Apply search term if present
    if (searchTerm.trim()) {
      const lowerCaseTerm = searchTerm.toLowerCase();
      tempTrips = tempTrips.filter(
      (trip) =>
          trip.orderNumber.toLowerCase().includes(lowerCaseTerm) ||
          trip.lrNumbers.some(lr => lr.toLowerCase().includes(lowerCaseTerm)) ||
          trip.clientName.toLowerCase().includes(lowerCaseTerm) ||
          trip.supplierName.toLowerCase().includes(lowerCaseTerm)
      );
    }
    
    return tempTrips;
  };

  // Modify handleProcessPayment to use the new payment flow
  const handleProcessPayment = (tripId: string, type: "advance" | "balance") => {
    handlePaymentAction(tripId, type);
  };

  const handleExportToCSV = (type: "advance" | "balance" | "history") => {
    let tripsToExport: Trip[] = [];
    let filename = "";
    
    // Determine which trips to export based on the tab
    switch (type) {
      case "advance":
        tripsToExport = advancePayments;
        filename = "advance_payments_export.csv";
        break;
      case "balance":
        tripsToExport = podPayments;
        filename = "balance_payments_export.csv";
        break;
      case "history":
        tripsToExport = completedPayments;
        filename = "payment_history_export.csv";
        break;
      default:
        tripsToExport = filteredTrips;
        filename = "all_payments_export.csv";
    }
    
    if (tripsToExport.length === 0) {
      toast({
        title: "No Data to Export",
        description: "There are no payments to export in this category.",
        variant: "destructive",
      });
      return;
    }
    
    try {
      // Create CSV header
      const headers = [
        "Order ID",
        "Trip Date",
        "LR Number",
        "Supplier",
        "Client",
        "From",
        "To",
        "Advance Amount",
        "Advance Status",
        "Balance Amount", 
        "Balance Status",
        "Total Freight",
        "Trip Status"
      ].join(",");
      
      // Create CSV rows
      const rows = tripsToExport.map(trip => {
        return [
          `"${trip.orderNumber}"`,
          `"${trip.pickupDate}"`,
          `"${trip.lrNumbers[0] || ""}"`,
          `"${trip.supplierName}"`,
          `"${trip.clientName}"`,
          `"${trip.clientCity}"`,
          `"${trip.destinationCity}"`,
          trip.advanceSupplierFreight,
          `"${trip.advancePaymentStatus}"`,
          trip.balanceSupplierFreight,
          `"${trip.balancePaymentStatus}"`,
          trip.supplierFreight,
          `"${trip.status}"`
        ].join(",");
      }).join("\n");
      
      // Combine header and rows
      const csvContent = `${headers}\n${rows}`;
      
      // Create a Blob and download link
      const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.setAttribute("href", url);
      link.setAttribute("download", filename);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      toast({
        title: "Export Completed",
        description: `${tripsToExport.length} payment records have been exported to CSV.`,
        duration: 3000,
      });
    } catch (error) {
      console.error("Error exporting to CSV:", error);
      toast({
        title: "Export Failed",
        description: "There was an error creating the CSV export.",
        variant: "destructive",
      });
    }
  };

  const handleExportToExcel = () => {
    // Modify to export all payments
    handleExportToCSV("history");
  };

  const handleDocumentUpload = (entityId: string, fileData: FileData) => {
    addDocument(entityId, fileData);
    
    toast({
      title: "Payment Document Added",
      description: `${fileData.name} has been uploaded for payment record`,
    });
  };

  // Add a more thorough refresh function for forced reloads
  const forceRefreshPayments = async () => {
    if (isRefreshing) return; // Prevent multiple refreshes
    
    setIsRefreshing(true);
    try {
      console.log("Force-refreshing payment data");
      
      // Clear the current data
      setAllTrips([]);
      setFilteredTrips([]);
      
      // Short delay to ensure UI updates
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Fetch fresh data
      const timestamp = Date.now(); // For cache busting
      console.log(`Fetching fresh payment data at ${new Date().toISOString()}`);
      
      const freshTrips = await api.trips.getAll();
      console.log(`Received ${freshTrips.length} trips from server`);
      
      // Log payment statuses for debugging
      freshTrips.forEach(trip => {
        console.log(`Trip ${trip.orderNumber}: Status=${trip.status}, Advance=${trip.advancePaymentStatus}, Balance=${trip.balancePaymentStatus}`);
      });
      
      // Update our data
      setAllTrips(freshTrips);
      
      // Re-apply filters
      applyFilters();
      
      // Show toast only for user-initiated refreshes
      toast({
        title: "Payment Data Refreshed",
        description: `Loaded ${freshTrips.length} trips with latest payment data`,
        duration: 3000,
      });
      
      // Emit events to notify other components
      events.emit(EVENT_TYPES.REFRESH_REQUIRED);
    } catch (error) {
      console.error("Error refreshing payment data:", error);
      toast({
        title: "Refresh Failed",
        description: "Could not refresh payment data. Please try again.",
        variant: "destructive"
      });
    } finally {
      setIsRefreshing(false);
    }
  };

  // Helper function to get button text based on payment status
  const getButtonText = (status: string): string => {
    // Use type assertion to treat status as string for comparison
    const paymentStatus = status as string;
    if (paymentStatus === "Not Started") return "Initiate";
    if (paymentStatus === "Initiated") return "Mark Pending";
    if (paymentStatus === "Pending") return "Mark Paid";
    return "Process";
  };

  // Now add a function to handle the adjustment
  const handleAmountAdjustment = (tripId: string) => {
    const trip = allTrips.find(t => t.id === tripId);
    if (!trip) return;
    
    // Find if trip has pending changes in session storage
    let pendingChanges;
    try {
      pendingChanges = JSON.parse(sessionStorage.getItem('pendingTripChanges') || '{}')[tripId];
    } catch (e) {
      console.error("Error parsing pending changes from session storage:", e);
      pendingChanges = null;
    }
    
    // Determine the actual balance amount (from session storage if available)
    const actualBalanceAmount = pendingChanges?.balanceSupplierFreight || trip.balanceSupplierFreight;
    
    // Find the original balance amount from when payment was initiated
    let originalBalanceAmount = trip.balanceSupplierFreight;
    
    // Check local storage for stored original amount
    try {
      const storedAmount = localStorage.getItem(`original_balance_${tripId}`);
      if (storedAmount) {
        originalBalanceAmount = Number(storedAmount);
      } else {
        // If no stored amount, we'll store the current amount for future comparisons
        localStorage.setItem(`original_balance_${tripId}`, String(trip.balanceSupplierFreight));
      }
    } catch (e) {
      console.error("Error handling stored balance amounts:", e);
    }
    
    // Set up adjustment dialog data
    setAdjustmentTripId(tripId);
    setOriginalAmount(originalBalanceAmount);
    setNewAmount(actualBalanceAmount);
    setAdjustmentDialogOpen(true);
  };

  // Add this function to accept the new amount
  const confirmAmountAdjustment = async () => {
    try {
      const trip = allTrips.find(t => t.id === adjustmentTripId);
      if (!trip) return;
      
      // Store the new amount as the "original" for future comparisons
      localStorage.setItem(`original_balance_${adjustmentTripId}`, String(newAmount));
      
      // Update UI to reflect the adjusted amount (remove amount changed indicator)
      const updatedTrips = allTrips.map(t => {
        if (t.id === adjustmentTripId) {
          return {
            ...t,
            balanceSupplierFreight: newAmount,
            amountChanged: false
          };
        }
        return t;
      });
      
      setAllTrips(updatedTrips);
      setFilteredTrips(prev => prev.map(t => {
        if (t.id === adjustmentTripId) {
          return {
            ...t,
            balanceSupplierFreight: newAmount,
            amountChanged: false
          };
        }
        return t;
      }));
      
      // Try to update the amount on the server if possible
      try {
        await api.trips.update(adjustmentTripId, { 
          balanceSupplierFreight: newAmount 
        });
        
        toast({
          title: "Amount Adjusted",
          description: `Balance amount updated to ₹${newAmount.toLocaleString()}`,
          duration: 3000,
        });
      } catch (error) {
        console.error("Failed to update balance amount on server:", error);
        toast({
          title: "Local Update Only",
          description: "Balance amount was updated locally but couldn't be saved to the server.",
          variant: "default",
          duration: 4000,
        });
      }
    } catch (error) {
      console.error("Error adjusting amount:", error);
      toast({
        title: "Adjustment Failed",
        description: "There was an error adjusting the balance amount.",
        variant: "destructive",
        duration: 3000,
      });
    }
  };

  return (
    <div className="container mx-auto px-4 py-6 space-y-6">
      {/* Enhanced Header Section */}
      <div className="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-950/20 dark:to-indigo-950/20 rounded-lg p-5 mb-6">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100 flex items-center">
              <BadgeIndianRupee className="mr-2 h-5 w-5 text-blue-600 dark:text-blue-400" />
              Payment Management
            </h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              Process, track and export advance and balance payments for all trips
            </p>
          </div>
          <div className="flex items-center gap-2">
            <div className="relative group">
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleExportToCSV("history")}
                className="border-blue-200 bg-white/90 hover:bg-blue-50 dark:border-blue-800 dark:bg-blue-950/50 dark:hover:bg-blue-900/50"
              >
                <Download size={14} className="mr-1.5" />
                Export All Payments
              </Button>
              <div className="absolute right-0 top-full mt-1 w-48 bg-white shadow-lg rounded-md border border-slate-200 dark:bg-slate-800 dark:border-slate-700 overflow-hidden hidden group-hover:block z-10">
                <div className="py-1">
                  <button 
                    onClick={() => handleExportToCSV("advance")} 
                    className="w-full text-left px-4 py-2 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 flex items-center"
                  >
                    <CreditCard className="h-3.5 w-3.5 mr-2 text-blue-600 dark:text-blue-400" />
                    Advance Payments
                  </button>
                  <button 
                    onClick={() => handleExportToCSV("balance")} 
                    className="w-full text-left px-4 py-2 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 flex items-center"
                  >
                    <DollarSign className="h-3.5 w-3.5 mr-2 text-green-600 dark:text-green-400" />
                    Balance Payments
                  </button>
                  <button 
                    onClick={() => handleExportToCSV("history")} 
                    className="w-full text-left px-4 py-2 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 flex items-center"
                  >
                    <Layers className="h-3.5 w-3.5 mr-2 text-purple-600 dark:text-purple-400" />
                    All Payment History
                  </button>
                </div>
              </div>
            </div>
            <Button
              variant="outline"
              size="sm"
              onClick={forceRefreshPayments}
              disabled={isRefreshing || isLoading}
              className="border-blue-200 bg-white/90 hover:bg-blue-50 dark:border-blue-800 dark:bg-blue-950/50 dark:hover:bg-blue-900/50"
            >
              <RefreshCw size={14} className={`mr-1.5 ${isRefreshing ? 'animate-spin' : ''}`} />
              {isRefreshing ? 'Refreshing...' : 'Refresh'}
            </Button>
          </div>
        </div>
      </div>

      {/* Tabs and Main Content */}
      <Tabs defaultValue="advance" className="w-full">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 mb-6 border-b pb-4">
          <TabsList className="grid w-full sm:w-auto grid-cols-3 h-10 items-stretch bg-slate-100 dark:bg-slate-800/50">
            <TabsTrigger value="advance" className="text-sm px-4 data-[state=active]:bg-white dark:data-[state=active]:bg-slate-700">
              <CreditCard className="h-4 w-4 mr-2 text-blue-600 dark:text-blue-400" />
              Advance Payments
            </TabsTrigger>
            <TabsTrigger value="pod" className="text-sm px-4 data-[state=active]:bg-white dark:data-[state=active]:bg-slate-700">
              <DollarSign className="h-4 w-4 mr-2 text-green-600 dark:text-green-400" />
              Balance Payments
            </TabsTrigger>
            <TabsTrigger value="history" className="text-sm px-4 data-[state=active]:bg-white dark:data-[state=active]:bg-slate-700">
              <Layers className="h-4 w-4 mr-2 text-purple-600 dark:text-purple-400" />
              Payment History
            </TabsTrigger>
        </TabsList>
          <div className="flex items-center gap-3 w-full sm:w-auto">
            <div className="relative flex-1 sm:flex-initial sm:w-72">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                placeholder="Search by Order ID, LR, Client..."
                    value={searchTerm}
                onChange={(e) => handleGeneralSearch(e.target.value, filteredTrips)}
                className="pl-9 h-10 w-full border-slate-200 dark:border-slate-700 focus:ring-blue-500"
                  />
            </div>
                  <Button
                    variant="ghost"
              size="icon"
              onClick={() => document.getElementById('filter-sidebar-toggle')?.click()}
              className="h-10 w-10 rounded-full bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700"
            >
              <Filter size={16} />
                  </Button>
          </div>
        </div>

        {/* Loading State */}
        {isLoading ? (
          <div className="space-y-6">
            {/* Skeleton for the tabs */}
            <div className="flex items-center space-x-4 mb-6">
              <div className="w-64 h-10 bg-slate-100 dark:bg-slate-800 rounded-md"></div>
              <div className="flex-1"></div>
              <Skeleton className="h-10 w-72" />
              <Skeleton className="h-10 w-10 rounded-full" />
            </div>
            
            {/* Skeleton for the table */}
            <Card className="shadow-sm border border-slate-200 dark:border-slate-800 overflow-hidden rounded-lg">
              <CardHeader className="px-6 py-4 bg-slate-50/80 dark:bg-slate-800/50">
                <div className="flex justify-between">
                  <Skeleton className="h-6 w-48" />
                  <Skeleton className="h-4 w-24" />
                </div>
              </CardHeader>
              <CardContent className="p-6">
                <div className="space-y-4">
                  {/* Skeleton table header */}
                  <div className="flex border-b border-slate-200 dark:border-slate-700 pb-3">
                    <Skeleton className="h-4 w-24 mr-6" />
                    <Skeleton className="h-4 w-24 mr-6" />
                    <Skeleton className="h-4 w-32 mr-6" />
                    <Skeleton className="h-4 w-24 mr-6" />
                    <Skeleton className="h-4 w-32 mr-6" />
                    <Skeleton className="h-4 w-32 mr-6" />
                    <Skeleton className="h-4 w-24 mr-6" />
                    <Skeleton className="h-4 w-32" />
                  </div>
                  
                  {/* Skeleton table rows */}
                  {[...Array(5)].map((_, index) => (
                    <div key={index} className={`flex items-center py-4 ${index < 4 ? 'border-b border-slate-200 dark:border-slate-700' : ''}`}>
                      <div className="flex flex-col space-y-1 w-24 mr-6">
                        <Skeleton className="h-5 w-20" />
                        <Skeleton className="h-3 w-16" />
                      </div>
                      <Skeleton className="h-5 w-24 mr-6" />
                      <div className="flex items-center w-32 mr-6">
                        <Skeleton className="h-8 w-8 rounded-full mr-2" />
                        <Skeleton className="h-5 w-20" />
                      </div>
                      <Skeleton className="h-5 w-24 mr-6" />
                      <Skeleton className="h-5 w-32 mr-6" />
                      <Skeleton className="h-5 w-24 mr-6" />
                      <Skeleton className="h-8 w-24 mr-6" />
                      <div className="flex space-x-2">
                        <Skeleton className="h-8 w-20" />
                        <Skeleton className="h-8 w-8" />
                      </div>
                    </div>
                  ))}
                  
                  {/* Pulsing animation for a better loading effect */}
                  <div className="h-1 w-full overflow-hidden">
                    <div className="h-full w-1/3 bg-primary rounded-full animate-pulse"></div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        ) : (
          <>
            {/* Advance Payments Tab */} 
            <TabsContent value="advance" className="mt-0">
              <Card className="shadow-sm border border-slate-200 dark:border-slate-800 overflow-hidden rounded-lg"> 
                <CardHeader className="flex flex-row items-center justify-between px-6 py-4 bg-slate-50/80 dark:bg-slate-800/50">
                  <div>
                    <CardTitle className="text-base font-medium">Advance Payment Queue</CardTitle>
                    <p className="text-xs text-muted-foreground mt-1">Manage and process advance payments for booked trips</p>
                  </div>
                  <div className="flex items-center">
                    <Button
                      variant="outline"
                      size="sm" 
                      onClick={() => handleExportToCSV("advance")}
                      className="border-blue-200 bg-white/90 hover:bg-blue-50 dark:border-blue-800 dark:bg-blue-950/50 dark:hover:bg-blue-900/50"
                    >
                      <Download size={14} className="mr-1.5" />
                      Export Advance Payments
                    </Button>
                    <span className="font-medium ml-4 text-sm text-muted-foreground">
                      <span className="mr-1.5">{advancePayments.length}</span> 
                      payments ready
                    </span>
                  </div>
                </CardHeader>
                <CardContent className="p-0">
                  <div className="overflow-hidden">
                <div className="overflow-x-auto">
                      <Table className="w-full">
                        <TableHeader className="bg-slate-50 dark:bg-slate-800/60">
                          <TableRow className="border-b border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800/80">
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Trip Date</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Order ID</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">LR Number</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Supplier</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Client</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Advance Amt (₹ | %)</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Status</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                        <TableBody className="divide-y divide-slate-200 dark:divide-slate-700">
                      {advancePayments.length > 0 ? (
                            advancePayments.map((trip, index) => (
                              <TableRow 
                                key={`adv-${trip.id}`} 
                                className={cn(
                                  "hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors duration-150",
                                  index % 2 !== 0 && "bg-slate-50/50 dark:bg-slate-800/20"
                                )}
                              >
                                <TableCell className="px-6 py-4 whitespace-nowrap text-sm">
                                  <div className="flex flex-col">
                                    <span>{trip.pickupDate}</span>
                                    <span className="text-xs text-slate-500 dark:text-slate-400">{trip.pickupTime}</span>
                                  </div>
                                </TableCell>
                                <TableCell className="font-medium px-6 py-4 whitespace-nowrap">
                                  <Link 
                                    to={`/payments/${trip.orderNumber}`} 
                                    className="text-blue-600 dark:text-blue-400 hover:underline font-semibold flex items-center"
                                  >
                                    {trip.orderNumber}
                                  </Link>
                                </TableCell>
                                <TableCell className="px-6 py-4 whitespace-nowrap">
                                  <a href="#" className="text-blue-600 dark:text-blue-400 hover:underline">
                                    {trip.lrNumbers[0]}
                                  </a>
                                </TableCell>
                                <TableCell className="px-6 py-4 whitespace-nowrap text-sm">
                                  <div className="flex items-center">
                                    <div className="h-8 w-8 rounded-full bg-indigo-100 dark:bg-indigo-900/50 flex items-center justify-center text-indigo-700 dark:text-indigo-300 font-medium text-xs mr-2">
                                      {trip.supplierName.charAt(0) + trip.supplierName.split(' ')[1]?.charAt(0) || ''}
                                    </div>
                                    <div className="flex items-center">
                                      <span>{trip.supplierName}</span>
                                      <SupplierInfoDialog supplierId={trip.supplierId} supplierName={trip.supplierName} />
                                    </div>
                                  </div>
                                </TableCell>
                                <TableCell className="px-6 py-4 whitespace-nowrap text-sm text-slate-600 dark:text-slate-300">{trip.clientName}</TableCell>
                                <TableCell className="text-right px-6 py-4 whitespace-nowrap">
                                  <div className="flex flex-col items-end">
                                    <span className="font-semibold text-slate-900 dark:text-white">₹{trip.advanceSupplierFreight.toLocaleString()}</span>
                                    <span className="text-xs text-blue-600 dark:text-blue-400 font-medium">
                                      {(trip.advanceSupplierFreight / trip.supplierFreight * 100).toFixed(1)}% of total
                                    </span>
                                  </div>
                                </TableCell>
                                <TableCell className="px-6 py-4 whitespace-nowrap">
                                  <div className="w-28"> {/* Fixed width for consistent layout */}
                                    <PaymentActionButton
                                      entityId={trip.id}
                                      currentStatus={trip.advancePaymentStatus}
                                      paymentType="advance"
                                      onActionClick={handlePaymentAction}
                                    />
                                  </div>
                                </TableCell>
                                <TableCell className="px-6 py-4 whitespace-nowrap">
                                  <div className="flex items-center space-x-2">
                                    {/* Only show Process button if payment is not already paid */}
                                    {!trip.advancePaymentStatus.toLowerCase().includes('paid') && (
                                <Button
                                        variant="default"
                                  size="sm"
                                        className="h-8 bg-green-600 hover:bg-green-700 text-white"
                                  onClick={() => handleProcessPayment(trip.id, "advance")}
                                >
                                        <CreditCard size={14} className="mr-1.5" /> 
                                        {getButtonText(trip.advancePaymentStatus)}
                                </Button>
                                    )}
                                    <FileActions 
                                      id={`PMT-ADV-${trip.id}`}
                                      type="payment"
                                      entityName={trip.orderNumber}
                                      documentType="Payment Receipt"
                                      onSuccess={(fileData) => handleDocumentUpload(`PMT-ADV-${trip.id}`, fileData)}
                                      existingFiles={getDocuments(`PMT-ADV-${trip.id}`)}
                                    />
                              </div>
                            </TableCell>
                          </TableRow>
                        ))
                      ) : (
                        <TableRow>
                              <TableCell colSpan={8} className="text-center py-16 text-slate-500 dark:text-slate-400">
                                <Inbox className="h-12 w-12 mx-auto mb-3 text-slate-300 dark:text-slate-600" />
                                <p className="font-medium text-slate-700 dark:text-slate-300">No Advance Payments Found</p>
                                <p className="text-sm mt-1">All advance payments are settled or none match your criteria.</p>
                          </TableCell>
                        </TableRow>
                      )}
                    </TableBody>
                  </Table>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* POD Payments Tab */}
            <TabsContent value="pod" className="mt-0">
              <Card className="shadow-sm border border-slate-200 dark:border-slate-800 overflow-hidden rounded-lg">
                <CardHeader className="flex flex-row items-center justify-between px-6 py-4 bg-slate-50/80 dark:bg-slate-800/50">
                  <div>
                    <CardTitle className="text-base font-medium">Balance Payment Queue (After POD)</CardTitle>
                    <p className="text-xs text-muted-foreground mt-1">Process balance payments after proof of delivery</p>
                  </div>
                  <div className="flex items-center">
                    <Button
                      variant="outline"
                      size="sm" 
                      onClick={() => handleExportToCSV("balance")}
                      className="border-blue-200 bg-white/90 hover:bg-blue-50 dark:border-blue-800 dark:bg-blue-950/50 dark:hover:bg-blue-900/50"
                    >
                      <Download size={14} className="mr-1.5" />
                      Export Balance Payments
                    </Button>
                    <span className="font-medium ml-4 text-sm text-muted-foreground">
                      <span className="mr-1.5">{podPayments.length}</span> 
                      POD payments pending
                    </span>
                  </div>
                </CardHeader>
                <CardContent className="p-0">
                  <div className="overflow-hidden">
                <div className="overflow-x-auto">
                      <Table className="w-full">
                        <TableHeader className="bg-slate-50 dark:bg-slate-800/60">
                          <TableRow className="border-b border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800/80">
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">POD Date</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Order ID</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">LR Number</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Supplier</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Client</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Balance Amt (₹ | %)</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Status</TableHead>
                            <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                        <TableBody className="divide-y divide-slate-200 dark:divide-slate-700">
                      {podPayments.length > 0 ? (
                            podPayments.map((trip, index) => (
                              <TableRow 
                                key={`pod-${trip.id}`}
                                className={cn(
                                  "hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors duration-150",
                                  index % 2 !== 0 && "bg-slate-50/50 dark:bg-slate-800/20"
                                )}
                              >
                                <TableCell className="px-6 py-4 whitespace-nowrap text-sm">
                                  <div className="flex flex-col">
                                    <span>
                                      {new Date(
                                        new Date(trip.pickupDate).getTime() + 3 * 24 * 60 * 60 * 1000
                                      ).toLocaleDateString()}
                                    </span>
                                    <span className="text-xs text-green-600 dark:text-green-400 px-1.5 py-0.5 bg-green-50 dark:bg-green-900/20 rounded inline-block mt-1 w-fit">
                                      POD Received
                                    </span>
                                  </div>
                                </TableCell>
                                <TableCell className="font-medium px-6 py-4 whitespace-nowrap">
                                  <Link 
                                    to={`/payments/${trip.orderNumber}`} 
                                    className="text-blue-600 dark:text-blue-400 hover:underline font-semibold flex items-center"
                                  >
                                    {trip.orderNumber}
                                  </Link>
                                </TableCell>
                                <TableCell className="px-6 py-4 whitespace-nowrap">
                                  <a href="#" className="text-blue-600 dark:text-blue-400 hover:underline">
                                    {trip.lrNumbers[0]}
                                  </a>
                                </TableCell>
                                <TableCell className="px-6 py-4 whitespace-nowrap text-sm">
                                  <div className="flex items-center">
                                    <div className="h-8 w-8 rounded-full bg-green-100 dark:bg-green-900/50 flex items-center justify-center text-green-700 dark:text-green-300 font-medium text-xs mr-2">
                                      {trip.supplierName.charAt(0) + trip.supplierName.split(' ')[1]?.charAt(0) || ''}
                                    </div>
                                    <div className="flex items-center">
                                      <span>{trip.supplierName}</span>
                                      <SupplierInfoDialog supplierId={trip.supplierId} supplierName={trip.supplierName} />
                                    </div>
                                  </div>
                                </TableCell>
                                <TableCell className="px-6 py-4 whitespace-nowrap text-sm text-slate-600 dark:text-slate-300">{trip.clientName}</TableCell>
                                <TableCell className="text-right px-6 py-4 whitespace-nowrap">
                                  <div className="flex flex-col items-end">
                                    <span className="font-semibold text-slate-900 dark:text-white">₹{trip.balanceSupplierFreight.toLocaleString()}</span>
                                    <span className="text-xs text-green-600 dark:text-green-400 font-medium">
                                      {(trip.balanceSupplierFreight / trip.supplierFreight * 100).toFixed(1)}% of total
                                    </span>
                                  </div>
                                </TableCell>
                                <TableCell className="px-6 py-4 whitespace-nowrap">
                                  <div className="w-28"> {/* Fixed width for consistent layout */}
                                    <PaymentActionButton
                                      entityId={trip.id}
                                      currentStatus={trip.balancePaymentStatus}
                                      paymentType="balance"
                                      onActionClick={handlePaymentAction}
                                    />
                                    
                                    {/* Add Amount Changed badge */}
                                    {hasAmountChanged(trip) && (
                                      <Badge 
                                        variant="outline" 
                                        className="ml-2 mt-1 bg-amber-50 text-amber-600 border-amber-200 hover:bg-amber-100 cursor-pointer"
                                        onClick={() => handleAmountAdjustment(trip.id)}
                                      >
                                        Amount Changed
                                      </Badge>
                                    )}
                                  </div>
                                </TableCell>
                                <TableCell className="px-6 py-4 whitespace-nowrap">
                                  <div className="flex items-center space-x-2">
                                    {/* Only show Process button if payment is not already paid */}
                                    {!trip.balancePaymentStatus.toLowerCase().includes('paid') && (
                                <Button
                                        variant="default"
                                  size="sm"
                                        className="h-8 bg-green-600 hover:bg-green-700 text-white"
                                  onClick={() => handleProcessPayment(trip.id, "balance")}
                                >
                                        <CreditCard size={14} className="mr-1.5" /> 
                                        {getButtonText(trip.balancePaymentStatus)}
                                </Button>
                                    )}
                                    <FileActions 
                                      id={`PMT-BAL-${trip.id}`}
                                      type="payment"
                                      entityName={trip.orderNumber}
                                      documentType="Balance Receipt"
                                      onSuccess={(fileData) => handleDocumentUpload(`PMT-BAL-${trip.id}`, fileData)}
                                      existingFiles={getDocuments(`PMT-BAL-${trip.id}`)}
                                    />
                              </div>
                            </TableCell>
                          </TableRow>
                        ))
                      ) : (
                        <TableRow>
                              <TableCell colSpan={8} className="text-center py-16 text-slate-500 dark:text-slate-400">
                                <Inbox className="h-12 w-12 mx-auto mb-3 text-slate-300 dark:text-slate-600" />
                                <p className="font-medium text-slate-700 dark:text-slate-300">No Balance Payments Found</p>
                                <p className="text-sm mt-1">No trips awaiting balance payment or none match your criteria.</p>
                          </TableCell>
                        </TableRow>
                      )}
                    </TableBody>
                  </Table>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Add Payment History Tab */}
        <TabsContent value="history" className="mt-0">
          <Card className="shadow-sm border border-slate-200 dark:border-slate-800 overflow-hidden rounded-lg">
            <CardHeader className="flex flex-row items-center justify-between px-6 py-4 bg-slate-50/80 dark:bg-slate-800/50">
              <div>
                <CardTitle className="text-base font-medium">Payment History</CardTitle>
                <p className="text-xs text-muted-foreground mt-1">View and export all processed payments for record keeping</p>
              </div>
              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm" 
                  onClick={() => handleExportToCSV("history")}
                  className="border-blue-200 bg-white/90 hover:bg-blue-50 dark:border-blue-800 dark:bg-blue-950/50 dark:hover:bg-blue-900/50"
                >
                  <Download size={14} className="mr-1.5" />
                  Export to CSV
                </Button>
              </div>
            </CardHeader>
            <CardContent className="p-0">
              <div className="overflow-hidden">
                <div className="overflow-x-auto">
                  <Table className="w-full">
                    <TableHeader className="bg-slate-50 dark:bg-slate-800/60">
                      <TableRow className="border-b border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800/80">
                        <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Order ID</TableHead>
                        <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Date</TableHead>
                        <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Supplier</TableHead>
                        <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Client</TableHead>
                        <TableHead className="whitespace-nowrap px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Advance Payment</TableHead>
                        <TableHead className="whitespace-nowrap px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Balance Payment</TableHead>
                        <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Trip Status</TableHead>
                        <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Documents</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody className="divide-y divide-slate-200 dark:divide-slate-700">
                      {completedPayments.length > 0 ? (
                        completedPayments.map((trip, index) => (
                          <TableRow 
                            key={`history-${trip.id}`}
                            className={cn(
                              "hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors duration-150",
                              index % 2 !== 0 && "bg-slate-50/50 dark:bg-slate-800/20"
                            )}
                          >
                            <TableCell className="font-medium px-6 py-4 whitespace-nowrap">
                              <Link 
                                to={`/payments/${trip.orderNumber}`} 
                                className="text-blue-600 dark:text-blue-400 hover:underline font-semibold flex items-center"
                              >
                                {trip.orderNumber}
                              </Link>
                            </TableCell>
                            <TableCell className="px-6 py-4 whitespace-nowrap text-sm">
                              <div className="flex flex-col">
                                <span>{trip.pickupDate}</span>
                                <span className="text-xs text-slate-500 dark:text-slate-400">{trip.pickupTime}</span>
                              </div>
                            </TableCell>
                            <TableCell className="px-6 py-4 whitespace-nowrap text-sm">
                              <div className="flex items-center">
                                <div className="h-8 w-8 rounded-full bg-purple-100 dark:bg-purple-900/50 flex items-center justify-center text-purple-700 dark:text-purple-300 font-medium text-xs mr-2">
                                  {trip.supplierName.charAt(0) + trip.supplierName.split(' ')[1]?.charAt(0) || ''}
                                </div>
                                <span>{trip.supplierName}</span>
                              </div>
                            </TableCell>
                            <TableCell className="px-6 py-4 whitespace-nowrap text-sm text-slate-600 dark:text-slate-300">{trip.clientName}</TableCell>
                            <TableCell className="text-right px-6 py-4 whitespace-nowrap">
                              <div className="flex flex-col items-end">
                                <span className="font-semibold text-slate-900 dark:text-white">₹{trip.advanceSupplierFreight.toLocaleString()}</span>
                                <span className="text-xs mt-1">
                                  <StatusBadge status={trip.advancePaymentStatus} />
                                </span>
                              </div>
                            </TableCell>
                            <TableCell className="text-right px-6 py-4 whitespace-nowrap">
                              <div className="flex flex-col items-end">
                                <span className="font-semibold text-slate-900 dark:text-white">₹{trip.balanceSupplierFreight.toLocaleString()}</span>
                                <span className="text-xs mt-1">
                                  <StatusBadge status={trip.balancePaymentStatus} />
                                </span>
                              </div>
                            </TableCell>
                            <TableCell className="px-6 py-4 whitespace-nowrap">
                              <StatusBadge status={trip.status} />
                            </TableCell>
                            <TableCell className="px-6 py-4 whitespace-nowrap">
                              <div className="flex items-center space-x-2">
                                <FileActions 
                                  id={`PMT-ADV-${trip.id}`}
                                  type="payment"
                                  entityName={trip.orderNumber}
                                  documentType="Payment Receipt"
                                  onSuccess={(fileData) => handleDocumentUpload(`PMT-ADV-${trip.id}`, fileData)}
                                  existingFiles={getDocuments(`PMT-ADV-${trip.id}`)}
                                />
                              </div>
                            </TableCell>
                          </TableRow>
                        ))
                      ) : (
                        <TableRow>
                          <TableCell colSpan={8} className="text-center py-16 text-slate-500 dark:text-slate-400">
                            <Inbox className="h-12 w-12 mx-auto mb-3 text-slate-300 dark:text-slate-600" />
                            <p className="font-medium text-slate-700 dark:text-slate-300">No Payment History Found</p>
                            <p className="text-sm mt-1">There are no completed payments in the system yet.</p>
                          </TableCell>
                        </TableRow>
                      )}
                    </TableBody>
                  </Table>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
          </>
        )}
      </Tabs>
      
      {/* Amount Adjustment Dialog */}
      <AmountAdjustmentDialog
        open={adjustmentDialogOpen}
        onOpenChange={setAdjustmentDialogOpen}
        tripId={adjustmentTripId}
        originalAmount={originalAmount}
        newAmount={newAmount}
        onConfirm={confirmAmountAdjustment}
      />
    </div>
  );
};

export default PaymentDashboard;
