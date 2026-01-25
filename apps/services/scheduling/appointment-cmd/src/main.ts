// -----------------------------------------------------------------------------
// POLYFILL: Crypto Compatibility for Node.js v18 + Webpack
// Context: Resolves "ReferenceError: crypto is not defined" within TypeORM.
// -----------------------------------------------------------------------------
import * as crypto from 'crypto';

if (!global.crypto) {
  // @ts-expect-error: Node.js 'crypto' differs slightly from the Web Crypto API.
  // We suppress this specific type mismatch to allow the polyfill to work.
  global.crypto = crypto;
}
// -----------------------------------------------------------------------------

import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';

import { AppModule } from './app/app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('Bootstrap');
  
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

 // ===========================================================================
  //  SECURITY: PROD CORS CONFIGURATION
  // ===========================================================================
  const whitelist = [
    // --- Local Development ---
    'http://localhost:3000',
    'http://localhost:4200',
    
    // --- QA Environment ---
    'https://martharodriguez_qa1.distribuidauce.org',  // ALB DNS/Domain
    'http://martharodriguez_qa2.distribuidauce.org',   // Static IP Domain (HTTP per env vars)
    'http://100.52.22.97',                             // QA Static IP
    'http://dermatech-qa-alb-868632428.us-east-1.elb.amazonaws.com',

    // --- PROD Environment ---
    'https://martharodriguez_prod1.distribuidauce.org', // ALB DNS/Domain
    'https://martharodriguez_prod2.distribuidauce.org', // Static IP Domain
    'http://100.50.124.78',                             // PROD Static IP
    'http://dermatech-prod-alb-433169419.us-east-1.elb.amazonaws.com'
  ];

  app.enableCors({

    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      
      // Allow requests with no origin (like mobile apps, curl, or server-to-server)
      if (!origin) {
        return callback(null, true);
      }
      
      if (whitelist.includes(origin)) {
        callback(null, true);
      } else {
        logger.warn(`⛔ Blocked CORS from: ${origin}`);
        callback(new Error('Not allowed by CORS'));
      }
    },
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
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