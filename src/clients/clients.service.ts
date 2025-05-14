import { Injectable, NotFoundException } from '@nestjs/common';
import { Client, CreateClientDto, UpdateClientDto } from './models/client.model';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class ClientsService {
  private clients: Client[] = [
    {
      id: "CL001",
      name: "Tata Steel Ltd",
      city: "Mumbai",
      address: "Bombay House, 24 Homi Mody Street, Fort, Mumbai - 400001",
      addressType: "Corporate Office",
      gstNumber: "27AAACT2727Q1ZW",
      panNumber: "AAACT2727Q",
      logisticsPOC: {
        name: "Rajesh Kumar",
        phone: "9876543210",
        email: "rajesh.kumar@tatasteel.com"
      },
      financePOC: {
        name: "Priya Sharma",
        phone: "9876543211",
        email: "priya.sharma@tatasteel.com"
      },
      invoicingType: "GST 18%",
      salesRep: {
        name: "Vikram Singh",
        designation: "Account Manager",
        phone: "9876543212",
        email: "vikram.singh@freightflow.com"
      }
    },
    {
      id: "CL002",
      name: "Reliance Industries",
      city: "Mumbai",
      address: "Maker Chambers IV, 222, Nariman Point, Mumbai - 400021",
      addressType: "Head Office",
      gstNumber: "27AAACR5055K1ZZ",
      panNumber: "AAACR5055K",
      logisticsPOC: {
        name: "Anand Patel",
        phone: "9876543213",
        email: "anand.patel@ril.com"
      },
      financePOC: {
        name: "Sunil Mehta",
        phone: "9876543214",
        email: "sunil.mehta@ril.com"
      },
      invoicingType: "GST 18%",
      salesRep: {
        name: "Deepak Gupta",
        designation: "Key Account Manager",
        phone: "9876543215",
        email: "deepak.gupta@freightflow.com"
      }
    },
    {
      id: "CL003",
      name: "Asian Paints Ltd",
      city: "Mumbai",
      address: "6A Shantinagar, Santacruz East, Mumbai - 400055",
      addressType: "Manufacturing Unit",
      gstNumber: "27AAACA6666Q1ZS",
      panNumber: "AAACA6666Q",
      logisticsPOC: {
        name: "Sanjay Mishra",
        phone: "9876543216",
        email: "sanjay.mishra@asianpaints.com"
      },
      financePOC: {
        name: "Neha Joshi",
        phone: "9876543217",
        email: "neha.joshi@asianpaints.com"
      },
      invoicingType: "GST 18%",
      salesRep: {
        name: "Rahul Verma",
        designation: "Senior Account Manager",
        phone: "9876543218",
        email: "rahul.verma@freightflow.com"
      }
    }
  ];

  findAll(): Client[] {
    return this.clients;
  }

  findOne(id: string): Client {
    const client = this.clients.find(client => client.id === id);
    if (!client) {
      throw new NotFoundException(`Client with ID ${id} not found`);
    }
    return client;
  }

  create(createClientDto: CreateClientDto): Client {
    const newClient: Client = {
      id: `CL${this.generateClientId()}`,
      ...createClientDto,
    };
    this.clients.push(newClient);
    return newClient;
  }

  update(id: string, updateClientDto: UpdateClientDto): Client {
    const clientIndex = this.clients.findIndex(client => client.id === id);
    if (clientIndex === -1) {
      throw new NotFoundException(`Client with ID ${id} not found`);
    }
    
    const updatedClient = {
      ...this.clients[clientIndex],
      ...updateClientDto,
    };
    
    this.clients[clientIndex] = updatedClient;
    return updatedClient;
  }

  remove(id: string): void {
    const clientIndex = this.clients.findIndex(client => client.id === id);
    if (clientIndex === -1) {
      throw new NotFoundException(`Client with ID ${id} not found`);
    }
    this.clients.splice(clientIndex, 1);
  }

  private generateClientId(): string {
    // Generate a random 3-digit number
    return Math.floor(100 + Math.random() * 900).toString();
  }
} 