import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';

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

  // 3. Iniciar servicios
  await app.startAllMicroservices(); // Arranca Kafka
  
  const globalPrefix = 'api';
  app.setGlobalPrefix(globalPrefix);
  const port = process.env.PORT || 3000;
  await app.listen(port); // Arranca HTTP

  Logger.log(
    `🚀 Triage Engine corriendo en: http://localhost:${port}/${globalPrefix}`
  );
  Logger.log(`👂 Escuchando eventos de Kafka...`);
}

bootstrap();