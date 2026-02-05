import { Controller, Logger, Inject } from '@nestjs/common';
import {
  EventPattern,
  Payload,
  Ctx,
  KafkaContext,
} from '@nestjs/microservices';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../../configs/redis.config';
import { AppointmentCreatedPayload } from '../../dto/kafka-events.dto';

@Controller()
export class AppointmentCreatedHandler {
  private readonly logger = new Logger(AppointmentCreatedHandler.name);
  private readonly TTL_SECONDS = 604800; // 7 Días

  constructor(@Inject(REDIS_CLIENT) private readonly redis: Redis) {}

  @EventPattern('booking.appointment_created')
  async handle(
    @Payload() payload: AppointmentCreatedPayload,
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

      await this.redis.sadd(redisKey, timeSlot);
      await this.redis.expire(redisKey, this.TTL_SECONDS);

      this.logger.log(
        `✅ [Redis] Slot LOCKED: ${timeSlot} for Doctor ${doctor_id} on ${dateKey}`
      );
    } catch (error) {
      const err = error as Error;
      this.logger.error(`❌ [Kafka] Projection Failed: ${err.message}`);
    }
  }
}