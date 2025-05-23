import React, { useState, useEffect } from "react";
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
  
  // I'll continue adding the handler functions next
};

export default TripDetail;
