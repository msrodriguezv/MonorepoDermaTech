import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

async function bootstrap() {
  // 1. Crear la aplicación híbrida (HTTP + Microservicio)
  const app = await NestFactory.create(AppModule);

  // 2. Configurar la conexión a Kafka
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.KAFKA,
    options: {
      client: {
        brokers: ['localhost:9092'], // Tu Kafka local
      },
      consumer: {
        groupId: 'triage-consumer-group', // Identificador del grupo
      },
    },
  });

  // 3. Configuración de Swagger corregida
  const config = new DocumentBuilder()
    .setTitle('DermaTech Triage API')
    .setDescription('Sistema de Triaje Dermatológico con Inteligencia Artificial')
    .setVersion('1.0')
    .addTag('triage')
    .addServer('/api') // 👈 ESTO ARREGLA EL ERROR 404 EN SWAGGER
    .build();
  
  const document = SwaggerModule.createDocument(app, config);
  
  // Mantenemos la documentación en /api/docs
  SwaggerModule.setup('api/docs', app, document); 

  // 4. Iniciar servicios
  await app.startAllMicroservices(); // Arranca Kafka
  
  const globalPrefix = 'api';
  app.setGlobalPrefix(globalPrefix);
  
  // Usamos el puerto que ya tienes configurado (según tu imagen es el 3007)
  const port = process.env.PORT || 3007; 
  await app.listen(port); 

  Logger.log(
    `🚀 Triage Engine HTTP corriendo en: http://localhost:${port}/${globalPrefix}`
  );
  Logger.log(
    `📖 Documentación Swagger disponible en: http://localhost:${port}/${globalPrefix}/docs`
  );
  Logger.log(`👂 Escuchando eventos de Kafka...`);
}

bootstrap();