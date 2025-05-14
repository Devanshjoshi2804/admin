
import React, { useState, useEffect } from "react";
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
import {
  vehicleTypes,
  vehicleSizes,
  vehicleCapacities,
  axleTypes
} from "@/data/mockData";

interface VehicleFormProps {
  vehicle?: any;
  suppliers: any[];
  onClose: () => void;
  mode: "create" | "edit";
}

const VehicleForm = ({ vehicle, suppliers, onClose, mode }: VehicleFormProps) => {
  const { toast } = useToast();
  const [formData, setFormData] = useState({
    registrationNumber: vehicle?.registrationNumber || "",
    supplierId: vehicle?.supplierId || "",
    vehicleType: vehicle?.vehicleType || "",
    vehicleSize: vehicle?.vehicleSize || "",
    vehicleCapacity: vehicle?.vehicleCapacity || "",
    axleType: vehicle?.axleType || "",
    driverName: vehicle?.driverName || "",
    driverPhone: vehicle?.driverPhone || "",
    insuranceExpiry: vehicle?.insuranceExpiry || "",
    rcNumber: vehicle?.rcNumber || "",
    pucExpiry: vehicle?.pucExpiry || "",
    driverLicenseNumber: vehicle?.driverLicenseNumber || "",
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

  const handleSave = () => {
    // Validate required fields
    if (!formData.registrationNumber || !formData.supplierId || !formData.vehicleType) {
      toast({
        title: "Missing Information",
        description: "Please fill all required fields.",
        variant: "destructive",
      });
      return;
    }

    // Logic to save vehicle would go here
    toast({
      title: mode === "create" ? "Vehicle Created" : "Vehicle Updated",
      description: `Vehicle ${formData.registrationNumber} has been ${mode === "create" ? "created" : "updated"} successfully.`,
    });
    onClose();
  };

  return (
    <div className="p-4">
      <Tabs defaultValue="basic" className="w-full">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="basic">Vehicle Information</TabsTrigger>
          <TabsTrigger value="documents">Documents & Compliance</TabsTrigger>
        </TabsList>

        {/* Basic Information Tab */}
        <TabsContent value="basic" className="space-y-4 mt-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="form-group">
              <label className="form-label" htmlFor="supplierId">Supplier*</label>
              <Select
                value={formData.supplierId}
                onValueChange={(value) => handleSelectChange("supplierId", value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select Supplier" />
                </SelectTrigger>
                <SelectContent>
                  {suppliers.map((supplier) => (
                    <SelectItem key={supplier.id} value={supplier.id}>
                      {supplier.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="registrationNumber">Vehicle Registration Number*</label>
              <Input
                id="registrationNumber"
                value={formData.registrationNumber}
                onChange={handleInputChange}
                placeholder="Enter registration number"
              />
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="vehicleType">Vehicle Type*</label>
              <Select
                value={formData.vehicleType}
                onValueChange={(value) => handleSelectChange("vehicleType", value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select Vehicle Type" />
                </SelectTrigger>
                <SelectContent>
                  {vehicleTypes.map((type) => (
                    <SelectItem key={type} value={type}>
                      {type}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="vehicleSize">Vehicle Size*</label>
              <Select
                value={formData.vehicleSize}
                onValueChange={(value) => handleSelectChange("vehicleSize", value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select Vehicle Size" />
                </SelectTrigger>
                <SelectContent>
                  {vehicleSizes.map((size) => (
                    <SelectItem key={size} value={size}>
                      {size}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="vehicleCapacity">Vehicle Capacity*</label>
              <Select
                value={formData.vehicleCapacity}
                onValueChange={(value) => handleSelectChange("vehicleCapacity", value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select Vehicle Capacity" />
                </SelectTrigger>
                <SelectContent>
                  {vehicleCapacities.map((capacity) => (
                    <SelectItem key={capacity} value={capacity}>
                      {capacity}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="axleType">Axle Type*</label>
              <Select
                value={formData.axleType}
                onValueChange={(value) => handleSelectChange("axleType", value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select Axle Type" />
                </SelectTrigger>
                <SelectContent>
                  {axleTypes.map((type) => (
                    <SelectItem key={type} value={type}>
                      {type}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="form-group">
              <label className="form-label" htmlFor="driverName">Driver Name*</label>
              <Input
                id="driverName"
                value={formData.driverName}
                onChange={handleInputChange}
                placeholder="Enter driver name"
              />
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="driverPhone">Driver Phone*</label>
              <Input
                id="driverPhone"
                value={formData.driverPhone}
                onChange={handleInputChange}
                placeholder="Enter driver phone"
              />
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="driverLicenseNumber">Driver License Number*</label>
              <Input
                id="driverLicenseNumber"
                value={formData.driverLicenseNumber}
                onChange={handleInputChange}
                placeholder="Enter driver license number"
              />
            </div>
          </div>
        </TabsContent>

        {/* Documents & Compliance Tab */}
        <TabsContent value="documents" className="space-y-4 mt-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="form-group">
              <label className="form-label" htmlFor="rcNumber">Registration Certificate Number*</label>
              <div className="flex space-x-2">
                <Input
                  id="rcNumber"
                  value={formData.rcNumber}
                  onChange={handleInputChange}
                  placeholder="Enter RC number"
                  className="flex-1"
                />
                <Input type="file" className="w-48" />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="insuranceExpiry">Insurance Expiry Date*</label>
              <div className="flex space-x-2">
                <Input
                  id="insuranceExpiry"
                  type="date"
                  value={formData.insuranceExpiry}
                  onChange={handleInputChange}
                  className="flex-1"
                />
                <Input type="file" className="w-48" />
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="form-group">
              <label className="form-label" htmlFor="pucExpiry">PUC Expiry Date*</label>
              <div className="flex space-x-2">
                <Input
                  id="pucExpiry"
                  type="date"
                  value={formData.pucExpiry}
                  onChange={handleInputChange}
                  className="flex-1"
                />
                <Input type="file" className="w-48" />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Driver License</label>
              <Input type="file" />
            </div>
          </div>
        </TabsContent>
      </Tabs>

      <div className="mt-6 flex justify-end space-x-2">
        <Button variant="outline" onClick={onClose}>Cancel</Button>
        <Button onClick={handleSave}>{mode === "create" ? "Add Vehicle" : "Update Vehicle"}</Button>
      </div>
    </div>
  );
};

export default VehicleForm;
