export class Supplier {
  id: string;
  name: string;
  city: string;
  address: string;
  contactPerson: {
    name: string;
    phone: string;
    email: string;
  };
  bankDetails: {
    bankName: string;
    accountNumber: string;
    ifscCode: string;
    accountType: string;
  };
  gstNumber: string;
}

export class CreateSupplierDto {
  name: string;
  city: string;
  address: string;
  contactPerson: {
    name: string;
    phone: string;
    email: string;
  };
  bankDetails: {
    bankName: string;
    accountNumber: string;
    ifscCode: string;
    accountType: string;
  };
  gstNumber: string;
}

export class UpdateSupplierDto extends CreateSupplierDto {} 