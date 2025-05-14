import React, { useState, useEffect, ReactNode } from "react";
import { useToast } from "@/hooks/use-toast";
import { useDocuments } from "@/hooks/use-documents";
import { Supplier } from "@/data/mockData";
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
import { Search, Plus, Edit, Download, X, Inbox, RefreshCw, AlertCircle } from "lucide-react";
import SupplierForm from "./SupplierForm";
import { cn } from "@/lib/utils";
import api from "@/lib/api";

interface SupplierFilters {
  supplierId: string;
  name: string;
  city: string;
  gstNumber: string;
}

interface SupplierListProps {
  setDynamicSidebarContent?: (content: ReactNode | null) => void;
}

const SupplierList = ({ setDynamicSidebarContent }: SupplierListProps) => {
  const { toast } = useToast();
  const { getDocuments, addDocument } = useDocuments();
  const [searchTerm, setSearchTerm] = useState(""); // General search
  const [allSuppliers, setAllSuppliers] = useState<Supplier[]>([]); // Base data
  const [filteredSuppliers, setFilteredSuppliers] = useState<Supplier[]>([]); // Displayed data
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [currentSupplier, setCurrentSupplier] = useState<Supplier | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [filters, setFilters] = useState<SupplierFilters>({
    supplierId: "",
    name: "",
    city: "",
    gstNumber: "",
  });

  const uniqueCities = Array.from(new Set(allSuppliers.map(s => s.city))).sort();

  const handleFilterChange = (field: keyof SupplierFilters, value: string) => {
    setFilters(prev => ({ ...prev, [field]: value }));
  };

  const applyFilters = () => {
    let tempSuppliers = allSuppliers;

    if (filters.supplierId) {
      tempSuppliers = tempSuppliers.filter(s => 
        s.id.toLowerCase().includes(filters.supplierId.toLowerCase())
      );
    }
    if (filters.name) {
      tempSuppliers = tempSuppliers.filter(s => 
        s.name.toLowerCase().includes(filters.name.toLowerCase())
      );
    }
    if (filters.city) {
      tempSuppliers = tempSuppliers.filter(s => s.city === filters.city);
    }
    if (filters.gstNumber) {
      tempSuppliers = tempSuppliers.filter(s => 
        s.gstNumber.toLowerCase().includes(filters.gstNumber.toLowerCase())
      );
    }

    setFilteredSuppliers(tempSuppliers);
    // Re-apply general search
    handleGeneralSearch(searchTerm, tempSuppliers);
  };

  const clearFilters = () => {
    setFilters({ supplierId: "", name: "", city: "", gstNumber: "" });
    setFilteredSuppliers(allSuppliers);
    setSearchTerm("");
  };

  useEffect(() => {
    applyFilters();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters, allSuppliers]);

  // --- General Search (applied on top of filters) ---
  const handleGeneralSearch = (term: string, baseList: Supplier[] = filteredSuppliers) => {
    setSearchTerm(term);
    let searchFiltered = baseList;

    if (term.trim()) {
      const lowerCaseTerm = term.toLowerCase();
      searchFiltered = baseList.filter(
      (supplier) =>
          supplier.id.toLowerCase().includes(lowerCaseTerm) ||
          supplier.name.toLowerCase().includes(lowerCaseTerm) ||
          supplier.city.toLowerCase().includes(lowerCaseTerm) ||
          supplier.contactPerson.name.toLowerCase().includes(lowerCaseTerm) ||
          supplier.gstNumber.toLowerCase().includes(lowerCaseTerm)
      );
    }
    setFilteredSuppliers(searchFiltered);
  };
  // ---------------------------------------------------

  const renderSidebarFilters = () => (
    <div className="space-y-4">
      <div>
        <Label htmlFor="filter-supplierId" className="text-xs font-medium">Supplier ID</Label>
        <Input 
          id="filter-supplierId" 
          placeholder="Search ID..."
          value={filters.supplierId}
          onChange={(e) => handleFilterChange("supplierId", e.target.value)}
          className="h-9 text-sm mt-1"
        />
      </div>
      <div>
        <Label htmlFor="filter-name" className="text-xs font-medium">Supplier Name</Label>
        <Input 
          id="filter-name" 
          placeholder="Search Name..."
          value={filters.name}
          onChange={(e) => handleFilterChange("name", e.target.value)}
          className="h-9 text-sm mt-1"
        />
      </div>
      <div>
        <Label htmlFor="filter-gst" className="text-xs font-medium">GST Number</Label>
        <Input 
          id="filter-gst" 
          placeholder="Search GST..."
          value={filters.gstNumber}
          onChange={(e) => handleFilterChange("gstNumber", e.target.value)}
          className="h-9 text-sm mt-1"
        />
      </div>
      <div>
        <Label htmlFor="filter-city" className="text-xs font-medium">City</Label>
        <Select 
          value={filters.city}
          onValueChange={(value) => handleFilterChange("city", value)}
        >
          <SelectTrigger id="filter-city" className="h-9 text-sm mt-1">
            <SelectValue placeholder="All Cities" />
          </SelectTrigger>
          <SelectContent>
            {uniqueCities.map(city => (
              <SelectItem key={city} value={city} className="text-sm">
                {city}
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
  }, [setDynamicSidebarContent, filters, allSuppliers]);

  const handleExportToExcel = () => {
    toast({
      title: "Export Initiated",
      description: "Your supplier details are being exported to Excel.",
    });

    // Create a fake blob for download demonstration
    const blob = new Blob(['Fake Excel Data'], { type: 'application/vnd.ms-excel' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'suppliers_export.xlsx';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  };

  const handleEditSupplier = (supplier: Supplier) => {
    setCurrentSupplier(supplier);
    setIsEditDialogOpen(true);
  };

  const handleDocumentUpload = (supplierId: string, fileData: FileData) => {
    addDocument(supplierId, fileData);
    
    toast({
      title: "Supplier Document Added",
      description: `${fileData.name} has been uploaded for supplier records`,
    });
  };
  
  // Removed unused handleSaveSupplier function
  /*
  const handleSaveSupplier = (supplierData: Supplier) => {
      if (currentSupplier) { // Update
          setAllSuppliers(prev => prev.map(s => s.id === supplierData.id ? supplierData : s));
          toast({ title: "Supplier Updated", description: `Details for ${supplierData.name} saved.` });
      } else { // Add
          const newSupplier = { ...supplierData, id: `S${Date.now().toString().slice(-4)}` }; // Generate simple ID
          setAllSuppliers(prev => [newSupplier, ...prev]);
          toast({ title: "Supplier Added", description: `${newSupplier.name} added successfully.` });
      }
      setIsAddDialogOpen(false);
      setIsEditDialogOpen(false);
      setCurrentSupplier(null);
  };
  */

  // Fetch suppliers function
  const fetchSuppliers = async (showToast = false) => {
    if (isRefreshing) return; // Prevent multiple simultaneous fetches
    
    setIsRefreshing(true);
    if (!showToast) setIsLoading(true);
    setError(null);

    try {
      // Use the API to fetch suppliers
      const fetchedSuppliers = await api.suppliers.getAll();
      setAllSuppliers(fetchedSuppliers);
      setFilteredSuppliers(fetchedSuppliers);
      
      if (showToast) {
        toast({
          title: "Data Refreshed",
          description: "Supplier data has been updated successfully.",
        });
      }
    } catch (e) {
      console.error("Error fetching suppliers:", e);
      setError("Failed to fetch suppliers. Please try again later.");
      
      if (showToast) {
        toast({
          title: "Refresh Failed",
          description: "Could not refresh supplier data. Please try again.",
          variant: "destructive"
        });
      }
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  // Initial data fetch
  useEffect(() => {
    fetchSuppliers();
  }, []);

  const refreshSuppliers = () => {
    fetchSuppliers(true);
  };

  return (
    <Card className="border shadow-sm">
      <CardHeader className="flex flex-row items-center justify-between space-x-4 p-4 border-b">
        <div className="flex items-center gap-3 flex-1">
          {/* General Search */}
          <div className="relative w-full max-w-md">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
              placeholder="Search suppliers (ID, Name, City, GST, POC...)"
                value={searchTerm}
              onChange={(e) => handleGeneralSearch(e.target.value, filteredSuppliers)}
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
          {/* Refresh Button */}
            <Button
              variant="outline"
            size="default"
            onClick={refreshSuppliers}
            disabled={isRefreshing}
            className="h-10"
          >
            <RefreshCw size={16} className={cn("mr-2", isRefreshing && "animate-spin")} />
            {isRefreshing ? "Refreshing..." : "Refresh"}
            </Button>
        </div>
        {/* Add Supplier Button */}
            <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
              <DialogTrigger asChild>
            <Button size="default" className="h-10">
              <Plus size={16} className="mr-2" /> Add Supplier
                </Button>
              </DialogTrigger>
          <DialogContent className="sm:max-w-[900px] max-h-[90vh] overflow-y-auto p-6">
            <DialogHeader className="mb-4">
              <DialogTitle className="text-xl">Add New Supplier</DialogTitle>
                  <DialogDescription>
                    Fill in the supplier details to onboard a new supplier.
                  </DialogDescription>
                </DialogHeader>
                <SupplierForm 
              onClose={() => {
                setIsAddDialogOpen(false);
                fetchSuppliers(); // Refresh after adding
              }}
                  mode="create"
                />
              </DialogContent>
            </Dialog>
      </CardHeader>
      
      <CardContent className="p-0">
        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-24">
            <RefreshCw className="h-12 w-12 animate-spin text-muted-foreground mb-4" />
            <p className="text-lg font-medium">Loading suppliers...</p>
          </div>
        ) : error ? (
          <div className="flex flex-col items-center justify-center py-24">
            <AlertCircle className="h-12 w-12 text-destructive mb-4" />
            <p className="text-lg font-medium text-destructive">Error Loading Data</p>
            <p className="text-muted-foreground mb-4">{error}</p>
            <Button onClick={refreshSuppliers}>Try Again</Button>
          </div>
        ) : (
          <div className="overflow-hidden">
            <div className="overflow-x-auto relative">
              <Table className="min-w-full">
                <TableHeader className="bg-muted/50">
                  <TableRow className="border-b border-border hover:bg-muted/60">
                    <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Supplier ID</TableHead>
                    <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Name</TableHead>
                    <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">City</TableHead>
                    <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Contact</TableHead>
                    <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">GST No.</TableHead>
                    <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Bank Details</TableHead>
                    <TableHead className="whitespace-nowrap px-6 py-3 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredSuppliers.length > 0 ? (
                    filteredSuppliers.map((supplier, index) => (
                      <TableRow 
                        key={supplier.id}
                        className={cn("hover:bg-muted/40 transition-colors duration-150", index % 2 !== 0 && "bg-muted/20")}
                      >
                        <TableCell className="font-medium px-6 py-4 whitespace-nowrap text-sm">{supplier.id}</TableCell>
                        <TableCell className="px-6 py-4 whitespace-nowrap text-sm text-foreground font-medium">{supplier.name}</TableCell>
                        <TableCell className="px-6 py-4 whitespace-nowrap text-sm">{supplier.city}</TableCell>
                        <TableCell className="px-6 py-4 whitespace-nowrap text-sm">
                          {supplier.contactPerson.name}
                          <div className="text-xs text-muted-foreground">
                            {supplier.contactPerson.phone} / {supplier.contactPerson.email}
                          </div>
                        </TableCell>
                        <TableCell className="px-6 py-4 whitespace-nowrap text-sm">{supplier.gstNumber}</TableCell>
                        <TableCell className="px-6 py-4 whitespace-nowrap text-sm">
                          <div className="font-medium">{supplier.bankDetails.bankName}</div>
                          <div className="text-xs text-muted-foreground">
                            A/C: {supplier.bankDetails.accountNumber} / IFSC: {supplier.bankDetails.ifscCode}
                          </div>
                        </TableCell>
                        <TableCell className="px-6 py-4 whitespace-nowrap text-sm">
                          <div className="flex items-center space-x-1">
                            <Dialog open={isEditDialogOpen && currentSupplier?.id === supplier.id} onOpenChange={setIsEditDialogOpen}>
                              <DialogTrigger asChild>
                                <Button
                                  variant="ghost"
                                  size="icon"
                                  className="h-8 w-8 text-muted-foreground hover:text-foreground"
                                  title="Edit Supplier"
                                  onClick={() => handleEditSupplier(supplier)}
                                >
                                  <Edit size={16} />
                                </Button>
                              </DialogTrigger>
                              <DialogContent className="sm:max-w-[900px] max-h-[90vh] overflow-y-auto p-6">
                                <DialogHeader className="mb-4">
                                  <DialogTitle className="text-xl">Edit Supplier: {currentSupplier?.name}</DialogTitle>
                                  <DialogDescription>
                                    Update supplier information.
                                  </DialogDescription>
                                </DialogHeader>
                                <SupplierForm 
                                  supplier={currentSupplier}
                                  onClose={() => {
                                    setIsEditDialogOpen(false);
                                    setCurrentSupplier(null);
                                    fetchSuppliers(); // Refresh after editing
                                  }}
                                  mode="edit"
                                />
                              </DialogContent>
                            </Dialog>
                            <FileActions
                              id={supplier.id}
                              type="supplier"
                              entityName={supplier.name}
                              documentType="Supplier Document"
                              onSuccess={(fileData) => handleDocumentUpload(supplier.id, fileData)}
                              existingFiles={getDocuments(supplier.id)}
                            />
                          </div>
                        </TableCell>
                      </TableRow>
                    ))
                  ) : (
                    <TableRow>
                      <TableCell colSpan={7} className="text-center py-16 text-muted-foreground">
                        <Inbox className="h-12 w-12 mx-auto mb-3 text-gray-400" />
                        <p className="font-medium">No Suppliers Found</p>
                        <p className="text-sm">Add a new supplier or adjust your search/filters.</p>
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </div>
          </div>
        )}
        </CardContent>
      </Card>
  );
};

export default SupplierList;
