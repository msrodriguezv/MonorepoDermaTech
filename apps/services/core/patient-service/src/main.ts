import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger'; // <-- IMPORTANTE
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api');

  // --- CONFIGURACIÓN DE SWAGGER (ESTO ES LO QUE TE FALTA) ---
 const config = new DocumentBuilder()
    .setTitle('Patient Service')
    .setDescription('The Patient Service API')
    .setVersion('1.0')
    
    .addBearerAuth() // <--- AGREGA ESTA LÍNEA EXACTAMENTE AQUÍ
    .build();
    
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document); 


  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const port = process.env.PORT || 3002;
  await app.listen(port);
  
  // URL exacta para entrar
  logger.log(`Patient Service is running on: http://localhost:${port}/api/docs`);
}

bootstrap();