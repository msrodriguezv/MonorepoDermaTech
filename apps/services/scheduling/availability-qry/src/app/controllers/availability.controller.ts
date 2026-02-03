import { Controller, Get, Query, Inject, Logger, BadRequestException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse as SwaggerApiResponse } from '@nestjs/swagger';
import Redis from 'ioredis';

// Shared Libs
import { REDIS_CLIENT } from '../configs/redis.config';
import { QueryAvailabilityDto } from '../dto/query-availability.dto';
import { AvailabilityResponseDto } from '../dto/availability-response.dto';
import { ApiResponse } from '@dermatech/shared-dtos'; 

@ApiTags('Availability')
@Controller('availability')
export class AvailabilityController {
  private readonly logger = new Logger(AvailabilityController.name);

  private readonly STANDARD_SLOTS = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30'
  ];

  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis
  ) {}

  @Get()
  @ApiOperation({ summary: 'Get valid slots filtering past times and taken bookings' })
  // 👇 Aquí usamos el de Swagger (renombrado) para documentar
  @SwaggerApiResponse({ status: 200, type: AvailabilityResponseDto, description: 'Returns available slots' })
  async getAvailability(@Query() query: QueryAvailabilityDto): Promise<ApiResponse<AvailabilityResponseDto>> {
    const { doctorId, date } = query;
    
    // 1. Validaciones de Fecha
    const requestDate = new Date(date + 'T00:00:00');
    const today = new Date();
    today.setHours(0,0,0,0);

    if (requestDate < today) {
       throw new BadRequestException('Cannot check availability for past dates.');
    }

    // 2. Consultar Redis
    const redisKey = `doc:${doctorId}:date:${date}`;
    const takenSlots = await this.redis.smembers(redisKey);

    // 3. Filtrado Lógico (Standard - Taken)
    let availableSlots = this.STANDARD_SLOTS.filter(
      (slot) => !takenSlots.includes(slot)
    );

    // 4. Regla: Si es HOY, filtrar horas pasadas
    if (requestDate.getTime() === today.getTime()) {
        const now = new Date();
        const currentHour = now.getHours();
        const currentMinutes = now.getMinutes();

        availableSlots = availableSlots.filter(slot => {
            const [slotHour, slotMin] = slot.split(':').map(Number);
            if (slotHour > currentHour) return true;
            if (slotHour === currentHour && slotMin > currentMinutes) return true;
            return false;
        });
    }

    const responseData: AvailabilityResponseDto = {
      doctorId,
      date,
      totalSlots: this.STANDARD_SLOTS.length,
      takenSlotsCount: takenSlots.length,
      availableSlots,
    };

    // 👇 Retornamos envuelto en tu estándar { success: true, data: ... }
    return new ApiResponse(true, 'Availability retrieved successfully', responseData);
  }
}