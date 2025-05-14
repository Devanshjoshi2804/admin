import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Client } from './entities/client.entity';
import { CreateClientDto } from './dto/create-client.dto';
import { UpdateClientDto } from './dto/update-client.dto';

@Injectable()
export class ClientsService {
  constructor(
    @InjectRepository(Client)
    private clientsRepository: Repository<Client>,
  ) {}

  async create(createClientDto: CreateClientDto): Promise<Client> {
    const client = this.clientsRepository.create({
      ...createClientDto,
      logisticsPOC: JSON.stringify(createClientDto.logisticsPOC || {}),
      financePOC: JSON.stringify(createClientDto.financePOC || {}),
      salesRep: JSON.stringify(createClientDto.salesRep || {}),
    });

    const savedClient = await this.clientsRepository.save(client);
    return this.deserializeJsonFields(savedClient);
  }

  async findAll(): Promise<Client[]> {
    const clients = await this.clientsRepository.find({
      order: {
        name: 'ASC'
      }
    });

    return clients.map(client => this.deserializeJsonFields(client));
  }

  async findOne(id: string): Promise<Client> {
    const client = await this.clientsRepository.findOne({ where: { id } });
    if (!client) {
      throw new NotFoundException(`Client with ID ${id} not found`);
    }
    return this.deserializeJsonFields(client);
  }

  async update(id: string, updateClientDto: UpdateClientDto): Promise<Client> {
    const client = await this.clientsRepository.findOne({ where: { id } });
    if (!client) {
      throw new NotFoundException(`Client with ID ${id} not found`);
    }

    // Handle JSON fields separately
    if (updateClientDto.logisticsPOC) {
      client.logisticsPOC = JSON.stringify(updateClientDto.logisticsPOC);
    }
    
    if (updateClientDto.financePOC) {
      client.financePOC = JSON.stringify(updateClientDto.financePOC);
    }
    
    if (updateClientDto.salesRep) {
      client.salesRep = JSON.stringify(updateClientDto.salesRep);
    }

    // Update other fields
    Object.keys(updateClientDto).forEach(key => {
      if (key !== 'logisticsPOC' && key !== 'financePOC' && key !== 'salesRep') {
        client[key] = updateClientDto[key];
      }
    });

    const savedClient = await this.clientsRepository.save(client);
    return this.deserializeJsonFields(savedClient);
  }

  async remove(id: string): Promise<void> {
    const result = await this.clientsRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException(`Client with ID ${id} not found`);
    }
  }

  // Helper to deserialize JSON fields stored as strings
  private deserializeJsonFields(client: Client): any {
    const result = { ...client };
    
    try {
      if (result.logisticsPOC && typeof result.logisticsPOC === 'string') {
        result.logisticsPOC = JSON.parse(result.logisticsPOC);
      }
      
      if (result.financePOC && typeof result.financePOC === 'string') {
        result.financePOC = JSON.parse(result.financePOC);
      }
      
      if (result.salesRep && typeof result.salesRep === 'string') {
        result.salesRep = JSON.parse(result.salesRep);
      }
    } catch (error) {
      console.error('Error deserializing JSON fields:', error);
    }
    
    return result;
  }
}
