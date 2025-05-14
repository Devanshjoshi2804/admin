import React, { useState, useEffect, ReactNode } from "react";
import { useToast } from "@/hooks/use-toast";
import { useDocuments } from "@/hooks/use-documents";
import { vehicles, Vehicle, suppliers, vehicleTypes, axleTypes } from "@/data/mockData";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { FileActions, FileData } from "@/components/ui/file-actions";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { Search, Plus, Edit, Download, X, Inbox } from "lucide-react";
import { cn } from "@/lib/utils";
import { Badge } from "@/components/ui/badge";

interface VehicleFilters {
  registrationNumber: string;
  supplierId: string;
  vehicleType: string;
  axleType: string;
}

interface VehicleListProps {
  setDynamicSidebarContent?: (content: ReactNode | null) => void;
}

const VehicleList = ({ setDynamicSidebarContent }: VehicleListProps) => {
  const { toast } = useToast();
  const { getDocuments, addDocument } = useDocuments();
  const [searchTerm, setSearchTerm] = useState(""); // General search
  const [allVehicles, setAllVehicles] = useState<Vehicle[]>(vehicles); // Base data
  const [filteredVehicles, setFilteredVehicles] = useState<Vehicle[]>(vehicles); // Displayed data
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [currentVehicle, setCurrentVehicle] = useState<Vehicle | null>(null);
  const [filters, setFilters] = useState<VehicleFilters>({
    registrationNumber: "",
    supplierId: "",
    vehicleType: "",
    axleType: "",
  });

  const uniqueSuppliers = suppliers; // Assuming suppliers data is available
  const uniqueVehicleTypes = vehicleTypes;
  const uniqueAxleTypes = axleTypes;

  const handleFilterChange = (field: keyof VehicleFilters, value: string) => {
    setFilters(prev => ({ ...prev, [field]: value }));
  };

  const applyFilters = () => {
    let tempVehicles = allVehicles;

    if (filters.registrationNumber) {
      tempVehicles = tempVehicles.filter(v => 
        v.registrationNumber.toLowerCase().includes(filters.registrationNumber.toLowerCase())
      );
    }
    if (filters.supplierId) {
      tempVehicles = tempVehicles.filter(v => v.supplierId === filters.supplierId);
    }
    if (filters.vehicleType) {
      tempVehicles = tempVehicles.filter(v => v.vehicleType === filters.vehicleType);
    }
    if (filters.axleType) {
      tempVehicles = tempVehicles.filter(v => v.axleType === filters.axleType);
    }

    setFilteredVehicles(tempVehicles);
    // Re-apply general search
    handleGeneralSearch(searchTerm, tempVehicles);
  };

  const clearFilters = () => {
    setFilters({ registrationNumber: "", supplierId: "", vehicleType: "", axleType: "" });
    setFilteredVehicles(allVehicles);
    setSearchTerm("");
  };

  useEffect(() => {
    applyFilters();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters, allVehicles]);

  // --- General Search ---
  const handleGeneralSearch = (term: string, baseList: Vehicle[] = filteredVehicles) => {
    setSearchTerm(term);
    let searchFiltered = baseList;

    if (term.trim()) {
        const lowerCaseTerm = term.toLowerCase();
        searchFiltered = baseList.filter(
      (vehicle) =>
            vehicle.registrationNumber.toLowerCase().includes(lowerCaseTerm) ||
            vehicle.supplierName.toLowerCase().includes(lowerCaseTerm) ||
            vehicle.vehicleType.toLowerCase().includes(lowerCaseTerm) ||
            vehicle.driverName.toLowerCase().includes(lowerCaseTerm)
        );
    }
    setFilteredVehicles(searchFiltered);
  };
  // ----------------------

  const renderSidebarFilters = () => (
    <div className="space-y-4">
      <div>
        <Label htmlFor="filter-regNum" className="text-xs font-medium">Registration No.</Label>
        <Input 
          id="filter-regNum" 
          placeholder="Search Reg No..."
          value={filters.registrationNumber}
          onChange={(e) => handleFilterChange("registrationNumber", e.target.value)}
          className="h-9 text-sm mt-1"
        />
      </div>
      <div>
        <Label htmlFor="filter-supplier" className="text-xs font-medium">Supplier</Label>
        <Select 
          value={filters.supplierId}
          onValueChange={(value) => handleFilterChange("supplierId", value)}
        >
          <SelectTrigger id="filter-supplier" className="h-9 text-sm mt-1">
            <SelectValue placeholder="All Suppliers" />
          </SelectTrigger>
          <SelectContent>
            {uniqueSuppliers.map(supplier => (
              <SelectItem key={supplier.id} value={supplier.id} className="text-sm">
                {supplier.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <div>
        <Label htmlFor="filter-vehicleType" className="text-xs font-medium">Vehicle Type</Label>
        <Select 
          value={filters.vehicleType}
          onValueChange={(value) => handleFilterChange("vehicleType", value)}
        >
          <SelectTrigger id="filter-vehicleType" className="h-9 text-sm mt-1">
            <SelectValue placeholder="All Types" />
          </SelectTrigger>
          <SelectContent>
            {uniqueVehicleTypes.map(type => (
              <SelectItem key={type} value={type} className="text-sm">
                {type}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <div>
        <Label htmlFor="filter-axleType" className="text-xs font-medium">Axle Type</Label>
        <Select 
          value={filters.axleType}
          onValueChange={(value) => handleFilterChange("axleType", value)}
        >
          <SelectTrigger id="filter-axleType" className="h-9 text-sm mt-1">
            <SelectValue placeholder="All Axle Types" />
          </SelectTrigger>
          <SelectContent>
            {uniqueAxleTypes.map(type => (
              <SelectItem key={type} value={type} className="text-sm">
                {type}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <Button variant="ghost" size="sm" onClick={clearFilters} className="w-full text-sm h-9 mt-2">
        <X className="h-4 w-4 mr-1.5"/> Clear Filters
      </Button>
    </div>
  );

  useEffect(() => {
    if (setDynamicSidebarContent) {
      setDynamicSidebarContent(renderSidebarFilters());
    }
    return () => {
      if (setDynamicSidebarContent) {
        setDynamicSidebarContent(null);
      }
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [setDynamicSidebarContent, filters, allVehicles]);

  const handleExportToExcel = () => {
    toast({
      title: "Export Initiated",
      description: "Your vehicle details are being exported to Excel.",
    });

    // Create a fake blob for download demonstration
    const blob = new Blob(['Fake Excel Data'], { type: 'application/vnd.ms-excel' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'vehicles_export.xlsx';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  };

  const handleEditVehicle = (vehicle: Vehicle) => {
    setCurrentVehicle(vehicle);
    setIsEditDialogOpen(true);
  };

  const handleDocumentUpload = (vehicleId: string, fileData: FileData) => {
    addDocument(vehicleId, fileData);
    
    toast({
      title: "Vehicle Document Added",
      description: `${fileData.name} has been uploaded for vehicle records`,
    });
  };

  // Calculate insurance status (valid, expiring soon, expired)
  const getInsuranceStatus = (expiryDate: string): { status: string; variant: "default" | "destructive" | "outline" | "secondary" | "ghost" | "link" | "success" | "warning" | null | undefined } => {
    const today = new Date();
    today.setHours(0, 0, 0, 0); // Normalize today to start of day
    const expiry = new Date(expiryDate);
    expiry.setHours(0, 0, 0, 0); // Normalize expiry to start of day
    const daysRemaining = Math.ceil((expiry.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
    
    if (daysRemaining < 0) {
      return { status: "Expired", variant: "destructive" };
    } else if (daysRemaining < 30) {
      return { status: `Expiring in ${daysRemaining} days`, variant: "warning" };
    } else {
      return { status: "Valid", variant: "success" };
    }
  };

  return (
    <Card className="shadow-sm">
      <CardHeader className="flex flex-row items-center justify-between space-x-4 p-4 border-b">
        <div className="flex items-center gap-3 flex-1">
           {/* General Search */}
          <div className="relative w-full max-w-md">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
              placeholder="Search vehicles (Reg No, Supplier, Type, Driver...)"
                value={searchTerm}
              onChange={(e) => handleGeneralSearch(e.target.value, filteredVehicles)}
              className="pl-9 h-10 w-full"
            />
            </div>
           {/* Export Button */}
            <Button
              variant="outline"
            size="default"
              onClick={handleExportToExcel}
            className="h-10"
            >
            <Download size={16} className="mr-2" /> Export
            </Button>
        </div>
         {/* Add Vehicle Button */} 
            <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
              <DialogTrigger asChild>
            <Button size="default" className="h-10">
              <Plus size={16} className="mr-2" /> Add Vehicle
                </Button>
              </DialogTrigger>
          <DialogContent className="sm:max-w-[900px] max-h-[90vh] overflow-y-auto p-6">
            <DialogHeader className="mb-4">
              <DialogTitle className="text-xl">Add New Vehicle</DialogTitle>
                  <DialogDescription>
                Register a new vehicle in the system.
                  </DialogDescription>
                </DialogHeader>
            {/* TODO: Replace with VehicleForm component */}
            <div className="p-4 text-center text-muted-foreground border rounded-md min-h-[200px] flex items-center justify-center">
              Vehicle Add Form Component Placeholder
            </div>
             {/* <VehicleForm onClose={() => setIsAddDialogOpen(false)} mode="create" /> */}
              </DialogContent>
            </Dialog>
        </CardHeader>
      <CardContent className="p-0">
        <div className="overflow-hidden">
          <div className="overflow-x-auto relative">
            <Table className="min-w-full">
              <TableHeader className="bg-muted/50">
                <TableRow className="border-b border-border hover:bg-muted/60">
                  <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Reg. Number</TableHead>
                  <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Supplier</TableHead>
                  <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Type</TableHead>
                  <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Size/Cap/Axle</TableHead>
                  <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Driver</TableHead>
                  <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Insurance Status</TableHead>
                  <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Actions</TableHead>
                  </TableRow>
                </TableHeader>
              <TableBody className="divide-y divide-border">
                  {filteredVehicles.length > 0 ? (
                  filteredVehicles.map((vehicle, index) => {
                    const insuranceStatus = getInsuranceStatus(vehicle.insuranceExpiry);
                    return (
                      <TableRow 
                        key={vehicle.id}
                        className={cn("hover:bg-muted/40 transition-colors duration-150", index % 2 !== 0 && "bg-muted/20")}
                      >
                        <TableCell className="font-medium px-6 py-4 whitespace-nowrap text-sm">{vehicle.registrationNumber}</TableCell>
                        <TableCell className="px-6 py-4 whitespace-nowrap text-sm text-foreground">{vehicle.supplierName}</TableCell>
                        <TableCell className="px-6 py-4 whitespace-nowrap text-sm">{vehicle.vehicleType}</TableCell>
                        <TableCell className="px-6 py-4 whitespace-nowrap text-sm">
                          {vehicle.vehicleSize}, {vehicle.vehicleCapacity}
                          <div className="text-xs text-muted-foreground">
                            {vehicle.axleType}
                          </div>
                        </TableCell>
                        <TableCell className="px-6 py-4 whitespace-nowrap text-sm">
                          {vehicle.driverName}
                          <div className="text-xs text-muted-foreground">
                            {vehicle.driverPhone}
                          </div>
                        </TableCell>
                        <TableCell className="px-6 py-4 whitespace-nowrap">
                          <Badge variant={insuranceStatus.variant} className="text-xs font-medium">
                            {insuranceStatus.status}
                          </Badge>
                        </TableCell>
                        <TableCell className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center space-x-1">
                            <Dialog open={isEditDialogOpen && currentVehicle?.id === vehicle.id} onOpenChange={setIsEditDialogOpen}>
                              <DialogTrigger asChild>
                                <Button
                                  variant="ghost"
                                  size="icon"
                                  className="h-8 w-8 text-muted-foreground hover:text-foreground"
                                  title="Edit Vehicle"
                                  onClick={() => handleEditVehicle(vehicle)}
                                >
                                  <Edit size={16} />
                                </Button>
                              </DialogTrigger>
                              <DialogContent className="sm:max-w-[900px] max-h-[90vh] overflow-y-auto p-6">
                                <DialogHeader className="mb-4">
                                  <DialogTitle className="text-xl">Edit Vehicle: {currentVehicle?.registrationNumber}</DialogTitle>
                                  <DialogDescription>
                                    Update vehicle information.
                                  </DialogDescription>
                                </DialogHeader>
                                 {/* TODO: Replace with VehicleForm component */}
                                <div className="p-4 text-center text-muted-foreground border rounded-md min-h-[200px] flex items-center justify-center">
                                  Vehicle Edit Form Component Placeholder
                                </div>
                                {/* <VehicleForm vehicle={currentVehicle} onClose={() => {setIsEditDialogOpen(false); setCurrentVehicle(null);}} mode="edit" /> */}
                              </DialogContent>
                            </Dialog>
                            <FileActions 
                              id={vehicle.id}
                              type="vehicle"
                              entityName={vehicle.registrationNumber}
                              documentType="Vehicle Document" // RC, Insurance, Permit etc.
                              onSuccess={(fileData) => handleDocumentUpload(vehicle.id, fileData)}
                              existingFiles={getDocuments(vehicle.id)}
                              buttonVariant="ghost"
                              buttonSize="icon"
                            />
                          </div>
                        </TableCell>
                      </TableRow>
                    );
                  })
                  ) : (
                    <TableRow>
                    <TableCell colSpan={7} className="text-center py-16 text-muted-foreground">
                       <Inbox className="h-12 w-12 mx-auto mb-3 text-gray-400" />
                       <p className="font-medium">No Vehicles Found</p>
                       <p className="text-sm">Add a new vehicle or adjust your search/filters.</p>
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </div>
          </div>
        </CardContent>
      </Card>
  );
};

export default VehicleList;
