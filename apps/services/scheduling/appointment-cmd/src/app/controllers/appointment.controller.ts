import { Controller, Get, Patch, Param, Body, Post, UseGuards } from '@nestjs/common';
import { CommandBus, QueryBus } from '@nestjs/cqrs';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard, RolesGuard, Roles, User } from '@dermatech/shared-guards';
import { UserRole, JwtPayload } from '@dermatech/shared-dtos';

import { GetStudentAppointmentsQuery } from '../cqrs/queries/impl/get-student-appointments.query';
import { GetClinicalQueueQuery } from '../cqrs/queries/impl/get-clinical-queue.query';
import { TriagePatientCommand } from '../cqrs/commands/impl/triage-patient.command';
import { BookAppointmentCommand } from '../cqrs/commands/impl/book-appointment.command';

import { TriageDecisionDto } from '../dto/triage-decision.dto';
import { AppointmentStatus } from '../entities/appointment.entity';
import { BookAppointmentDto } from '../dto/book-appointment.dto';

@ApiTags('Appointments & Clinical Workflow')
@ApiBearerAuth()
@Controller('appointments')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AppointmentController {
  constructor(
    private readonly commandBus: CommandBus,
    private readonly queryBus: QueryBus,
  ) {}

  @Get('queue/nurse')
  @ApiOperation({ summary: 'Get Triage Queue (Patients waiting for Nurse)' })
  @ApiResponse({ status: 200, description: 'List of patients with SCHEDULED status.' })
  async getNurseQueue() {
    return this.queryBus.execute(
      new GetClinicalQueueQuery(AppointmentStatus.SCHEDULED)
    );
  }

  @Get('queue/doctor/:doctorId')
  @ApiOperation({ summary: 'Get Doctor Queue (Patients waiting for Consultation)' })
  @ApiResponse({ status: 200, description: 'List of patients triaged and waiting for specific doctor.' })
  async getDoctorQueue(@Param('doctorId') doctorId: string) {
    return this.queryBus.execute(
      new GetClinicalQueueQuery(AppointmentStatus.WAITING_FOR_DOCTOR, doctorId)
    );
  }

  @Get('my-history')
  @Roles(UserRole.STUDENT)
  @ApiOperation({ summary: 'Get logged-in student appointment history' })
  @ApiResponse({ status: 200, description: 'List of student appointments.' })
  async getMyAppointments(@User() user: JwtPayload) {
    return this.queryBus.execute(
      new GetStudentAppointmentsQuery(user.sub)
    );
  }

  @Post()
  @ApiOperation({ summary: 'Book a new Appointment (Student)' })
  async bookAppointment(@Body() dto: BookAppointmentDto, @User() user: JwtPayload) {
    return this.commandBus.execute(
      new BookAppointmentCommand(user.sub, dto)
    );
  }

  @Patch(':id/triage')
  @ApiOperation({ summary: 'Nurse completes Triage (Update Status & Notes)' })
  @ApiResponse({ status: 200, description: 'Appointment status updated to WAITING_FOR_DOCTOR or REFERRED.' })
  async triagePatient(
    @Param('id') id: string,
    @Body() dto: TriageDecisionDto
  ) {
    return this.commandBus.execute(
      new TriagePatientCommand(id, dto)
    );
  }
}