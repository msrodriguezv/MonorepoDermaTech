import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

import { AppModule } from './app/app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // 1. API Versioning & Prefix
  // URIs will look like: http://localhost:3002/api/v1/scheduling/appointments
  const globalPrefix = 'api/v1/scheduling'; 
  app.setGlobalPrefix(globalPrefix);

  // 2. Global Validation Pipe (Security Layer)
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Strips unseen properties from DTOs
      forbidNonWhitelisted: true, // Errors if extra properties are sent
      transform: true, // Auto-convert types (e.g. query params numbers)
    })
  );

  // 3. Swagger Documentation Setup (Missing piece restored)
  const config = new DocumentBuilder()
    .setTitle('Appointment Command Service')
    .setDescription('Microservice responsible for Scheduling and Doctor Management (Write Model)')
    .setVersion('1.0')
    .addTag('Doctors (Admin)', 'Manage medical profiles')
    .addTag('Appointments (Student)', 'Book medical consultations')
    .addBearerAuth() // Enables JWT button in Swagger UI
    .build();

  const document = SwaggerModule.createDocument(app, config);
  
  // Swagger will be available at: http://localhost:3002/api/docs
  SwaggerModule.setup('api/docs', app, document);

  // 4. Server Port Configuration
  const port = process.env.PORT || 3002;
  
  await app.listen(port);
  
  Logger.log(
    `🚀 Appointment Command Service is running on: http://localhost:${port}/${globalPrefix}`
  );
  Logger.log(
    `📑 Swagger Documentation available at: http://localhost:${port}/api/docs`
  );
}

bootstrap();