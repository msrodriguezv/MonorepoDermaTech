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
import { Logger, ValidationPipe, VersioningType } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('AuthService');

  const requiredEnvs = [
    'JWT_SECRET',
    'DATABASE_HOST',
    'DATABASE_PORT',
    'DATABASE_USER',
    'DATABASE_PASSWORD',
    'DATABASE_NAME',
    'KAFKA_BROKERS',
    'KAFKA_CLIENT_ID',
    'KAFKA_GROUP_ID'
  ];

  const missingEnvs = requiredEnvs.filter(key => !process.env[key]);

  if (missingEnvs.length > 0) {
    logger.error(`Missing required environment variables: ${missingEnvs.join(', ')}`);
    process.exit(1); // kill process with error code
  }

  const app = await NestFactory.create(AppModule);
  
  // 1. Set Global Prefix
  app.setGlobalPrefix('api');

  // 2. Enable URI Versioning
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // Global Validation Pipe
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));

  // CORS Configuration
  app.enableCors({
    origin: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  // Swagger Documentation
  const config = new DocumentBuilder()
    .setTitle('DermaTech Auth Service')
    .setDescription('Microservice responsible for Authentication.')
    .setVersion('1.0')
    .addTag('auth')
    .addBearerAuth()
    .build();
  
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  
  logger.log(`Auth Service is running on: http://localhost:${port}/api/v1/auth`);
  logger.log(`Swagger Docs available at: http://localhost:${port}/api/docs`);
}
bootstrap();