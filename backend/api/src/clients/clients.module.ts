import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Client, ClientSchema } from './schemas/client.schema';
import { ClientsController } from './clients.controller';
import { ClientsService } from './clients.service';

@Module({
  imports: [
    // MongoDB support
    MongooseModule.forFeature([{ name: Client.name, schema: ClientSchema }])
  ],
  providers: [ClientsService],
  controllers: [ClientsController],
  exports: [MongooseModule, ClientsService],
})
export class ClientsModule {}
