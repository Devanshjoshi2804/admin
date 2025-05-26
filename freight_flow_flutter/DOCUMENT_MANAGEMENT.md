# Document Management System

## Overview
The FTL Trips system now includes a comprehensive document management feature that allows users to upload, view, download, and manage trip-related documents with MongoDB integration.

## Features

### 1. Dynamic Document Upload
- **File Types Supported**: PDF, DOC, DOCX, JPG, JPEG, PNG
- **File Size Limit**: 10MB per document
- **Document Types**: 
  - LR Copy
  - Invoice
  - E-way Bill
  - POD (Proof of Delivery)
  - Weighment Slip
  - Gate Pass
  - Other

### 2. Enhanced UI/UX
- **Modern Layout**: Clean, spacious design with better typography
- **Improved Table**: Better column spacing and alternating row colors
- **Enhanced Actions**: Colored action buttons with proper tooltips
- **Professional Cards**: Document cards with proper status indicators
- **Real-time Updates**: Automatic refresh after document operations

### 3. Database Integration
- **MongoDB Storage**: Documents are stored in MongoDB database
- **Metadata Management**: Filename, type, upload date, document number tracking
- **URL Generation**: Proper URL handling for document access
- **File Storage**: Binary data storage with proper content type handling

### 4. Document Operations

#### Upload Process
1. Select document type from dropdown
2. File picker opens for file selection
3. File validation (size, type)
4. Upload progress indicator
5. MongoDB storage
6. Automatic trip data refresh
7. Success notification

#### Download Process
1. Click download button on document
2. API call to retrieve file bytes
3. Browser download initiation
4. Success notification

#### Preview/View
1. Click view button
2. Opens document in new browser tab (for real documents)
3. Shows document details dialog (for local documents)

#### Auto-Payment Status Update
- When POD is uploaded, balance payment status automatically updates to "Ready for Payment"
- Notification confirms the status change

### 5. Enhanced Trip List View

#### Improved Layout
- **Better Spacing**: Increased padding and margins
- **Color Coding**: Status-based colors for better visual hierarchy
- **Enhanced Typography**: Improved font weights and sizes
- **Professional Cards**: Card-based design with shadows

#### Action Buttons
- **View Details**: Blue background, opens trip detail page
- **Documents**: Purple background, shows document count in tooltip
- **Delete**: Red background, confirmation dialog

#### Financial Display
- **Client Freight**: Green color coding
- **Supplier Freight**: Bold formatting
- **Margin**: Color-coded based on positive/negative value
- **Proper Currency Formatting**: ₹ symbol with number formatting

### 6. Advanced Filters Panel

#### Modern Design
- **Card Layout**: Professional card with header
- **Grid Status Filters**: Visual status selection grid
- **Dropdown Filters**: Client and vehicle type dropdowns
- **Quick Search**: Unified search across multiple fields
- **Clear Filters**: One-click filter reset
- **Export Functionality**: Direct CSV export from panel

#### Filter Options
- **Status**: All, Booked, In Transit, Delivered, Completed
- **Client**: Dropdown with major clients
- **Vehicle Type**: Truck, Trailer, Container, Multi Axle
- **Quick Search**: Order ID, LR Number, Client name

### 7. Document Status Tracking
- **Upload Status**: Tracks document upload state
- **Type-based Status**: Different status for LR, POD, etc.
- **Visual Indicators**: Color-coded status chips
- **Document Count**: Shows total documents per trip

## Technical Implementation

### API Integration
```dart
// Document upload
final apiService = ApiService();
await apiService.uploadDocument(tripId, docData);

// Document download
final bytes = await apiService.downloadDocument(doc.url);

// Document deletion (placeholder)
// Implementation pending in backend
```

### State Management
- **Riverpod Integration**: Reactive state management
- **Auto Refresh**: Automatic data refresh after operations
- **Error Handling**: Comprehensive error handling with user feedback

### File Handling
- **PlatformFile**: Uses file_picker for cross-platform file selection
- **Validation**: File size and type validation
- **Progress Tracking**: Upload progress indicators
- **Error Recovery**: Graceful error handling

## Future Enhancements

### Planned Features
1. **Document Versioning**: Track document versions
2. **Bulk Upload**: Multiple document upload
3. **Document Templates**: Pre-defined document templates
4. **OCR Integration**: Extract text from uploaded documents
5. **Digital Signatures**: E-signature capability
6. **Document Approval Workflow**: Multi-step approval process
7. **Advanced Search**: Full-text search within documents
8. **Document Sharing**: Share documents with clients/suppliers

### Backend Enhancements Needed
1. **Document Deletion API**: Implement document deletion endpoint
2. **File Storage Optimization**: Implement cloud storage (AWS S3, Google Cloud)
3. **Document Indexing**: Search indexing for better performance
4. **Access Control**: Role-based document access
5. **Audit Trail**: Track document access and modifications

## Usage Guide

### Uploading Documents
1. Navigate to FTL Trips page
2. Click the purple document icon for any trip
3. Select document type from dropdown
4. File picker will open automatically
5. Select your file (max 10MB)
6. Wait for upload confirmation
7. Document appears in the list immediately

### Downloading Documents
1. Open document dialog for any trip
2. Find the document you want to download
3. Click the green download button
4. File will download to your default download folder

### Managing Documents
1. Use the refresh button to update document list
2. Preview documents by clicking the blue view button
3. Delete documents using the red delete button (with confirmation)
4. Documents are automatically linked to payment status updates

## Troubleshooting

### Common Issues
1. **File too large**: Ensure file is under 10MB
2. **Unsupported format**: Use PDF, DOC, DOCX, JPG, JPEG, PNG only
3. **Upload fails**: Check internet connection and try again
4. **Document not appearing**: Click refresh button in document dialog

### Error Messages
- "File size must be less than 10MB"
- "Upload failed: [error details]"
- "Document not found in database"
- "Download failed: [error details]"

The document management system provides a complete solution for handling trip-related documents with a modern, user-friendly interface and robust backend integration. 