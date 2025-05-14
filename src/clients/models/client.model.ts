export class Client {
  id: string;
  name: string;
  city: string;
  address: string;
  addressType: string;
  gstNumber: string;
  panNumber: string;
  logisticsPOC: {
    name: string;
    phone: string;
    email: string;
  };
  financePOC: {
    name: string;
    phone: string;
    email: string;
  };
  invoicingType: string;
  salesRep: {
    name: string;
    designation: string;
    phone: string;
    email: string;
  };
}

export class CreateClientDto {
  name: string;
  city: string;
  address: string;
  addressType: string;
  gstNumber: string;
  panNumber: string;
  logisticsPOC: {
    name: string;
    phone: string;
    email: string;
  };
  financePOC: {
    name: string;
    phone: string;
    email: string;
  };
  invoicingType: string;
  salesRep: {
    name: string;
    designation: string;
    phone: string;
    email: string;
  };
}

export class UpdateClientDto extends CreateClientDto {} 