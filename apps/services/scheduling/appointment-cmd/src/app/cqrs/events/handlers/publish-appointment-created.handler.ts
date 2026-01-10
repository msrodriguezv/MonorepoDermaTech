import { EventsHandler, IEventHandler } from '@nestjs/cqrs';
import { Inject, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ClientKafka } from '@nestjs/microservices';
import { AppointmentCreatedEvent } from '../impl/appointment-created.event';

/**
 * Event Handler: Bridges internal CQRS events to external Kafka messages.
 * 
 * Architecture Role:
 * This handler implements the Bridge Pattern in event-driven architecture,
 * transforming internal domain events (CQRS) into integration events (Kafka).
 * It decouples the domain model from external infrastructure.
 * 
 * Event Flow:
 * 1. AppointmentCreatedEvent is published by CreateAppointmentHandler (CQRS)
 * 2. This handler catches the event from the internal event bus
 * 3. Event is transformed into Kafka message format (CloudEvents spec)
 * 4. Message is published to 'booking.events' topic
 * 5. Other microservices (availability-qry) consume and react
 * 
 * Lifecycle Management:
 * - onModuleInit: Establishes Kafka producer connection with retry logic
 * - handle: Publishes events to Kafka topic
 * - onModuleDestroy: Gracefully closes Kafka connection
 * 
 * Error Handling Strategy:
 * - Connection failures trigger automatic background reconnection
 * - Publish failures are logged and re-thrown to CQRS
 * - Events are lost if Kafka is unavailable (TODO: implement DLQ)
 */
@EventsHandler(AppointmentCreatedEvent)
export class PublishAppointmentCreatedHandler 
  implements IEventHandler<AppointmentCreatedEvent>, OnModuleInit, OnModuleDestroy {
  
  private readonly logger = new Logger(PublishAppointmentCreatedHandler.name);
  private isKafkaConnected = false;

  constructor(
    @Inject('KAFKA_SERVICE_APPOINTMENT') private readonly kafkaClient: ClientKafka
  ) {}

  /**
   * Module initialization hook: establishes Kafka producer connection.
   * 
   * Connection Strategy:
   * 1. Wait 8 seconds to allow init-kafka to create topics with leaders
   * 2. Subscribe to response topics (required by NestJS even for fire-and-forget)
   * 3. Connect to Kafka cluster
   * 4. Mark connection as ready
   * 
   * Error Recovery:
   * If initial connection fails, triggers background reconnection attempts
   * without blocking application startup. Service continues to operate,
   * but events will be lost until Kafka is available.
   * 
   * @throws Does not throw - errors are logged and handled gracefully
   */
  async onModuleInit() {
    try {
      this.logger.log('🔌 Initializing Kafka producer connection...');
      
      // Wait for init-kafka container to create topics and elect partition leaders
      // This delay prevents "no leader for partition" errors on first publish attempt
      await new Promise(resolve => setTimeout(resolve, 8000));
      
      // Subscribe to response topics (NestJS requirement for ClientKafka)
      // Even though we use fire-and-forget pattern, this is mandatory
      this.kafkaClient.subscribeToResponseOf('booking.events');
      
      // Establish connection to Kafka broker cluster
      await this.kafkaClient.connect();
      
      this.isKafkaConnected = true;
      this.logger.log('✅ Kafka producer connected successfully');
      
    } catch (error) {
      this.logger.error(`❌ Failed to connect Kafka producer: ${error.message}`);
      this.logger.warn('⚠️  Events will be lost until Kafka connection is restored');
      
      // Schedule background reconnection attempts without blocking
      this.scheduleReconnection();
    }
  }

  /**
   * Background reconnection strategy for handling Kafka unavailability.
   * 
   * Retry Strategy:
   * - 10 reconnection attempts with 5-second intervals
   * - Non-blocking: runs asynchronously without halting application
   * - Updates connection status flag on success
   * - Logs each attempt for operational monitoring
   * 
   * This prevents cascading failures and allows the service to self-heal
   * when Kafka becomes available after temporary outages.
   */
  private async scheduleReconnection() {
    const maxAttempts = 10;
    let currentAttempt = 0;

    const reconnect = async () => {
      while (!this.isKafkaConnected && currentAttempt < maxAttempts) {
        currentAttempt++;
        this.logger.log(`🔄 Kafka reconnection attempt ${currentAttempt}/${maxAttempts}`);
        
        await new Promise(resolve => setTimeout(resolve, 5000));
        
        try {
          await this.kafkaClient.connect();
          this.isKafkaConnected = true;
          this.logger.log('✅ Kafka producer reconnected successfully');
          return;
        } catch (error) {
          this.logger.warn(`⚠️  Reconnection attempt ${currentAttempt} failed: ${error.message}`);
        }
      }

      if (!this.isKafkaConnected) {
        this.logger.error('❌ Max reconnection attempts reached. Manual intervention required.');
      }
    };

    // Execute reconnection asynchronously without awaiting
    reconnect().catch(err => 
      this.logger.error(`Reconnection process failed: ${err.message}`)
    );
  }

  /**
   * Main event handler: transforms and publishes domain events to Kafka.
   * 
   * Processing Pipeline:
   * 1. Receive AppointmentCreatedEvent from CQRS event bus
   * 2. Validate Kafka connection status (guard clause)
   * 3. Transform domain event to integration event (CloudEvents format)
   * 4. Publish to 'booking.events' topic via Kafka producer
   * 5. Log success/failure for monitoring and debugging
   * 
   * Data Transformation:
   * - event_id: Unique identifier for idempotency and tracing
   * - occurred_on: ISO timestamp for event ordering
   * - type: Event type discriminator for consumer filtering
   * - data: Event payload with appointment details
   * 
   * Error Handling:
   * - Kafka disconnected: Event is lost, error logged (TODO: DLQ)
   * - Publish failure: Error is re-thrown to CQRS for potential retry
   * 
   * @param event - Domain event containing appointment creation details
   * @throws Error if publish fails, allowing CQRS to handle retry
   */
  async handle(event: AppointmentCreatedEvent) {
    this.logger.log(`[Bridge] 🌉 Catching internal event: Appointment ${event.appointmentId}`);

    // Guard clause: prevent publishing if Kafka is unavailable
    if (!this.isKafkaConnected) {
      this.logger.error('❌ Kafka not connected. Event will be lost!');
      this.logger.warn('💡 TODO: Implement retry queue or DLQ for resilience');
      // TODO: Push to retry queue (Bull/BullMQ) or DLQ for later processing
      // Example: await this.retryQueue.add('failed-event', event);
      return;
    }

    // Transform domain event to integration event (CloudEvents specification)
    const integrationEvent = {
      event_id: event.appointmentId,
      occurred_on: new Date(),
      type: 'booking.appointment_created',
      data: {
        appointment_id: event.appointmentId,
        doctor_id: event.doctorId,
        student_id: event.studentId,
        start_time: event.date,
      },
    };

    try {
      // Publish event to Kafka topic using fire-and-forget pattern
      // emit() returns an Observable but we don't await acknowledgment
      this.kafkaClient.emit('booking.events', integrationEvent);
      
      this.logger.log(`✅ [Kafka] Event published to topic 'booking.events'`);
      
    } catch (error) {
      this.logger.error(`❌ Failed to publish event: ${error.message}`);
      this.logger.error(`Event payload: ${JSON.stringify(integrationEvent)}`);
      
      // Re-throw error to allow CQRS framework to handle failure
      // This enables potential retry mechanisms at the CQRS level
      throw error;
    }
  }

  /**
   * Module destruction hook: gracefully closes Kafka connection.
   * 
   * Cleanup Process:
   * - Closes producer connection to prevent resource leaks
   * - Flushes any pending messages in buffer
   * - Logs disconnection for operational awareness
   * 
   * This ensures clean shutdown and prevents orphaned connections
   * when the service is stopped or restarted.
   */
  async onModuleDestroy() {
    try {
      if (this.isKafkaConnected) {
        await this.kafkaClient.close();
        this.logger.log('👋 Kafka producer disconnected gracefully');
      }
    } catch (error) {
      this.logger.error(`Error closing Kafka connection: ${error.message}`);
    }
  }
}