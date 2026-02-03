import * as crypto from 'crypto';

if (!global.crypto) {
  // @ts-expect-error: Polyfill for Node 18+ compatibility
  global.crypto = crypto;
}
import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';

async function bootstrap() {
  const logger = new Logger('Triage-Engine');
  const app = await NestFactory.create(AppModule);

  // 1. Kafka Consumer Config
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.KAFKA,
    options: {
      client: {
        brokers: (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
        clientId: 'triage-engine',
      },
      consumer: {
        groupId: 'triage-orchestrator-group', // 👈 Nombre único para este servicio
      },
    },
  });

  await app.startAllMicroservices();
  
  const port = process.env.PORT || 3007;
  await app.listen(port);
  
  logger.log(`🚀 Triage Engine Orchestrator running on port ${port}`);
}

bootstrap();