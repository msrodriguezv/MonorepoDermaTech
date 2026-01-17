process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const logger = new Logger('TriageEngine');
  
  // 1. Crear la App
  const app = await NestFactory.create(AppModule);

  // 2. Conectar el Microservicio (Consumer Kafka)
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.KAFKA,
    options: {
      client: {
        brokers: [process.env.KAFKA_BROKERS || 'localhost:9092'],
      },
      consumer: {
        groupId: process.env.KAFKA_GROUP_ID || 'triage-engine-group',
      },
    },
  });

  // 3. Iniciar todo
  await app.startAllMicroservices();
  await app.listen(3003);
  
  logger.log('🚀 Triage Engine (NestJS) escuchando eventos de Kafka...');
}

bootstrap();