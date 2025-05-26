import { Injectable } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import { Connection } from 'mongoose';

@Injectable()
export class AppService {
  constructor(
    @InjectConnection() private readonly mongoConnection: Connection,
  ) {}

  getHello(): string {
    return 'Hello World!';
  }

  getHealth(): { status: string; timestamp: string; version: string } {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      version: process.env.npm_package_version || '1.0.0',
    };
  }

  getApiHealth(): { status: string; timestamp: string; version: string; database: string } {
    const dbStatus = this.mongoConnection.readyState === 1 ? 'connected' : 'disconnected';
    
    return {
      status: dbStatus === 'connected' ? 'ok' : 'error',
      timestamp: new Date().toISOString(),
      version: process.env.npm_package_version || '1.0.0',
      database: dbStatus,
    };
  }
}
