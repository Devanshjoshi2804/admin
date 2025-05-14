import { NestFactory } from '@nestjs/core';
import { AppModule, seedDatabase } from './app.module';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Enable CORS
  app.enableCors({
    origin: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: 'Content-Type,Accept,Authorization',
    credentials: true,
  });
  
  // Set global path prefix
  app.setGlobalPrefix('api');
  
  // Enable validation
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    transform: true,
    forbidNonWhitelisted: true,
  }));
  
  // Start the server
  await app.listen(process.env.PORT ?? 3000);
  console.log(`Application running on: ${await app.getUrl()}`);
  
  // Seed the database with initial data
  try {
    await seedDatabase(app);
  } catch (error) {
    console.error('Error seeding database:', error);
  }
}
bootstrap();
