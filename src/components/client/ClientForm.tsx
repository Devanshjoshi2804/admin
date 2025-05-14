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
import { invoicingTypes } from "@/data/mockData";
import { UploadCloud, FileText, Building, Phone, Mail, User, Landmark, FileCheck } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

interface ClientFormProps {
  client?: any;
  onClose: () => void;
  onSubmit?: (clientData: any) => void;
  mode: "create" | "edit";
}

const ClientForm = ({ client, onClose, onSubmit, mode }: ClientFormProps) => {
  const { toast } = useToast();
  const [activeTab, setActiveTab] = useState("basic");
  const [formData, setFormData] = useState({
    name: client?.name || "",
    city: client?.city || "",
    address: client?.address || "",
    addressType: client?.addressType || "",
    gstNumber: client?.gstNumber || "",
    panNumber: client?.panNumber || "",
    logisticsPOCName: client?.logisticsPOC?.name || "",
    logisticsPOCPhone: client?.logisticsPOC?.phone || "",
    logisticsPOCEmail: client?.logisticsPOC?.email || "",
    financePOCName: client?.financePOC?.name || "",
    financePOCPhone: client?.financePOC?.phone || "",
    financePOCEmail: client?.financePOC?.email || "",
    invoicingType: client?.invoicingType || "",
    salesRepName: client?.salesRep?.name || "",
    salesRepDesignation: client?.salesRep?.designation || "",
    salesRepPhone: client?.salesRep?.phone || "",
    salesRepEmail: client?.salesRep?.email || "",
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

  const handleTabChange = (value: string) => {
    setActiveTab(value);
  };

  const handleSave = () => {
    // Validate required fields
    if (!formData.name || !formData.city || !formData.address) {
      toast({
        title: "Missing Information",
        description: "Please fill all required fields.",
        variant: "destructive",
      });
      return;
    }

    // Prepare client data object
    const clientData = {
      name: formData.name,
      city: formData.city,
      address: formData.address,
      addressType: formData.addressType,
      gstNumber: formData.gstNumber,
      panNumber: formData.panNumber,
      logisticsPOC: {
        name: formData.logisticsPOCName,
        phone: formData.logisticsPOCPhone,
        email: formData.logisticsPOCEmail,
      },
      financePOC: {
        name: formData.financePOCName,
        phone: formData.financePOCPhone,
        email: formData.financePOCEmail,
      },
      invoicingType: formData.invoicingType,
      salesRep: {
        name: formData.salesRepName,
        designation: formData.salesRepDesignation,
        phone: formData.salesRepPhone,
        email: formData.salesRepEmail,
      },
    };

    // If onSubmit is provided, use it, otherwise show toast
    if (onSubmit) {
      onSubmit(clientData);
    } else {
      toast({
        title: mode === "create" ? "Client Created" : "Client Updated",
        description: `${formData.name} has been ${mode === "create" ? "created" : "updated"} successfully.`,
      });
      onClose();
    }
  };

  const formProgress = () => {
    let filled = 0;
    let total = 0;
    
    // Basic tab fields
    ['name', 'city', 'address', 'addressType', 'invoicingType', 'gstNumber', 'panNumber'].forEach(field => {
      total++;
      if (formData[field as keyof typeof formData]) filled++;
    });
    
    // Contact tab fields (POCs)
    ['logisticsPOCName', 'logisticsPOCPhone', 'logisticsPOCEmail', 
     'financePOCName', 'financePOCPhone', 'financePOCEmail',
     'salesRepName', 'salesRepDesignation', 'salesRepPhone', 'salesRepEmail'].forEach(field => {
      total++;
      if (formData[field as keyof typeof formData]) filled++;
    });
    
    return Math.round((filled / total) * 100);
  };

  const calculateTabStatus = (tabId: string) => {
    switch(tabId) {
      case 'basic':
        const basicFields = ['name', 'city', 'address', 'addressType', 'invoicingType'];
        return basicFields.every(field => !!formData[field as keyof typeof formData]) ? 'complete' : 
               basicFields.some(field => !!formData[field as keyof typeof formData]) ? 'partial' : 'empty';
      
      case 'contact':
        const contactFields = ['logisticsPOCName', 'logisticsPOCPhone', 'logisticsPOCEmail', 
                              'financePOCName', 'financePOCPhone', 'financePOCEmail',
                              'salesRepName', 'salesRepDesignation', 'salesRepPhone', 'salesRepEmail'];
        return contactFields.every(field => !!formData[field as keyof typeof formData]) ? 'complete' : 
               contactFields.some(field => !!formData[field as keyof typeof formData]) ? 'partial' : 'empty';
      
      case 'documents':
        // This would depend on document upload status, for now it's always empty
        return 'empty';
      
      default:
        return 'empty';
    }
  };

  return (
    <div className="p-4">
      {/* Form progress indicator */}
      <div className="mb-6">
        <div className="flex justify-between items-center mb-2">
          <div className="text-sm font-medium">Client Onboarding Progress</div>
          <Badge variant={formProgress() === 100 ? "default" : "outline"} className="px-2 py-0 h-5">
            {formProgress()}%
          </Badge>
        </div>
        <div className="h-2 w-full bg-muted rounded-full overflow-hidden">
          <div
            className="h-full bg-primary transition-all duration-500 ease-in-out"
            style={{ width: `${formProgress()}%` }}
          ></div>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={handleTabChange} className="w-full">
        <TabsList className="grid w-full grid-cols-3 mb-2">
          <TabsTrigger 
            value="basic" 
            className="relative data-[state=active]:shadow-none"
          >
            <div className="flex items-center gap-2">
              <Building className="h-4 w-4" />
              <span>Basic Info</span>
            </div>
            <div className={cn(
              "absolute top-0 right-1 w-2 h-2 rounded-full",
              calculateTabStatus('basic') === 'complete' ? "bg-green-500" :
              calculateTabStatus('basic') === 'partial' ? "bg-amber-500" : "bg-muted"
            )} />
          </TabsTrigger>
          <TabsTrigger 
            value="contact" 
            className="relative data-[state=active]:shadow-none"
          >
            <div className="flex items-center gap-2">
              <User className="h-4 w-4" />
              <span>Contacts</span>
            </div>
            <div className={cn(
              "absolute top-0 right-1 w-2 h-2 rounded-full",
              calculateTabStatus('contact') === 'complete' ? "bg-green-500" :
              calculateTabStatus('contact') === 'partial' ? "bg-amber-500" : "bg-muted"
            )} />
          </TabsTrigger>
          <TabsTrigger 
            value="documents" 
            className="relative data-[state=active]:shadow-none"
          >
            <div className="flex items-center gap-2">
              <FileText className="h-4 w-4" />
              <span>Documents</span>
            </div>
            <div className={cn(
              "absolute top-0 right-1 w-2 h-2 rounded-full",
              calculateTabStatus('documents') === 'complete' ? "bg-green-500" :
              calculateTabStatus('documents') === 'partial' ? "bg-amber-500" : "bg-muted"
            )} />
          </TabsTrigger>
        </TabsList>

        {/* Basic Information Tab */}
        <TabsContent value="basic" className="space-y-4 mt-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="form-group">
              <label className="form-label" htmlFor="name">Client Name*</label>
              <Input
                id="name"
                value={formData.name}
                onChange={handleInputChange}
                placeholder="Enter client name"
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

            <div className="form-group">
              <label className="form-label" htmlFor="addressType">Address Type*</label>
              <Input
                id="addressType"
                value={formData.addressType}
                onChange={handleInputChange}
                placeholder="E.g., Head Office, Factory, Warehouse"
              />
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="invoicingType">Invoicing Type*</label>
              <Select
                value={formData.invoicingType}
                onValueChange={(value) => handleSelectChange("invoicingType", value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select Invoicing Type" />
                </SelectTrigger>
                <SelectContent>
                  {invoicingTypes.map((type) => (
                    <SelectItem key={type} value={type}>
                      {type}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <Separator className="my-4" />

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
              <label className="form-label" htmlFor="panNumber">PAN Number</label>
              <div className="flex space-x-2">
                <Input
                  id="panNumber"
                  value={formData.panNumber}
                  onChange={handleInputChange}
                  placeholder="Enter PAN number"
                  className="flex-1"
                />
                <Input type="file" className="w-48" />
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="form-group">
              <label className="form-label">Cancelled Cheque</label>
              <Input type="file" />
            </div>

            <div className="form-group">
              <label className="form-label">MSME Certificate</label>
              <Input type="file" />
            </div>
          </div>
        </TabsContent>

        {/* Contact Details Tab */}
        <TabsContent value="contact" className="space-y-4 mt-4">
          <div>
            <h3 className="text-lg font-medium mb-4">Logistics Point of Contact</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="form-group">
                <label className="form-label" htmlFor="logisticsPOCName">Name*</label>
                <Input
                  id="logisticsPOCName"
                  value={formData.logisticsPOCName}
                  onChange={handleInputChange}
                  placeholder="Enter name"
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="logisticsPOCPhone">Phone*</label>
                <Input
                  id="logisticsPOCPhone"
                  value={formData.logisticsPOCPhone}
                  onChange={handleInputChange}
                  placeholder="Enter phone number"
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="logisticsPOCEmail">Email*</label>
                <Input
                  id="logisticsPOCEmail"
                  value={formData.logisticsPOCEmail}
                  onChange={handleInputChange}
                  placeholder="Enter email address"
                  type="email"
                />
              </div>
            </div>
          </div>

          <Separator className="my-4" />

          <div>
            <h3 className="text-lg font-medium mb-4">Finance Point of Contact</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="form-group">
                <label className="form-label" htmlFor="financePOCName">Name*</label>
                <Input
                  id="financePOCName"
                  value={formData.financePOCName}
                  onChange={handleInputChange}
                  placeholder="Enter name"
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="financePOCPhone">Phone*</label>
                <Input
                  id="financePOCPhone"
                  value={formData.financePOCPhone}
                  onChange={handleInputChange}
                  placeholder="Enter phone number"
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="financePOCEmail">Email*</label>
                <Input
                  id="financePOCEmail"
                  value={formData.financePOCEmail}
                  onChange={handleInputChange}
                  placeholder="Enter email address"
                  type="email"
                />
              </div>
            </div>
          </div>

          <Separator className="my-4" />

          <div>
            <h3 className="text-lg font-medium mb-4">Sales Representative</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="form-group">
                <label className="form-label" htmlFor="salesRepName">Name*</label>
                <Input
                  id="salesRepName"
                  value={formData.salesRepName}
                  onChange={handleInputChange}
                  placeholder="Enter name"
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="salesRepDesignation">Designation*</label>
                <Input
                  id="salesRepDesignation"
                  value={formData.salesRepDesignation}
                  onChange={handleInputChange}
                  placeholder="Enter designation"
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="salesRepPhone">Phone*</label>
                <Input
                  id="salesRepPhone"
                  value={formData.salesRepPhone}
                  onChange={handleInputChange}
                  placeholder="Enter phone number"
                />
              </div>

              <div className="form-group">
                <label className="form-label" htmlFor="salesRepEmail">Email*</label>
                <Input
                  id="salesRepEmail"
                  value={formData.salesRepEmail}
                  onChange={handleInputChange}
                  placeholder="Enter email address"
                  type="email"
                />
              </div>
            </div>
          </div>
        </TabsContent>

        {/* Documents Tab */}
        <TabsContent value="documents" className="space-y-4 mt-4">
          <div className="form-group">
            <label className="form-label">Client Onboarding Form</label>
            <Input type="file" />
          </div>

          <div className="space-y-2">
            <h3 className="text-lg font-medium">Document Gallery</h3>
            <p className="text-sm text-gray-500">
              All uploaded documents related to this client will appear here.
            </p>
            <div className="p-10 border-2 border-dashed rounded-md flex justify-center items-center">
              <p className="text-gray-400">No documents uploaded yet</p>
            </div>
          </div>
        </TabsContent>
      </Tabs>

      <div className="mt-6 flex justify-between items-center">
        <Button variant="outline" onClick={onClose}>Cancel</Button>
        <div className="flex gap-2">
          {activeTab !== "basic" && (
            <Button variant="outline" onClick={() => handleTabChange(activeTab === "documents" ? "contact" : "basic")}>
              Previous
            </Button>
          )}
          {activeTab !== "documents" ? (
            <Button onClick={() => handleTabChange(activeTab === "basic" ? "contact" : "documents")}>
              Next
            </Button>
          ) : (
            <Button onClick={handleSave} className="bg-primary">
              {mode === "create" ? "Create Client" : "Update Client"}
            </Button>
          )}
        </div>
      </div>
    </div>
  );
};

export default ClientForm;
