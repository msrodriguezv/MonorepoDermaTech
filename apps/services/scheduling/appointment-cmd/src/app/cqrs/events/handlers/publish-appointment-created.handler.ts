import { EventsHandler, IEventHandler } from '@nestjs/cqrs';
import { Inject, Logger } from '@nestjs/common';
import { ClientKafka } from '@nestjs/microservices';
import { AppointmentCreatedEvent } from '../impl/appointment-created.event'; // Import relativo correcto

@EventsHandler(AppointmentCreatedEvent)
export class PublishAppointmentCreatedHandler implements IEventHandler<AppointmentCreatedEvent> {
  private readonly logger = new Logger(PublishAppointmentCreatedHandler.name);

  constructor(
    @Inject('KAFKA_SERVICE') private readonly kafkaClient: ClientKafka
  ) {}

  async handle(event: AppointmentCreatedEvent) {
    this.logger.log(`[Bridge] 🌉 Catching internal event: Appointment ${event.appointmentId}`);

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

    this.kafkaClient.emit('booking.events', integrationEvent);
    
    this.logger.log(`[Kafka] 🚀 Published to topic 'booking.events'`);
  }
}