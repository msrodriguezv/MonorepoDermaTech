import { Controller, Logger, Inject } from '@nestjs/common';
import { EventPattern, Payload, Ctx, KafkaContext } from '@nestjs/microservices';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../../configs/redis.config';
import { AppointmentCreatedPayload, KafkaMessage } from '../../dto/kafka-events.dto';

/**
 * Kafka Event Consumer: Handles appointment creation events for availability updates.
 * 
 * Architecture Role:
 * This handler implements the Projection Engine pattern in CQRS architecture.
 * It listens to events from the Write Model (appointment-cmd) and updates the
 * Read Model (Redis) asynchronously, maintaining eventual consistency.
 * 
 * Event-Driven Flow:
 * 1. appointment-cmd creates appointment in PostgreSQL (Write Model)
 * 2. appointment-cmd publishes AppointmentCreatedEvent to Kafka
 * 3. This handler consumes event from 'booking.events' topic
 * 4. Handler updates Redis with booked time slot (Read Model)
 * 5. availability-qry can now query updated availability in real-time
 * 
 * Benefits of this approach:
 * - Decoupled services: appointment-cmd and availability-qry are independent
 * - Optimized reads: Redis provides sub-millisecond query performance
 * - Scalability: Read model can be replicated/cached independently
 * - Resilience: Temporary failures don't block appointment creation
 * 
 * Idempotency:
 * Redis SADD operation is naturally idempotent - adding the same time slot
 * multiple times has no effect. This gracefully handles duplicate Kafka messages
 * caused by retries or exactly-once delivery failures.
 */
@Controller()
export class AppointmentCreatedHandler {
  private readonly logger = new Logger(AppointmentCreatedHandler.name);

  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis
  ) {}

  /**
   * Kafka event consumer: processes messages from 'booking.events' topic.
   * 
   * Message Processing Pipeline:
   * 1. Receive message from Kafka consumer group
   * 2. Validate message structure (defensive programming)
   * 3. Filter by event type (handler-specific logic)
   * 4. Parse and validate timestamp data
   * 5. Extract date and time components
   * 6. Update Redis read model with booked slot
   * 7. Set TTL for automatic data cleanup
   * 
   * Error Handling Strategy:
   * - Malformed messages: Logged and dropped (prevents consumer crash)
   * - Invalid dates: Exception thrown, logged with stack trace
   * - Redis errors: Logged with full context for debugging
   * - Future enhancement: Push failed events to DLQ for manual review
   * 
   * Kafka Context:
   * The context provides metadata about the consumed message:
   * - Topic: Source topic name
   * - Partition: Which partition the message came from
   * - Offset: Position in the partition (for exactly-once processing)
   * 
   * @param message - Typed Kafka message containing appointment details
   * @param context - Kafka context with partition and offset metadata
   */
  @EventPattern('booking.events')
  async handleAppointmentCreated(
    @Payload() message: KafkaMessage<AppointmentCreatedPayload>,
    @Ctx() context: KafkaContext
  ) {
    const topic = context.getTopic();
    const partition = context.getPartition();
    
    this.logger.log(`[Kafka Consumer] 📨 Processing message from topic: ${topic} (Partition: ${partition})`);

    // Defensive programming: validate message structure before processing
    // Prevents runtime crashes from malformed messages due to:
    // - Serialization errors in producer
    // - Schema evolution mismatches
    // - Network corruption (rare but possible)
    if (!message || !message.data) {
      this.logger.error('[Kafka Consumer] ❌ Malformed message received. Dropping event.');
      return;
    }

    // Event type filtering: ensures handler only processes relevant events
    // This allows multiple event types to coexist in the same Kafka topic
    // (event streaming pattern vs. separate topics per event type)
    if (message.type !== 'booking.appointment_created') {
      this.logger.debug(`[Kafka Consumer] ℹ️ Skipping unrelated event type: ${message.type}`);
      return;
    }

    const { doctor_id, start_time } = message.data;

    try {
      // Data transformation: parse ISO 8601 timestamp
      // Expected format: "2026-01-10T14:30:00.000Z"
      // This standard format ensures consistent date handling across services
      const dateObj = new Date(start_time);
      
      // Validation: ensure date string parsed into valid Date object
      // Invalid dates produce NaN when calling getTime()
      // Common invalid inputs: malformed strings, out-of-range values
      if (isNaN(dateObj.getTime())) {
        throw new Error(`Invalid ISO date format received: ${start_time}`);
      }

      // Extract date component in YYYY-MM-DD format for Redis key construction
      // Example: "2026-01-10T14:30:00.000Z" -> "2026-01-10"
      const dateKey = dateObj.toISOString().split('T')[0];
      
      // Extract time component in HH:MM format for Redis set member
      // Example: "2026-01-10T14:30:00.000Z" -> "14:30"
      const timeSlot = dateObj.toISOString().split('T')[1].substring(0, 5);

      // Redis key schema: doc:{uuid}:date:{YYYY-MM-DD}
      // Design rationale:
      // - Hierarchical namespace prevents key collisions
      // - Date-based partitioning enables efficient range queries
      // - Consistent schema across availability-qry service
      // - Matches read model schema in AvailabilityController
      const redisKey = `doc:${doctor_id}:date:${dateKey}`;

      this.logger.log(`[Redis Write] 💾 Locking slot ${timeSlot} for resource: ${redisKey}`);

      // Atomic operation: SADD adds member to Redis set
      // Properties:
      // - Atomic: No race conditions with concurrent writes
      // - Idempotent: Adding same slot multiple times is a no-op
      // - O(1) time complexity: Constant-time operation
      // - Set ensures uniqueness: No duplicate time slots possible
      await this.redis.sadd(redisKey, timeSlot);
      
      // TTL management: expire key after 48 hours (172800 seconds)
      // Design rationale:
      // - Prevents unbounded memory growth from historical data
      // - 48 hours covers typical appointment booking windows
      // - Expired data is automatically removed by Redis
      // - Historical records remain in PostgreSQL (source of truth)
      // - Balance between performance and memory efficiency
      await this.redis.expire(redisKey, 172800);

      this.logger.log(`[Redis Write] ✅ Successfully updated availability for ${redisKey}`);

    } catch (error) {
      // Type-safe error handling: cast to Error for safe property access
      const err = error as Error;
      this.logger.error(
        `[Kafka Consumer] ❌ Failed to process event: ${err.message}`,
        err.stack
      );
      
      // Future enhancement: Dead Letter Queue (DLQ) implementation
      // Benefits:
      // - Failed events can be reviewed and replayed manually
      // - Prevents silent data loss from transient errors
      // - Enables retry with exponential backoff
      // - Provides audit trail for debugging
      // 
      // Implementation options:
      // - Separate Kafka topic for failed events
      // - Redis list for failed event queue
      // - External service like AWS SQS/SNS
      // 
      // Example:
      // await this.dlqService.push({
      //   originalMessage: message,
      //   error: err.message,
      //   timestamp: new Date(),
      //   retryCount: 0
      // });
    }
  }
}