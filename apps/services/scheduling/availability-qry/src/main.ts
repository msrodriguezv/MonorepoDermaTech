import { Logger, ValidationPipe, VersioningType } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { Transport, MicroserviceOptions } from '@nestjs/microservices';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

import { AppModule } from './app/app.module';

async function bootstrap() {
  const logger = new Logger('AvailabilityQryService');
  
  // Initialize hybrid application (HTTP + Kafka)
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);

   // Enable URI Versioning (This adds /v1/ to the path automatically)
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1', // Forces v1 for all controllers without explicit version
  });


  // Configure Kafka consumer microservice
  // This consumer listens to domain events published by other services
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.KAFKA,
    options: { 
      client: {
        // Use environment variables for flexible configuration across environments
        clientId: configService.get<string>('KAFKA_CLIENT_ID', 'availability-qry'),
        brokers: [configService.get<string>('KAFKA_BROKERS', 'localhost:9092')],
        
        // Enhanced retry configuration to handle initial connection delays
        // Prevents "no leader for partition" errors during topic initialization
        retry: {
          retries: 15,                    // Increased retry attempts for robustness
          initialRetryTime: 500,          // Start with 500ms delay between retries
          maxRetryTime: 30000,            // Cap maximum delay at 30 seconds
          multiplier: 2,                  // Exponential backoff (500ms, 1s, 2s, 4s, ...)
          
          // Callback executed on connection failure
          // Returning true enables automatic reconnection attempts
          restartOnFailure: async (error) => {
            logger.error(`Kafka connection failed: ${error.message}. Retrying...`);
            return true;
          }
        },
      },
      
      producer: {
        idempotent: true,                 // Prevent duplicate messages on retry
        
        // CRITICAL: Disable auto topic creation
        // Topics MUST exist before connecting to prevent leaderless partition errors
        // Only allow auto-creation in non-production for development flexibility
        allowAutoTopicCreation: configService.get<string>('NODE_ENV') !== 'production',
      },
      
      consumer: {
        // Use environment variable for consumer group ID
        // This allows horizontal scaling with multiple instances sharing the load
        groupId: configService.get<string>('KAFKA_GROUP_ID', 'availability-consumer-group'),
        
        sessionTimeout: 30000,            // Max time without heartbeat before rebalance
        
        // CRITICAL: Disable auto topic creation on consumer side
        // Ensures we only subscribe to pre-existing topics with elected leaders
        allowAutoTopicCreation: false,
      },
      
      subscribe: {
        // Start consuming from the beginning of the topic on first connection
        // This ensures no events are missed during initial deployment
        fromBeginning: true,
      }
    },
  });

  // Configure HTTP server (REST API)
  app.setGlobalPrefix('api');
  
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
  
  // Global validation pipe for automatic DTO validation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,                    // Strip properties not defined in DTO
      forbidNonWhitelisted: true,         // Throw error if unknown properties received
      transform: true,                    // Auto-transform payloads to DTO instances
    })
  );

  // Configure Swagger documentation
  const config = new DocumentBuilder()
    .setTitle('Availability Query Service')
    .setDescription('CQRS Read Model: High-performance doctor slot checking via Redis')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
    
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  // Start HTTP server first (allows health checks while Kafka connects)
  const port = configService.get<number>('PORT') || 3003;
  await app.listen(port);
  
  logger.log(`🚀 Availability Query Service running on port ${port}`);
  logger.log(`HTTP Server is running on: http://localhost:${port}/api/docs`);

  // Delay Kafka connection to allow topic initialization by init-kafka container
  // This prevents race condition where consumer connects before topics have leaders
  logger.log('⏳ Waiting 8 seconds for Kafka topics to be initialized...');
  await new Promise(resolve => setTimeout(resolve, 8000));

  // Start Kafka consumer microservice
  try {
    await app.startAllMicroservices();
    logger.log(`✅ Kafka Consumer connected successfully`);
    logger.log(`👂 Listening to consumer group: '${configService.get('KAFKA_GROUP_ID')}'`);
  } catch (error) {
    // Non-blocking error: service continues with HTTP only if Kafka fails
    logger.error(`❌ Failed to start Kafka consumer: ${error.message}`);
    logger.warn(`⚠️  Service running in HTTP-only mode. Check Kafka availability.`);
  }

   logger.log(`Auth Service is running on: http://localhost:${port}/api/v1/availability`);
  logger.log(`HTTP Server is running on: http://localhost:${port}/api/docs`);
}

bootstrap();