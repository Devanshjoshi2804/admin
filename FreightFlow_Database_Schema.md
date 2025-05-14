# FreightFlow Booking System - Database Schema Documentation

## Overview

The FreightFlow Booking System uses SQLite for data storage with TypeORM as the ORM layer. The system follows a relational database model with proper foreign key constraints enabled.

## Database Configuration

```typescript
{
  type: 'sqlite',
  database: 'freight_flow.sqlite',
  entities: [...],
  synchronize: true, // Set to false in production
  logging: true,
  extra: {
    // Enable foreign key constraints for proper database integrity
    pragma: [
      'PRAGMA foreign_keys = ON'
    ]
  }
}
```

## Entities and Relationships

### Client Entity

**Table Name:** `client`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK, Generated | Primary key |
| name | varchar | NOT NULL | Client company name |
| city | varchar | NOT NULL | City where client is located |
| address | varchar | NOT NULL | Full address |
| addressType | varchar | NOT NULL | Type of address (e.g., Corporate Office, Warehouse) |
| gstNumber | varchar | NOT NULL | GST registration number |
| panNumber | varchar | NOT NULL | PAN card number |
| logisticsPOC | text | NOT NULL | JSON data for logistics point of contact |
| financePOC | text | NOT NULL | JSON data for finance point of contact |
| invoicingType | varchar | NOT NULL | Type of invoicing used |
| salesRep | text | NOT NULL | JSON data for sales representative |

**Relationships:**
- One-to-Many with `Trip` (One client can have many trips)

### Supplier Entity

**Table Name:** `supplier`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK, Generated | Primary key |
| name | varchar | NOT NULL | Supplier company name |
| city | varchar | NOT NULL | City where supplier is located |
| address | varchar | NOT NULL | Full address |
| contactPerson | text | NOT NULL | JSON data for contact person information |
| bankDetails | text | NOT NULL | JSON data for bank account details |
| gstNumber | varchar | NOT NULL | GST registration number |

**Relationships:**
- One-to-Many with `Trip` (One supplier can have many trips)
- One-to-Many with `Vehicle` (One supplier can have many vehicles, implied)

### Vehicle Entity

**Table Name:** `vehicle`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK, Generated | Primary key |
| registrationNumber | varchar | NOT NULL | Vehicle registration number |
| supplierId | varchar | FK, NOT NULL | Foreign key to Supplier |
| supplierName | varchar | NOT NULL | Denormalized supplier name |
| vehicleType | varchar | NOT NULL | Type of vehicle (e.g., Open Body, Container) |
| vehicleSize | varchar | NOT NULL | Size of vehicle (e.g., 20FT, 32FT) |
| vehicleCapacity | varchar | NOT NULL | Capacity of vehicle (e.g., 10 Ton) |
| axleType | varchar | NOT NULL | Type of axle (e.g., Single, Multi) |
| driverName | varchar | NOT NULL | Name of driver |
| driverPhone | varchar | NOT NULL | Phone number of driver |
| insuranceExpiry | varchar | NOT NULL | Insurance expiry date |

**Relationships:**
- Many-to-One with `Supplier` (Many vehicles belong to one supplier)
- One-to-Many with `Trip` (One vehicle can be used for many trips)

### Trip Entity

**Table Name:** `trip`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK, Generated | Primary key |
| orderNumber | varchar | UNIQUE, NOT NULL | Unique order number for the trip |
| lrNumbers | simple-array | NOT NULL | Array of LR numbers |
| clientId | varchar | FK, NULL | Foreign key to Client |
| clientName | varchar | NOT NULL | Denormalized client name |
| clientAddress | varchar | NOT NULL | Client address for the trip |
| clientAddressType | varchar | NOT NULL | Type of client address |
| clientCity | varchar | NOT NULL | Client city |
| destinationAddress | varchar | NOT NULL | Destination address |
| destinationCity | varchar | NOT NULL | Destination city |
| destinationAddressType | varchar | NOT NULL | Type of destination address |
| supplierId | varchar | FK, NULL | Foreign key to Supplier |
| supplierName | varchar | NOT NULL | Denormalized supplier name |
| vehicleId | varchar | FK, NULL | Foreign key to Vehicle |
| vehicleNumber | varchar | NOT NULL | Vehicle registration number |
| driverName | varchar | NULL | Name of driver |
| driverPhone | varchar | NULL | Phone number of driver |
| vehicleType | varchar | NOT NULL | Type of vehicle |
| vehicleSize | varchar | NOT NULL | Size of vehicle |
| vehicleCapacity | varchar | NOT NULL | Capacity of vehicle |
| axleType | varchar | NOT NULL | Type of axle |
| materials | text | NOT NULL | JSON data for materials being transported |
| pickupDate | varchar | NOT NULL | Date of pickup |
| pickupTime | varchar | NOT NULL | Time of pickup |
| clientFreight | float | NOT NULL | Amount charged to client |
| supplierFreight | float | NOT NULL | Amount paid to supplier |
| advancePercentage | float | NOT NULL | Percentage of advance payment |
| advanceSupplierFreight | float | NOT NULL | Advance amount paid to supplier |
| balanceSupplierFreight | float | NOT NULL | Balance amount to be paid to supplier |
| documents | text | NULL | JSON data for documents |
| fieldOps | text | NOT NULL | JSON data for field operations |
| gsmTracking | boolean | DEFAULT false | Whether GSM tracking is enabled |
| status | varchar | NOT NULL | Current status of the trip |
| advancePaymentStatus | varchar | NOT NULL | Status of advance payment |
| balancePaymentStatus | varchar | NOT NULL | Status of balance payment |
| podUploaded | boolean | DEFAULT false | Whether POD has been uploaded |
| additionalCharges | text | NULL | JSON data for additional charges |
| deductionCharges | text | NULL | JSON data for deduction charges |
| lrCharges | float | NULL | LR charges amount |
| platformFees | float | NULL | Platform fees amount |
| utrNumber | varchar | NULL | UTR number for payment |
| paymentMethod | varchar | NULL | Method of payment |
| ifscCode | varchar | NULL | IFSC code for bank payment |
| createdAt | timestamp | DEFAULT NOW() | Record creation timestamp |
| updatedAt | timestamp | AUTO UPDATE | Record update timestamp |

**Relationships:**
- Many-to-One with `Client` (Many trips belong to one client)
- Many-to-One with `Supplier` (Many trips are fulfilled by one supplier)
- Many-to-One with `Vehicle` (Many trips use one vehicle)

## Entity Relationship Diagram (ERD)

```
Client (1) --- (*) Trip (*) --- (1) Supplier
                   |
                   |
                   (*) --- (1) Vehicle
```

## Foreign Key Constraints

- `trip.clientId` references `client.id` (ON DELETE SET NULL)
- `trip.supplierId` references `supplier.id` (ON DELETE SET NULL)
- `trip.vehicleId` references `vehicle.id` (ON DELETE SET NULL)
- `vehicle.supplierId` references `supplier.id`

## Special Data Types

Several fields store JSON data as text strings that are parsed/stringified by the application:
- `logisticsPOC`, `financePOC`, `salesRep` in Client
- `contactPerson`, `bankDetails` in Supplier 
- `materials`, `documents`, `fieldOps`, `additionalCharges`, `deductionCharges` in Trip

## Indexes

- Primary key indexes on all entity IDs
- Unique index on `trip.orderNumber`

## Notes

1. The system uses UUID generation for primary keys
2. Some denormalization is used (e.g., storing `supplierName` in Vehicle and Trip entities) to improve query performance
3. Foreign key constraints are enabled using SQLite pragma settings
4. The `synchronize` option is enabled in development, which automatically updates the database schema based on entity changes (should be disabled in production) 