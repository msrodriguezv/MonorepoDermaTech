// -----------------------------------------------------------------------------
// POLYFILL: Crypto Compatibility
// -----------------------------------------------------------------------------
import * as crypto from 'crypto';
if (!global.crypto) {
  // @ts-expect-error: Compatibility fix for Node 18/20
  global.crypto = crypto;
}

import { NestFactory } from '@nestjs/core';
import { Logger, ValidationPipe } from '@nestjs/common'; // Eliminado VersioningType
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('AuthService');

  // 1. Validation of Critical Variables
  const requiredEnvs = [
    'JWT_SECRET',
    'DATABASE_HOST',
    'DATABASE_USER',
    'DATABASE_PASSWORD',
    'DATABASE_NAME',
    'KAFKA_BROKERS'
  ];
  const missingEnvs = requiredEnvs.filter(key => !process.env[key]);
  if (missingEnvs.length > 0) {
    logger.error(`❌ CRITICAL: Missing envs: ${missingEnvs.join(', ')}`);
    process.exit(1);
  }

  const app = await NestFactory.create(AppModule);

  // ===========================================================================
  // ⚠️ ROUTING STRATEGY (CRITICAL FOR GATEWAY)
  // ===========================================================================
  // We REMOVE 'app.setGlobalPrefix' and 'app.enableVersioning'.
  // Why? The API Gateway handles the Public Surface (/api/v1/...).
  // It strips the prefix and forwards requests to this service.
  // 
  // Incoming from Gateway: http://auth-service:3000/auth/login
  // Controller Route:      @Controller('auth') + @Post('login')
  // Result:                MATCH ✅
  // ===========================================================================

  // 2. Global Validation
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));

  // ===========================================================================
  // 🛡️ SECURITY: PROD CORS CONFIGURATION
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
    origin: (origin, callback) => {
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

  // 3. Swagger (Internal)
  const config = new DocumentBuilder()
    .setTitle('DermaTech Auth Service')
    .setDescription('Internal Microservice for Authentication')
    .setVersion('1.0')
    .addTag('auth')
    .addBearerAuth()
    .build();
  
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document); // Docs at /docs

  const port = process.env.PORT || 3000;
  await app.listen(port);
  
  logger.log(`🚀 Auth Service (Internal) running on port ${port}`);
  logger.log(`📝 Swagger available at: http://localhost:${port}/docs`);
}
bootstrap();