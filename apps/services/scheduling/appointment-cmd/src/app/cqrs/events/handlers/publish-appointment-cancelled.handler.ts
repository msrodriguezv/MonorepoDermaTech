import { EventsHandler, IEventHandler } from '@nestjs/cqrs';
import { Inject, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ClientKafka } from '@nestjs/microservices';
import { AppointmentCancelledEvent } from '../../events/impl/appointment-cancelled.event';

@EventsHandler(AppointmentCancelledEvent)
export class PublishAppointmentCancelledHandler implements IEventHandler<AppointmentCancelledEvent>, OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PublishAppointmentCancelledHandler.name);

  constructor(
    @Inject('KAFKA_SERVICE_APPOINTMENT') private readonly kafkaClient: ClientKafka,
  ) {}

  async onModuleInit() {
    try {
      await this.kafkaClient.connect();
      this.logger.log('✅ Kafka producer connected successfully');
    } catch (error) {
      this.logger.error(`❌ Failed to connect Kafka producer: ${error instanceof Error ? error.message : error}`);
    }
  }

  async onModuleDestroy() {
    await this.kafkaClient.close();
  }

  async handle(event: AppointmentCancelledEvent) {
    const payload = {
      appointment_id: event.appointmentId,
      doctor_id: event.doctorId,
      start_time: event.startTime.toISOString(),
    };

    this.kafkaClient.emit('booking.appointment_cancelled', payload);
    
    this.logger.log(`[Kafka] 📤 Event published to 'booking.appointment_cancelled' for Appointment ${event.appointmentId}`);
  }
}