import { Controller, Post, Body, UseGuards, HttpStatus, Logger } from '@nestjs/common';
import { CommandBus } from '@nestjs/cqrs';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';

// SHARED LIBS (Security & Decorators)
import { JwtAuthGuard, RolesGuard, Roles } from '@dermatech/shared-guards';
import { User } from '@dermatech/shared-guards'; 
import { UserRole } from '@dermatech/shared-dtos';

// LOCAL IMPORTS
import { BookAppointmentDto } from '../dto/book-appointment.dto';
import { BookAppointmentCommand } from '../cqrs/commands/impl/book-appointment.command';
import { Appointment } from '../entities/appointment.entity';

/**
 * Controller for Managing Appointments.
 * Exposed primarily to STUDENTS for booking.
 */
@ApiTags('Appointments (Student)')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('appointments')
export class AppointmentController {
  private readonly logger = new Logger(AppointmentController.name);

  constructor(private readonly commandBus: CommandBus) {}

  /**
   * Endpoint: Book a new Appointment.
   * Access: STUDENT only.
   * Logic: The Student ID is extracted securely from the JWT, not the body.
   */
  @Post()
  @Roles(UserRole.STUDENT) // RBAC Protection
  @ApiOperation({ summary: 'Book a medical appointment' })
  @ApiResponse({ status: HttpStatus.CREATED, description: 'Appointment booked successfully', type: Appointment })
  @ApiResponse({ status: HttpStatus.CONFLICT, description: 'Time slot already taken or Doctor unavailable' })
  @ApiResponse({ status: HttpStatus.BAD_REQUEST, description: 'Invalid time range' })
  async bookAppointment(
    @User('userId') studentId: string, // Custom Decorator extracts ID from Token
    @Body() dto: BookAppointmentDto
  ): Promise<Appointment> {
    
    this.logger.log(`REST Request: Booking for Student ${studentId}`);

    return await this.commandBus.execute(
      new BookAppointmentCommand(studentId, dto),
    );
  }
}