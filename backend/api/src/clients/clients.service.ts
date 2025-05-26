import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Client, ClientDocument } from './schemas/client.schema';
import { CreateClientDto } from './dto/create-client.dto';
import { UpdateClientDto } from './dto/update-client.dto';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class ClientsService {
  private readonly logger = new Logger(ClientsService.name);

  constructor(
    @InjectModel(Client.name)
    private clientModel: Model<ClientDocument>,
  ) {}

  async create(createClientDto: CreateClientDto): Promise<Client> {
    try {
      // Generate a unique ID if not provided
      const clientId = createClientDto.id || `CL${uuidv4().substring(0, 8).toUpperCase()}`;
      
      // Process the data to handle nested objects
      const clientData: any = {
        ...createClientDto,
        id: clientId,
      };
      
      // Handle logistics POC data
      if (clientData.logisticsPOC) {
        clientData.logisticsName = clientData.logisticsPOC.name;
        clientData.logisticsPhone = clientData.logisticsPOC.phone;
        clientData.logisticsEmail = clientData.logisticsPOC.email;
      }
      
      // Handle finance POC data
      if (clientData.financePOC) {
        clientData.financeName = clientData.financePOC.name;
        clientData.financePhone = clientData.financePOC.phone;
        clientData.financeEmail = clientData.financePOC.email;
      }
      
      // Handle sales rep data - support both salesRep and salesRepresentative field names
      if (clientData.salesRep) {
        clientData.salesRepName = clientData.salesRep.name;
        clientData.salesRepDesignation = clientData.salesRep.designation;
        clientData.salesRepPhone = clientData.salesRep.phone;
        clientData.salesRepEmail = clientData.salesRep.email;
      } else if (clientData.salesRepresentative) {
        clientData.salesRepName = clientData.salesRepresentative.name;
        clientData.salesRepDesignation = clientData.salesRepresentative.designation;
        clientData.salesRepPhone = clientData.salesRepresentative.phone;
        clientData.salesRepEmail = clientData.salesRepresentative.email;
        
        // Remove the salesRepresentative field to avoid MongoDB errors
        delete clientData.salesRepresentative;
      }
      
      this.logger.log(`Creating new client: ${clientData.name} (${clientId})`);
      
      // Create the MongoDB document
      const newClient = new this.clientModel(clientData);
      
      // Save to MongoDB
      const savedClient = await newClient.save();
      this.logger.log(`Client created successfully: ${savedClient.id}`);
      return savedClient;
    } catch (error) {
      this.logger.error(`Error creating client: ${error.message}`, error.stack);
      if (error.code === 11000) {
        throw new BadRequestException('Client with this ID already exists');
      }
      throw new BadRequestException(`Failed to create client: ${error.message}`);
    }
  }

  async findAll(): Promise<Client[]> {
    try {
      this.logger.log('Fetching all clients');
      // Get clients from MongoDB
      return this.clientModel.find().sort({ name: 1 }).exec();
    } catch (error) {
      this.logger.error(`Error fetching clients: ${error.message}`, error.stack);
      throw new BadRequestException(`Failed to fetch clients: ${error.message}`);
    }
  }

  async findOne(id: string): Promise<Client> {
    try {
      this.logger.log(`Fetching client with ID: ${id}`);
      const client = await this.clientModel.findOne({ id }).exec();
      if (!client) {
        this.logger.warn(`Client with ID ${id} not found`);
        throw new NotFoundException(`Client with ID ${id} not found`);
      }
      return client;
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error(`Error fetching client ${id}: ${error.message}`, error.stack);
      throw new BadRequestException(`Failed to fetch client: ${error.message}`);
    }
  }

  async update(id: string, updateClientDto: UpdateClientDto): Promise<Client> {
    try {
      this.logger.log(`Updating client with ID: ${id}`);
      
      // Process the data to handle nested objects
      const clientData: any = {
        ...updateClientDto,
      };
      
      // Handle logistics POC data
      if (clientData.logisticsPOC) {
        clientData.logisticsName = clientData.logisticsPOC.name;
        clientData.logisticsPhone = clientData.logisticsPOC.phone;
        clientData.logisticsEmail = clientData.logisticsPOC.email;
      }
      
      // Handle finance POC data
      if (clientData.financePOC) {
        clientData.financeName = clientData.financePOC.name;
        clientData.financePhone = clientData.financePOC.phone;
        clientData.financeEmail = clientData.financePOC.email;
      }
      
      // Handle sales rep data - support both salesRep and salesRepresentative field names
      if (clientData.salesRep) {
        clientData.salesRepName = clientData.salesRep.name;
        clientData.salesRepDesignation = clientData.salesRep.designation;
        clientData.salesRepPhone = clientData.salesRep.phone;
        clientData.salesRepEmail = clientData.salesRep.email;
      } else if (clientData.salesRepresentative) {
        clientData.salesRepName = clientData.salesRepresentative.name;
        clientData.salesRepDesignation = clientData.salesRepresentative.designation;
        clientData.salesRepPhone = clientData.salesRepresentative.phone;
        clientData.salesRepEmail = clientData.salesRepresentative.email;
        
        // Remove the salesRepresentative field to avoid MongoDB errors
        delete clientData.salesRepresentative;
      }
      
      // Remove any undefined or null values to prevent overwriting existing data
      Object.keys(clientData).forEach(key => {
        if (clientData[key] === undefined || clientData[key] === null) {
          delete clientData[key];
        }
      });
      
      const updatedClient = await this.clientModel.findOneAndUpdate(
        { id },
        { $set: clientData },
        { new: true }
      ).exec();
      
      if (!updatedClient) {
        this.logger.warn(`Client with ID ${id} not found for update`);
        throw new NotFoundException(`Client with ID ${id} not found`);
      }
      
      this.logger.log(`Client ${id} updated successfully`);
      return updatedClient;
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error(`Error updating client ${id}: ${error.message}`, error.stack);
      throw new BadRequestException(`Failed to update client: ${error.message}`);
    }
  }

  async uploadDocument(id: string, docData: {
    type: string;
    url: string;
    number?: string;
    filename?: string;
  }): Promise<Client> {
    try {
      this.logger.log(`Uploading document for client ${id}: ${docData.type}`);
      
      // Find the client
      const client = await this.findOne(id);
      
      if (!client) {
        throw new NotFoundException(`Client with ID ${id} not found`);
      }
      
      // Create the new document object
      const newDocument = {
        ...docData,
        uploadedAt: new Date(),
      };
      
      // Add the document to the client
      const updatedClient = await this.clientModel.findOneAndUpdate(
        { id: client.id },
        { $push: { documents: newDocument } },
        { new: true }
      ).exec();
      
      if (!updatedClient) {
        throw new NotFoundException(`Failed to update client with ID ${id}`);
      }
      
      this.logger.log(`Document uploaded successfully for client ${id}`);
      return updatedClient;
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error(`Error uploading document for client ${id}: ${error.message}`, error.stack);
      throw new BadRequestException(`Failed to upload document: ${error.message}`);
    }
  }

  async remove(id: string): Promise<void> {
    try {
      this.logger.log(`Deleting client with ID: ${id}`);
      const result = await this.clientModel.deleteOne({ id }).exec();
      if (result.deletedCount === 0) {
        this.logger.warn(`Client with ID ${id} not found for deletion`);
        throw new NotFoundException(`Client with ID ${id} not found`);
      }
      this.logger.log(`Client ${id} deleted successfully`);
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error(`Error deleting client ${id}: ${error.message}`, error.stack);
      throw new BadRequestException(`Failed to delete client: ${error.message}`);
    }
  }
}
