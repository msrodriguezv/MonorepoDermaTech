import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.modules';
import { Logger, ValidationPipe, VersioningType } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  const logger = new Logger('ExternalPartners');
  const app = await NestFactory.create(AppModule);

  // ---------------------------------------------------------
  // 1. CONFIGURACIÓN GLOBALES
  // ---------------------------------------------------------
  const globalPrefix = 'api/support/external-partners';
  app.setGlobalPrefix(globalPrefix);

  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // ---------------------------------------------------------
  // 2. CORS (MANDATORIO PARA TODOS LOS MICROSERVICIOS)
  // ---------------------------------------------------------
  // Define quién puede consumir este servicio (Frontend, Gateway, etc)
  app.enableCors({
    origin: true, // Permitir cualquier origen (ajustar a dominio real en Prod)
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true, // Permitir cookies/tokens de autorización
    allowedHeaders: 'Content-Type, Accept, Authorization',
  });
  logger.log('✅ CORS habilitado con credenciales y métodos estándar.');

  // ---------------------------------------------------------
  // 3. PIPES DE VALIDACIÓN (CQRS/DTOs)
  // ---------------------------------------------------------
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // ---------------------------------------------------------
  // 4. SWAGGER (DOCUMENTACIÓN)
  // ---------------------------------------------------------
  const config = new DocumentBuilder()
    .setTitle('External Partners Service')
    .setDescription('Microservicio de Derivación Médica Externa')
    .setVersion('1.0')
    .addBearerAuth() // Para documentar que usa JWT
    .build();
  
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup(`${globalPrefix}/docs`, app, document);

  // ---------------------------------------------------------
  // 5. START
  // ---------------------------------------------------------
  const port = process.env.PORT || 3000;
  await app.listen(port);
  
  logger.log(`🚀 Microservice running on: http://localhost:${port}/${globalPrefix}`);
  logger.log(`📄 Swagger UI: http://localhost:${port}/${globalPrefix}/docs`);
}
bootstrap();