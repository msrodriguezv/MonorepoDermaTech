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

import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger, VersioningType} from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { Transport, MicroserviceOptions } from '@nestjs/microservices';
import { AppModule } from './app.module';

async function bootstrap() {


  const logger = new Logger('PatientService');
  
  // 1. Create the application instance
  const app = await NestFactory.create(AppModule, {
    logger: ['log', 'error', 'warn', 'debug', 'verbose'], 
  })
  
  const configService = app.get(ConfigService);

  app.setGlobalPrefix('api');

  // Enable URI Versioning
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1', 
  });
  
  // 2. CONNECT KAFKA MICROSERVICE
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.KAFKA,
    options: {
      client: {
        clientId: configService.get<string>('KAFKA_CLIENT_ID', 'patient-service'),
        brokers: [configService.get<string>('KAFKA_BROKERS') || 'localhost:9092'],
        retry: { retries: 10, initialRetryTime: 300 },
      },
      producer: {
        idempotent: true, 
        allowAutoTopicCreation: configService.get<string>('NODE_ENV') !== 'production',
      },
      consumer: {
        groupId: configService.get<string>('KAFKA_GROUP_ID') || 'patient-service-group',
        sessionTimeout: 30000,
        allowAutoTopicCreation: configService.get<string>('NODE_ENV') !== 'production',
      },
    },
  });

  // Swagger Configuration
  const config = new DocumentBuilder()
    .setTitle('Patient Service')
    .setDescription('The Patient Service API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
    
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document); 

  // Global Pipes
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
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

  // 3. START MICROSERVICES
  await app.startAllMicroservices();
  logger.log('Microservice (Kafka Consumer) is listening...');

  // 4. START HTTP SERVER
  const port = configService.get<number>('PORT') || 3001;
  await app.listen(port);
  
  logger.log(`Patient Service is running on: http://localhost:${port}/api/v1/patient`);
  logger.log(`HTTP Server is running on: http://localhost:${port}/api/docs`);
}
bootstrap();