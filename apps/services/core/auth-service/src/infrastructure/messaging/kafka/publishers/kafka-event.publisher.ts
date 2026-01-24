import { Inject, Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { ClientKafka } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { EventPublisherPort } from '../../../../application/ports/event.publisher.port';
@Injectable()
export class KafkaEventPublisher implements EventPublisherPort, OnModuleInit {
  private readonly logger = new Logger(KafkaEventPublisher.name);

  constructor(
    @Inject('AUTH_KAFKA_CLIENT') private readonly kafkaClient: ClientKafka,
  ) {}

  /**
   * Establishes the connection to the Kafka broker on module initialization.
   */
  async onModuleInit(): Promise<void> {
    try {
      this.logger.log('Connecting to Kafka...');
      await this.kafkaClient.connect();
      this.logger.log('Successfully connected to Kafka.');
    } catch (error) {
      this.logger.error('Failed to connect to Kafka', error);
    }
  }

  /**
   * Publishes an event to the specified Kafka topic.
   * Uses Generics <T> to ensure type safety without using 'any'.
   */
  async publish<T>(topic: string, event: T): Promise<void> {
    this.logger.debug(`Publishing event to topic: ${topic}`);

    try {
      // 'emit' returns an Observable. We use 'lastValueFrom' to convert it to a Promise
      // so we can properly 'await' the operation and catch potential errors.
      await lastValueFrom(this.kafkaClient.emit(topic, event));
      
      this.logger.log(`Event published successfully to ${topic}`);
    } catch (error) {
      this.logger.error(`Error publishing to topic ${topic}`, error);
      // Opcional: Relanzar el error si quieres que el Handler superior lo maneje
      throw error;
    }
  }
}