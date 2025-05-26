import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { MongoSeeder } from './database/mongo-seeder';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Enable CORS
  app.enableCors({
    origin: true, // Allow all origins or specify your frontend URL
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
    allowedHeaders: 'Content-Type,Accept,Authorization',
    exposedHeaders: 'Content-Disposition',
  });
  
  // Set global prefix for all routes
  app.setGlobalPrefix('api');
  
  // Enable validation
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    transform: true,
    forbidNonWhitelisted: true,
  }));
  
  // Start the server
  await app.listen(process.env.PORT ?? 3000);
  console.log(`Application is running on: ${await app.getUrl()}`);
  
  // Seed the MongoDB database with initial data
  try {
    const mongoSeeder = app.get(MongoSeeder);
    await mongoSeeder.seed();
  } catch (error) {
    console.error('Error seeding MongoDB database:', error);
  }
}
bootstrap();
