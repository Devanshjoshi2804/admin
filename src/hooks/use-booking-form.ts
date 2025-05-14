import { useState, useEffect, useCallback } from 'react';
import { useToast } from './use-toast';
import api from '@/lib/api';
import { Trip, CreateTripDto } from '@/trips/models/trip.model';
import { useNavigate } from 'react-router-dom';
// Import only vehicles from mock data
import { vehicles } from '@/data/mockData';

export interface BookingFormState {
  // Client Information
  clientId: string;
  addressType: string;
  clientCity: string;
  loadingAddress: string;
  destinationAddress: string;
  destinationCity: string;
  destinationType: string;
  
  // Supplier Information
  supplierId: string;
  pickupDate: string;
  pickupTime: string;
  
  // Vehicle Details
  vehicleId: string;
  vehicleNumber: string;
  driverName: string;
  driverPhone: string;
  vehicleType: string;
  vehicleSize: string;
  vehicleCapacity: string;
  axleType: string;
  
  // Material Information
  materials: Array<{
    id: string;
    name: string;
    weight: number;
    unit: 'MT' | 'KG';
    ratePerMT: number;
    amount: number;
  }>;
  
  // Freight Information
  clientFreight: number;
  supplierFreight: number;
  margin: number;
  advancePercentage: number;
  advanceSupplierFreight: number;
  balanceSupplierFreight: number;
  
  // Documents
  lrNumbers: Array<{
    number: string;
    file: File | null;
  }>;
  invoices: Array<{
    number: string;
    file: File | null;
  }>;
  ewayBills: Array<{
    number: string;
    file: File | null;
    expiryDate: string;
    expiryTime: string;
  }>;
  
  // Field Operations
  fieldOpsName: string;
  fieldOpsPhone: string;
  fieldOpsEmail: string;
  enableGSMTracking: boolean;
}

export type FormStep = 'basic-info' | 'vehicle-material' | 'documentation-tracking';

export const useBookingForm = () => {
  const { toast } = useToast();
  const navigate = useNavigate();
  const [step, setStep] = useState<FormStep>('basic-info');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [createdTripId, setCreatedTripId] = useState<string | null>(null);
  
  // Add state variables for clients and suppliers
  const [clients, setClients] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  
  const [formState, setFormState] = useState<BookingFormState>({
    // Client Information
    clientId: '',
    addressType: '',
    clientCity: '',
    loadingAddress: '',
    destinationAddress: '',
    destinationCity: '',
    destinationType: '',
    
    // Supplier Information
    supplierId: '',
    pickupDate: '',
    pickupTime: '',
    
    // Vehicle Details
    vehicleId: '',
    vehicleNumber: '',
    driverName: '',
    driverPhone: '',
    vehicleType: '',
    vehicleSize: '',
    vehicleCapacity: '',
    axleType: '',
    
    // Material Information
    materials: [{
      id: '1',
      name: '',
      weight: 0,
      unit: 'MT',
      ratePerMT: 0,
      amount: 0,
    }],
    
    // Freight Information
    clientFreight: 0,
    supplierFreight: 0,
    margin: 0,
    advancePercentage: 30,
    advanceSupplierFreight: 0,
    balanceSupplierFreight: 0,
    
    // Documents
    lrNumbers: [{ number: '', file: null }],
    invoices: [{ number: '', file: null }],
    ewayBills: [{ number: '', file: null, expiryDate: '', expiryTime: '' }],
    
    // Field Operations
    fieldOpsName: '',
    fieldOpsPhone: '',
    fieldOpsEmail: '',
    enableGSMTracking: true,
  });

  // Fetch clients and suppliers on component mount
  useEffect(() => {
    const fetchData = async () => {
      setIsLoading(true);
      try {
        // Fetch clients and suppliers in parallel
        const [clientsData, suppliersData] = await Promise.all([
          api.clients.getAll(),
          api.suppliers.getAll()
        ]);
        
        setClients(clientsData);
        setSuppliers(suppliersData);
        console.log("Fetched real clients and suppliers data:", {
          clients: clientsData.length,
          suppliers: suppliersData.length
        });
      } catch (error) {
        console.error("Error fetching clients/suppliers:", error);
        toast({
          title: "Data Load Error",
          description: "Could not load clients and suppliers data. Some features may be limited.",
          variant: "destructive"
        });
      } finally {
        setIsLoading(false);
      }
    };
    
    fetchData();
  }, [toast]);

  // Update client details when client is selected
  useEffect(() => {
    if (formState.clientId) {
      // Make sure we have clients data loaded
      if (clients.length === 0) return;
      
      const client = clients.find(c => c.id === formState.clientId);
      if (client) {
        setFormState(prev => ({
          ...prev,
          clientCity: client.city,
          loadingAddress: client.address,
          addressType: client.addressType || '',
        }));
      }
    }
  }, [formState.clientId, clients]);

  // Update vehicle details when vehicle is selected
  useEffect(() => {
    if (formState.vehicleId) {
      const vehicle = vehicles.find(v => v.id === formState.vehicleId);
      if (vehicle) {
        setFormState(prev => ({
          ...prev,
          vehicleNumber: vehicle.registrationNumber,
          driverName: vehicle.driverName,
          driverPhone: vehicle.driverPhone,
          vehicleType: vehicle.vehicleType,
          vehicleSize: vehicle.vehicleSize,
          vehicleCapacity: vehicle.vehicleCapacity,
          axleType: vehicle.axleType,
        }));
      }
    }
  }, [formState.vehicleId]);

  // Recalculate derived values
  useEffect(() => {
    // Calculate material amounts and total client freight
    const updatedMaterials = formState.materials.map(material => {
      const weightInMT = material.unit === 'KG' ? material.weight / 1000 : material.weight;
      const amount = weightInMT * material.ratePerMT;
      return { ...material, amount };
    });
    
    const totalClientFreight = updatedMaterials.reduce((sum, material) => sum + material.amount, 0);
    
    // Calculate advance amount and balance
    const advanceAmount = (formState.supplierFreight * formState.advancePercentage) / 100;
    const balanceAmount = formState.supplierFreight - advanceAmount;
    
    // Calculate margin
    const margin = totalClientFreight - formState.supplierFreight;
    
    setFormState(prev => ({
      ...prev,
      materials: updatedMaterials,
      clientFreight: totalClientFreight,
      margin,
      advanceSupplierFreight: advanceAmount,
      balanceSupplierFreight: balanceAmount,
    }));
  }, [
    formState.materials,
    formState.supplierFreight,
    formState.advancePercentage
  ]);

  // Generic field update handler
  const updateField = <K extends keyof BookingFormState>(
    field: K, 
    value: BookingFormState[K]
  ) => {
    setFormState(prev => ({ ...prev, [field]: value }));
  };

  // Handle step change separately
  const updateStep = (newStep: FormStep) => {
    setStep(newStep);
  };

  // Material handlers
  const addMaterial = () => {
    setFormState(prev => ({
      ...prev,
      materials: [
        ...prev.materials,
        {
          id: Date.now().toString(),
          name: '',
          weight: 0,
          unit: 'MT',
          ratePerMT: 0,
          amount: 0,
        }
      ]
    }));
  };

  const updateMaterial = (id: string, field: keyof BookingFormState['materials'][0], value: any) => {
    setFormState(prev => ({
      ...prev,
      materials: prev.materials.map(material => 
        material.id === id ? { ...material, [field]: value } : material
      )
    }));
  };

  const removeMaterial = (id: string) => {
    if (formState.materials.length <= 1) {
      toast({
        title: "Cannot Remove",
        description: "At least one material is required",
        variant: "destructive",
      });
      return;
    }
    
    setFormState(prev => ({
      ...prev,
      materials: prev.materials.filter(material => material.id !== id)
    }));
  };

  // Document handlers
  const addDocument = <T extends 'lrNumbers' | 'invoices' | 'ewayBills'>(documentType: T) => {
    setFormState(prev => {
      if (documentType === 'lrNumbers') {
        return {
          ...prev,
          lrNumbers: [...prev.lrNumbers, { number: '', file: null }]
        };
      } else if (documentType === 'invoices') {
        return {
          ...prev,
          invoices: [...prev.invoices, { number: '', file: null }]
        };
      } else {
        return {
          ...prev,
          ewayBills: [...prev.ewayBills, { number: '', file: null, expiryDate: '', expiryTime: '' }]
        };
      }
    });
  };

  const updateDocument = <T extends 'lrNumbers' | 'invoices' | 'ewayBills'>(
    documentType: T,
    index: number,
    field: keyof BookingFormState[T][0],
    value: any
  ) => {
    setFormState(prev => {
      const documents = [...prev[documentType]];
      documents[index] = { ...documents[index], [field]: value };
      return { ...prev, [documentType]: documents };
    });
  };

  const removeDocument = <T extends 'lrNumbers' | 'invoices' | 'ewayBills'>(
    documentType: T,
    index: number
  ) => {
    if (formState[documentType].length <= 1) {
      toast({
        title: "Cannot Remove",
        description: `At least one ${documentType === 'lrNumbers' ? 'LR number' : documentType === 'invoices' ? 'invoice' : 'e-way bill'} is required`,
        variant: "destructive",
      });
      return;
    }
    
    setFormState(prev => {
      const documents = [...prev[documentType]];
      documents.splice(index, 1);
      return { ...prev, [documentType]: documents };
    });
  };

  // Validation functions for each step
  const validateBasicInfo = () => {
    if (!formState.clientId) {
      toast({
        title: "Client Required",
        description: "Please select a client",
        variant: "destructive",
      });
      return false;
    }
    
    if (!formState.destinationAddress) {
      toast({
        title: "Destination Required",
        description: "Please enter a destination address",
        variant: "destructive",
      });
      return false;
    }
    
    if (!formState.destinationCity) {
      toast({
        title: "Destination City Required",
        description: "Please enter a destination city",
        variant: "destructive",
      });
      return false;
    }
    
    if (!formState.supplierId) {
      toast({
        title: "Supplier Required",
        description: "Please select a supplier",
        variant: "destructive",
      });
      return false;
    }
    
    if (!formState.pickupDate) {
      toast({
        title: "Pickup Date Required",
        description: "Please select a pickup date",
        variant: "destructive",
      });
      return false;
    }
    
    return true;
  };

  const validateVehicleMaterial = () => {
    if (!formState.vehicleNumber) {
      toast({
        title: "Vehicle Number Required",
        description: "Please enter a vehicle number",
        variant: "destructive",
      });
      return false;
    }
    
    if (!formState.driverName) {
      toast({
        title: "Driver Name Required",
        description: "Please enter a driver name",
        variant: "destructive",
      });
      return false;
    }
    
    if (!formState.vehicleType) {
      toast({
        title: "Vehicle Type Required",
        description: "Please select a vehicle type",
        variant: "destructive",
      });
      return false;
    }
    
    // Validate materials
    for (const material of formState.materials) {
      if (!material.name) {
        toast({
          title: "Material Name Required",
          description: "Please enter a material name for all materials",
          variant: "destructive",
        });
        return false;
      }
      
      if (material.weight <= 0) {
        toast({
          title: "Weight Required",
          description: "Please enter a valid weight for all materials",
          variant: "destructive",
        });
        return false;
      }
    }
    
    if (formState.supplierFreight <= 0) {
      toast({
        title: "Supplier Freight Required",
        description: "Please enter a valid supplier freight amount",
        variant: "destructive",
      });
      return false;
    }
    
    return true;
  };

  const validateDocumentation = () => {
    // Check LR numbers
    for (const lr of formState.lrNumbers) {
      if (!lr.number) {
        toast({
          title: "LR Number Required",
          description: "Please enter all LR numbers",
          variant: "destructive",
        });
        return false;
      }
    }
    
    // Check E-way bills
    for (const bill of formState.ewayBills) {
      if (bill.number && (!bill.expiryDate || !bill.expiryTime)) {
        toast({
          title: "E-way Bill Details Required",
          description: "Please enter both expiry date and time for all E-way bills",
          variant: "destructive",
        });
        return false;
      }
    }
    
    // Check field ops details
    if (!formState.fieldOpsName) {
      toast({
        title: "Field Ops Name Required",
        description: "Please enter a field operations contact name",
        variant: "destructive",
      });
      return false;
    }
    
    if (!formState.fieldOpsPhone) {
      toast({
        title: "Field Ops Phone Required",
        description: "Please enter a field operations contact phone",
        variant: "destructive",
      });
      return false;
    }
    
    return true;
  };

  // Navigation functions
  const nextStep = () => {
    if (step === 'basic-info') {
      if (validateBasicInfo()) {
        setStep('vehicle-material');
      }
    } else if (step === 'vehicle-material') {
      if (validateVehicleMaterial()) {
        setStep('documentation-tracking');
      }
    }
  };

  const prevStep = () => {
    if (step === 'vehicle-material') {
      setStep('basic-info');
    } else if (step === 'documentation-tracking') {
      setStep('vehicle-material');
    }
  };

  // Transform form data to trip data for API
  const transformFormToTripData = useCallback((): CreateTripDto => {
    // Get client and supplier details from their IDs
    const client = clients.find(c => c.id === formState.clientId);
    const supplier = suppliers.find(s => s.id === formState.supplierId);

    // Make sure materials have all required fields and no extraneous fields
    const formattedMaterials = formState.materials
      .filter(m => m.name.trim() !== '') // Filter out empty materials
      .map(m => ({
        name: m.name,
        weight: Number(m.weight),
        unit: m.unit,
        ratePerMT: Number(m.ratePerMT)
      }));

    console.log("Formatted materials:", JSON.stringify(formattedMaterials));

    return {
      lrNumbers: formState.lrNumbers.map(lr => lr.number).filter(Boolean),
      clientId: formState.clientId,
      clientName: client?.name || '',
      clientAddress: formState.loadingAddress,
      clientAddressType: formState.addressType,
      clientCity: formState.clientCity,
      destinationAddress: formState.destinationAddress,
      destinationCity: formState.destinationCity,
      destinationAddressType: formState.destinationType || formState.addressType || 'Warehouse',
      supplierId: formState.supplierId,
      supplierName: supplier?.name || '',
      vehicleId: formState.vehicleId,
      vehicleNumber: formState.vehicleNumber,
      driverName: formState.driverName,
      driverPhone: formState.driverPhone,
      vehicleType: formState.vehicleType,
      vehicleSize: formState.vehicleSize,
      vehicleCapacity: formState.vehicleCapacity,
      axleType: formState.axleType,
      materials: formattedMaterials,
      pickupDate: formState.pickupDate,
      pickupTime: formState.pickupTime,
      clientFreight: Number(formState.clientFreight),
      supplierFreight: Number(formState.supplierFreight),
      advancePercentage: Number(formState.advancePercentage),
      fieldOps: {
        name: formState.fieldOpsName,
        phone: formState.fieldOpsPhone,
        email: formState.fieldOpsEmail,
      },
      gsmTracking: formState.enableGSMTracking,
      // Required status fields
      status: 'Booked',
      advancePaymentStatus: 'Not Started',
      balancePaymentStatus: 'Not Started',
    };
  }, [formState, clients, suppliers]);

  // Handle document uploads after trip creation
  const uploadTripDocuments = useCallback(async (tripId: string) => {
    try {
      // In a real implementation, you would upload each file to the server
      // and update the trip with document references
      console.log(`Uploading documents for trip ${tripId}`);
      
      // Mock implementation - in real app, iterate through document arrays and upload each file
      return true;
    } catch (error) {
      console.error('Error uploading documents:', error);
      return false;
    }
  }, []);

  // Form submission with real-time trip creation
  const submitForm = async () => {
    if (!validateDocumentation()) {
      return;
    }
    
    setIsSubmitting(true);
    
    try {
      // Transform form data to trip data
      const tripData = transformFormToTripData();
      
      console.log("Submitting trip data:", JSON.stringify(tripData));
      
      // Use the integrated function that handles trip creation and payment initiation
      const createdTrip = await api.trips.createWithPaymentIntegration(tripData);
      
      // Store the created trip ID for reference
      setCreatedTripId(createdTrip.id);
      
      // Upload documents if there are any
      await uploadTripDocuments(createdTrip.id);
      
      // Show success notification
      toast({
        title: "Booking Created",
        description: `Booking created successfully. Order ID: ${createdTrip.orderNumber}`,
      });
      
      console.log("Created trip:", createdTrip); // Log the created trip for debugging
      
      // Redirect to the trips page after a short delay
      setTimeout(() => {
        // Log before navigation to ensure this code runs
        console.log("Redirecting to /trips page...");
        
        try {
          navigate('/trips');
        } catch (navigationError) {
          console.error("Navigation error:", navigationError);
          // As a fallback, try using window.location
          window.location.href = '/trips';
        }
      }, 1500);
      
    } catch (error) {
      console.error('Error creating booking:', error);
      
      // Extract detailed error message from API response if available
      let errorMessage = "There was a problem creating your booking. Please try again.";
      
      if (error.response) {
        console.log("API error response:", error.response);
        
        if (error.response.data && error.response.data.message) {
          if (Array.isArray(error.response.data.message)) {
            // Handle validation errors
            errorMessage = error.response.data.message.join('\n');
          } else {
            errorMessage = error.response.data.message;
          }
        } else if (error.response.status === 400) {
          errorMessage = "Bad request error. Please check your form data for invalid values.";
        }
      }
      
      toast({
        title: "Error Creating Booking",
        description: errorMessage,
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetForm = () => {
    setFormState({
      // Reset to initial state
      clientId: '',
      addressType: '',
      clientCity: '',
      loadingAddress: '',
      destinationAddress: '',
      destinationCity: '',
      destinationType: '',
      supplierId: '',
      pickupDate: '',
      pickupTime: '',
      vehicleId: '',
      vehicleNumber: '',
      driverName: '',
      driverPhone: '',
      vehicleType: '',
      vehicleSize: '',
      vehicleCapacity: '',
      axleType: '',
      materials: [{
        id: '1',
        name: '',
        weight: 0,
        unit: 'MT',
        ratePerMT: 0,
        amount: 0,
      }],
      clientFreight: 0,
      supplierFreight: 0,
      margin: 0,
      advancePercentage: 30,
      advanceSupplierFreight: 0,
      balanceSupplierFreight: 0,
      lrNumbers: [{ number: '', file: null }],
      invoices: [{ number: '', file: null }],
      ewayBills: [{ number: '', file: null, expiryDate: '', expiryTime: '' }],
      fieldOpsName: '',
      fieldOpsPhone: '',
      fieldOpsEmail: '',
      enableGSMTracking: true,
    });
    setStep('basic-info');
    setCreatedTripId(null);
  };

  return {
    formState,
    step,
    isSubmitting,
    createdTripId,
    clients,
    suppliers,
    isLoading,
    updateField,
    updateStep,
    addMaterial,
    updateMaterial,
    removeMaterial,
    addDocument,
    updateDocument,
    removeDocument,
    nextStep,
    prevStep,
    submitForm,
    uploadTripDocuments,
    resetForm,
  };
}; 