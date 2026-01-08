import { NestFactory } from '@nestjs/core';
import { Logger, ValidationPipe } from '@nestjs/common';
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
  app.setGlobalPrefix('api');
  const corsOrigin = process.env.CORS_ORIGIN || 'http://localhost:4200';

  // Log the allowed origins to debug connection issues easily
  logger.log(`CORS enabled for origin(s): ${corsOrigin}`);

  // Global Validation Pipe (DTO Validation)
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));

  // CORS Configuration
  app.enableCors({
    origin: corsOrigin.split(',').map(origin => origin.trim()), // In production, replace with specific domain
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  // Good Documentation (Swagger/OpenAPI)
  const config = new DocumentBuilder()
    .setTitle('DermaTech Auth Service')
    .setDescription('Microservice responsible for Authentication, Authorization and Identity Management.')
    .setVersion('1.0')
    .addTag('auth')
    .addBearerAuth()
    .build();
  
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  logger.log(`Auth Service is running on: http://localhost:${port}`);
  logger.log(`Swagger Docs available at: http://localhost:${port}/api/docs`);
}
bootstrap();