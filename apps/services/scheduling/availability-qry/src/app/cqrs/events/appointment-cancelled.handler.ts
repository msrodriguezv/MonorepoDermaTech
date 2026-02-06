import { Controller, Logger, Inject } from '@nestjs/common';
import { EventPattern, Payload, Ctx, KafkaContext } from '@nestjs/microservices';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../../configs/redis.config';

interface AppointmentCancelledPayload {
  appointment_id: string;
  doctor_id: string;
  start_time: string;
}

@Controller()
export class AppointmentCancelledHandler {
  private readonly logger = new Logger(AppointmentCancelledHandler.name);

  constructor(@Inject(REDIS_CLIENT) private readonly redis: Redis) {}

  @EventPattern('booking.appointment_cancelled')
  async handle(
    @Payload() payload: AppointmentCancelledPayload,
    @Ctx() context: KafkaContext
  ) {
    const topic = context.getTopic();
    this.logger.log(`📨 [Kafka] Event received on topic: ${topic}`);

    if (!payload || !payload.doctor_id || !payload.start_time) {
      return;
    }

    const { doctor_id, start_time } = payload;

    try {
      const dateObj = new Date(start_time);

      const year = dateObj.getUTCFullYear();
      const month = String(dateObj.getUTCMonth() + 1).padStart(2, '0');
      const day = String(dateObj.getUTCDate()).padStart(2, '0');
      
      const hour = String(dateObj.getUTCHours()).padStart(2, '0');
      const minute = String(dateObj.getUTCMinutes()).padStart(2, '0');

      const dateKey = `${year}-${month}-${day}`;
      const timeSlot = `${hour}:${minute}`;

      const redisKey = `doc:${doctor_id}:date:${dateKey}`;

      await this.redis.srem(redisKey, timeSlot);

      this.logger.log(`🔓 [Redis] Slot FREED: ${timeSlot} for Doctor ${doctor_id} on ${dateKey}`);

    } catch (error) {
      const err = error as Error;
      this.logger.error(`❌ [Kafka] Cancellation Projection Failed: ${err.message}`);
    }
  }
}