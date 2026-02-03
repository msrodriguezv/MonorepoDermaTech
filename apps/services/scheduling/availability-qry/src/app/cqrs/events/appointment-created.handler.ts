import { Controller, Logger, Inject } from '@nestjs/common';
import { EventPattern, Payload, Ctx, KafkaContext } from '@nestjs/microservices';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../../configs/redis.config';
import { AppointmentCreatedPayload } from '../../dto/kafka-events.dto';

/**
 * Kafka Consumer: Projects Appointment Data into Redis Availability.
 * Pattern: CQRS Projection (Write Model -> Read Model).
 */
@Controller()
export class AppointmentCreatedHandler {
  private readonly logger = new Logger(AppointmentCreatedHandler.name);
  private readonly TTL_SECONDS = 604800; // 7 Days retention

  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis
  ) {}

  @EventPattern('booking.appointment_created')
  async handle(
    @Payload() payload: AppointmentCreatedPayload,
    @Ctx() context: KafkaContext
  ) {
    const topic = context.getTopic();
    this.logger.log(`📨 [Kafka] Event received on topic: ${topic}`);

    // 1. Defensive Programming: Basic validation
    if (!payload || !payload.doctor_id || !payload.start_time) {
      this.logger.error('❌ [Kafka] Invalid Payload: Missing doctor_id or start_time. Dropping event.');
      return;
    }

    const { doctor_id, start_time } = payload;

    try {
      // 2. Date Parsing & Validation
      const dateObj = new Date(start_time);

      if (isNaN(dateObj.getTime())) {
        throw new Error(`Invalid ISO date format: ${start_time}`);
      }

      // 3. Key Construction
      // Extract YYYY-MM-DD for the Redis Key
      const dateKey = dateObj.toISOString().split('T')[0];
      
      // Extract HH:MM for the Set Member
      const timeSlot = dateObj.toISOString().split('T')[1].substring(0, 5);

      // Key Schema: doc:{uuid}:date:{YYYY-MM-DD}
      const redisKey = `doc:${doctor_id}:date:${dateKey}`;

      // 4. Update Read Model (Atomic & Idempotent)
      // SADD adds the timeSlot to the set of taken slots.
      // If the slot is already there, Redis ignores it (Idempotency).
      await this.redis.sadd(redisKey, timeSlot);

      // 5. Manage Lifecycle (TTL)
      // Reset expiration to ensure the key lives long enough but doesn't leak memory forever.
      await this.redis.expire(redisKey, this.TTL_SECONDS);

      this.logger.log(`✅ [Redis] Slot ${timeSlot} locked for Doctor ${doctor_id} on ${dateKey}`);

    } catch (error) {
      const err = error as Error;
      this.logger.error(`❌ [Kafka] Error processing projection: ${err.message}`, err.stack);
      // NOTE: In a production environment, you would push this payload to a Dead Letter Queue (DLQ) here.
    }
  }
}