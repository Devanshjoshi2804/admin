import { useState, useEffect } from "react";
import { FileData } from "@/components/ui/file-actions";
import api from "@/lib/api";
import { useToast } from "@/hooks/use-toast";

type DocumentEntityType = "trip" | "payment" | "client" | "supplier" | "vehicle";

// Sample initial documents for demo purposes
const initialDocuments: Record<string, FileData[]> = {
  // Trip documents
  "T001": [
    {
      id: "doc-1",
      name: "LR_T001_12345.pdf",
      size: 256000,
      type: "application/pdf",
      uploadDate: "2023-09-15T10:30:00Z",
      url: "#"
    },
    {
      id: "doc-2",
      name: "Invoice_T001_INV2023.pdf",
      size: 324000,
      type: "application/pdf",
      uploadDate: "2023-09-15T11:45:00Z",
      url: "#"
    }
  ],
  // Client documents
  "CL001": [
    {
      id: "doc-3",
      name: "TataSteel_GST_Certificate.pdf",
      size: 512000,
      type: "application/pdf",
      uploadDate: "2023-06-10T09:15:00Z",
      url: "#"
    },
    {
      id: "doc-4",
      name: "TataSteel_CompanyProfile.pdf",
      size: 1024000,
      type: "application/pdf",
      uploadDate: "2023-06-10T09:20:00Z", 
      url: "#"
    }
  ],
  // Supplier documents
  "SUP001": [
    {
      id: "doc-5",
      name: "SpeedwayLogistics_Agreement.pdf",
      size: 768000,
      type: "application/pdf",
      uploadDate: "2023-07-05T14:30:00Z",
      url: "#"
    }
  ],
  // Vehicle documents
  "VEH001": [
    {
      id: "doc-6", 
      name: "DL1GC1234_RC.jpg",
      size: 384000,
      type: "image/jpeg",
      uploadDate: "2023-08-20T16:45:00Z",
      url: "#"
    },
    {
      id: "doc-7",
      name: "DL1GC1234_Insurance.pdf",
      size: 420000,
      type: "application/pdf",
      uploadDate: "2023-08-20T16:50:00Z",
      url: "#"
    }
  ],
  // Payment documents
  "PMT001": [
    {
      id: "doc-8",
      name: "Payment_Receipt_12345.pdf",
      size: 198000,
      type: "application/pdf",
      uploadDate: "2023-09-25T13:20:00Z",
      url: "#"
    }
  ]
};

// Enhanced document hook with API integration
export const useDocuments = () => {
  const [documents, setDocuments] = useState<Record<string, FileData[]>>({});
  const [loading, setLoading] = useState<Record<string, boolean>>({});
  const { toast } = useToast();
  
  /**
   * Get documents for a specific entity
   */
  const getDocuments = async (entityId: string): Promise<FileData[]> => {
    // Return cached documents if available
    if (documents[entityId]) {
      return documents[entityId];
    }
    
    // Set loading state for this entity
    setLoading(prev => ({ ...prev, [entityId]: true }));
    
    try {
      // Determine entity type from the entityId prefix
      const entityType = getEntityTypeFromId(entityId);
      const realEntityId = stripPrefix(entityId);
      
      // Fetch documents from the server
      let fetchedDocuments: FileData[] = [];
      
      if (entityType === "trip") {
        const trip = await api.trips.getOne(realEntityId);
        fetchedDocuments = trip?.documents || [];
      } else if (entityType === "client") {
        const client = await api.clients.getOne(realEntityId);
        fetchedDocuments = client?.documents || [];
      } else if (entityType === "supplier") {
        const supplier = await api.suppliers.getOne(realEntityId);
        fetchedDocuments = supplier?.documents || [];
      } else if (entityType === "vehicle") {
        const vehicle = await api.vehicles.getOne(realEntityId);
        fetchedDocuments = vehicle?.documents || [];
      } else {
        // For entities without direct API endpoints, we'll try to get from localStorage
        fetchedDocuments = getFromLocalStorage(entityId);
      }
      
      // Cache the documents
      setDocuments(prev => ({ ...prev, [entityId]: fetchedDocuments }));
      return fetchedDocuments;
    } catch (error) {
      console.error(`Error fetching documents for ${entityId}:`, error);
      
      // Fallback to localStorage if API fails
      const localDocs = getFromLocalStorage(entityId);
      setDocuments(prev => ({ ...prev, [entityId]: localDocs }));
      
      return localDocs;
    } finally {
      setLoading(prev => ({ ...prev, [entityId]: false }));
    }
  };
  
  /**
   * Add a document to an entity
   */
  const addDocument = async (entityId: string, document: FileData): Promise<FileData> => {
    try {
      // Determine entity type from the entityId prefix
      const entityType = getEntityTypeFromId(entityId);
      const realEntityId = stripPrefix(entityId);
      
      // Create document data for API
      const docData = {
        type: getDocumentType(document),
        number: document.id,
        filename: document.name,
        size: document.size,
        fileType: document.type,
        url: document.url || ""
      };
      
      // Save to the appropriate API endpoint
      if (entityType === "trip") {
        await api.trips.uploadDocument(realEntityId, docData);
      } else if (entityType === "client") {
        await api.clients.uploadDocument(realEntityId, docData);
      } else if (entityType === "supplier") {
        await api.suppliers.uploadDocument(realEntityId, docData);
      } else if (entityType === "vehicle") {
        await api.vehicles.uploadDocument(realEntityId, docData);
      } else {
        // For entities without direct API endpoints, save to localStorage
        saveToLocalStorage(entityId, document);
      }
      
      // Update local cache
      setDocuments(prevDocuments => ({
        ...prevDocuments,
        [entityId]: [...(prevDocuments[entityId] || []), document]
      }));
      
      return document;
    } catch (error) {
      console.error(`Error saving document for ${entityId}:`, error);
      
      // Save to localStorage as fallback
      saveToLocalStorage(entityId, document);
      
      // Still update local cache for immediate UI feedback
      setDocuments(prevDocuments => ({
        ...prevDocuments,
        [entityId]: [...(prevDocuments[entityId] || []), document]
      }));
      
      toast({
        title: "Document Saved Locally",
        description: "The document was saved locally but couldn't be uploaded to the server. It will sync when connection is restored.",
        variant: "default"
      });
      
      return document;
    }
  };
  
  /**
   * Remove a document
   */
  const removeDocument = async (entityId: string, documentId: string): Promise<boolean> => {
    try {
      // Determine entity type from the entityId prefix
      const entityType = getEntityTypeFromId(entityId);
      const realEntityId = stripPrefix(entityId);
      
      // Delete from the appropriate API endpoint
      if (entityType === "trip") {
        await api.trips.deleteDocument(realEntityId, documentId);
      } else if (entityType === "client") {
        await api.clients.deleteDocument(realEntityId, documentId);
      } else if (entityType === "supplier") {
        await api.suppliers.deleteDocument(realEntityId, documentId);
      } else if (entityType === "vehicle") {
        await api.vehicles.deleteDocument(realEntityId, documentId);
      } else {
        // For entities without direct API endpoints, remove from localStorage
        removeFromLocalStorage(entityId, documentId);
      }
      
      // Update local cache
      setDocuments(prevDocuments => ({
        ...prevDocuments,
        [entityId]: (prevDocuments[entityId] || []).filter(doc => doc.id !== documentId)
      }));
      
      return true;
    } catch (error) {
      console.error(`Error removing document ${documentId}:`, error);
      
      // Try to remove from local cache anyway for UI consistency
      setDocuments(prevDocuments => ({
        ...prevDocuments,
        [entityId]: (prevDocuments[entityId] || []).filter(doc => doc.id !== documentId)
      }));
      
      // Mark for deletion in localStorage to sync later
      markForDeletion(entityId, documentId);
      
      toast({
        title: "Document Removal Issue",
        description: "The document was removed locally but the server update failed. Changes will sync when connection is restored.",
        variant: "default"
      });
      
      return false;
    }
  };
  
  /**
   * Generate a download URL for a document
   */
  const getDocumentUrl = (entityId: string, documentId: string): string => {
    const entityDocs = documents[entityId] || [];
    const doc = entityDocs.find(d => d.id === documentId);
    
    if (!doc) return "";
    
    // If there's already a URL, use it
    if (doc.url) return doc.url;
    
    // Otherwise construct a download URL
    const entityType = getEntityTypeFromId(entityId);
    const realEntityId = stripPrefix(entityId);
    
    return `${api.baseUrl}/${entityType}s/${realEntityId}/documents/${documentId}`;
  };
  
  // Helper functions
  
  // Extract entity type from ID (e.g., "TRP-123" -> "trip")
  const getEntityTypeFromId = (entityId: string): DocumentEntityType => {
    if (entityId.startsWith("TRP-") || entityId.startsWith("trip-")) return "trip";
    if (entityId.startsWith("PMT-") || entityId.startsWith("payment-")) return "payment";
    if (entityId.startsWith("CL-") || entityId.startsWith("client-")) return "client";
    if (entityId.startsWith("SUP-") || entityId.startsWith("supplier-")) return "supplier";
    if (entityId.startsWith("VEH-") || entityId.startsWith("vehicle-")) return "vehicle";
    
    // Try to infer from the rest of the ID
    if (entityId.includes("trip")) return "trip";
    if (entityId.includes("payment")) return "payment";
    if (entityId.includes("client")) return "client";
    if (entityId.includes("supplier")) return "supplier";
    if (entityId.includes("vehicle")) return "vehicle";
    
    // Default fallback
    return "trip";
  };
  
  // Remove prefix from entityId to get the real ID
  const stripPrefix = (entityId: string): string => {
    // Remove common prefixes
    const prefixes = ["TRP-", "PMT-", "CL-", "SUP-", "VEH-", "trip-", "payment-", "client-", "supplier-", "vehicle-"];
    
    for (const prefix of prefixes) {
      if (entityId.startsWith(prefix)) {
        return entityId.substring(prefix.length);
      }
    }
    
    return entityId;
  };
  
  // Get document type from file data
  const getDocumentType = (document: FileData): string => {
    const name = document.name.toLowerCase();
    
    if (name.includes("pod") || name.includes("delivery")) return "POD";
    if (name.includes("lr") || name.includes("lorry")) return "LR";
    if (name.includes("invoice") || name.includes("bill")) return "Invoice";
    if (name.includes("eway") || name.includes("e-way")) return "E-waybill";
    if (name.includes("rc") || name.includes("registration")) return "RC";
    if (name.includes("insurance")) return "Insurance";
    if (name.includes("gst") || name.includes("tax")) return "GST";
    if (name.includes("pan")) return "PAN";
    
    return "Document";
  };
  
  // Local storage helpers for offline support
  
  const getFromLocalStorage = (entityId: string): FileData[] => {
    try {
      const storageKey = `documents_${entityId}`;
      const storedData = localStorage.getItem(storageKey);
      return storedData ? JSON.parse(storedData) : [];
    } catch (error) {
      console.error("Error retrieving documents from localStorage:", error);
      return [];
    }
  };
  
  const saveToLocalStorage = (entityId: string, document: FileData): void => {
    try {
      const storageKey = `documents_${entityId}`;
      const existingDocs = getFromLocalStorage(entityId);
      const updatedDocs = [...existingDocs, document];
      localStorage.setItem(storageKey, JSON.stringify(updatedDocs));
    } catch (error) {
      console.error("Error saving document to localStorage:", error);
    }
  };
  
  const removeFromLocalStorage = (entityId: string, documentId: string): void => {
    try {
      const storageKey = `documents_${entityId}`;
      const existingDocs = getFromLocalStorage(entityId);
      const updatedDocs = existingDocs.filter(doc => doc.id !== documentId);
      localStorage.setItem(storageKey, JSON.stringify(updatedDocs));
    } catch (error) {
      console.error("Error removing document from localStorage:", error);
    }
  };
  
  const markForDeletion = (entityId: string, documentId: string): void => {
    try {
      const storageKey = `documents_to_delete`;
      const existingItems = JSON.parse(localStorage.getItem(storageKey) || "[]");
      existingItems.push({ entityId, documentId });
      localStorage.setItem(storageKey, JSON.stringify(existingItems));
    } catch (error) {
      console.error("Error marking document for deletion:", error);
    }
  };
  
  // Additional properties to expose
  const isLoading = (entityId: string): boolean => loading[entityId] || false;
  
  return {
    getDocuments,
    addDocument,
    removeDocument,
    getDocumentUrl,
    isLoading
  };
}; 