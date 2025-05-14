import React, { useState, useRef, useEffect } from "react";
import { FileUp, Download, FileText, Check, AlertCircle, File as FileIcon, Image as FileImage } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useToast } from "@/hooks/use-toast";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { Progress } from "@/components/ui/progress";
import api from "@/lib/api";

interface FileActionsProps {
  id: string;
  type: "trip" | "payment" | "client" | "supplier" | "vehicle" | "lr-document" | "invoice-document" | "eway-document" | "pod-document";
  entityName: string;
  documentType?: string; // Optional, for specific document types like "POD", "Invoice", etc.
  onSuccess?: (fileData: FileData) => void;
  existingFiles?: FileData[];
}

export interface FileData {
  id: string;
  name: string;
  size: number;
  type: string;
  uploadDate: string;
  url: string;
}

// File type icons and thumbnails
const getFileIcon = (type: string) => {
  if (type.includes('image')) return FileImage;
  if (type.includes('pdf')) return FileText; // Use FileText for PDF files
  if (type.includes('word') || type.includes('doc')) return FileText;
  if (type.includes('excel') || type.includes('sheet') || type.includes('csv')) return FileText;
  if (type.includes('video')) return FileText;
  return FileIcon;
};

// Generate a thumbnail preview for a file if possible
const FilePreview = ({ file }: { file: File | FileData }) => {
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  
  useEffect(() => {
    // For File objects (being uploaded)
    if ('size' in file && 'type' in file && 'name' in file && !(file as FileData).url) {
      const browserFile = file as File;
      if (browserFile.type.includes('image')) {
        const reader = new FileReader();
        reader.onloadend = () => {
          setPreviewUrl(reader.result as string);
        };
        reader.readAsDataURL(browserFile);
      }
    } 
    // For FileData objects (already uploaded)
    else if ('url' in file && file.type.includes('image')) {
      setPreviewUrl(file.url);
    }
    
    return () => {
      if (previewUrl && !('url' in file)) {
        URL.revokeObjectURL(previewUrl);
      }
    };
  }, [file]);
  
  if (previewUrl) {
    return (
      <div className="w-full h-20 flex items-center justify-center overflow-hidden bg-slate-100 dark:bg-slate-800 rounded-md">
        <img 
          src={previewUrl} 
          alt="Preview" 
          className="max-h-full max-w-full object-contain" 
        />
      </div>
    );
  }
  
  // Show icon for non-image files
  const FileTypeIcon = getFileIcon('size' in file && !('url' in file) 
    ? (file as File).type 
    : (file as FileData).type);
  
  return (
    <div className="w-full h-20 flex items-center justify-center bg-slate-100 dark:bg-slate-800 rounded-md">
      <FileTypeIcon className="h-10 w-10 text-slate-400 dark:text-slate-500" />
    </div>
  );
};

export const FileActions = ({
  id,
  type,
  entityName,
  documentType = "document",
  onSuccess,
  existingFiles = [],
}: FileActionsProps) => {
  const { toast } = useToast();
  const [uploadDialogOpen, setUploadDialogOpen] = useState(false);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [uploading, setUploading] = useState(false);
  const [uploadSuccess, setUploadSuccess] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleUploadClick = () => {
    setUploadDialogOpen(true);
    setSelectedFile(null);
    setUploadProgress(0);
    setUploading(false);
    setUploadSuccess(false);
  };

  const handleViewDocuments = () => {
    setViewDialogOpen(true);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      setSelectedFile(e.target.files[0]);
    }
  };

  const handleDownload = (file: FileData) => {
    // Create a mock download URL
    const url = file.url || URL.createObjectURL(new Blob(["Mock file content"], { type: file.type }));
    
    // Create a temporary anchor element
    const a = document.createElement("a");
    a.href = url;
    a.download = file.name;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);

    toast({
      title: "Download Started",
      description: `Downloading ${file.name}`,
    });
  };

  const handleFileUpload = async () => {
    if (!selectedFile) return;
    
    // Start uploading
    setUploading(true);
    setUploadProgress(10); // Initial progress
    
    try {
      // Simulate progress for better UX
      const progressInterval = setInterval(() => {
        setUploadProgress(prev => {
          if (prev >= 90) {
            clearInterval(progressInterval);
            return 90;
          }
          return prev + 10;
        });
      }, 300);
      
      // Create file data object
      const fileData: FileData = {
        id: `${Date.now()}-${selectedFile.name}`,
        name: selectedFile.name,
        type: selectedFile.type,
        size: selectedFile.size,
        uploadDate: new Date().toISOString(),
        url: URL.createObjectURL(selectedFile)
      };
      
      // Check if this is a POD document
      const isPodUpload = 
        (type === "trip" || type === "pod-document") && 
        (documentType.toLowerCase().includes("pod") || selectedFile.name.toLowerCase().includes("pod"));
      
      // Call onSuccess with the file data
      if (onSuccess) {
        await onSuccess(fileData);
      }
      
      // Special handling for POD documents
      if (isPodUpload) {
        handlePodUpload(id, fileData);
      }
      
      // Complete the upload
      clearInterval(progressInterval);
      setUploadProgress(100);
      setUploadSuccess(true);
      
      // Close dialog after a short delay
      setTimeout(() => {
        setUploadDialogOpen(false);
        setUploadProgress(0);
        setUploading(false);
        setUploadSuccess(false);
      }, 1500);
    } catch (error) {
      console.error("Error uploading file:", error);
      toast({
        title: "Upload Failed",
        description: "There was an error uploading your file. Please try again.",
        variant: "destructive"
      });
      setUploading(false);
      setUploadProgress(0);
    }
  };

  // Add helper function for POD uploads
  const handlePodUpload = async (entityId: string, fileData: FileData) => {
    try {
      // First, make sure we have a valid ID (non-empty string)
      if (!entityId || typeof entityId !== 'string' || entityId.trim() === '') {
        console.error("Invalid entity ID for POD upload");
        toast({
          title: "POD Upload Issue",
          description: "Invalid trip ID. Please try again.",
          variant: "destructive"
        });
        return;
      }

      // Extract the actual trip ID from the entityId
      const tripId = entityId.includes('-') ? entityId.split('-')[1] : entityId;
      
      // Call the API to update POD status only - don't initiate balance payment
      console.log("Updating POD status for trip:", tripId);
      
      // Create proper payload for the API call
      const payload = { podUploaded: true };
      
      api.trips.update(tripId, payload)
        .then(response => {
          console.log("POD status updated successfully:", response);
          toast({
            title: "POD Uploaded",
            description: "Document uploaded successfully.",
            variant: "default"
          });
        })
        .catch(error => {
          console.error("Error updating POD status:", error);
          
          // Check for specific error messages from the API if available
          let errorMsg = "Document was saved but system update failed. Please try again.";
          if (error.response && error.response.data && error.response.data.message) {
            errorMsg = error.response.data.message;
          }
          
          toast({
            title: "POD Upload Issue",
            description: errorMsg,
            variant: "destructive"
          });
        });
    } catch (error) {
      console.error("Error in POD upload process:", error);
      toast({
        title: "POD Upload Failed",
        description: "An unexpected error occurred. Please try again.",
        variant: "destructive"
      });
    }
  };

  const getEntityLabel = () => {
    switch (type) {
      case "trip": return "Trip";
      case "payment": return "Payment";
      case "client": return "Client";
      case "supplier": return "Supplier";
      case "vehicle": return "Vehicle";
      case "lr-document": return "LR Document";
      case "invoice-document": return "Invoice";
      case "eway-document": return "E-way Bill";
      case "pod-document": return "Proof of Delivery";
      default: return "Entity";
    }
  };

  return (
    <>
      <div className="flex space-x-1">
        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant="ghost"
                size="icon"
                className="h-7 w-7"
                onClick={handleUploadClick}
              >
                <FileUp size={14} />
              </Button>
            </TooltipTrigger>
            <TooltipContent side="top" align="center" className="text-xs">
              <p>Upload {documentType}</p>
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>

        <TooltipProvider>
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant="ghost"
                size="icon"
                className="h-7 w-7"
                onClick={handleViewDocuments}
              >
                <FileText size={14} />
              </Button>
            </TooltipTrigger>
            <TooltipContent side="top" align="center" className="text-xs">
              <p>View Documents</p>
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>
      </div>

      {/* Upload Dialog */}
      <Dialog open={uploadDialogOpen} onOpenChange={setUploadDialogOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Upload {documentType}</DialogTitle>
            <DialogDescription>
              Upload {documentType} for {getEntityLabel().toLowerCase()} {entityName}
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            {uploadSuccess ? (
              <div className="flex items-center justify-center flex-col gap-2 py-4">
                <div className="rounded-full bg-green-100 p-2">
                  <Check className="h-6 w-6 text-green-600" />
                </div>
                <p className="text-sm font-medium">Upload Successful</p>
                <p className="text-xs text-gray-500">{selectedFile?.name}</p>
              </div>
            ) : (
              <>
                <div className="relative border-2 border-dashed rounded-md p-6 flex flex-col items-center justify-center gap-2">
                  {selectedFile ? (
                    <div className="flex flex-col items-center gap-3">
                      <FilePreview file={selectedFile} />
                      <div className="w-full">
                        <div className="text-sm font-medium mb-1 truncate">{selectedFile.name}</div>
                        <div className="flex justify-between text-xs text-gray-500">
                          <span>{(selectedFile.size / 1024).toFixed(1)} KB</span>
                          <span>{new Date().toLocaleString()}</span>
                        </div>
                      </div>
                      {uploading && (
                        <div className="w-full mt-2">
                          <Progress value={uploadProgress} className="h-2" />
                          <div className="flex justify-between mt-1 text-xs text-gray-500">
                            <span>{uploadProgress === 100 ? 'Complete' : 'Uploading...'}</span>
                            <span>{uploadProgress}%</span>
                          </div>
                        </div>
                      )}
                    </div>
                  ) : (
                    <>
                      <input
                        type="file"
                        ref={fileInputRef}
                        onChange={handleFileChange}
                        className="hidden"
                      />
                      <div 
                        onClick={() => fileInputRef.current?.click()}
                        className="flex flex-col items-center justify-center cursor-pointer p-4 h-full"
                      >
                        <div className="rounded-full bg-blue-50 dark:bg-blue-900/20 p-3 mb-2">
                          <FileUp className="h-6 w-6 text-blue-600 dark:text-blue-400" />
                        </div>
                        <p className="text-sm font-medium">Upload {documentType}</p>
                        <p className="text-xs text-gray-500 mt-1">
                          Drag and drop or click to select
                        </p>
                        <p className="text-xs text-gray-500 mt-3">
                          Supported formats: PDF, JPG, PNG, DOC
                        </p>
                      </div>
                    </>
                  )}
                </div>
              </>
            )}
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setUploadDialogOpen(false)}
              disabled={uploading}
            >
              Cancel
            </Button>
            <Button 
              onClick={handleFileUpload} 
              disabled={!selectedFile || uploading || uploadSuccess}
            >
              Upload
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* View Documents Dialog */}
      <Dialog open={viewDialogOpen} onOpenChange={setViewDialogOpen}>
        <DialogContent className="sm:max-w-[600px]">
          <DialogHeader>
            <DialogTitle>Documents</DialogTitle>
            <DialogDescription>
              View and download documents for {getEntityLabel().toLowerCase()} {entityName}
            </DialogDescription>
          </DialogHeader>
          <div className="py-4">
            {existingFiles && existingFiles.length > 0 ? (
              <div className="space-y-3">
                {existingFiles.map((file) => (
                  <div 
                    key={file.id} 
                    className="flex items-center justify-between p-3 border rounded-md"
                  >
                    <div className="flex items-center gap-3">
                      <FileText className="h-5 w-5 text-blue-500" />
                      <div>
                        <p className="text-sm font-medium">{file.name}</p>
                        <p className="text-xs text-gray-500">
                          {new Date(file.uploadDate).toLocaleDateString()} • 
                          {(file.size / 1024).toFixed(1)} KB
                        </p>
                      </div>
                    </div>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleDownload(file)}
                    >
                      <Download size={16} className="mr-2" /> Download
                    </Button>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8">
                <AlertCircle className="h-8 w-8 text-gray-400 mx-auto mb-2" />
                <h3 className="text-sm font-medium">No documents found</h3>
                <p className="text-xs text-gray-500 mt-1">
                  Upload documents using the upload button
                </p>
              </div>
            )}
          </div>
          <DialogFooter>
            <Button onClick={() => setViewDialogOpen(false)}>
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}; 