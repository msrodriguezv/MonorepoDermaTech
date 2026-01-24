import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { Logger, ValidationPipe, VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  // 1. Logger con nombre consistente
  const logger = new Logger('ExternalPartners');
  
  const app = await NestFactory.create(AppModule);
  
  // ⚠️ ESTO FALLARÁ SI NO ARREGLAS EL APP.MODULE (Ver Paso 2 abajo)
  const configService = app.get(ConfigService);

  // 2. Configuración Global
  app.enableCors(); 
  app.setGlobalPrefix('api'); // Prefijo global recomendado

  // 3. Versionamiento
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // 4. Pipes de Validación
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    })
  );

  // 5. Swagger (Documentación)
  const config = new DocumentBuilder()
    .setTitle('External Partners Service') // Título corregido
    .setDescription('Microservicio para gestión de aliados externos')
    .setVersion('1.0')
    .addTag('external-partners')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document); // 👈 Ruta explícita

  // 6. Iniciar Servidor
  const port = configService.get<number>('PORT') || 3004;
  await app.listen(port);
  
  // 7. Logs Dinámicos (Usan el puerto real)
  logger.log(`🚀 External Partners Service running on: http://localhost:${port}/api/v1/`);
  logger.log(`📑 Swagger Docs available at:         http://localhost:${port}/api/docs`);
}
bootstrap();