import React, { useState } from "react";
import { useToast } from "@/hooks/use-toast";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import { Separator } from "@/components/ui/separator";
import api from "@/lib/api";
import { Supplier } from "@/data/mockData";

interface SupplierFormProps {
  supplier?: Supplier;
  onClose: () => void;
  mode: "create" | "edit";
}

interface FormData {
  name: string;
  city: string;
  address: string;
  contactPersonName: string;
  contactPersonPhone: string;
  contactPersonEmail: string;
  bankName: string;
  accountNumber: string;
  ifscCode: string;
  accountType: string;
  gstNumber: string;
  representativeName: string;
  representativeDesignation: string;
  representativePhone: string;
  representativeEmail: string;
}

const SupplierForm = ({ supplier, onClose, mode }: SupplierFormProps) => {
  const { toast } = useToast();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formData, setFormData] = useState<FormData>({
    name: supplier?.name || "",
    city: supplier?.city || "",
    address: supplier?.address || "",
    contactPersonName: supplier?.contactPerson?.name || "",
    contactPersonPhone: supplier?.contactPerson?.phone || "",
    contactPersonEmail: supplier?.contactPerson?.email || "",
    bankName: supplier?.bankDetails?.bankName || "",
    accountNumber: supplier?.bankDetails?.accountNumber || "",
    ifscCode: supplier?.bankDetails?.ifscCode || "",
    accountType: supplier?.bankDetails?.accountType || "",
    gstNumber: supplier?.gstNumber || "",
    representativeName: "",
    representativeDesignation: "",
    representativePhone: "",
    representativeEmail: "",
  });

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { id, value } = e.target;
    setFormData({
      ...formData,
      [id]: value,
    });
  };

  const handleSelectChange = (id: string, value: string) => {
    setFormData({
      ...formData,
      [id]: value,
    });
  };

  const handleSave = async () => {
    // Validate required fields
    if (!formData.name || !formData.city || !formData.address) {
      toast({
        title: "Missing Information",
        description: "Please fill all required fields.",
        variant: "destructive",
      });
      return;
    }

    setIsSubmitting(true);

    try {
      // Prepare the data for API
      const supplierData = {
        name: formData.name,
        city: formData.city,
        address: formData.address,
        contactPerson: {
          name: formData.contactPersonName,
          phone: formData.contactPersonPhone,
          email: formData.contactPersonEmail,
        },
        bankDetails: {
          bankName: formData.bankName,
          accountNumber: formData.accountNumber,
          ifscCode: formData.ifscCode,
          accountType: formData.accountType,
        },
        gstNumber: formData.gstNumber,
      };

      if (mode === "create") {
        await api.suppliers.create(supplierData);
        toast({
          title: "Supplier Created",
          description: `${formData.name} has been created successfully.`,
        });
      } else {
        if (supplier?.id) {
          await api.suppliers.update(supplier.id, supplierData);
          toast({
            title: "Supplier Updated",
            description: `${formData.name} has been updated successfully.`,
          });
        }
      }
      
      onClose();
    } catch (error) {
      console.error("Error saving supplier:", error);
      toast({
        title: `Error ${mode === "create" ? "Creating" : "Updating"} Supplier`,
        description: "There was a problem saving the supplier data. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="p-4">
      <Tabs defaultValue="basic" className="w-full">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="basic">Basic Information</TabsTrigger>
          <TabsTrigger value="banking">Banking Details</TabsTrigger>
          <TabsTrigger value="documents">Documents</TabsTrigger>
        </TabsList>

        {/* Basic Information Tab */}
        <TabsContent value="basic" className="space-y-4 mt-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="form-group">
              <label className="form-label" htmlFor="name">Supplier Name*</label>
              <Input
                id="name"
                value={formData.name}
                onChange={handleInputChange}
                placeholder="Enter supplier name"
              />
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="city">City*</label>
              <Input
                id="city"
                value={formData.city}
                onChange={handleInputChange}
                placeholder="Enter city"
              />
            </div>

            <div className="form-group col-span-1 md:col-span-2">
              <label className="form-label" htmlFor="address">Address*</label>
              <Input
                id="address"
                value={formData.address}
                onChange={handleInputChange}
                placeholder="Enter address"
              />
            </div>
          </div>

          <Separator className="my-4" />

          <div>
            <h3 className="text-lg font-medium mb-4">Contact Person</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="form-group">
                <label className="form-label" htmlFor="contactPersonName">Name*</label>
                <Input
                  id="contactPersonName"
                  value={formData.contactPersonName}
                  onChange={handleInputChange}
                  placeholder="Enter name"
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="contactPersonPhone">Phone*</label>
                <Input
                  id="contactPersonPhone"
                  value={formData.contactPersonPhone}
                  onChange={handleInputChange}
                  placeholder="Enter phone number"
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="contactPersonEmail">Email*</label>
                <Input
                  id="contactPersonEmail"
                  value={formData.contactPersonEmail}
                  onChange={handleInputChange}
                  placeholder="Enter email address"
                  type="email"
                />
              </div>
            </div>
          </div>

          <Separator className="my-4" />

          <div>
            <h3 className="text-lg font-medium mb-4">Supplier Representative</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="form-group">
                <label className="form-label" htmlFor="representativeName">Name*</label>
                <Input
                  id="representativeName"
                  value={formData.representativeName}
                  onChange={handleInputChange}
                  placeholder="Enter name"
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="representativeDesignation">Designation*</label>
                <Input
                  id="representativeDesignation"
                  value={formData.representativeDesignation}
                  onChange={handleInputChange}
                  placeholder="Enter designation"
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="representativePhone">Phone*</label>
                <Input
                  id="representativePhone"
                  value={formData.representativePhone}
                  onChange={handleInputChange}
                  placeholder="Enter phone number"
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="representativeEmail">Email*</label>
                <Input
                  id="representativeEmail"
                  value={formData.representativeEmail}
                  onChange={handleInputChange}
                  placeholder="Enter email address"
                  type="email"
                />
              </div>
            </div>
          </div>
        </TabsContent>

        {/* Banking Details Tab */}
        <TabsContent value="banking" className="space-y-4 mt-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="form-group">
              <label className="form-label" htmlFor="bankName">Bank Name*</label>
              <Input
                id="bankName"
                value={formData.bankName}
                onChange={handleInputChange}
                placeholder="Enter bank name"
              />
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="accountType">Account Type*</label>
              <Select
                value={formData.accountType}
                onValueChange={(value) => handleSelectChange("accountType", value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select Account Type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Current">Current</SelectItem>
                  <SelectItem value="Savings">Savings</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="accountNumber">Account Number*</label>
              <Input
                id="accountNumber"
                value={formData.accountNumber}
                onChange={handleInputChange}
                placeholder="Enter account number"
              />
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="ifscCode">IFSC Code*</label>
              <Input
                id="ifscCode"
                value={formData.ifscCode}
                onChange={handleInputChange}
                placeholder="Enter IFSC code"
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Cancelled Cheque</label>
            <Input type="file" />
          </div>
        </TabsContent>

        {/* Documents Tab */}
        <TabsContent value="documents" className="space-y-4 mt-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="form-group">
              <label className="form-label" htmlFor="gstNumber">GST Number</label>
              <div className="flex space-x-2">
                <Input
                  id="gstNumber"
                  value={formData.gstNumber}
                  onChange={handleInputChange}
                  placeholder="Enter GST number"
                  className="flex-1"
                />
                <Input type="file" className="w-48" />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">PAN Card</label>
              <Input type="file" />
            </div>

            <div className="form-group">
              <label className="form-label">MSME Certificate</label>
              <Input type="file" />
            </div>
          </div>

          <Separator className="my-4" />

          <div className="form-group">
            <label className="form-label">Supplier Onboarding Form</label>
            <Input type="file" />
          </div>

          <div className="space-y-2">
            <h3 className="text-lg font-medium">Document Gallery</h3>
            <p className="text-sm text-gray-500">
              All uploaded documents related to this supplier will appear here.
            </p>
            <div className="p-10 border-2 border-dashed rounded-md flex justify-center items-center">
              <p className="text-gray-400">No documents uploaded yet</p>
            </div>
          </div>
        </TabsContent>
      </Tabs>

      <div className="mt-6 flex justify-end space-x-2">
        <Button variant="outline" onClick={onClose} disabled={isSubmitting}>Cancel</Button>
        <Button onClick={handleSave} disabled={isSubmitting}>
          {isSubmitting ? (
            <>
              <span className="animate-spin mr-2">&#9696;</span>
              {mode === "create" ? "Creating..." : "Updating..."}
            </>
          ) : (
            mode === "create" ? "Create Supplier" : "Update Supplier"
          )}
        </Button>
      </div>
    </div>
  );
};

export default SupplierForm;
