import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';

import { AppModule } from './app/app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // 0. Configuration Service Extraction
  const configService = app.get(ConfigService);

  // 1. API Versioning & Prefix
  // URIs will look like: http://localhost:3002/api/v1/scheduling/appointments
  const globalPrefix = 'api/v1/scheduling'; 
  app.setGlobalPrefix(globalPrefix);

  // 2. Global Validation Pipe (Security Layer)
  // Ensures data integrity before it reaches the Controllers
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,            // Strips properties that are not in the DTO
      forbidNonWhitelisted: true, // Throws an error if extra properties are sent (Strict Mode)
      transform: true,            // Auto-converts primitive types (e.g., param id string -> number)
      transformOptions: {
        enableImplicitConversion: true,
      },
    })
  );

  // 3. CORS Configuration (Mandatory for Flutter Web)
  app.enableCors({
    origin: '*', // In production, replace with specific domain
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  // 4. Swagger Documentation Setup
  const config = new DocumentBuilder()
    .setTitle('Appointment Command Service')
    .setDescription('Microservice responsible for Scheduling and Doctor Management (Write Model)')
    .setVersion('1.0')
    .addTag('Doctors (Admin)', 'Manage medical profiles')
    .addTag('Appointments (Student)', 'Book medical consultations')
    .addBearerAuth() // Enables JWT button in Swagger UI
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  // 5. Graceful Shutdown (Docker Signal Handling)
  app.enableShutdownHooks();

  // 6. Server Port Configuration
  const port = configService.get<number>('PORT') || 3002;
  
  await app.listen(port);
  
  Logger.log(
    `🚀 Appointment Command Service is running on: http://localhost:${port}/${globalPrefix}`
  );
  Logger.log(
    `📑 Swagger Documentation available at: http://localhost:${port}/api/docs`
  );
}

bootstrap();