import React from "react";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

interface StatusBadgeProps {
  status: string;
  size?: "default" | "sm";
  className?: string;
}

// Define badge CSS classes based on status strings
export const getStatusColorClass = (status: string): string => {
  const lowerStatus = status.toLowerCase();
  if (lowerStatus.includes("paid") || lowerStatus.includes("completed") || lowerStatus.includes("delivered")) {
    return "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300";
  }
  if (lowerStatus.includes("pending") || lowerStatus.includes("in transit")) {
    return "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300";
  }
  if (lowerStatus.includes("initiated") || lowerStatus.includes("booked")) {
    return "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300";
  }
  if (lowerStatus.includes("not started")) {
    return "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300";
  }
  return "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300";
};

export const StatusBadge: React.FC<StatusBadgeProps> = ({
  status,
  size = "default",
  className
}) => {
  return (
    <Badge 
      className={cn(
        getStatusColorClass(status),
        size === "sm" ? "text-xs py-0 px-2" : "px-2 py-0.5",
        "font-medium border-0",
        className
      )}
    >
      {status}
    </Badge>
  );
};

export default StatusBadge; 