import { Controller, Post, Body, UseGuards, HttpStatus, Logger } from '@nestjs/common';
import { CommandBus } from '@nestjs/cqrs';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';

// SHARED LIBS IMPORTS (Security & Contracts)
import { JwtAuthGuard, RolesGuard, Roles } from '@dermatech/shared-guards';
import { UserRole } from '@dermatech/shared-dtos';

// LOCAL IMPORTS
import { CreateDoctorDto } from '../dto/create-doctor.dto';
import { CreateDoctorCommand } from '../cqrs/commands/impl/create-doctor.command';
import { Doctor } from '../entities/doctor.entity';

/**
 * Controller for managing Doctor profiles (Write Operations).
 * Restricted to ADMIN role.
 */
@ApiTags('Doctors (Admin)')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('doctors')
export class DoctorController {
  private readonly logger = new Logger(DoctorController.name);

  constructor(private readonly commandBus: CommandBus) {}

  /**
   * Endpoint: Register a new Doctor.
   * Access: ADMIN only.
   */
  @Post()
  @Roles(UserRole.ADMIN) // Security Enforced
  @ApiOperation({ summary: 'Register a new doctor profile' })
  @ApiResponse({ status: HttpStatus.CREATED, description: 'Doctor created successfully', type: Doctor })
  @ApiResponse({ status: HttpStatus.FORBIDDEN, description: 'Insufficient permissions' })
  @ApiResponse({ status: HttpStatus.CONFLICT, description: 'User is already a doctor' })
  async createDoctor(@Body() dto: CreateDoctorDto): Promise<Doctor> {
    this.logger.log(`REST Request: Create Doctor for UserID ${dto.userId}`);
    
    return await this.commandBus.execute(
      new CreateDoctorCommand(dto),
    );
  }
}