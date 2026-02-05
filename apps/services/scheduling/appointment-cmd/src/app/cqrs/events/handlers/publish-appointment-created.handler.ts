import { EventsHandler, IEventHandler } from '@nestjs/cqrs';
import { Inject, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ClientKafka } from '@nestjs/microservices';
import { AppointmentCreatedEvent } from '../../events/impl/appointment-created.event';

@EventsHandler(AppointmentCreatedEvent)
export class PublishAppointmentCreatedHandler implements IEventHandler<AppointmentCreatedEvent>, OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PublishAppointmentCreatedHandler.name);

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

  async handle(event: AppointmentCreatedEvent) {
    const payload = {
      appointment_id: event.appointmentId,
      doctor_id: event.doctorId,
      student_id: event.studentId,
      start_time: event.startTime.toISOString(),
      symptoms: event.symptoms,
    };

    this.kafkaClient.emit('booking.appointment_created', payload);
    
    this.logger.log(`[Kafka] 📤 Event published to 'booking.appointment_created' for Appointment ${event.appointmentId}`);
  }
}