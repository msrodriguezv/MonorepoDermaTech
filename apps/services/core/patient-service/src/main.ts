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
  const logger = new Logger('Bootstrap');
  
  // 1. Create the application instance
  const app = await NestFactory.create(AppModule);
  
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
  
  // CORS Configuration
  app.enableCors({
    origin: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
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