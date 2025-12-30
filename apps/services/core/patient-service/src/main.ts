import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  console.log('REVISIÓN DE HOST:', `"${process.env.DB_HOST}"`);
 console.log('PUERTO QUE LEO:', `"${process.env.DB_PORT}"`);
  const app = await NestFactory.create(AppModule);



  // Configuración de Swagger
  const config = new DocumentBuilder()
    .setTitle('Patient Service API')
    .setDescription('Microservicio de Pacientes')
    .setVersion('1.0')
    .addTag('Patients')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  
  // Swagger estará disponible en: /docs
  SwaggerModule.setup('docs', app, document);

  app.enableCors();

  const port = process.env.PORT || 3001;
  await app.listen(port);

  Logger.log(
    `🚀 Application is running on: http://localhost:${port}`
  );
  Logger.log(
    `📄 Swagger is running on: http://localhost:${port}/docs`
  );
}

bootstrap();