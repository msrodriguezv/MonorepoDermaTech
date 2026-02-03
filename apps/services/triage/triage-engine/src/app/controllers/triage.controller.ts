import { Controller, Logger } from '@nestjs/common';
import { EventPattern, Payload, Ctx, KafkaContext } from '@nestjs/microservices';
import { TriageService } from '../services/triage.service';
import { AppointmentCreatedPayload } from '../dto/triage.dto';

@Controller()
export class TriageController {
  private readonly logger = new Logger(TriageController.name);

  constructor(private readonly triageService: TriageService) {}

  @EventPattern('booking.appointment_created') // 👈 EL MISMO QUE APPOINTMENT-CMD
  async handleNewAppointment(
    @Payload() message: AppointmentCreatedPayload,
    @Ctx() context: KafkaContext
  ) {
    const topic = context.getTopic();
    this.logger.log(`📨 [Kafka] Received Event from ${topic} for Appointment ${message.appointment_id}`);

    if (!message.appointment_id || !message.symptoms) {
        this.logger.warn('⚠️ Invalid payload received. Skipping.');
        return;
    }

    await this.triageService.processAppointmentEvent(message);
  }
}