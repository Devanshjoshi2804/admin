import React, { useState, useEffect } from "react";
import { useParams, Link } from "react-router-dom";
import { useToast } from "@/hooks/use-toast";
import { Trip } from "@/trips/models/trip.model";
import api from "@/lib/api";
import { useDocuments } from "@/hooks/use-documents";
import { FileData } from "@/components/ui/file-actions";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import StatusBadge from "@/components/ui/status-badge";
import { ArrowLeft, MapPin, User, Phone, Mail, Clock, Calendar, FileCheck, FileText, Download, CreditCard } from "lucide-react";
import { cn } from "@/lib/utils";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { FileActions } from "@/components/ui/file-actions";

const PaymentDetail = () => {
  const { id } = useParams<{ id: string }>();
  const { toast } = useToast();
  const { getDocuments, addDocument } = useDocuments();
  const [trip, setTrip] = useState<Trip | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("advance");
  
  // Dialog states
  const [isInitiatePaymentDialogOpen, setIsInitiatePaymentDialogOpen] = useState(false);
  const [isUploadReceiptDialogOpen, setIsUploadReceiptDialogOpen] = useState(false);
  
  // Input states
  const [utrNumber, setUtrNumber] = useState("");
  const [paymentMethod, setPaymentMethod] = useState("NEFT");
  const [paymentAmount, setPaymentAmount] = useState<number>(0);
  const [paymentNotes, setPaymentNotes] = useState("");

  useEffect(() => {
    const fetchPaymentDetails = async () => {
      setLoading(true);
      try {
        if (!id) return;
        
        const fetchedTrip = await api.trips.getById(id);
        setTrip(fetchedTrip);
      } catch (error) {
        console.error("Error fetching payment details:", error);
        toast({
          title: "Error",
          description: "Failed to load payment details. Please try again.",
          variant: "destructive",
        });
      } finally {
        setLoading(false);
      }
    };

    fetchPaymentDetails();
  }, [id, toast]);

  // Function to handle document uploads and update payment status when needed
  const handleDocumentUpload = async (fileData: FileData) => {
    try {
      if (!trip) return;
      
      // Add document to local storage
      addDocument(trip.id, fileData);
      
      toast({
        title: "Document Uploaded",
        description: `${fileData.name} has been uploaded successfully.`,
      });
      
      // If this is a receipt and payment status is Initiated or Pending, mark as Paid
      if (fileData.type.toLowerCase().includes("receipt") || fileData.name.toLowerCase().includes("receipt")) {
        let fieldToUpdate = "";
        if (activeTab === "advance" && ["Initiated", "Pending"].includes(trip.advancePaymentStatus)) {
          fieldToUpdate = "advancePaymentStatus";
        } else if (activeTab === "balance" && ["Initiated", "Pending"].includes(trip.balancePaymentStatus) && 
                   trip.podUploaded && trip.status === "Completed") {
          fieldToUpdate = "balancePaymentStatus";
        }
        
        if (fieldToUpdate) {
          // Update trip in the database
          await api.trips.update(trip.id, { [fieldToUpdate]: "Paid" });
          
          // Update local state
          setTrip(prev => prev ? { ...prev, [fieldToUpdate]: "Paid" } : null);
          
          toast({
            title: "Payment Status Updated",
            description: `${fieldToUpdate === "advancePaymentStatus" ? "Advance" : "Balance"} payment has been marked as Paid.`,
          });
        }
      }
    } catch (error) {
      console.error("Error handling document upload:", error);
      toast({
        title: "Error",
        description: "There was a problem uploading the document.",
        variant: "destructive",
      });
    }
  };

  // Function to handle initiating a payment
  const handleInitiatePayment = async () => {
    if (!trip) return;
    
    try {
      const paymentType = activeTab === "advance" ? "advancePaymentStatus" : "balancePaymentStatus";
      
      // Validate if payment can be initiated
      if (paymentType === "balancePaymentStatus" && !trip.podUploaded) {
        toast({
          title: "POD Required",
          description: "Proof of Delivery must be uploaded before initiating balance payment.",
          variant: "destructive",
        });
        return;
      }
      
      console.log(`Initiating ${paymentType} for trip ${trip.id}`);
      
      // Update payment status in database
      const payload = { [paymentType]: "Initiated" };
      console.log("Sending payment update payload:", JSON.stringify(payload));
      
      try {
        // First try to use updatePaymentStatus
        const updatedTrip = await api.trips.updatePaymentStatus(trip.id, payload);
        console.log("Payment status updated successfully via updatePaymentStatus");
        
        // Update local state
        setTrip(updatedTrip);
      } catch (apiError) {
        console.error("Error with updatePaymentStatus, falling back to regular update:", apiError);
        
        // Fallback to regular update
        const updatedTrip = await api.trips.update(trip.id, payload);
        console.log("Payment status updated successfully via regular update");
        
        // Update local state
        setTrip(updatedTrip);
      }
      
      // Close dialog
      setIsInitiatePaymentDialogOpen(false);
      
      // Reset form
      setUtrNumber("");
      setPaymentMethod("NEFT");
      setPaymentNotes("");
      
      toast({
        title: "Payment Initiated",
        description: `${activeTab === "advance" ? "Advance" : "Balance"} payment has been initiated successfully.`,
      });
    } catch (error) {
      console.error("Error initiating payment:", error);
      
      // Show more detailed error information
      let errorMessage = "There was an error initiating the payment. Please try again.";
      if (error.response?.data?.message) {
        errorMessage = error.response.data.message;
      }
      
      toast({
        title: "Failed to Initiate Payment",
        description: errorMessage,
        variant: "destructive",
      });
    }
  };
  
  // Function to handle marking a payment as paid
  const handleMarkAsPaid = async () => {
    if (!trip) return;
    
    try {
      const paymentType = activeTab === "advance" ? "advancePaymentStatus" : "balancePaymentStatus";
      
      // Update payment status in database
      const updatedTrip = await api.trips.updatePaymentStatus(trip.id, {
        [paymentType]: "Paid",
      });
      
      // Update local state
      setTrip(updatedTrip);
      
      // Close dialog
      setIsUploadReceiptDialogOpen(false);
      
      toast({
        title: "Payment Marked as Paid",
        description: `${activeTab === "advance" ? "Advance" : "Balance"} payment has been marked as paid.`,
      });
    } catch (error) {
      console.error("Error marking payment as paid:", error);
      toast({
        title: "Failed to Update Payment",
        description: "There was an error updating the payment status. Please try again.",
        variant: "destructive",
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
        <h2 className="text-xl font-semibold mb-2">Payment Not Found</h2>
        <p className="text-muted-foreground mb-4">The requested payment could not be found.</p>
        <Button asChild>
          <Link to="/payments">
            <ArrowLeft className="mr-2 h-4 w-4" /> Back to Payments
          </Link>
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Back button */}
      <div>
        <Button variant="ghost" size="sm" asChild className="pl-0">
          <Link to="/payments">
            <ArrowLeft className="mr-2 h-4 w-4" /> Back to Payments
          </Link>
        </Button>
      </div>

      {/* Payment Header */}
      <div>
        <h1 className="text-2xl font-bold mb-1">Payment Dashboard: {trip.orderNumber}</h1>
        <p className="text-muted-foreground text-sm">{trip.clientName} • {new Date(trip.createdAt).toLocaleDateString()}</p>
      </div>

      {/* Status Card */}
      <Card className="overflow-hidden">
        <div className="border-b p-4">
          <div className="flex items-center justify-between">
            <div className="flex gap-3">
              <StatusBadge status={`Advance: ${trip.advancePaymentStatus}`} />
              <StatusBadge status={`Balance: ${trip.balancePaymentStatus}`} />
            </div>
            <Button variant="outline" size="sm" className="flex items-center gap-1.5">
              <FileText className="h-4 w-4 mr-1" />
              View Invoice
            </Button>
          </div>
        </div>
        <CardContent className="p-4">
          <div className="flex flex-col gap-1">
            <div className="grid grid-cols-[auto_1fr] items-center gap-2">
              <MapPin className="h-4 w-4 text-gray-400" />
              <h3 className="font-medium">{trip.clientCity} to {trip.destinationCity}</h3>
            </div>
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Calendar className="h-3.5 w-3.5" />
              <span>Trip Date: {new Date(trip.pickupDate).toLocaleDateString()}</span>
              <Clock className="h-3.5 w-3.5 ml-2" />
              <span>Created: {new Date(trip.createdAt).toLocaleDateString()}</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Tabs */}
      <Tabs defaultValue="advance" value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="grid grid-cols-2 mb-6">
          <TabsTrigger value="advance">Advance Payments</TabsTrigger>
          <TabsTrigger value="balance">Balance (POD) Payments</TabsTrigger>
        </TabsList>

        {/* Advance Payments Tab */}
        <TabsContent value="advance" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2">
            {/* Payment Information */}
            <Card>
              <div className="p-4 font-medium border-b">Advance Payment Information</div>
              <CardContent className="p-4 space-y-4">
                <div>
                  <p className="text-sm text-muted-foreground">Advance Amount</p>
                  <p className="text-lg font-semibold">₹{trip.advanceSupplierFreight.toLocaleString()}</p>
                  <StatusBadge status={`${trip.advancePaymentStatus}`} />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Percentage of Total</p>
                  <p className="font-medium">{trip.advancePercentage}% of ₹{trip.supplierFreight.toLocaleString()}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Transaction Date</p>
                  <p className="font-medium">{new Date(trip.createdAt).toLocaleDateString()}</p>
                </div>
              </CardContent>
            </Card>

            {/* Trip Information */}
            <Card>
              <div className="p-4 font-medium border-b">Trip Information</div>
              <CardContent className="p-4 space-y-4">
                <div>
                  <p className="text-sm text-muted-foreground">Order ID</p>
                  <p className="font-medium">{trip.orderNumber}</p>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground">Client</p>
                    <p className="font-medium">{trip.clientName}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Supplier</p>
                    <p className="font-medium">{trip.supplierName}</p>
                  </div>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Trip Status</p>
                  <StatusBadge status={`${trip.status}`} />
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Payment Transaction Details */}
          <Card>
            <div className="p-4 font-medium border-b">Transaction Details</div>
            <CardContent className="p-4 space-y-4">
              {(trip.advancePaymentStatus as string) === 'Not Started' ? (
                <div className="text-center py-6">
                  <CreditCard className="h-8 w-8 mx-auto mb-2 text-muted-foreground" />
                  <p className="text-muted-foreground mb-3">No payment has been initiated yet</p>
                  <Button 
                    onClick={() => setIsInitiatePaymentDialogOpen(true)}
                    className="mt-2"
                  >
                    Initiate Payment
                  </Button>
                </div>
              ) : (
                <>
                  <div className="grid md:grid-cols-2 gap-6">
                    <div className="space-y-3">
                      <div>
                        <p className="text-sm text-muted-foreground">UTR Number</p>
                        <p className="font-medium">{trip.utrNumber || "UTR12345789"}</p>
                      </div>
                      <div>
                        <p className="text-sm text-muted-foreground">Payment Method</p>
                        <p className="font-medium">{trip.paymentMethod || "NEFT"}</p>
                      </div>
                    </div>
                    <div className="space-y-3">
                      <div>
                        <p className="text-sm text-muted-foreground">Account Holder</p>
                        <p className="font-medium">{trip.supplierName}</p>
                      </div>
                      <div>
                        <p className="text-sm text-muted-foreground">Account Number</p>
                        <p className="font-medium">{trip.accountNumber || "1234567890"}</p>
                      </div>
                    </div>
                  </div>
                  <div className="flex justify-between mt-4 pt-4 border-t">
                    <div>
                      <p className="text-sm text-muted-foreground">Initiated By</p>
                      <p className="font-medium">John Doe</p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-muted-foreground">Initiated On</p>
                      <p className="font-medium">{new Date(trip.createdAt).toLocaleDateString()} {new Date(trip.createdAt).toLocaleTimeString()}</p>
                    </div>
                  </div>
                  
                  {/* Show action button based on payment status */}
                  {trip.advancePaymentStatus !== 'Paid' && (
                    <div className="flex justify-center mt-4 pt-4 border-t">
                      <Button 
                        onClick={() => setIsUploadReceiptDialogOpen(true)}
                        variant="default"
                      >
                        Mark as Paid
                      </Button>
                    </div>
                  )}
                </>
              )}
            </CardContent>
          </Card>

          {/* Payment Receipt */}
          <Card>
            <div className="p-4 font-medium border-b">Payment Receipt</div>
            <CardContent className="p-4">
              {trip.advancePaymentStatus === 'Paid' ? (
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <FileCheck className="h-5 w-5 text-green-500" />
                    <div>
                      <p className="font-medium">Payment Receipt</p>
                      <p className="text-sm text-muted-foreground">payment_receipt_{trip.orderNumber}.pdf</p>
                    </div>
                  </div>
                  <Button variant="outline" size="sm">
                    <Download className="h-4 w-4 mr-1.5" /> Download
                  </Button>
                </div>
              ) : (
                <div className="text-center py-6">
                  <CreditCard className="h-8 w-8 mx-auto mb-2 text-muted-foreground" />
                  <p className="text-muted-foreground">No payment receipt available</p>
                  {trip.advancePaymentStatus === 'Initiated' && (
                    <Button className="mt-4" variant="outline">Upload Receipt</Button>
                  )}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Notes and Comments */}
          <Card>
            <div className="p-4 font-medium border-b">Notes & Comments</div>
            <CardContent className="p-4">
              <div className="p-3 bg-muted/50 rounded-md">
                <p className="text-sm">Advance payment initiated via NEFT. Supplier confirmed receipt.</p>
                <div className="flex justify-between mt-2 text-xs text-muted-foreground">
                  <span>Added by: John Doe</span>
                  <span>{new Date().toLocaleDateString()}</span>
                </div>
              </div>
              <Button className="mt-4 w-full" variant="outline">Add Comment</Button>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Balance Payments Tab */}
        <TabsContent value="balance" className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2">
            {/* Balance Payment Information */}
            <Card>
              <div className="p-4 font-medium border-b">Balance Payment Information</div>
              <CardContent className="p-4 space-y-4">
                <div>
                  <p className="text-sm text-muted-foreground">Balance Amount</p>
                  <p className="text-lg font-semibold">₹{trip.balanceSupplierFreight.toLocaleString()}</p>
                  <StatusBadge status={`${trip.balancePaymentStatus}`} />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Percentage of Total</p>
                  <p className="font-medium">{100 - trip.advancePercentage}% of ₹{trip.supplierFreight.toLocaleString()}</p>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">POD Status</p>
                  <StatusBadge status={`${trip.podUploaded ? "Uploaded" : "Awaiting Upload"}`} />
                </div>
                
                {/* Show deduction charges if any */}
                {trip.deductionCharges && trip.deductionCharges.length > 0 && (
                  <div className="pt-2 border-t">
                    <p className="text-sm font-medium mb-2">Deduction Charges</p>
                    <div className="space-y-1">
                      {trip.deductionCharges
                        .filter(charge => !charge.description.toLowerCase().includes('misc'))
                        .map((charge, index) => (
                          <div key={index} className="flex justify-between text-sm">
                            <span>{charge.description}</span>
                            <span className="font-medium">-₹{charge.amount.toLocaleString()}</span>
                          </div>
                        ))}
                    </div>
                  </div>
                )}
                
                {/* Show miscellaneous charges if any */}
                {trip.deductionCharges && trip.deductionCharges.filter(c => c.description.toLowerCase().includes('misc')).length > 0 && (
                  <div className="pt-2 border-t">
                    <p className="text-sm font-medium mb-2">Miscellaneous Charges</p>
                    <div className="space-y-1">
                      {trip.deductionCharges
                        .filter(charge => charge.description.toLowerCase().includes('misc'))
                        .map((charge, index) => (
                          <div key={index} className="flex justify-between text-sm">
                            <span>{charge.description}</span>
                            <span className="font-medium">-₹{charge.amount.toLocaleString()}</span>
                          </div>
                        ))}
                    </div>
                  </div>
                )}
                
                {/* Show LR charges */}
                <div className="pt-2 border-t">
                  <p className="text-sm font-medium mb-2">Platform Fees</p>
                  <div className="flex justify-between text-sm">
                    <span>LR Charges</span>
                    <span className="font-medium">-₹{trip.lrCharges ? trip.lrCharges.toLocaleString() : '500'}</span>
                  </div>
                </div>
                
                {/* Final payable amount */}
                <div className="pt-2 border-t">
                  <div className="flex justify-between text-sm font-medium">
                    <span>Final Payable Amount</span>
                    <span>₹{(trip.balanceSupplierFreight - 
                          (trip.deductionCharges?.reduce((sum, charge) => sum + charge.amount, 0) || 0) - 
                          (trip.lrCharges || 500)).toLocaleString()}</span>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* POD Information */}
            <Card>
              <div className="p-4 font-medium border-b">POD Information</div>
              <CardContent className="p-4">
                {trip.podUploaded ? (
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <FileCheck className="h-5 w-5 text-green-500" />
                        <div>
                          <p className="font-medium">POD Document</p>
                          <p className="text-sm text-muted-foreground">pod_{trip.orderNumber}.pdf</p>
                        </div>
                      </div>
                      <Button variant="outline" size="sm">
                        <Download className="h-4 w-4 mr-1.5" /> Download
                      </Button>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Uploaded On</p>
                      <p className="font-medium">{new Date().toLocaleDateString()}</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Delivery Date</p>
                      <p className="font-medium">{new Date().toLocaleDateString()}</p>
                    </div>
                  </div>
                ) : (
                  <div className="text-center py-6">
                    <FileText className="h-8 w-8 mx-auto mb-2 text-muted-foreground" />
                    <p className="text-muted-foreground">POD pending upload</p>
                    <p className="text-xs text-muted-foreground mt-1">Balance payment will be processed after POD upload</p>
                    <Button className="mt-4" variant="outline">Upload POD</Button>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          {/* Balance Payment Transaction Details */}
          <Card>
            <div className="p-4 font-medium border-b">Transaction Details</div>
            <CardContent className="p-4">
              {(trip.balancePaymentStatus as string) === 'Not Started' ? (
                <div className="text-center py-6">
                  <CreditCard className="h-8 w-8 mx-auto mb-2 text-muted-foreground" />
                  <p className="text-muted-foreground">Balance payment has not been processed yet</p>
                  {trip.podUploaded ? (
                    <Button 
                      className="mt-4" 
                      variant="default"
                      onClick={() => setIsInitiatePaymentDialogOpen(true)}
                    >
                      Initiate Balance Payment
                    </Button>
                  ) : (
                    <div className="mt-3">
                      <span className="text-xs text-amber-600 block mb-2">POD must be uploaded before initiating balance payment</span>
                      <Button disabled className="opacity-70">Initiate Balance Payment</Button>
                    </div>
                  )}
                </div>
              ) : (trip.balancePaymentStatus as string) === 'Initiated' || (trip.balancePaymentStatus as string) === 'Pending' ? (
                <div className="space-y-4">
                  <div className="grid md:grid-cols-2 gap-6">
                    <div className="space-y-3">
                      <div>
                        <p className="text-sm text-muted-foreground">UTR Number</p>
                        <p className="font-medium">Awaiting Payment</p>
                      </div>
                      <div>
                        <p className="text-sm text-muted-foreground">Payment Method</p>
                        <p className="font-medium">RTGS</p>
                      </div>
                    </div>
                    <div className="space-y-3">
                      <div>
                        <p className="text-sm text-muted-foreground">Account Holder</p>
                        <p className="font-medium">{trip.supplierName}</p>
                      </div>
                      <div>
                        <p className="text-sm text-muted-foreground">Account Number</p>
                        <p className="font-medium">1234567890</p>
                      </div>
                    </div>
                  </div>
                  <div className="flex justify-between mt-4 pt-4 border-t">
                    <div>
                      <p className="text-sm text-muted-foreground">Status</p>
                      <StatusBadge status={trip.balancePaymentStatus} />
                    </div>
                    <div className="text-right">
                      <Button 
                        onClick={() => setIsUploadReceiptDialogOpen(true)}
                        variant="default"
                      >
                        Mark as Paid
                      </Button>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="space-y-4">
                  <div className="grid md:grid-cols-2 gap-6">
                    <div className="space-y-3">
                      <div>
                        <p className="text-sm text-muted-foreground">UTR Number</p>
                        <p className="font-medium">UTR98765432</p>
                      </div>
                      <div>
                        <p className="text-sm text-muted-foreground">Payment Method</p>
                        <p className="font-medium">RTGS</p>
                      </div>
                    </div>
                    <div className="space-y-3">
                      <div>
                        <p className="text-sm text-muted-foreground">Account Holder</p>
                        <p className="font-medium">{trip.supplierName}</p>
                      </div>
                      <div>
                        <p className="text-sm text-muted-foreground">Account Number</p>
                        <p className="font-medium">1234567890</p>
                      </div>
                    </div>
                  </div>
                  <div className="flex justify-between mt-4 pt-4 border-t">
                    <div>
                      <p className="text-sm text-muted-foreground">Initiated By</p>
                      <p className="font-medium">Jane Smith</p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-muted-foreground">Initiated On</p>
                      <p className="font-medium">{new Date().toLocaleDateString()} {new Date().toLocaleTimeString()}</p>
                    </div>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Notes and Comments */}
          <Card>
            <div className="p-4 font-medium border-b">Notes & Comments</div>
            <CardContent className="p-4">
              {trip.balancePaymentStatus !== 'Not Started' ? (
                <div className="p-3 bg-muted/50 rounded-md">
                  <p className="text-sm">Balance payment processed after POD verification. All documentation complete.</p>
                  <div className="flex justify-between mt-2 text-xs text-muted-foreground">
                    <span>Added by: Jane Smith</span>
                    <span>{new Date().toLocaleDateString()}</span>
                  </div>
                </div>
              ) : (
                <div className="text-center py-6 text-muted-foreground">
                  <p>No comments added yet</p>
                </div>
              )}
              <Button className="mt-4 w-full" variant="outline">Add Comment</Button>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
      
      {/* Initiate Payment Dialog */}
      <Dialog open={isInitiatePaymentDialogOpen} onOpenChange={setIsInitiatePaymentDialogOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Initiate {activeTab === "advance" ? "Advance" : "Balance"} Payment</DialogTitle>
            <DialogDescription>
              Enter the details to initiate the {activeTab === "advance" ? "advance" : "balance"} payment for this trip.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="amount" className="text-right">
                Amount
              </Label>
              <Input
                id="amount"
                type="number"
                value={activeTab === "advance" ? trip?.advanceSupplierFreight || 0 : trip?.balanceSupplierFreight || 0}
                readOnly
                className="col-span-3"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="paymentMethod" className="text-right">
                Method
              </Label>
              <Input
                id="paymentMethod"
                value={paymentMethod}
                onChange={(e) => setPaymentMethod(e.target.value)}
                placeholder="NEFT/RTGS/IMPS"
                className="col-span-3"
              />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="notes" className="text-right">
                Notes
              </Label>
              <Input
                id="notes"
                value={paymentNotes}
                onChange={(e) => setPaymentNotes(e.target.value)}
                placeholder="Optional notes"
                className="col-span-3"
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsInitiatePaymentDialogOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" onClick={handleInitiatePayment}>
              Initiate Payment
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
      
      {/* Mark as Paid Dialog */}
      <Dialog open={isUploadReceiptDialogOpen} onOpenChange={setIsUploadReceiptDialogOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Mark {activeTab === "advance" ? "Advance" : "Balance"} Payment as Paid</DialogTitle>
            <DialogDescription>
              Upload the payment receipt or enter UTR number to mark payment as completed.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="utrNumber" className="text-right">
                UTR Number
              </Label>
              <Input
                id="utrNumber"
                value={utrNumber}
                onChange={(e) => setUtrNumber(e.target.value)}
                placeholder="Enter UTR number"
                className="col-span-3"
              />
            </div>
            <div className="col-span-4">
              <Label className="block mb-2">Payment Receipt</Label>
              <FileActions
                id={`${trip?.id}-${activeTab}-receipt`}
                type="pod-document"
                entityName={trip?.orderNumber || ""}
                documentType="Receipt"
                onSuccess={handleDocumentUpload}
                existingFiles={getDocuments(`${trip?.id}-${activeTab}-receipt`)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsUploadReceiptDialogOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" onClick={handleMarkAsPaid}>
              Mark as Paid
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default PaymentDetail; 