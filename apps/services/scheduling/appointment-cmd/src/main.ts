import * as crypto from 'crypto';

if (!global.crypto) {
  // @ts-expect-error: Polyfill for Node 18+ compatibility
  global.crypto = crypto;
}

import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app/app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('Appointment-cmd');
  const configService = app.get(ConfigService);
  const globalPrefix = 'api/v1';
  const port = configService.get<number>('PORT') || 3002;

  app.setGlobalPrefix(globalPrefix);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    })
  );

  const config = new DocumentBuilder()
    .setTitle('Appointment Command Service')
    .setDescription('Microservice responsible for Scheduling and Doctor Management')
    .setVersion('1.0')
    .addTag('Appointments (Student)', 'Book medical consultations')
    .addTag('Appointments & Clinical Workflow', 'Clinical operations')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);

  Object.values(document.paths).forEach((pathItem) => {
    Object.values(pathItem).forEach((content) => {
      if (
        typeof content === 'object' &&
        content !== null &&
        'tags' in content
      ) {
        const operation = content as { tags?: string[] };
        const studentTag = 'Appointments (Student)';
        
        if (operation.tags?.includes(studentTag)) {
          operation.tags = [studentTag];
        }
      }
    });
  });

  SwaggerModule.setup('api/docs', app, document);

  app.enableShutdownHooks();

  await app.listen(port);

  logger.log(`🚀 Service running on: http://localhost:${port}/${globalPrefix}`);
  logger.log(`📑 Swagger available at: http://localhost:${port}/api/docs`);
}

bootstrap();