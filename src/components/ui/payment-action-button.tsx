import React from "react";
import { Button } from "@/components/ui/button";
import { CreditCard } from "lucide-react";
import StatusBadge from "./status-badge";

interface PaymentActionButtonProps {
  entityId: string;
  currentStatus: string;
  paymentType: "advance" | "balance";
  disabled?: boolean;
  onActionClick: (entityId: string, paymentType: "advance" | "balance") => void;
}

/**
 * Payment Action Button Component
 * 
 * This component shows different actions based on payment status:
 * - For "Not Started" status: Shows "Process Advance" or "Process Balance" button
 * - For "Initiated" status: Shows "Mark Pending" button
 * - For "Pending" status: Shows "Mark Paid" button
 * - For "Paid" status: Only shows a status badge with no actions
 * 
 * The payment flow is: Not Started → Initiated → Pending → Paid
 * Once a payment is marked as "Paid", it will be filtered out of the payment queues
 * and will no longer appear in the payment dashboard for that payment type.
 */
export const PaymentActionButton: React.FC<PaymentActionButtonProps> = ({
  entityId,
  currentStatus,
  paymentType,
  disabled = false,
  onActionClick
}) => {
  // Determine what action is available based on the current status
  const getActionButton = () => {
    // Ensure status check is case-insensitive and handle null/undefined values
    const lowerStatus = (currentStatus || '').toLowerCase();
    
    // If already paid, just show the status badge without any action button
    if (lowerStatus === "paid" || lowerStatus.includes("paid")) {
      return (
        <StatusBadge status={currentStatus} />
      );
    }
    
    // For Pending status, show "Mark Paid" button
    if (lowerStatus === "pending" || lowerStatus.includes("pending")) {
      return (
        <div className="flex flex-col gap-1">
          <Button 
            variant="outline" 
            size="sm"
            className="w-full"
            onClick={() => onActionClick(entityId, paymentType)}
          >
            <CreditCard className="h-3.5 w-3.5 mr-1.5" /> 
            Mark Paid
          </Button>
          <StatusBadge status={currentStatus} size="sm" className="self-start" />
        </div>
      );
    }
    
    // For Initiated status, show "Mark Pending" button
    if (lowerStatus === "initiated" || lowerStatus.includes("initiated")) {
      return (
        <div className="flex flex-col gap-1">
          <Button 
            variant="outline" 
            size="sm"
            className="w-full"
            onClick={() => onActionClick(entityId, paymentType)}
          >
            <CreditCard className="h-3.5 w-3.5 mr-1.5" /> 
            Mark Pending
          </Button>
          <StatusBadge status={currentStatus} size="sm" className="self-start" />
        </div>
      );
    }
    
    // Default case - Not Started status
    return (
      <div className="flex flex-col gap-1">
        <Button 
          variant="outline" 
          size="sm"
          className="w-full"
          disabled={disabled}
          onClick={() => onActionClick(entityId, paymentType)}
        >
          <CreditCard className="h-3.5 w-3.5 mr-1.5" /> 
          {paymentType === "advance" ? "Process Advance" : "Process Balance"}
        </Button>
        <StatusBadge status={currentStatus} size="sm" className="self-start" />
      </div>
    );
  };

  return getActionButton();
};

export default PaymentActionButton; 