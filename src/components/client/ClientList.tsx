import React, { useState, useEffect, ReactNode } from "react";
import { useToast } from "@/hooks/use-toast";
import { useDocuments } from "@/hooks/use-documents";
import { Client } from "@/data/mockData";
import { clientsApi } from "@/lib/api";
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
import { Search, Plus, Edit, Download, X, Inbox, Loader2, RefreshCw, AlertCircle } from "lucide-react";
import ClientForm from "./ClientForm";
import { cn } from "@/lib/utils";

interface ClientFilters {
  clientId: string;
  name: string;
  city: string;
  gstNumber: string;
}

interface ClientListProps {
  setDynamicSidebarContent?: (content: ReactNode | null) => void;
}

const ClientList = ({ setDynamicSidebarContent }: ClientListProps) => {
  const { toast } = useToast();
  const { getDocuments, addDocument } = useDocuments();
  const [searchTerm, setSearchTerm] = useState(""); // General search
  const [allClients, setAllClients] = useState<Client[]>([]); // Base data
  const [filteredClients, setFilteredClients] = useState<Client[]>([]); // Displayed data
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [currentClient, setCurrentClient] = useState<Client | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<ClientFilters>({
    clientId: "",
    name: "",
    city: "",
    gstNumber: "",
  });

  // Fetch clients from API
  const fetchClients = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const data = await clientsApi.getAll();
      setAllClients(data);
      setFilteredClients(data);
      setIsLoading(false);
    } catch (err) {
      console.error("Error fetching clients:", err);
      setError("Failed to load clients. Please try again later.");
      setIsLoading(false);
      toast({
        title: "Error",
        description: "Failed to load clients. Please try again later.",
        variant: "destructive",
      });
    }
  };
  
  useEffect(() => {
    fetchClients();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [toast]);

  // Unique cities for filter dropdown
  const uniqueCities = Array.from(new Set(allClients.map(client => client.city))).sort();

  const handleFilterChange = (field: keyof ClientFilters, value: string) => {
    setFilters(prev => ({ ...prev, [field]: value }));
  };

  const handleDocumentUpload = (clientId: string, fileData: FileData) => {
    addDocument(clientId, fileData);
    toast({
      title: "Document Uploaded",
      description: `${fileData.name} has been uploaded successfully.`,
    });
  };

  const handleCreateClient = async (clientData: any) => {
    try {
      setIsLoading(true);
      await clientsApi.create(clientData);
      
      // Refresh the client list
      const updatedClients = await clientsApi.getAll();
      setAllClients(updatedClients);
      setFilteredClients(updatedClients);
      
      setIsAddDialogOpen(false);
      setIsLoading(false);
      
      toast({
        title: "Client Created",
        description: `${clientData.name} has been added successfully.`,
      });
    } catch (error) {
      console.error("Error creating client:", error);
      setIsLoading(false);
      toast({
        title: "Error",
        description: "Failed to create client. Please try again.",
        variant: "destructive",
      });
    }
  };

  const handleUpdateClient = async (id: string, clientData: any) => {
    try {
      setIsLoading(true);
      await clientsApi.update(id, clientData);
      
      // Refresh the client list
      const updatedClients = await clientsApi.getAll();
      setAllClients(updatedClients);
      setFilteredClients(updatedClients);
      
      setIsEditDialogOpen(false);
      setCurrentClient(null);
      setIsLoading(false);
      
      toast({
        title: "Client Updated",
        description: `${clientData.name} has been updated successfully.`,
      });
    } catch (error) {
      console.error("Error updating client:", error);
      setIsLoading(false);
      toast({
        title: "Error",
        description: "Failed to update client. Please try again.",
        variant: "destructive",
      });
    }
  };

  const handleDeleteClient = async (id: string) => {
    if (window.confirm(`Are you sure you want to delete this client?`)) {
      try {
        setIsLoading(true);
        await clientsApi.delete(id);
        
        // Refresh the client list
        const updatedClients = await clientsApi.getAll();
        setAllClients(updatedClients);
        setFilteredClients(updatedClients);
        
        setIsEditDialogOpen(false);
        setCurrentClient(null);
        setIsLoading(false);
        
        toast({
          title: "Client Deleted",
          description: "Client has been deleted successfully.",
        });
      } catch (error) {
        console.error("Error deleting client:", error);
        setIsLoading(false);
        toast({
          title: "Error",
          description: "Failed to delete client. Please try again.",
          variant: "destructive",
        });
      }
    }
  };

  const handleExportToExcel = () => {
    toast({
      title: "Export Initiated",
      description: "Your client details are being exported to Excel.",
    });

    // Create a fake blob for download demonstration
    const blob = new Blob(['Fake Excel Data'], { type: 'application/vnd.ms-excel' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'clients_export.xlsx';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  };

  const handleEditClient = (client: Client) => {
    setCurrentClient(client);
    setIsEditDialogOpen(true);
  };

  const applyFilters = () => {
    let tempClients = allClients;

    if (filters.clientId) {
      tempClients = tempClients.filter(client => 
        client.id.toLowerCase().includes(filters.clientId.toLowerCase())
      );
    }
    if (filters.name) {
      tempClients = tempClients.filter(client => 
        client.name.toLowerCase().includes(filters.name.toLowerCase())
      );
    }
    if (filters.city) {
      tempClients = tempClients.filter(client => client.city === filters.city);
    }
    if (filters.gstNumber) {
      tempClients = tempClients.filter(client => 
        client.gstNumber.toLowerCase().includes(filters.gstNumber.toLowerCase())
      );
    }

    setFilteredClients(tempClients);
    // Re-apply general search on the newly filtered list
    handleGeneralSearch(searchTerm, tempClients);
  };

  const clearFilters = () => {
    setFilters({
      clientId: "",
      name: "",
      city: "",
      gstNumber: "",
    });
    setFilteredClients(allClients);
    setSearchTerm("");
  };

  useEffect(() => {
    applyFilters();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters, allClients]); // Re-run if base data changes

  // --- General Search (applied on top of filters) ---
  const handleGeneralSearch = (term: string, baseList: Client[] = filteredClients) => {
    setSearchTerm(term);
    let searchFiltered = baseList;

    if (term.trim()) {
        const lowerCaseTerm = term.toLowerCase();
        searchFiltered = baseList.filter(
          (client) =>
            client.id.toLowerCase().includes(lowerCaseTerm) ||
            client.name.toLowerCase().includes(lowerCaseTerm) ||
            client.city.toLowerCase().includes(lowerCaseTerm) ||
            client.logisticsPOC.name.toLowerCase().includes(lowerCaseTerm) ||
            client.financePOC.name.toLowerCase().includes(lowerCaseTerm) ||
            client.gstNumber.toLowerCase().includes(lowerCaseTerm)
        );
    }
    setFilteredClients(searchFiltered);
  };
  // ---------------------------------------------------

  const renderSidebarFilters = () => (
    <div className="space-y-4">
      <div>
        <Label htmlFor="filter-clientId" className="text-xs font-medium">Client ID</Label>
        <Input 
          id="filter-clientId" 
          placeholder="Search Client ID..."
          value={filters.clientId}
          onChange={(e) => handleFilterChange("clientId", e.target.value)}
          className="h-9 text-sm mt-1"
        />
      </div>
      <div>
        <Label htmlFor="filter-name" className="text-xs font-medium">Client Name</Label>
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
  }, [setDynamicSidebarContent, filters, allClients]); // Include allClients dependency for unique cities

  // Render the client list UI with proper error handling and loading states
  return (
    <div className="space-y-4">
      {/* Search and Action Bar */}
      <div className="flex flex-col md:flex-row justify-between gap-4 mb-6">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search clients..."
                value={searchTerm}
            onChange={(e) => handleGeneralSearch(e.target.value)}
            className="pl-9 h-10"
          />
            </div>
            <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
              <DialogTrigger asChild>
            <Button className="shrink-0 gap-1.5">
              <Plus className="h-4 w-4" />
              <span>Add Client</span>
                </Button>
              </DialogTrigger>
          <DialogContent className="max-w-3xl">
                <DialogHeader>
                  <DialogTitle>Add New Client</DialogTitle>
                  <DialogDescription>
                Create a new client and add them to your system.
                  </DialogDescription>
                </DialogHeader>
                <ClientForm 
              onSubmit={handleCreateClient}
                  onClose={() => setIsAddDialogOpen(false)}
                  mode="create"
                />
              </DialogContent>
            </Dialog>
          </div>

      {/* Client Table */}
      <Card>
        <CardHeader className="py-4">
          <CardTitle className="text-xl">Client Management</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex flex-col items-center justify-center py-8">
              <Loader2 className="h-8 w-8 animate-spin text-primary mb-2" />
              <p className="text-muted-foreground">Loading clients...</p>
            </div>
          ) : error ? (
            <div className="flex flex-col items-center justify-center py-16 text-center">
              <div className="rounded-full bg-red-100 p-4 mb-4">
                <AlertCircle className="h-8 w-8 text-red-600" />
              </div>
              <h3 className="text-lg font-semibold mb-2">Error Loading Data</h3>
              <p className="text-muted-foreground mb-6">Failed to load clients. Please try again later.</p>
              <Button onClick={fetchClients} variant="outline" className="gap-2">
                <RefreshCw className="h-4 w-4" />
                Retry
              </Button>
            </div>
          ) : filteredClients.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-center">
              <div className="rounded-full bg-muted p-4 mb-4">
                <Inbox className="h-8 w-8 text-muted-foreground" />
              </div>
              <h3 className="text-lg font-semibold mb-2">No Clients Found</h3>
              <p className="text-muted-foreground mb-6">
                {searchTerm || Object.values(filters).some(v => v) 
                  ? "No clients match your search criteria. Try adjusting your filters."
                  : "You haven't added any clients yet. Click 'Add Client' to get started."}
              </p>
              {searchTerm || Object.values(filters).some(v => v) ? (
                <Button onClick={clearFilters} variant="outline">Clear Filters</Button>
              ) : (
                <DialogTrigger asChild onClick={() => setIsAddDialogOpen(true)}>
                  <Button>Add Your First Client</Button>
                </DialogTrigger>
              )}
            </div>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Client ID</TableHead>
                    <TableHead>Name</TableHead>
                    <TableHead>City</TableHead>
                    <TableHead>Logistics POC</TableHead>
                    <TableHead>Finance POC</TableHead>
                    <TableHead>Documents</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredClients.map((client) => (
                    <TableRow key={client.id} className="group hover:bg-muted/50">
                        <TableCell className="font-medium">{client.id}</TableCell>
                      <TableCell>
                        <div className="font-medium">{client.name}</div>
                        <div className="text-xs text-muted-foreground">{client.gstNumber}</div>
                      </TableCell>
                        <TableCell>{client.city}</TableCell>
                        <TableCell>
                        <div className="font-medium">{client.logisticsPOC.name}</div>
                        <div className="text-xs">
                          <a 
                            href={`tel:${client.logisticsPOC.phone}`} 
                            className="text-blue-600 hover:underline"
                          >
                            {client.logisticsPOC.phone}
                          </a>
                          </div>
                        </TableCell>
                        <TableCell>
                        <div className="font-medium">{client.financePOC.name}</div>
                        <div className="text-xs">
                          <a 
                            href={`mailto:${client.financePOC.email}`} 
                            className="text-blue-600 hover:underline"
                          >
                            {client.financePOC.email}
                          </a>
                          </div>
                        </TableCell>
                        <TableCell>
                        <FileActions
                          id={client.id}
                          type="client"
                          entityName={client.name}
                          documentType="Client Document"
                          onSuccess={(file) => handleDocumentUpload(client.id, file)}
                          existingFiles={getDocuments(client.id)}
                        />
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end">
                                <Button
                                  variant="ghost"
                                  size="icon"
                                  onClick={() => handleEditClient(client)}
                            className="opacity-0 group-hover:opacity-100 transition-opacity"
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={handleExportToExcel}
                            className="opacity-0 group-hover:opacity-100 transition-opacity"
                          >
                            <Download className="h-4 w-4" />
                                </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Edit Client Dialog */}
      {currentClient && (
        <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
          <DialogContent className="max-w-3xl">
                                <DialogHeader>
                                  <DialogTitle>Edit Client</DialogTitle>
                                  <DialogDescription>
                                    Update client information.
                                  </DialogDescription>
                                </DialogHeader>
                                <ClientForm 
                                  client={currentClient}
              onSubmit={(data) => handleUpdateClient(currentClient.id, data)}
                                  onClose={() => setIsEditDialogOpen(false)}
                                  mode="edit"
                                />
                              </DialogContent>
                            </Dialog>
      )}
    </div>
  );
};

export default ClientList;
