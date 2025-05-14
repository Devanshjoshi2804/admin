import React from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useBookingForm } from "@/hooks/use-booking-form";
import { 
  vehicles, 
  vehicleTypes, 
  vehicleSizes, 
  vehicleCapacities, 
  axleTypes, 
  materialTypes, 
  weightUnits,
  addressTypes
} from "@/data/mockData";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Plus, X, FileUp } from "lucide-react";
import { Checkbox } from "@/components/ui/checkbox";

const BookingForm = () => {
  const {
    formState,
    step,
    isSubmitting,
    isLoading,
    clients,
    suppliers,
    updateField,
    addMaterial,
    updateMaterial,
    removeMaterial,
    addDocument,
    updateDocument,
    removeDocument,
    nextStep,
    prevStep,
    submitForm
  } = useBookingForm();

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="flex flex-col items-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mb-4"></div>
          <p className="text-slate-600 dark:text-slate-400">Loading client and supplier data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <Tabs
        value={step}
        onValueChange={(value: any) => updateField(value as keyof typeof formState, step)}
        className="w-full"
      >
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="basic-info">Basic Info</TabsTrigger>
          <TabsTrigger value="vehicle-material">Vehicle & Material</TabsTrigger>
          <TabsTrigger value="documentation-tracking">Documentation & Tracking</TabsTrigger>
        </TabsList>

        {/* Basic Info Tab */}
        <TabsContent value="basic-info" className="space-y-6">
          <div className="bg-white p-6 rounded-md border">
            <h2 className="text-xl font-semibold mb-4">Client Information</h2>
            <p className="text-sm text-gray-500 mb-4">Select client and address details</p>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="space-y-2">
                <Label htmlFor="clientName">Client Name*</Label>
                  <Select 
                  value={formState.clientId}
                  onValueChange={(value) => updateField("clientId", value)}
                  >
                  <SelectTrigger id="clientName">
                      <SelectValue placeholder="Select Client" />
                    </SelectTrigger>
                    <SelectContent>
                      {clients.map(client => (
                        <SelectItem key={client.id} value={client.id}>
                          {client.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

              <div className="space-y-2">
                <Label htmlFor="addressType">Address Type</Label>
                <Select 
                  value={formState.addressType}
                  onValueChange={(value) => updateField("addressType", value)}
                >
                  <SelectTrigger id="addressType">
                    <SelectValue placeholder="Select Type" />
                  </SelectTrigger>
                  <SelectContent>
                    {addressTypes.map(type => (
                      <SelectItem key={type} value={type}>
                        {type}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                </div>

              <div className="space-y-2">
                <Label htmlFor="clientCity">Client City</Label>
                  <Input 
                    id="clientCity" 
                  value={formState.clientCity}
                  onChange={(e) => updateField("clientCity", e.target.value)}
                  />
              </div>
                </div>

            <div className="mt-4">
              <Label htmlFor="loadingAddress">Loading Address</Label>
                  <Input 
                    id="loadingAddress" 
                value={formState.loadingAddress}
                onChange={(e) => updateField("loadingAddress", e.target.value)}
                className="mt-1"
                  />
                </div>

            <div className="mt-6 grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="space-y-2">
                <Label htmlFor="destinationAddress">Destination Address*</Label>
                  <Input 
                    id="destinationAddress" 
                  value={formState.destinationAddress}
                  onChange={(e) => updateField("destinationAddress", e.target.value)}
                  />
                </div>

              <div className="space-y-2">
                <Label htmlFor="destinationCity">Destination City*</Label>
                  <Input 
                    id="destinationCity" 
                  value={formState.destinationCity}
                  onChange={(e) => updateField("destinationCity", e.target.value)}
                  />
                </div>

              <div className="space-y-2">
                <Label htmlFor="destinationType">Destination Address Type*</Label>
                  <Select 
                  value={formState.destinationType}
                  onValueChange={(value) => updateField("destinationType", value)}
                  >
                  <SelectTrigger id="destinationType">
                      <SelectValue placeholder="Select Type" />
                    </SelectTrigger>
                    <SelectContent>
                      {addressTypes.map(type => (
                        <SelectItem key={type} value={type}>
                          {type}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
          </div>
          
          <div className="bg-white p-6 rounded-md border">
            <h2 className="text-xl font-semibold mb-4">Supplier Information</h2>
            <p className="text-sm text-gray-500 mb-4">Select supplier details</p>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="space-y-2">
                <Label htmlFor="supplierName">Supplier Name*</Label>
                  <Select 
                  value={formState.supplierId}
                  onValueChange={(value) => updateField("supplierId", value)}
                  >
                  <SelectTrigger id="supplierName">
                      <SelectValue placeholder="Select Supplier" />
                    </SelectTrigger>
                    <SelectContent>
                      {suppliers.map(supplier => (
                        <SelectItem key={supplier.id} value={supplier.id}>
                          {supplier.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

              <div className="space-y-2">
                <Label htmlFor="pickupDate">Pickup Date*</Label>
                  <Input 
                    id="pickupDate" 
                    type="date" 
                  value={formState.pickupDate}
                  onChange={(e) => updateField("pickupDate", e.target.value)}
                  />
                </div>

              <div className="space-y-2">
                <Label htmlFor="pickupTime">Pickup Time*</Label>
                  <Input 
                    id="pickupTime" 
                    type="time" 
                  value={formState.pickupTime}
                  onChange={(e) => updateField("pickupTime", e.target.value)}
                  />
                </div>
              </div>
          </div>
        </TabsContent>

        {/* Vehicle & Material Tab */}
        <TabsContent value="vehicle-material" className="space-y-6">
          <div className="bg-white p-6 rounded-md border">
            <h2 className="text-xl font-semibold mb-4">Vehicle Details</h2>
            <p className="text-sm text-gray-500 mb-4">Select vehicle and driver details</p>
            
            <div className="grid grid-cols-1 gap-6">
              <div>
                <Label htmlFor="registeredVehicle">Registered Vehicle</Label>
                <Select 
                  value={formState.vehicleId}
                  onValueChange={(value) => updateField("vehicleId", value)}
                >
                  <SelectTrigger id="registeredVehicle">
                      <SelectValue placeholder="Select Vehicle" />
                    </SelectTrigger>
                    <SelectContent>
                    {vehicles.map(vehicle => (
                          <SelectItem key={vehicle.id} value={vehicle.id}>
                            {vehicle.registrationNumber} - {vehicle.vehicleType}
                          </SelectItem>
                        ))}
                    </SelectContent>
                  </Select>
                </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="vehicleNumber">Vehicle Number*</Label>
                  <Input 
                    id="vehicleNumber" 
                    value={formState.vehicleNumber}
                    onChange={(e) => updateField("vehicleNumber", e.target.value)}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="driverName">Driver Name*</Label>
                  <Input 
                    id="driverName" 
                    value={formState.driverName}
                    onChange={(e) => updateField("driverName", e.target.value)}
                  />
                </div>
                </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="driverPhone">Driver Number*</Label>
                  <Input 
                    id="driverPhone"
                    value={formState.driverPhone}
                    onChange={(e) => updateField("driverPhone", e.target.value)}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="vehicleType">Vehicle Type*</Label>
                  <Select 
                    value={formState.vehicleType}
                    onValueChange={(value) => updateField("vehicleType", value)}
                  >
                    <SelectTrigger id="vehicleType">
                      <SelectValue placeholder="Select Type" />
                    </SelectTrigger>
                    <SelectContent>
                      {vehicleTypes.map(type => (
                        <SelectItem key={type} value={type}>
                          {type}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="vehicleSize">Vehicle Size*</Label>
                  <Select 
                    value={formState.vehicleSize}
                    onValueChange={(value) => updateField("vehicleSize", value)}
                  >
                    <SelectTrigger id="vehicleSize">
                      <SelectValue placeholder="Select Size" />
                    </SelectTrigger>
                    <SelectContent>
                      {vehicleSizes.map(size => (
                        <SelectItem key={size} value={size}>
                          {size}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="vehicleCapacity">Vehicle Capacity*</Label>
                  <Select 
                    value={formState.vehicleCapacity}
                    onValueChange={(value) => updateField("vehicleCapacity", value)}
                  >
                    <SelectTrigger id="vehicleCapacity">
                      <SelectValue placeholder="Select Capacity" />
                    </SelectTrigger>
                    <SelectContent>
                      {vehicleCapacities.map(capacity => (
                        <SelectItem key={capacity} value={capacity}>
                          {capacity}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="axleType">Axle Type*</Label>
                  <Select 
                    value={formState.axleType}
                    onValueChange={(value) => updateField("axleType", value)}
                  >
                    <SelectTrigger id="axleType">
                      <SelectValue placeholder="Select Type" />
                    </SelectTrigger>
                    <SelectContent>
                      {axleTypes.map(type => (
                        <SelectItem key={type} value={type}>
                          {type}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </div>
          </div>
          
          <div className="bg-white p-6 rounded-md border">
            <h2 className="text-xl font-semibold mb-4">Material Information</h2>
            <p className="text-sm text-gray-500 mb-4">Enter material details</p>
            
            {formState.materials.map((material, index) => (
              <div key={material.id} className="grid grid-cols-5 gap-4 items-center mb-4">
                <div>
                  <Label htmlFor={`material-${index}`}>Material Type*</Label>
                  <Select 
                    value={material.name}
                    onValueChange={(value) => updateMaterial(material.id, "name", value)}
                  >
                    <SelectTrigger id={`material-${index}`}>
                          <SelectValue placeholder="Select Material" />
                        </SelectTrigger>
                        <SelectContent>
                          {materialTypes.map(type => (
                        <SelectItem key={type} value={type}>
                          {type}
                        </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                
                <div>
                  <Label htmlFor={`weight-${index}`}>Weight*</Label>
                      <Input 
                    id={`weight-${index}`}
                        type="number" 
                        min="0"
                    value={material.weight || ""}
                    onChange={(e) => updateMaterial(material.id, "weight", Number(e.target.value))}
                      />
                    </div>
                
                <div>
                  <Label htmlFor={`unit-${index}`}>Unit*</Label>
                      <Select 
                        value={material.unit} 
                    onValueChange={(value) => updateMaterial(material.id, "unit", value as 'MT' | 'KG')}
                      >
                    <SelectTrigger id={`unit-${index}`}>
                      <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          {weightUnits.map(unit => (
                        <SelectItem key={unit} value={unit}>
                          {unit}
                        </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                
                <div>
                  <Label htmlFor={`rate-${index}`}>Rate Per MT*</Label>
                      <Input 
                    id={`rate-${index}`}
                        type="number" 
                        min="0"
                    value={material.ratePerMT || ""}
                    onChange={(e) => updateMaterial(material.id, "ratePerMT", Number(e.target.value))}
                      />
                    </div>
                
                <div className="pt-6 flex items-center">
                      <Button 
                    type="button"
                    variant="ghost"
                        size="icon"
                    className="h-8 w-8"
                    onClick={() => removeMaterial(material.id)}
                      >
                    <X className="h-4 w-4" />
                      </Button>
                  <span className="ml-2">₹{material.amount.toLocaleString()}</span>
                    </div>
                  </div>
                ))}
                
                <Button
              type="button"
                  variant="outline"
                  size="sm"
              onClick={addMaterial}
                  className="mt-2"
                >
              <Plus className="h-4 w-4 mr-2" /> Add Material
                </Button>
              </div>
          
          <div className="bg-white p-6 rounded-md border">
            <h2 className="text-xl font-semibold mb-4">Freight Information</h2>
            <p className="text-sm text-gray-500 mb-4">Enter freight and payment details</p>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="space-y-2">
                <Label htmlFor="clientFreight">Client Freight (₹)*</Label>
                  <Input 
                    id="clientFreight" 
                    type="number" 
                    min="0"
                  value={formState.clientFreight || ""}
                  onChange={(e) => updateField("clientFreight", Number(e.target.value))}
                  readOnly
                  />
                </div>

              <div className="space-y-2">
                <Label htmlFor="supplierFreight">Supplier Freight (₹)*</Label>
                  <Input 
                    id="supplierFreight" 
                    type="number" 
                    min="0"
                  value={formState.supplierFreight || ""}
                  onChange={(e) => updateField("supplierFreight", Number(e.target.value))}
                  />
                </div>

              <div className="space-y-2">
                <Label htmlFor="margin">Margin (₹)</Label>
                  <Input 
                    id="margin" 
                    type="number" 
                  readOnly
                  value={formState.margin || ""}
                  />
              </div>
                </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-4">
              <div className="space-y-2">
                <Label htmlFor="advancePercentage">Advance Percentage (%)*</Label>
                  <Input 
                    id="advancePercentage" 
                    type="number" 
                    min="0" 
                    max="100"
                  value={formState.advancePercentage || ""}
                  onChange={(e) => updateField("advancePercentage", Number(e.target.value))}
                  />
                </div>

              <div className="space-y-2">
                <Label htmlFor="advanceSupplierFreight">Advance Supplier Freight (₹)</Label>
                  <Input 
                  id="advanceSupplierFreight"
                    type="number" 
                  readOnly
                  value={formState.advanceSupplierFreight || ""}
                  />
                </div>

              <div className="space-y-2">
                <Label htmlFor="balanceSupplierFreight">Balance Supplier Freight (₹)</Label>
                  <Input 
                  id="balanceSupplierFreight"
                    type="number" 
                  readOnly
                  value={formState.balanceSupplierFreight || ""}
                  />
                </div>
              </div>
          </div>
        </TabsContent>

        {/* Documentation & Tracking Tab */}
        <TabsContent value="documentation-tracking" className="space-y-6">
          <div className="bg-white p-6 rounded-md border">
            <h2 className="text-xl font-semibold mb-4">Document Upload</h2>
            <p className="text-sm text-gray-500 mb-4">Add LR numbers, invoices, and e-way bills</p>
            
              <div className="space-y-6">
                <div className="space-y-2">
                <Label htmlFor="lrNumbers">LR Numbers*</Label>
                {formState.lrNumbers.map((lr, index) => (
                  <div key={index} className="flex items-center gap-2 mt-2">
                      <Input
                      value={lr.number}
                      onChange={(e) => updateDocument("lrNumbers", index, "number", e.target.value)}
                        placeholder="Enter LR Number"
                    />
                    <Button 
                      type="button" 
                      variant="ghost" 
                      size="icon" 
                      onClick={() => removeDocument("lrNumbers", index)}
                    >
                      <X className="h-4 w-4" />
                    </Button>
                    <div className="relative cursor-pointer">
                      <Button type="button" variant="outline">
                        Choose File {lr.file && "✓"}
                      </Button>
                      <input
                        type="file"
                        className="absolute inset-0 opacity-0 cursor-pointer"
                        onChange={(e) => {
                          if (e.target.files?.[0]) {
                            updateDocument("lrNumbers", index, "file", e.target.files[0]);
                          }
                        }}
                      />
                    </div>
                    </div>
                  ))}
                  <Button
                  type="button" 
                    variant="outline"
                    size="sm"
                  onClick={() => addDocument("lrNumbers")}
                    className="mt-2"
                  >
                  <Plus className="h-4 w-4 mr-2" /> Add LR Number
                  </Button>
                </div>

                <div className="space-y-2">
                <Label htmlFor="invoices">Invoice of Material*</Label>
                {formState.invoices.map((invoice, index) => (
                  <div key={index} className="flex items-center gap-2 mt-2">
                    <Input
                      value={invoice.number}
                      onChange={(e) => updateDocument("invoices", index, "number", e.target.value)}
                      placeholder="Invoice Number"
                    />
                    <Button 
                      type="button" 
                      variant="ghost" 
                      size="icon" 
                      onClick={() => removeDocument("invoices", index)}
                    >
                      <X className="h-4 w-4" />
                    </Button>
                    <div className="relative cursor-pointer">
                      <Button type="button" variant="outline">
                        Choose File {invoice.file && "✓"}
                      </Button>
                      <input
                      type="file"
                        className="absolute inset-0 opacity-0 cursor-pointer"
                        onChange={(e) => {
                          if (e.target.files?.[0]) {
                            updateDocument("invoices", index, "file", e.target.files[0]);
                          }
                        }}
                      />
                    </div>
                  </div>
                ))}
                  <Button
                  type="button" 
                    variant="outline"
                    size="sm"
                  onClick={() => addDocument("invoices")}
                    className="mt-2"
                  >
                  <Plus className="h-4 w-4 mr-2" /> Add Invoice
                  </Button>
                </div>

                <div className="space-y-2">
                <Label htmlFor="ewayBills">E-way Bills*</Label>
                {formState.ewayBills.map((bill, index) => (
                  <div key={index} className="flex flex-wrap items-center gap-2 mt-2">
                    <Input
                      value={bill.number}
                      onChange={(e) => updateDocument("ewayBills", index, "number", e.target.value)}
                      placeholder="E-way Bill Number"
                      className="flex-1 min-w-[200px]"
                    />
                    <Button 
                      type="button" 
                      variant="ghost" 
                      size="icon" 
                      onClick={() => removeDocument("ewayBills", index)}
                    >
                      <X className="h-4 w-4" />
                    </Button>
                    <div className="relative cursor-pointer">
                      <Button type="button" variant="outline">
                        Choose File {bill.file && "✓"}
                      </Button>
                      <input
                      type="file"
                        className="absolute inset-0 opacity-0 cursor-pointer"
                        onChange={(e) => {
                          if (e.target.files?.[0]) {
                            updateDocument("ewayBills", index, "file", e.target.files[0]);
                          }
                        }}
                      />
                    </div>
                    <div className="flex flex-wrap items-center gap-2 w-full mt-2">
                      <div className="flex flex-col">
                        <Label htmlFor={`ewayBill-date-${index}`} className="text-xs text-muted-foreground">Expiry Date*</Label>
                        <Input
                          id={`ewayBill-date-${index}`}
                          type="date"
                          className="max-w-[180px]" 
                          value={bill.expiryDate}
                          onChange={(e) => updateDocument("ewayBills", index, "expiryDate", e.target.value)}
                        />
                      </div>
                      <div className="flex flex-col">
                        <Label htmlFor={`ewayBill-time-${index}`} className="text-xs text-muted-foreground font-bold text-red-500">Expiry Time*</Label>
                        <Input
                          id={`ewayBill-time-${index}`}
                          type="time"
                          className="max-w-[180px]" 
                          value={bill.expiryTime}
                          onChange={(e) => updateDocument("ewayBills", index, "expiryTime", e.target.value)}
                        />
                      </div>
                    </div>
                  </div>
                ))}
                  <Button
                  type="button" 
                    variant="outline"
                    size="sm"
                  onClick={() => addDocument("ewayBills")}
                    className="mt-2"
                  >
                  <Plus className="h-4 w-4 mr-2" /> Add E-way Bill
                  </Button>
                </div>
              </div>
          </div>
          
          <div className="bg-white p-6 rounded-md border">
            <h2 className="text-xl font-semibold mb-4">Field Operations & Tracking</h2>
            <p className="text-sm text-gray-500 mb-4">Assign operations team and enable tracking</p>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="space-y-2">
                <Label htmlFor="fieldOpsName">Field Ops Name*</Label>
                  <Input 
                  id="fieldOpsName"
                  value={formState.fieldOpsName}
                  onChange={(e) => updateField("fieldOpsName", e.target.value)}
                    placeholder="Enter name"
                  />
                </div>

              <div className="space-y-2">
                <Label htmlFor="fieldOpsPhone">Field Ops Phone*</Label>
                  <Input 
                  id="fieldOpsPhone"
                  value={formState.fieldOpsPhone}
                  onChange={(e) => updateField("fieldOpsPhone", e.target.value)}
                    placeholder="Enter phone number"
                  />
                </div>

              <div className="space-y-2">
                <Label htmlFor="fieldOpsEmail">Field Ops Email*</Label>
                  <Input 
                  id="fieldOpsEmail"
                    type="email" 
                  value={formState.fieldOpsEmail}
                  onChange={(e) => updateField("fieldOpsEmail", e.target.value)}
                    placeholder="Enter email address"
                  />
              </div>
                </div>

            <div className="flex items-center space-x-2 mt-6">
              <Checkbox
                id="enableGSMTracking"
                checked={formState.enableGSMTracking}
                onCheckedChange={(checked) => 
                  updateField("enableGSMTracking", checked as boolean)
                }
              />
              <Label htmlFor="enableGSMTracking">Enable GSM Tracking</Label>
                </div>
              </div>
        </TabsContent>
      </Tabs>

      {/* Action buttons */}
      <div className="flex justify-end">
        {step !== "basic-info" && (
          <Button
            type="button"
            variant="outline"
            onClick={prevStep}
            className="mr-2"
            disabled={isSubmitting}
          >
            Back
          </Button>
        )}
        
        {step === "documentation-tracking" ? (
          <Button 
            type="button" 
            onClick={submitForm} 
            disabled={isSubmitting}
            className={isSubmitting ? "opacity-80" : ""}
          >
            {isSubmitting ? (
              <>
                <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Processing Booking...
              </>
            ) : (
              "Confirm Booking"
            )}
          </Button>
        ) : (
        <Button
            type="button" 
            onClick={nextStep}
            disabled={isSubmitting}
          >
            Continue Booking
        </Button>
        )}
      </div>
      
      {/* Success notification overlay that appears when a booking is successfully created */}
      {isSubmitting && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg max-w-md w-full text-center">
            <svg className="animate-spin h-10 w-10 text-primary mx-auto mb-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <h3 className="text-lg font-semibold mb-2">Creating Booking...</h3>
            <p className="text-gray-600 mb-1">Your booking is being processed.</p>
            <p className="text-gray-600 text-sm">You'll be redirected to the trips dashboard when complete.</p>
          </div>
        </div>
      )}
    </div>
  );
};

export default BookingForm;
