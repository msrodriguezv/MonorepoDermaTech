import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';

async function bootstrap() {
  // 1. Crear la aplicación Híbrida (REST + Kafka)
  const app = await NestFactory.create(AppModule);

  // 2. Configurar el Microservicio Kafka
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.KAFKA,
    options: {
      client: {
        brokers: ['localhost:9092'], // Tu broker de Kafka
      },
      consumer: {
        groupId: 'triage-consumer-group', // Importante para que no pierda mensajes
      },
    },
  });

  // 3. Iniciar ambos
  await app.startAllMicroservices();
  
  // Puerto 3003 para no chocar con Go (3006) ni otros
  await app.listen(3003);
  console.log('🚀 Triage Engine (NestJS) corriendo en puerto 3003 y escuchando Kafka');
}
bootstrap();