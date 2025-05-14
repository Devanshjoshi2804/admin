import React, { useState, useEffect } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogClose
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Supplier } from "@/suppliers/models/supplier.model";
import { Info, X } from "lucide-react";
import api from "@/lib/api";
import { useToast } from "@/hooks/use-toast";

interface SupplierInfoDialogProps {
  supplierId?: string | null;
  supplierName?: string; // Optional supplier name for fallback lookup
}

const SupplierInfoDialog = ({ supplierId, supplierName }: SupplierInfoDialogProps) => {
  const [open, setOpen] = useState(false);
  const [supplier, setSupplier] = useState<Supplier | null>(null);
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();

  const fetchSupplierInfo = async () => {
    setLoading(true);
    try {
      // First try to find by ID if available
      if (supplierId && supplierId !== 'null' && supplierId !== 'undefined' && supplierId.trim() !== '') {
        console.log("Fetching supplier data for ID:", supplierId);
        try {
          const supplierData = await api.suppliers.getById(supplierId);
          if (supplierData) {
            console.log("Supplier data received:", supplierData ? "success" : "null");
            setSupplier(supplierData);
            setLoading(false);
            return;
          }
        } catch (error) {
          console.error("Error fetching supplier by ID:", error);
          // Continue to fallback methods
        }
      }
      
      // Fallback: Search by name if ID lookup failed or wasn't available
      if (supplierName) {
        console.log("Falling back to supplier lookup by name:", supplierName);
        try {
          const suppliers = await api.suppliers.getAll();
          const matchedSupplier = suppliers.find(s => 
            s.name.toLowerCase() === supplierName.toLowerCase()
          );
          
          if (matchedSupplier) {
            console.log("Found supplier by name match");
            setSupplier(matchedSupplier);
            setLoading(false);
            return;
          }
        } catch (fallbackError) {
          console.error("Error in name fallback lookup:", fallbackError);
          // Continue to error handling
        }
      }
      
      // If all lookups failed, show error
      console.error("All supplier lookup methods failed");
      setSupplier(null);
      toast({
        title: "Error",
        description: "Failed to load supplier information.",
        variant: "destructive",
      });
    } catch (error) {
      console.error("Error fetching supplier info:", error);
      setSupplier(null);
      toast({
        title: "Error",
        description: "Failed to load supplier information.",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleOpen = () => {
    // Check if we have either an ID or a name to look up
    if ((!supplierId || supplierId === 'null' || supplierId === 'undefined' || supplierId.trim() === '') && 
        (!supplierName || supplierName.trim() === '')) {
      console.error("Invalid supplier information - ID:", supplierId, "Name:", supplierName);
      toast({
        title: "Information Not Available",
        description: "Supplier information is not available for this entry.",
        variant: "destructive",
      });
      return;
    }
    
    setOpen(true);
    fetchSupplierInfo();
  };

  return (
    <>
      <Button
        variant="ghost"
        size="icon"
        className="h-6 w-6 rounded-full hover:bg-indigo-100 dark:hover:bg-indigo-900/30"
        onClick={handleOpen}
      >
        <Info className="h-4 w-4 text-indigo-600 dark:text-indigo-400" />
      </Button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center">
              <span>Supplier Information</span>
              <DialogClose className="ml-auto">
                <X className="h-4 w-4" />
                <span className="sr-only">Close</span>
              </DialogClose>
            </DialogTitle>
            <DialogDescription>
              Supplier and bank account details
            </DialogDescription>
          </DialogHeader>
          
          {loading ? (
            <div className="py-6 text-center text-sm text-muted-foreground">
              Loading supplier information...
            </div>
          ) : supplier ? (
            <div className="space-y-4">
              {/* Supplier Company Information */}
              <div className="border rounded-md p-4">
                <h4 className="text-sm font-medium mb-2">Company Details</h4>
                <div className="grid grid-cols-2 gap-3 text-sm">
                  <div>
                    <p className="text-muted-foreground">Supplier ID</p>
                    <p className="font-medium">{supplier.id}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Name</p>
                    <p className="font-medium">{supplier.name}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">City</p>
                    <p className="font-medium">{supplier.city}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">GST Number</p>
                    <p className="font-medium">{supplier.gstNumber}</p>
                  </div>
                </div>
              </div>
              
              {/* Bank Details */}
              <div className="border rounded-md p-4">
                <h4 className="text-sm font-medium mb-2">Bank Account Details</h4>
                <div className="grid grid-cols-2 gap-3 text-sm">
                  <div>
                    <p className="text-muted-foreground">Bank Name</p>
                    <p className="font-medium">{supplier.bankDetails.bankName}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Account Type</p>
                    <p className="font-medium">{supplier.bankDetails.accountType}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Account Number</p>
                    <p className="font-medium">{supplier.bankDetails.accountNumber}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">IFSC Code</p>
                    <p className="font-medium">{supplier.bankDetails.ifscCode}</p>
                  </div>
                </div>
              </div>
              
              {/* Contact Person */}
              <div className="border rounded-md p-4">
                <h4 className="text-sm font-medium mb-2">Contact Person</h4>
                <div className="grid grid-cols-2 gap-3 text-sm">
                  <div>
                    <p className="text-muted-foreground">Name</p>
                    <p className="font-medium">{supplier.contactPerson.name}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Phone</p>
                    <p className="font-medium">{supplier.contactPerson.phone}</p>
                  </div>
                  <div className="col-span-2">
                    <p className="text-muted-foreground">Email</p>
                    <p className="font-medium">{supplier.contactPerson.email}</p>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="py-6 text-center text-muted-foreground">
              No supplier information available.
            </div>
          )}
        </DialogContent>
      </Dialog>
    </>
  );
};

export default SupplierInfoDialog; 