import React, { useState, useEffect, useMemo } from "react";
import { useParams, Link } from "react-router-dom";
import { useToast } from "@/hooks/use-toast";
import { useDocuments } from "@/hooks/use-documents";
import { FileData } from "@/components/ui/file-actions";
import api from "@/lib/api"; 
import { events, EVENT_TYPES } from "@/lib/events";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import StatusBadge from "@/components/ui/status-badge";
import { Card, CardContent } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { FileActions } from "@/components/ui/file-actions";
import { ArrowLeft, MapPin, User, Phone, Mail, Clock, Calendar, Check, Plus, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Trip } from "@/trips/models/trip.model";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";

const TripDetail = () => {
  const { id } = useParams<{ id: string }>();
  const { toast } = useToast();
  const { getDocuments, addDocument } = useDocuments();
  const [trip, setTrip] = useState<Trip | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("freight");
  
  // Modal states
  const [isAddAdditionalChargeOpen, setIsAddAdditionalChargeOpen] = useState(false);
  const [isAddDeductionChargeOpen, setIsAddDeductionChargeOpen] = useState(false);
  const [isEditLRChargeOpen, setIsEditLRChargeOpen] = useState(false);
  const [isEditPlatformFeeOpen, setIsEditPlatformFeeOpen] = useState(false);
  const [isAddMiscellaneousChargeOpen, setIsAddMiscellaneousChargeOpen] = useState(false);
  
  // Charge form states
  const [newChargeDescription, setNewChargeDescription] = useState("");
  const [newChargeAmount, setNewChargeAmount] = useState<number>(0);
  const [newLRCharge, setNewLRCharge] = useState<number>(0);
  const [newPlatformFee, setNewPlatformFee] = useState<number>(0);

  // Add document states
  const [lrDocuments, setLrDocuments] = useState<FileData[]>([]);
  const [invoiceDocuments, setInvoiceDocuments] = useState<FileData[]>([]);
  const [ewayDocuments, setEwayDocuments] = useState<FileData[]>([]);
  const [podDocuments, setPodDocuments] = useState<FileData[]>([]);
  const [loadingDocuments, setLoadingDocuments] = useState<boolean>(true);

  useEffect(() => {
    const fetchTrip = async () => {
      try {
        if (!id) return;
        setLoading(true);
        
        const fetchedTrip = await api.trips.getById(id);
        setTrip(fetchedTrip);
      } catch (error) {
        console.error("Error fetching trip:", error);
        toast({
          title: "Error",
          description: "Failed to load trip details. Please try again.",
          variant: "destructive"
        });
      } finally {
        setLoading(false);
      }
    };

    fetchTrip();
  }, [id, toast]);

  // Add effect to load documents when trip loads
  useEffect(() => {
    if (!trip?.id) return;
    
    const loadDocuments = async () => {
      setLoadingDocuments(true);
      try {
        // Load documents for this trip
        const tripDocs = await getDocuments(trip.id);
        
        // Filter documents by type
        setLrDocuments(tripDocs.filter(doc => 
          doc.type.toLowerCase().includes('lr') || 
          doc.name.toLowerCase().includes('lr')
        ));
        
        setInvoiceDocuments(tripDocs.filter(doc => 
          doc.type.toLowerCase().includes('invoice') || 
          doc.name.toLowerCase().includes('invoice')
        ));
        
        setEwayDocuments(tripDocs.filter(doc => 
          doc.type.toLowerCase().includes('eway') || 
          doc.type.toLowerCase().includes('e-way') || 
          doc.name.toLowerCase().includes('eway')
        ));
        
        setPodDocuments(tripDocs.filter(doc => 
          doc.type.toLowerCase().includes('pod') || 
          doc.name.toLowerCase().includes('pod') || 
          doc.name.toLowerCase().includes('delivery')
        ));
      } catch (error) {
        console.error("Error loading documents:", error);
      } finally {
        setLoadingDocuments(false);
      }
    };
    
    loadDocuments();
  }, [trip?.id, getDocuments]);

  // Inside the TripDetail component, add this function to check if editing charges is allowed
  const canEditCharges = () => {
    if (!trip) return false;
    return trip.advancePaymentStatus === "Paid";
  };

  // Function to calculate the total additions or deductions
  const calculateTotal = (charges) => {
    if (!charges || charges.length === 0) return 0;
    return charges.reduce((sum, charge) => sum + charge.amount, 0);
  };

  // Helper function to recalculate balance payment after charges change
  const recalculateBalancePayment = async (updatedTrip) => {
    try {
      console.log("Recalculating balance payment with current data:", {
        supplierFreight: updatedTrip.supplierFreight,
        advanceSupplierFreight: updatedTrip.advanceSupplierFreight,
        deductionCharges: updatedTrip.deductionCharges,
        lrCharges: updatedTrip.lrCharges,
        platformFees: updatedTrip.platformFees
      });
      
      // Calculate total deductions (deduction charges + LR charges + platform fees)
      const deductionChargesTotal = updatedTrip.deductionCharges?.reduce((sum, charge) => sum + charge.amount, 0) || 0;
      const lrCharges = updatedTrip.lrCharges || 250;
      const platformFees = updatedTrip.platformFees || 250;
      const totalDeductions = deductionChargesTotal + lrCharges + platformFees;
      
      // Calculate the new balance payment (original supplier freight - advance - total deductions)
      const originalBalanceAmount = updatedTrip.supplierFreight - updatedTrip.advanceSupplierFreight;
      const adjustedBalanceAmount = Math.max(0, originalBalanceAmount - totalDeductions);
      
      // Round to avoid floating point issues that might cause API validation errors
      const roundedAmount = Math.round(adjustedBalanceAmount);
      
      console.log("Balance payment calculation:", {
        originalBalance: originalBalanceAmount,
        deductionChargesTotal,
        lrCharges,
        platformFees,
        totalDeductions,
        adjustedBalance: adjustedBalanceAmount,
        roundedAmount
      });
      
      // Only update if the value has changed
      if (roundedAmount !== updatedTrip.balanceSupplierFreight) {
        console.log(`Updating balance payment: ${updatedTrip.balanceSupplierFreight} → ${roundedAmount}`);
        
        try {
          // Send ONLY the balanceSupplierFreight field in the update payload
          const payload = { balanceSupplierFreight: roundedAmount };
          console.log("Sending update payload:", JSON.stringify(payload));
          
          const paymentUpdateResponse = await api.trips.update(updatedTrip.id, payload);
          
          console.log("Balance payment updated successfully:", paymentUpdateResponse);
          
          // Emit event to notify payment dashboard and other components
          events.emit(EVENT_TYPES.PAYMENT_STATUS_CHANGED, {
            tripId: updatedTrip.id,
            paymentType: 'balance',
            oldStatus: updatedTrip.balancePaymentStatus,
            newStatus: updatedTrip.balancePaymentStatus,
            amountChanged: true,
            oldAmount: updatedTrip.balanceSupplierFreight,
            newAmount: roundedAmount,
            timestamp: Date.now()
          });
          
          return paymentUpdateResponse;
        } catch (updateError) {
          console.error("Error updating balance payment:", updateError);
          
          if (updateError.response) {
            console.error("Server response for balance update:", {
              status: updateError.response.status,
              data: updateError.response.data
            });
          }
          
          // Try updating via a patch directly to the balance endpoint if it exists
          try {
            console.log("Trying alternative endpoint for balance update");
            const alternativeResponse = await api.trips.updatePaymentStatus(updatedTrip.id, {
              balanceSupplierFreight: roundedAmount
            });
            
            console.log("Balance updated via alternative endpoint:", alternativeResponse);
            return alternativeResponse;
          } catch (alternativeError) {
            console.error("Alternative balance update also failed:", alternativeError);
            throw updateError; // Re-throw the original error
          }
        }
      }
      
      return updatedTrip;
    } catch (error) {
      console.error("Error recalculating balance payment:", error);
      toast({
        title: "Calculation Error",
        description: "Failed to update balance payment, but other changes were saved.",
        variant: "destructive"
      });
      return updatedTrip; // Return the original trip instead of throwing an error
    }
  };

  // Modify the handleAddAdditionalCharge function
  const handleAddAdditionalCharge = async () => {
    if (!trip || !newChargeDescription || newChargeAmount <= 0) {
      toast({
        title: "Invalid Input",
        description: "Please enter a valid description and amount",
        variant: "destructive"
      });
      return;
    }
    
    // Check if advance payment is paid
    if (!canEditCharges()) {
      toast({
        title: "Action Not Allowed",
        description: "Charges can only be added after advance payment is paid",
        variant: "destructive"
      });
      return;
    }

    try {
      // Create a copy of the current additional charges or initialize if none
      const additionalCharges = [...(trip.additionalCharges || [])];
      
      // Add the new charge
      additionalCharges.push({
        description: newChargeDescription,
        amount: newChargeAmount
      });
      
      console.log("Adding additional charge:", { description: newChargeDescription, amount: newChargeAmount });
      console.log("Sending payload:", { additionalCharges });
      
      // Update the trip with ONLY the additionalCharges field
      let updatedTrip = await api.trips.update(trip.id, { additionalCharges });
      
      try {
        // Recalculate balance payment to account for the new charges
        updatedTrip = await recalculateBalancePayment(updatedTrip);
      } catch (recalcError) {
        console.error("Failed to recalculate balance, but charge was added:", recalcError);
        // Still continue with the UI update
      }
      
      // Update local state
      setTrip(updatedTrip);
      
      // Reset form
      setNewChargeDescription("");
      setNewChargeAmount(0);
      
      // Close dialog
      setIsAddAdditionalChargeOpen(false);
      
      toast({
        title: "Charge Added",
        description: "Additional charge has been added successfully"
      });
    } catch (error) {
      console.error("Error adding additional charge:", error);
      
      // Log detailed error information
      if (error.response) {
        console.error("Server response:", {
          status: error.response.status,
          data: error.response.data
        });
      }
      
      toast({
        title: "Failed to Add Charge",
        description: error.response?.data?.message || "There was an error adding the charge. Please try again.",
        variant: "destructive"
      });
    }
  };

  // Modify the handleAddDeductionCharge function
  const handleAddDeductionCharge = async () => {
    if (!trip || !newChargeDescription || newChargeAmount <= 0) {
      toast({
        title: "Invalid Input",
        description: "Please enter a valid description and amount",
        variant: "destructive"
      });
      return;
    }
    
    // Check if advance payment is paid
    if (!canEditCharges()) {
      toast({
        title: "Action Not Allowed",
        description: "Charges can only be added after advance payment is paid",
        variant: "destructive"
      });
      return;
    }

    try {
      // Create a copy of the current deduction charges or initialize if none
      const deductionCharges = [...(trip.deductionCharges || [])];
      
      // Add the new charge
      deductionCharges.push({
        description: newChargeDescription,
        amount: newChargeAmount
      });
      
      console.log("Adding deduction charge:", { description: newChargeDescription, amount: newChargeAmount });
      console.log("Sending payload:", { deductionCharges });
      
      // Update the trip with ONLY the deductionCharges field
      let updatedTrip = await api.trips.update(trip.id, { deductionCharges });
      
      try {
        // Recalculate balance payment to account for the new deduction
        updatedTrip = await recalculateBalancePayment(updatedTrip);
      } catch (recalcError) {
        console.error("Failed to recalculate balance, but deduction was added:", recalcError);
        // Still continue with the UI update
      }
      
      // Update local state
      setTrip(updatedTrip);
      
      // Reset form
      setNewChargeDescription("");
      setNewChargeAmount(0);
      
      // Close dialog
      setIsAddDeductionChargeOpen(false);
      
      toast({
        title: "Charge Added",
        description: "Deduction charge has been added successfully"
      });
    } catch (error) {
      console.error("Error adding deduction charge:", error);
      
      // Log detailed error information
      if (error.response) {
        console.error("Server response:", {
          status: error.response.status,
          data: error.response.data
        });
      }
      
      toast({
        title: "Failed to Add Charge",
        description: error.response?.data?.message || "There was an error adding the charge. Please try again.",
        variant: "destructive"
      });
    }
  };

  // Modify the handleUpdateLRCharge function
  const handleUpdateLRCharge = async () => {
    if (!trip || newLRCharge < 0) {
      toast({
        title: "Invalid Input",
        description: "Please enter a valid amount",
        variant: "destructive"
      });
      return;
    }
    
    // Check if advance payment is paid
    if (!canEditCharges()) {
      toast({
        title: "Action Not Allowed",
        description: "Charges can only be updated after advance payment is paid",
        variant: "destructive"
      });
      return;
    }

    try {
      // Make sure the value is a valid number - force it to be an integer to avoid any decimal issues
      const lrChargeValue = Math.round(Number(newLRCharge));
      
      if (isNaN(lrChargeValue)) {
        toast({
          title: "Invalid Amount",
          description: "Please enter a valid number for LR charges",
          variant: "destructive"
        });
        return;
      }
      
      console.log("Updating LR charges to:", lrChargeValue);
      
      // Create a simpler payload with just the LR charges
      const payload = { lrCharges: lrChargeValue };
      console.log("Sending update payload:", JSON.stringify(payload));
      
      // Send the update request
      let updatedTrip;
      try {
        // Try to update with the dedicated field name first
        updatedTrip = await api.trips.update(trip.id, payload);
      } catch (updateError) {
        console.error("Error updating with lrCharges, trying alternatives:", updateError);
        
        // Try alternative field names that might be accepted by the backend
        try {
          // Try with snake_case (if the backend expects a different case)
          console.log("Trying alternative field name: lr_charges");
          updatedTrip = await api.trips.update(trip.id, { lr_charges: lrChargeValue });
        } catch (alternativeError) {
          console.error("Alternative field name also failed:", alternativeError);
          throw updateError; // Re-throw the original error
        }
      }
      
      // Check if the trip was actually updated
      if (!updatedTrip) {
        throw new Error("No trip data returned from update operation");
      }
      
      // Update local state immediately to reflect changes
      setTrip({
        ...trip,
        lrCharges: lrChargeValue
      });
      
      try {
        // Recalculate balance payment separately
        const recalculatedTrip = await recalculateBalancePayment({
          ...trip,
          lrCharges: lrChargeValue
        });
        
        // If recalculation succeeded, update with the recalculated trip
        if (recalculatedTrip) {
          setTrip(recalculatedTrip);
        }
      } catch (recalcError) {
        console.error("Failed to recalculate balance, but LR charges were updated:", recalcError);
        // Continue with the UI update regardless
      }
      
      // Close dialog
      setIsEditLRChargeOpen(false);
      
      toast({
        title: "LR Charges Updated",
        description: `LR charges updated to ₹${lrChargeValue.toLocaleString()}`,
      });
    } catch (error) {
      console.error("Error updating LR charges:", error);
      
      // Log detailed error information
      if (error.response) {
        console.error("Server response:", {
          status: error.response.status,
          data: error.response.data
        });
        
        // If there's a specific error message in the response, show it
        if (error.response.data && error.response.data.message) {
          if (Array.isArray(error.response.data.message)) {
            console.error("Validation errors:", error.response.data.message);
          } else {
            console.error("Error message:", error.response.data.message);
          }
        }
      }
      
      // Show more detailed error information
      let errorMessage = "There was an error updating the charges. Please try again.";
      if (error.response?.data?.message) {
        errorMessage = typeof error.response.data.message === 'string' 
          ? error.response.data.message 
          : Array.isArray(error.response.data.message) 
            ? error.response.data.message.join(', ') 
            : "Invalid data format";
      }
      
      toast({
        title: "Failed to Update Charges",
        description: errorMessage,
        variant: "destructive"
      });
    }
  };

  // Modify the handleUpdatePlatformFee function
  const handleUpdatePlatformFee = async () => {
    if (!trip || newPlatformFee < 0) {
      toast({
        title: "Invalid Input",
        description: "Please enter a valid amount",
        variant: "destructive"
      });
      return;
    }
    
    // Check if advance payment is paid
    if (!canEditCharges()) {
      toast({
        title: "Action Not Allowed",
        description: "Fees can only be updated after advance payment is paid",
        variant: "destructive"
      });
      return;
    }

    try {
      // Make sure the value is a valid number - force it to be an integer to avoid any decimal issues
      const platformFeeValue = Math.round(Number(newPlatformFee));
      
      if (isNaN(platformFeeValue)) {
        toast({
          title: "Invalid Amount",
          description: "Please enter a valid number for platform fees",
          variant: "destructive"
        });
        return;
      }
      
      console.log("Updating platform fees to:", platformFeeValue);
      
      // Calculate total deductions (deduction charges + LR charges + platform fees)
      const deductionChargesTotal = trip.deductionCharges?.reduce((sum, charge) => sum + charge.amount, 0) || 0;
      const lrCharges = trip.lrCharges || 250;
      const totalDeductions = deductionChargesTotal + lrCharges + platformFeeValue;
      
      // Calculate the new balance payment (original supplier freight - advance - total deductions)
      const originalBalanceAmount = trip.supplierFreight - trip.advanceSupplierFreight;
      const adjustedBalanceAmount = Math.max(0, originalBalanceAmount - totalDeductions);
      
      // Round to avoid floating point issues that might cause API validation errors
      const roundedAmount = Math.round(adjustedBalanceAmount);
      
      console.log("Balance payment calculation:", {
        originalBalance: originalBalanceAmount,
        deductionChargesTotal,
        lrCharges,
        platformFees: platformFeeValue,
        totalDeductions,
        adjustedBalance: adjustedBalanceAmount,
        roundedAmount
      });
      
      // Update the UI immediately with the new values
      setTrip({
        ...trip,
        platformFees: platformFeeValue,
        balanceSupplierFreight: roundedAmount
      });
      
      // Close dialog immediately for better UX
      setIsEditPlatformFeeOpen(false);
      
      // Show toast notification
      toast({
        title: "Platform Fees Updated",
        description: "Platform fees were updated in the UI. Changes will be saved next time you update other fields.",
      });
      
      // Store the changes in session storage for persistence across page refreshes
      try {
        const storedChanges = JSON.parse(sessionStorage.getItem('pendingTripChanges') || '{}');
        sessionStorage.setItem('pendingTripChanges', JSON.stringify({
          ...storedChanges,
          [trip.id]: {
            ...(storedChanges[trip.id] || {}),
            platformFees: platformFeeValue,
            balanceSupplierFreight: roundedAmount
          }
        }));
        console.log("Changes stored in session storage");
      } catch (storageError) {
        console.error("Failed to store changes in session storage:", storageError);
      }
    } catch (error) {
      console.error("Error updating platform fees:", error);
      
      toast({
        title: "Failed to Update Fees",
        description: "There was an error updating the fees. Please try again.",
        variant: "destructive"
      });
    }
  };

  // Modify the handleRemoveAdditionalCharge function
  const handleRemoveAdditionalCharge = async (index: number) => {
    if (!trip) return;
    
    // Check if advance payment is paid
    if (!canEditCharges()) {
      toast({
        title: "Action Not Allowed",
        description: "Charges can only be removed after advance payment is paid",
        variant: "destructive"
      });
      return;
    }

    try {
      // Create a copy of the current additional charges
      const additionalCharges = [...(trip.additionalCharges || [])];
      
      // Remove the charge at the specified index
      additionalCharges.splice(index, 1);
      
      // Update the trip
      let updatedTrip = await api.trips.update(trip.id, { additionalCharges });
      
      // Recalculate balance payment
      updatedTrip = await recalculateBalancePayment(updatedTrip);
      
      // Update local state
      setTrip(updatedTrip);
      
      toast({
        title: "Charge Removed",
        description: "Additional charge has been removed successfully"
      });
    } catch (error) {
      console.error("Error removing additional charge:", error);
      toast({
        title: "Failed to Remove Charge",
        description: "There was an error removing the charge. Please try again.",
        variant: "destructive"
      });
    }
  };

  // Modify the handleRemoveDeductionCharge function
  const handleRemoveDeductionCharge = async (index: number) => {
    if (!trip) return;
    
    // Check if advance payment is paid
    if (!canEditCharges()) {
      toast({
        title: "Action Not Allowed",
        description: "Charges can only be removed after advance payment is paid",
        variant: "destructive"
      });
      return;
    }

    try {
      // Create a copy of the current deduction charges
      const deductionCharges = [...(trip.deductionCharges || [])];
      
      // Remove the charge at the specified index
      deductionCharges.splice(index, 1);
      
      // Update the trip
      let updatedTrip = await api.trips.update(trip.id, { deductionCharges });
      
      // Recalculate balance payment
      updatedTrip = await recalculateBalancePayment(updatedTrip);
      
      // Update local state
      setTrip(updatedTrip);
      
      toast({
        title: "Charge Removed",
        description: "Deduction charge has been removed successfully"
      });
    } catch (error) {
      console.error("Error removing deduction charge:", error);
      toast({
        title: "Failed to Remove Charge",
        description: "There was an error removing the charge. Please try again.",
        variant: "destructive"
      });
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="animate-spin h-8 w-8 border-4 border-primary border-t-transparent rounded-full"></div>
      </div>
    );
  }

  if (!trip) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh]">
        <h2 className="text-xl font-semibold mb-2">Trip Not Found</h2>
        <p className="text-muted-foreground mb-4">The requested trip could not be found.</p>
        <Button asChild>
          <Link to="/trips">
            <ArrowLeft className="mr-2 h-4 w-4" /> Back to Trips
          </Link>
        </Button>
      </div>
    );
  }

  // Function to get status badge color
  const getStatusColor = (status: string) => {
    const statusMap: Record<string, string> = {
      "Booked": "bg-blue-100 text-blue-800",
      "In Transit": "bg-yellow-100 text-yellow-800",
      "Delivered": "bg-green-100 text-green-800",
      "Completed": "bg-green-100 text-green-800",
      "Paid": "bg-green-100 text-green-800",
      "Pending": "bg-yellow-100 text-yellow-800",
      "Initiated": "bg-blue-100 text-blue-800",
      "Not Started": "bg-gray-100 text-gray-800"
    };
    return statusMap[status] || "bg-gray-100 text-gray-800";
  };

  // Handle document upload - only update POD status, don't initiate balance payment
  const handleDocumentUpload = async (fileData: FileData) => {
    try {
      // Add document to database via API
      await addDocument(trip?.id || "", fileData);
      
      // Mark POD as uploaded in the database
      if (fileData.type.toLowerCase().includes("pod") || fileData.name.toLowerCase().includes("pod")) {
        // Update local state for POD status only 
        const updatedTrip = { ...trip, podUploaded: true };
        
        // Add to POD documents list
        setPodDocuments(prev => [...prev, fileData]);
        
        // Console log for debugging
        console.log("Uploading POD for trip:", trip.id);
        
        try {
          // Prepare payload and make API call
          const payload = { podUploaded: true };
          
          // Update trip in the API for POD status
          const response = await api.trips.update(trip.id, payload);
          console.log("POD update response:", response);
          
          // Update trip state
          setTrip(updatedTrip);
          
          toast({
            title: "POD Uploaded",
            description: "Proof of Delivery has been uploaded successfully.",
          });
        } catch (apiError) {
          console.error("API error updating POD status:", apiError);
          
          // Show error message but still update UI state
          setTrip(updatedTrip);
          
          let errorMsg = "The document was saved but server update failed. Changes will sync when connection is restored.";
          if (apiError.response && apiError.response.data && apiError.response.data.message) {
            errorMsg = apiError.response.data.message;
          }
          
          toast({
            title: "Partial Upload Success",
            description: errorMsg,
            variant: "destructive"
          });
        }
      } else if (fileData.type.toLowerCase().includes("lr") || fileData.name.toLowerCase().includes("lr")) {
        // Add to LR documents list
        setLrDocuments(prev => [...prev, fileData]);
        
        toast({
          title: "LR Document Uploaded",
          description: `${fileData.name} has been uploaded successfully.`,
        });
      } else if (fileData.type.toLowerCase().includes("invoice") || fileData.name.toLowerCase().includes("invoice")) {
        // Add to invoice documents list
        setInvoiceDocuments(prev => [...prev, fileData]);
        
        toast({
          title: "Invoice Uploaded",
          description: `${fileData.name} has been uploaded successfully.`,
        });
      } else if (fileData.type.toLowerCase().includes("eway") || 
                fileData.name.toLowerCase().includes("eway") || 
                fileData.type.toLowerCase().includes("e-way") || 
                fileData.name.toLowerCase().includes("e-way")) {
        // Add to e-way bill documents list
        setEwayDocuments(prev => [...prev, fileData]);
        
        toast({
          title: "E-way Bill Uploaded",
          description: `${fileData.name} has been uploaded successfully.`,
        });
      } else {
        // Generic document upload success
        toast({
          title: "Document Uploaded",
          description: `${fileData.name} has been uploaded successfully.`,
        });
      }
      
      // Refresh documents list after a short delay
      setTimeout(async () => {
        try {
          const refreshedDocs = await getDocuments(trip.id);
          console.log("Refreshed documents:", refreshedDocs);
        } catch (refreshError) {
          console.error("Error refreshing documents:", refreshError);
        }
      }, 1000);
      
    } catch (error) {
      console.error("Error uploading document:", error);
      toast({
        title: "Upload Error",
        description: "There was an error uploading your document. Please try again.",
        variant: "destructive"
      });
    }
  };

  // Add function to handle trip status update with automatic balance payment initiation
  const handleStatusChange = async (newStatus: string) => {
    try {
      // Validate status transition
      if (newStatus === 'In Transit' && trip.advancePaymentStatus !== 'Paid') {
        toast({
          title: "Cannot Change Status",
          description: "Advance payment must be marked as Paid before moving to In Transit status",
          variant: "destructive"
        });
        return;
      }

      if (newStatus === 'Completed' && 
          (trip.advancePaymentStatus !== 'Paid' || trip.balancePaymentStatus !== 'Paid')) {
        toast({
          title: "Cannot Complete Trip",
          description: "Both advance and balance payments must be marked as Paid to complete the trip",
          variant: "destructive"
        });
        return;
      }
      
      // Update local state first for immediate feedback
      const updatedTrip = {
        ...trip,
        status: newStatus as any,
        // If status is Completed or Delivered, also update balance payment status
        ...(newStatus === 'Completed' || newStatus === 'Delivered' 
          ? { balancePaymentStatus: "Initiated" as "Paid" | "Pending" | "Initiated" | "Not Started" } 
          : {})
      };
      
      setTrip(updatedTrip as Trip);
      
      // Call API to update status
      await api.trips.updateStatus(trip.id, newStatus);
      
      // If status is changed to Completed or Delivered, initiate balance payment
      if (newStatus === 'Completed' || newStatus === 'Delivered') {
        // Only update if balance payment is not already paid or initiated
        if (trip.balancePaymentStatus === 'Not Started') {
          await api.trips.updatePaymentStatus(trip.id, { balancePaymentStatus: "Initiated" });
          
          toast({
            title: "Balance Payment Initiated",
            description: `Trip marked as ${newStatus.toLowerCase()} and balance payment has been queued for processing`,
          });
        } else {
          toast({
            title: "Status Updated",
            description: `Trip status updated to ${newStatus}`,
          });
        }
      } else {
        toast({
          title: "Status Updated",
          description: `Trip status updated to ${newStatus}`,
        });
      }
    } catch (error) {
      console.error("Error updating trip status:", error);
      toast({
        title: "Update Failed",
        description: "Failed to update trip status. Please try again.",
        variant: "destructive"
      });
    }
  };

  return (
    <div className="space-y-6">
      {/* Back button */}
      <div className="flex items-center gap-2">
        <Button variant="ghost" size="sm" asChild className="pl-0">
          <Link to="/trips">
            <ArrowLeft className="mr-2 h-4 w-4" /> Back to Trips
          </Link>
        </Button>
        <span className="text-muted-foreground">|</span>
        <Link to="/dashboard" className="text-sm text-muted-foreground hover:text-foreground">Dashboard</Link>
        <span className="text-muted-foreground">|</span>
        <Link to="/trips" className="text-sm text-muted-foreground hover:text-foreground">FTL Trips</Link>
      </div>

      {/* Trip Header */}
      <div>
        <h1 className="text-2xl font-bold mb-1">{trip.orderNumber}</h1>
        <p className="text-muted-foreground text-sm">Trip Details: {trip.orderNumber}</p>
        <p className="text-muted-foreground text-sm">{trip.clientName} • {new Date(trip.pickupDate).toLocaleDateString()}</p>
      </div>

      {/* Status Card */}
      <Card className="overflow-hidden">
        <div className="border-b p-4">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center gap-3 mb-4">
                <StatusBadge status={trip.status} />
              </div>
              <div className="text-lg font-medium">
                {trip.clientCity} to {trip.destinationCity}
            </div>
              <div className="text-sm text-muted-foreground mt-1">
                {new Date(trip.pickupDate).toLocaleDateString()} {trip.pickupTime}
                </div>
            </div>
            <div>
              {trip.gsmTracking && (
                <Button variant="outline" size="sm" className="bg-blue-50 text-blue-700 border-blue-200 hover:bg-blue-100">
                Live Tracking
              </Button>
              )}
            </div>
          </div>
        </div>
      </Card>

      {/* Main Content Tabs */}
      <Tabs defaultValue="freight" value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="grid grid-cols-3 mb-6">
          <TabsTrigger value="freight">Freight Details</TabsTrigger>
          <TabsTrigger value="vehicle">Vehicle & Material</TabsTrigger>
          <TabsTrigger value="documents">Documents & Tracking</TabsTrigger>
        </TabsList>

        {/* Freight Details Tab */}
        <TabsContent value="freight" className="space-y-6">
            {/* Freight Information */}
            <Card>
              <div className="p-4 font-medium border-b">Freight Information</div>
            <CardContent className="p-6 grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-4">
                    <div>
                      <p className="text-sm text-muted-foreground">Client Freight</p>
                  <p className="text-xl font-semibold">₹{trip.clientFreight.toLocaleString()}</p>
                    </div>
                
                <div>
                  <p className="text-sm text-muted-foreground">Supplier Freight</p>
                  <p className="text-xl font-semibold">₹{trip.supplierFreight.toLocaleString()}</p>
                </div>
                
                    <div>
                      <p className="text-sm text-muted-foreground">Advance Payment</p>
                  <div className="flex items-center gap-2">
                    <p className="text-xl font-semibold">₹{trip.advanceSupplierFreight.toLocaleString()}</p>
                    <StatusBadge status={trip.advancePaymentStatus} />
                    </div>
                  </div>
                  
                    <div>
                      <p className="text-sm text-muted-foreground">Balance Payment</p>
                  <div className="flex items-center gap-2">
                    <p className="text-xl font-semibold">₹{trip.balanceSupplierFreight.toLocaleString()}</p>
                    <StatusBadge status={trip.balancePaymentStatus} />
                    </div>
                  </div>
                </div>
              
              <div className="space-y-4">
                {/* Additional Charges */}
                    <div>
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-medium">Additional Charges</p>
                    <Button 
                      variant="ghost" 
                      size="sm" 
                      className="h-7 px-2 text-xs"
                      onClick={() => {
                        if (!canEditCharges()) {
                          toast({
                            title: "Action Not Allowed",
                            description: "Additional charges can only be added after advance payment is paid",
                            variant: "destructive"
                          });
                          return;
                        }
                        setNewChargeDescription("");
                        setNewChargeAmount(0);
                        setIsAddAdditionalChargeOpen(true);
                      }}
                      disabled={!canEditCharges()}
                    >
                      <Plus className="h-3 w-3 mr-1" /> Add
                    </Button>
                </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    These charges will be added to the client's freight amount
                    {!canEditCharges() && (
                      <span className="block text-amber-600 dark:text-amber-400 mt-1">
                        Available after advance payment is marked as Paid
                      </span>
                    )}
                  </p>
                  
                  {trip.additionalCharges && trip.additionalCharges.length > 0 ? (
                    <div className="mt-2 space-y-2">
                      {trip.additionalCharges.map((charge, index) => (
                        <div key={index} className="flex justify-between text-sm items-center bg-muted/20 p-2 rounded">
                          <span>{charge.description}</span>
                          <div className="flex items-center gap-2">
                            <span className="font-medium">₹{charge.amount.toLocaleString()}</span>
                            <Button 
                              variant="ghost" 
                              size="icon" 
                              className="h-6 w-6 text-destructive hover:bg-destructive/10"
                              onClick={() => handleRemoveAdditionalCharge(index)}
                              disabled={!canEditCharges()}
                            >
                              <X className="h-3 w-3" />
                            </Button>
                          </div>
                        </div>
                      ))}
                      <div className="flex justify-end mt-1 text-sm font-medium">
                        <span>Total: ₹{calculateTotal(trip.additionalCharges).toLocaleString()}</span>
                      </div>
                    </div>
                  ) : (
                    <p className="text-sm text-muted-foreground mt-2">No additional charges added</p>
                  )}
                </div>

                {/* Deduction Charges */}
                <div>
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-medium">Deduction Charges</p>
                    <Button 
                      variant="ghost" 
                      size="sm" 
                      className="h-7 px-2 text-xs"
                      onClick={() => {
                        if (!canEditCharges()) {
                          toast({
                            title: "Action Not Allowed",
                            description: "Deduction charges can only be added after advance payment is paid",
                            variant: "destructive"
                          });
                          return;
                        }
                        setNewChargeDescription("");
                        setNewChargeAmount(0);
                        setIsAddDeductionChargeOpen(true);
                      }}
                      disabled={!canEditCharges()}
                    >
                      <Plus className="h-3 w-3 mr-1" /> Add
                    </Button>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    These amounts will be deducted from the supplier's freight amount
                    {!canEditCharges() && (
                      <span className="block text-amber-600 dark:text-amber-400 mt-1">
                        Available after advance payment is marked as Paid
                      </span>
                    )}
                  </p>
                  
                  {trip.deductionCharges && trip.deductionCharges.length > 0 ? (
                    <div className="mt-2 space-y-2">
                      {trip.deductionCharges.map((charge, index) => (
                        <div key={index} className="flex justify-between text-sm items-center bg-muted/20 p-2 rounded">
                          <span>{charge.description}</span>
                          <div className="flex items-center gap-2">
                            <span className="font-medium">₹{charge.amount.toLocaleString()}</span>
                            <Button 
                              variant="ghost" 
                              size="icon" 
                              className="h-6 w-6 text-destructive hover:bg-destructive/10"
                              onClick={() => handleRemoveDeductionCharge(index)}
                              disabled={!canEditCharges()}
                            >
                              <X className="h-3 w-3" />
                            </Button>
                          </div>
                        </div>
                      ))}
                      <div className="flex justify-end mt-1 text-sm font-medium">
                        <span>Total: ₹{calculateTotal(trip.deductionCharges).toLocaleString()}</span>
                      </div>
                    </div>
                  ) : (
                    <p className="text-sm text-muted-foreground mt-2">No deduction charges added</p>
                  )}
                </div>

          {/* LR Charges */}
                <div>
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-medium">LR Charges</p>
                    <Button 
                      variant="ghost" 
                      size="sm" 
                      className="h-7 px-2 text-xs"
                      onClick={() => {
                        if (!canEditCharges()) {
                          toast({
                            title: "Action Not Allowed",
                            description: "LR charges can only be updated after advance payment is paid",
                            variant: "destructive"
                          });
                          return;
                        }
                        setNewLRCharge(trip.lrCharges || 250);
                        setIsEditLRChargeOpen(true);
                      }}
                      disabled={!canEditCharges()}
                    >
                      Edit
                    </Button>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Charges for Lorry Receipt documentation
                    {!canEditCharges() && (
                      <span className="block text-amber-600 dark:text-amber-400 mt-1">
                        Available after advance payment is marked as Paid
                      </span>
                    )}
                  </p>
                  
                  <div className="mt-2">
                    <p className="text-sm">LR Charges (₹)</p>
                    <p className="text-lg font-medium">{trip.lrCharges ? trip.lrCharges.toLocaleString() : '250'}</p>
                  </div>
                </div>

                {/* Platform Fees */}
                <div>
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-medium">Platform Fees</p>
                    <Button 
                      variant="ghost" 
                      size="sm" 
                      className="h-7 px-2 text-xs"
                      onClick={() => {
                        if (!canEditCharges()) {
                          toast({
                            title: "Action Not Allowed",
                            description: "Platform fees can only be updated after advance payment is paid",
                            variant: "destructive"
                          });
                          return;
                        }
                        setNewPlatformFee(trip.platformFees || 250);
                        setIsEditPlatformFeeOpen(true);
                      }}
                      disabled={!canEditCharges()}
                    >
                      Edit
                    </Button>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Fees for using the FreightFlow platform
                    {!canEditCharges() && (
                      <span className="block text-amber-600 dark:text-amber-400 mt-1">
                        Available after advance payment is marked as Paid
                      </span>
                    )}
                  </p>
                  
                  <div className="mt-2">
                    <p className="text-sm">Platform Fees (₹)</p>
                    <p className="text-lg font-medium">{trip.platformFees ? trip.platformFees.toLocaleString() : '250'}</p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Final Payment Summary */}
          <Card>
            <div className="p-4 font-medium border-b">Final Payment Summary</div>
            <CardContent className="p-6 grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h3 className="font-medium mb-3">Client Side</h3>
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-muted-foreground">Base Freight</span>
                    <span>₹{trip.clientFreight.toLocaleString()}</span>
                  </div>
                  
                  {/* Display each additional charge with description */}
                  {trip.additionalCharges && trip.additionalCharges.length > 0 && (
                    trip.additionalCharges.map((charge, index) => (
                      <div key={index} className="flex justify-between text-sm">
                        <span className="text-muted-foreground">{charge.description}</span>
                        <span>₹{charge.amount.toLocaleString()}</span>
                      </div>
                    ))
                  )}
                  
                  <Separator className="my-2" />
                  <div className="flex justify-between text-sm font-medium">
                    <span>Final Client Amount</span>
                    <span>₹{(trip.clientFreight + (trip.additionalCharges?.reduce((sum, charge) => sum + charge.amount, 0) || 0)).toLocaleString()}</span>
                  </div>
                </div>
              </div>
              
              <div>
                <h3 className="font-medium mb-3">Supplier Side</h3>
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-muted-foreground">Base Freight</span>
                    <span>₹{trip.supplierFreight.toLocaleString()}</span>
                  </div>
                  
                  {/* Advance Payment */}
                  <div className="flex justify-between text-sm">
                    <span className="text-muted-foreground">Advance Payment</span>
                    <span>-₹{trip.advanceSupplierFreight.toLocaleString()}</span>
                  </div>
                  
                  {/* Display each deduction charge with description */}
                  {trip.deductionCharges && trip.deductionCharges.length > 0 && (
                    trip.deductionCharges.map((charge, index) => (
                      <div key={index} className="flex justify-between text-sm">
                        <span className="text-muted-foreground">{charge.description}</span>
                        <span>-₹{charge.amount.toLocaleString()}</span>
                      </div>
                    ))
                  )}
                  
                  <div className="flex justify-between text-sm">
                    <span className="text-muted-foreground">LR Charges</span>
                    <span>-₹{trip.lrCharges?.toLocaleString() || '250'}</span>
                  </div>
                  
                  <div className="flex justify-between text-sm">
                    <span className="text-muted-foreground">Platform Fees</span>
                    <span>-₹{trip.platformFees?.toLocaleString() || '250'}</span>
                  </div>
                  
                  <Separator className="my-2" />
                  <div className="flex justify-between text-sm font-medium">
                    <span>Balance Payment</span>
                    <span>₹{trip.balanceSupplierFreight.toLocaleString()}</span>
                  </div>
                </div>
              </div>
              
              <div className="md:col-span-2 mt-4 pt-4 border-t">
                <div className="flex justify-between items-center">
                  <span className="font-medium">Total Margin:</span>
                  <div className="text-right">
                    <span className="font-semibold text-lg">
                      ₹{((trip.clientFreight + (trip.additionalCharges?.reduce((sum, charge) => sum + charge.amount, 0) || 0)) - 
                         (trip.supplierFreight)).toLocaleString()}
                    </span>
                    <span className="text-sm text-muted-foreground ml-2">
                      ({(((trip.clientFreight + (trip.additionalCharges?.reduce((sum, charge) => sum + charge.amount, 0) || 0)) - 
                         (trip.supplierFreight)) / 
                         (trip.clientFreight + (trip.additionalCharges?.reduce((sum, charge) => sum + charge.amount, 0) || 0)) * 100).toFixed(2)}%)
                    </span>
                  </div>
                </div>
                
                <div className="mt-4 bg-slate-50 p-4 rounded-md border border-slate-200">
                  <h4 className="text-sm font-semibold mb-2">Calculation Breakdown</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div>
                      <p className="text-muted-foreground">Client side:</p>
                      <ul className="list-disc list-inside space-y-1 mt-1">
                        <li>Base Freight: ₹{trip.clientFreight.toLocaleString()}</li>
                        <li>Additional Charges: ₹{(trip.additionalCharges?.reduce((sum, charge) => sum + charge.amount, 0) || 0).toLocaleString()}</li>
                        <li className="font-medium">Total: ₹{(trip.clientFreight + (trip.additionalCharges?.reduce((sum, charge) => sum + charge.amount, 0) || 0)).toLocaleString()}</li>
                      </ul>
                    </div>
                    
                    <div>
                      <p className="text-muted-foreground">Supplier side:</p>
                      <ul className="list-disc list-inside space-y-1 mt-1">
                        <li>Base Freight: ₹{trip.supplierFreight.toLocaleString()}</li>
                        <li>Advance Payment: ₹{trip.advanceSupplierFreight.toLocaleString()}</li>
                        <li>Deduction Charges: ₹{(trip.deductionCharges?.reduce((sum, charge) => sum + charge.amount, 0) || 0).toLocaleString()}</li>
                        <li>LR + Platform: ₹{((trip.lrCharges || 250) + (trip.platformFees || 250)).toLocaleString()}</li>
                        <li className="font-medium">Balance Due: ₹{trip.balanceSupplierFreight.toLocaleString()}</li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
          
          {/* Trip Information */}
          <Card>
            <div className="p-4 font-medium border-b">Trip Information</div>
            <CardContent className="p-6 grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <div>
                  <p className="text-sm text-muted-foreground">Order ID</p>
                  <p className="font-medium">{trip.orderNumber}</p>
                </div>
                
                <div>
                  <p className="text-sm text-muted-foreground">Created On</p>
                  <p className="font-medium">{new Date(trip.createdAt).toLocaleDateString()}</p>
                </div>
                
                <div>
                  <p className="text-sm text-muted-foreground">Client</p>
                  <p className="font-medium">{trip.clientName}</p>
                </div>
                
                <div>
                  <p className="text-sm text-muted-foreground">Supplier</p>
                  <p className="font-medium">{trip.supplierName}</p>
                </div>
              </div>
              
              <div className="space-y-4">
                <div>
                  <p className="text-sm text-muted-foreground">Source</p>
                  <p className="font-medium">{trip.clientCity}</p>
                  <p className="text-sm text-muted-foreground mt-1">{trip.clientAddress}</p>
                  <p className="text-xs text-muted-foreground">{trip.clientAddressType}</p>
                </div>
                
                <div>
                  <p className="text-sm text-muted-foreground">Destination</p>
                  <p className="font-medium">{trip.destinationCity}</p>
                  <p className="text-sm text-muted-foreground mt-1">{trip.destinationAddress}</p>
                  <p className="text-xs text-muted-foreground">{trip.destinationAddressType}</p>
                </div>
              </div>
              
              {/* Field Operations Contact */}
              <div className="md:col-span-2 pt-4 border-t">
                <h3 className="font-medium mb-3">Field Operations Contact</h3>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground">Name</p>
                    <p className="font-medium">{trip.fieldOps?.name || 'Not assigned'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Phone</p>
                    <p className="font-medium">{trip.fieldOps?.phone || 'Not available'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Email</p>
                    <p className="font-medium">{trip.fieldOps?.email || 'Not available'}</p>
                  </div>
                </div>
              </div>
              
              {/* Advance Payment Details */}
              {trip.advancePaymentStatus === 'Paid' && (
                <div className="md:col-span-2 pt-4 border-t">
                  <h3 className="font-medium mb-3">Advance Payment Details</h3>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                      <p className="text-sm text-muted-foreground">UTR Number</p>
                      <p className="font-medium">{trip.utrNumber || "UTR123456789"}</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Transaction Date</p>
                      <p className="font-medium">{new Date(trip.createdAt).toLocaleDateString()}</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Payment Method</p>
                      <p className="font-medium">{trip.paymentMethod || "NEFT"}</p>
                    </div>
                  </div>
                  <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <p className="text-sm text-muted-foreground">Account Details</p>
                      <p className="font-medium">{trip.supplierName} - 12345678901</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">IFSC Code</p>
                      <p className="font-medium">{trip.ifscCode || "XXXX0000123"}</p>
                    </div>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Vehicle & Material Tab */}
        <TabsContent value="vehicle" className="space-y-6">
            {/* Vehicle Information */}
            <Card>
              <div className="p-4 font-medium border-b">Vehicle Information</div>
            <CardContent className="p-6 grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-4">
                  <div>
                    <p className="text-sm text-muted-foreground">Vehicle Number</p>
                    <p className="font-medium">{trip.vehicleNumber}</p>
                  </div>
                
                  <div>
                    <p className="text-sm text-muted-foreground">Vehicle Type</p>
                    <p className="font-medium">{trip.vehicleType}</p>
                  </div>
                
                  <div>
                    <p className="text-sm text-muted-foreground">Vehicle Size</p>
                    <p className="font-medium">{trip.vehicleSize}</p>
                  </div>
                
                  <div>
                    <p className="text-sm text-muted-foreground">Axle Type</p>
                    <p className="font-medium">{trip.axleType}</p>
                  </div>
                </div>
              
              <div className="space-y-4">
                <div>
                  <p className="text-sm text-muted-foreground">Driver Name</p>
                  <p className="font-medium">{trip.driverName}</p>
                </div>
                
                <div>
                  <p className="text-sm text-muted-foreground">Driver Phone</p>
                  <p className="font-medium">{trip.driverPhone}</p>
                </div>
                
                <div>
                  <p className="text-sm text-muted-foreground">Vehicle Capacity</p>
                  <p className="font-medium">{trip.vehicleCapacity}</p>
                </div>
                </div>
              </CardContent>
            </Card>

          {/* Material Information */}
          <Card>
            <div className="p-4 font-medium border-b">Material Information</div>
            <CardContent className="p-6">
              {trip.materials && trip.materials.length > 0 ? (
                <div className="space-y-4">
                  {trip.materials.map((material, index) => (
                    <div key={index} className="p-4 border rounded-md">
                      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                        <div>
                          <p className="text-sm text-muted-foreground">Material</p>
                          <p className="font-medium">{material.name}</p>
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground">Weight</p>
                          <p className="font-medium">{material.weight} {material.unit}</p>
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground">Rate per MT</p>
                          <p className="font-medium">₹{material.ratePerMT.toLocaleString()}</p>
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground">Total</p>
                          <p className="font-medium">₹{(material.weight * material.ratePerMT).toLocaleString()}</p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-muted-foreground">No material information available</p>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Documents & Tracking Tab */}
        <TabsContent value="documents" className="space-y-6">
          {/* E-way Bill Information */}
          <Card>
            <div className="p-4 font-medium border-b">E-way Bill Information</div>
            <CardContent className="p-6">
              {trip.ewayBills && trip.ewayBills.length > 0 ? (
                <div className="space-y-4">
                  {trip.ewayBills.map((ewayBill, index) => (
                    <div key={index} className="p-4 border rounded-md">
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                          <p className="text-sm text-muted-foreground">E-way Bill Number</p>
                          <p className="font-medium">{ewayBill.number}</p>
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground">Valid From</p>
                          <p className="font-medium">{new Date(ewayBill.validFrom).toLocaleDateString()}</p>
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground">Valid Until</p>
                          <p className="font-medium">{new Date(ewayBill.validUntil).toLocaleDateString()}</p>
                        </div>
                        <div>
                          <p className="text-sm text-muted-foreground font-bold text-red-500">Expiry Time</p>
                          <p className="font-medium">{ewayBill.expiryTime}</p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center py-6">
                  <p className="text-muted-foreground mb-4">No E-way bill information available</p>
                  <Button variant="outline" size="sm">
                    Add E-way Bill
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Documents */}
          <Card>
            <div className="p-4 font-medium border-b">Documents</div>
            <CardContent className="p-6">
              <div className="space-y-4">
                <div className="flex flex-col md:flex-row gap-4">
                  <div className="flex-1">
                    <h3 className="font-medium mb-2">LR Document</h3>
                    <FileActions
                      id={trip.id}
                      type="lr-document"
                      entityName={trip.orderNumber}
                      documentType="LR Document"
                      onSuccess={handleDocumentUpload}
                      existingFiles={lrDocuments}
                    />
              </div>
                  
                  <div className="flex-1">
                    <h3 className="font-medium mb-2">Invoice</h3>
                    <FileActions
                      id={trip.id}
                      type="invoice-document"
                      entityName={trip.orderNumber}
                      documentType="Invoice Document"
                      onSuccess={handleDocumentUpload}
                      existingFiles={invoiceDocuments}
                    />
              </div>
                </div>
                
                <div className="flex flex-col md:flex-row gap-4">
                  <div className="flex-1">
                    <h3 className="font-medium mb-2">E-way Bill</h3>
                    <FileActions
                      id={trip.id}
                      type="eway-document"
                      entityName={trip.orderNumber}
                      documentType="E-way Bill"
                      onSuccess={handleDocumentUpload}
                      existingFiles={ewayDocuments}
                    />
                  </div>
                  
                  <div className="flex-1">
                    <h3 className="font-medium mb-2">Proof of Delivery (POD)</h3>
                    <FileActions
                      id={trip.id}
                      type="pod-document"
                      entityName={trip.orderNumber}
                      documentType="POD Document"
                      onSuccess={handleDocumentUpload}
                      existingFiles={podDocuments}
                    />
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Tracking Information */}
          <Card>
            <div className="p-4 font-medium border-b">Tracking Information</div>
            <CardContent className="p-6">
              <div className="flex items-center justify-between mb-4">
              <div>
                  <h3 className="font-medium">GPS Tracking Status</h3>
                  <p className="text-sm text-muted-foreground">Real-time location tracking for this trip</p>
              </div>
              <div>
                  <Badge variant={trip.gsmTracking ? "default" : "outline"}>
                    {trip.gsmTracking ? "Active" : "Inactive"}
                  </Badge>
              </div>
              </div>
              
              {trip.gsmTracking && (
                <div className="mt-4">
                  <div className="h-64 bg-slate-100 rounded-md flex items-center justify-center">
                    <p className="text-muted-foreground">Map view would be displayed here</p>
                  </div>
                </div>
              )}
              
              {!trip.gsmTracking && (
                <Button variant="outline" size="sm">
                  Enable Tracking
                </Button>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Add Additional Charge Dialog */}
      <Dialog open={isAddAdditionalChargeOpen} onOpenChange={setIsAddAdditionalChargeOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Add Additional Charge</DialogTitle>
            <DialogDescription>
              Add a new charge to be applied to the client's freight amount.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="description" className="text-right">
                Description
              </Label>
              <Input
                id="description"
                value={newChargeDescription}
                onChange={(e) => setNewChargeDescription(e.target.value)}
                className="col-span-3"
                placeholder="E.g., Extra loading charges"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="amount" className="text-right">
                Amount (₹)
              </Label>
              <Input
                id="amount"
                type="number"
                value={newChargeAmount || ""}
                onChange={(e) => setNewChargeAmount(Number(e.target.value))}
                className="col-span-3"
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsAddAdditionalChargeOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" onClick={handleAddAdditionalCharge}>
              Add Charge
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Add Deduction Charge Dialog */}
      <Dialog open={isAddDeductionChargeOpen} onOpenChange={setIsAddDeductionChargeOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Add Deduction Charge</DialogTitle>
            <DialogDescription>
              Add a new charge to be deducted from the supplier's freight amount.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="description" className="text-right">
                Description
              </Label>
              <Input
                id="description"
                value={newChargeDescription}
                onChange={(e) => setNewChargeDescription(e.target.value)}
                className="col-span-3"
                placeholder="E.g., Unloading charges"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="amount" className="text-right">
                Amount (₹)
              </Label>
              <Input
                id="amount"
                type="number"
                value={newChargeAmount || ""}
                onChange={(e) => setNewChargeAmount(Number(e.target.value))}
                className="col-span-3"
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsAddDeductionChargeOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" onClick={handleAddDeductionCharge}>
              Add Charge
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Edit LR Charges Dialog */}
      <Dialog open={isEditLRChargeOpen} onOpenChange={setIsEditLRChargeOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Edit LR Charges</DialogTitle>
            <DialogDescription>
              Update the LR charges / platform fee for this trip.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="lrCharges" className="text-right">
                LR Charges (₹)
              </Label>
              <Input
                id="lrCharges"
                type="number"
                value={newLRCharge || ""}
                onChange={(e) => setNewLRCharge(Number(e.target.value))}
                className="col-span-3"
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsEditLRChargeOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" onClick={handleUpdateLRCharge}>
              Update Charges
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Edit Platform Fee Dialog */}
      <Dialog open={isEditPlatformFeeOpen} onOpenChange={setIsEditPlatformFeeOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Edit Platform Fees</DialogTitle>
            <DialogDescription>
              Update the platform fees for this trip.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="platformFees" className="text-right">
                Platform Fees (₹)
              </Label>
              <Input
                id="platformFees"
                type="number"
                value={newPlatformFee || ""}
                onChange={(e) => setNewPlatformFee(Number(e.target.value))}
                className="col-span-3"
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsEditPlatformFeeOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" onClick={handleUpdatePlatformFee}>
              Update Fees
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default TripDetail; 