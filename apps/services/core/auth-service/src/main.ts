// -----------------------------------------------------------------------------
// POLYFILL: Crypto Compatibility
// -----------------------------------------------------------------------------
import * as crypto from 'crypto';
if (!global.crypto) {
  // @ts-expect-error: Compatibility fix for Node 18/20
  global.crypto = crypto;
}

import { NestFactory } from '@nestjs/core';
import { Logger, ValidationPipe } from '@nestjs/common';
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

  const app = await NestFactory.create(AppModule, {
    logger: ['log', 'error', 'warn', 'debug', 'verbose'], 
  })

  // 2. Global Validation
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));

  app.enableCors({
    origin: true, // Aceptar todas las conexiones (especialmente la del Gateway)
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