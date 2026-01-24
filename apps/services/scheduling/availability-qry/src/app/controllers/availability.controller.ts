import { Controller, Get, Query, Inject, Logger, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import Redis from 'ioredis';

// Shared Libs
import { JwtAuthGuard } from '@dermatech/shared-guards';

// Local Components
import { QueryAvailabilityDto } from '../dto/query-availability.dto';
import { REDIS_CLIENT } from '../configs/redis.config';

@ApiTags('Availability')
@ApiBearerAuth() // Indicates JWT is required in Swagger
@UseGuards(JwtAuthGuard) // Protects the endpoint
@Controller()
export class AvailabilityController {
  private readonly logger = new Logger(AvailabilityController.name);

  // Hardcoded Logic for MVP: Working hours 09:00 - 17:00 (30 min slots)
  // In a real system, this would come from a "DoctorSchedule" table in Postgres.
  private readonly STANDARD_SLOTS = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30'
  ];

  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis
  ) {}

  @Get()
  @ApiOperation({ summary: 'Check doctor availability for a specific date' })
  @ApiResponse({ 
    status: 200, 
    description: 'Returns the list of available time slots.',
    schema: {
      example: {
        doctorId: "uuid...",
        date: "2025-01-20",
        totalSlots: 14,
        availableSlots: ["09:00", "10:30", "11:00"]
      }
    }
  })
  async getAvailability(@Query() query: QueryAvailabilityDto) {
    const { doctorId, date } = query;
    const dateStr = date.split('T')[0]; // Ensure strictly YYYY-MM-DD

    // 1. Construct the same Redis Key used by the Consumer
    const redisKey = `doc:${doctorId}:date:${dateStr}`;

    this.logger.log(`🔍 Querying availability for: ${redisKey}`);

    // 2. Fetch "Taken" slots from Redis
    // SMEMBERS returns an array of strings: ["10:00", "14:30"]
    const takenSlots = await this.redis.smembers(redisKey);

    // 3. Calculate Available Slots
    // Logic: Available = Standard - Taken
    const availableSlots = this.STANDARD_SLOTS.filter(
      (slot) => !takenSlots.includes(slot)
    );

    return {
      doctorId,
      date: dateStr,
      totalSlots: this.STANDARD_SLOTS.length,
      takenSlotsCount: takenSlots.length,
      availableSlots, // <--- This is what the Frontend needs to render the grid
    };
  }
}