import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Enable CORS to allow the React frontend to communicate with the API
  app.enableCors({
    origin: 'http://localhost:5173', // React Vite default port
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });
  
  // Set global API prefix
  app.setGlobalPrefix('api');

  await app.listen(3000);
  console.log('NestJS API server running on http://localhost:3000/api');
}
bootstrap(); 