import React from "react";
import { 
  DropdownMenu, 
  DropdownMenuContent, 
  DropdownMenuItem, 
  DropdownMenuTrigger 
} from "@/components/ui/dropdown-menu";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { ChevronDown } from "lucide-react";

interface StatusDropdownProps {
  entityId: string;
  currentStatus: string;
  availableStatuses: string[];
  onStatusChange: (entityId: string, newStatus: string) => void;
  statusType: "trip" | "payment"; // To apply different badge styles
}

// Define badge CSS classes based on status strings
const getBadgeClass = (status: string): string => {
  const lowerStatus = status.toLowerCase();
  if (lowerStatus.includes("paid") || lowerStatus.includes("completed") || lowerStatus.includes("delivered") || lowerStatus.includes("valid")) {
    return "badge-success";
  }
  if (lowerStatus.includes("pending") || lowerStatus.includes("in transit") || lowerStatus.includes("expiring")) {
    return "badge-warning";
  }
  if (lowerStatus.includes("initiated") || lowerStatus.includes("booked")) {
    return "badge-info";
  }
  if (lowerStatus.includes("not started") || lowerStatus.includes("expired")) {
    return "badge-red"; // Reuse existing destructive class logic if possible or define badge-destructive
  }
  return ""; // Default badge style (from Badge component itself)
};

export const StatusDropdown: React.FC<StatusDropdownProps> = ({
  entityId,
  currentStatus,
  availableStatuses,
  onStatusChange,
  statusType
}) => {

  const handleSelect = (newStatus: string) => {
    if (newStatus !== currentStatus) {
      onStatusChange(entityId, newStatus);
    }
  };

  // Filter out the current status from the dropdown items
  const dropdownItems = availableStatuses.filter(status => status !== currentStatus);

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button 
          variant="outline" 
          size="sm" 
          className="flex items-center gap-1 h-7 px-2 py-0.5 w-full justify-start min-w-[100px]"
        >
          <Badge 
            className={cn(getBadgeClass(currentStatus), "pointer-events-none mr-1")}
          >
            {currentStatus}
          </Badge>
          <ChevronDown className="h-3 w-3 text-muted-foreground ml-auto"/>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="start">
        {dropdownItems.map((status) => (
          <DropdownMenuItem 
            key={status}
            onSelect={() => handleSelect(status)}
            className="text-xs cursor-pointer"
          >
            {status}
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}; 