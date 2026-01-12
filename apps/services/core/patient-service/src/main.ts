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
  
  // Retrieve ConfigService to access environment variables safely
  const configService = app.get(ConfigService);

  app.setGlobalPrefix('api');

  // Enable URI Versioning (This adds /v1/ to the path automatically)
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1', // Forces v1 for all controllers without explicit version
  });
  

  // 2. CONNECT KAFKA MICROSERVICE
  // This enables the application to listen to Kafka messages/events.
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.KAFKA,
    options: {
      client: {
        clientId: configService.get<string>('KAFKA_CLIENT_ID', 'patient-service'),
        brokers: [configService.get<string>('KAFKA_BROKERS') || 'localhost:9092'],
        retry: { retries: 10, initialRetryTime: 300 },
      },
      producer: {
        idempotent: true, // not duplicates
        allowAutoTopicCreation: configService.get<string>('NODE_ENV') !== 'production',
      },
      consumer: {
        groupId: configService.get<string>('KAFKA_GROUP_ID') || 'patient-service-group',
        sessionTimeout: 30000,
        allowAutoTopicCreation: configService.get<string>('NODE_ENV') !== 'production',
      },
    },
  });

  // --- SWAGGER CONFIGURATION ---
  const config = new DocumentBuilder()
    .setTitle('Patient Service')
    .setDescription('The Patient Service API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
    
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document); 

  // --- GLOBAL PIPES ---
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  
  // CORS Configuration
  app.enableCors({
    origin: true, // In production, replace with specific domain
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  // 3. START MICROSERVICES
  // CRITICAL STEP: Without this, the Kafka consumer will never start listening.
  await app.startAllMicroservices();
  logger.log('Microservice (Kafka Consumer) is listening...');

  // 4. START HTTP SERVER
  const port = configService.get<number>('PORT') || 3001;
  await app.listen(port);
  
   logger.log(`Auth Service is running on: http://localhost:${port}/api/v1/patient`);
  logger.log(`HTTP Server is running on: http://localhost:${port}/api/docs`);
}

bootstrap();