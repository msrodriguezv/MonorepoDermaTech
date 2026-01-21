import { Controller, Get, Patch, Param, Body, Post } from '@nestjs/common';
import { CommandBus, QueryBus } from '@nestjs/cqrs';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

// Imports of your Commands and Queries
import { GetClinicalQueueQuery } from '../cqrs/queries/get-clinical-queue.query';
import { TriagePatientCommand } from '../cqrs/commands/impl/triage-patient.command';
import { BookAppointmentCommand } from '../cqrs/commands/impl/book-appointment.command'; // Ensure this exists if you use POST

// DTOs & Enums
import { TriageDecisionDto } from '../dto/triage-decision.dto';
import { AppointmentStatus } from '../entities/appointment.entity';
import { BookAppointmentDto } from '../dto/book-appointment.dto'; // Ensure this DTO exists

@ApiTags('Appointments & Clinical Workflow')
@Controller('appointments')
export class AppointmentController {
  constructor(
    private readonly commandBus: CommandBus,
    private readonly queryBus: QueryBus,
  ) {}

  // --- READ ENDPOINTS (Queries) ---

  @Get('queue/nurse')
  @ApiOperation({ summary: 'Get Triage Queue (Patients waiting for Nurse)' })
  @ApiResponse({ status: 200, description: 'List of patients with SCHEDULED status.' })
  async getNurseQueue() {
    // Executes the Query Handler to fetch data
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

  // --- WRITE ENDPOINTS (Commands) ---

  @Post()
  @ApiOperation({ summary: 'Book a new Appointment (Student)' })
  async bookAppointment(@Body() dto: BookAppointmentDto) {
    // FIX: The command expects (studentId, dto). 
    // Usually, you get studentId from @User() decorator. 
    // For now, we pass a placeholder string to fix the compilation error.
    const studentId = 'temp-student-id'; 

    return this.commandBus.execute(
      new BookAppointmentCommand(studentId, dto) // <--- Agregamos el primer argumento
    );
  }

  @Patch(':id/triage')
  @ApiOperation({ summary: 'Nurse completes Triage (Update Status & Notes)' })
  @ApiResponse({ status: 200, description: 'Appointment status updated to WAITING_FOR_DOCTOR or REFERRED.' })
  async triagePatient(
    @Param('id') id: string,
    @Body() dto: TriageDecisionDto
  ) {
    // Executes the Command Handler to perform the logic
    return this.commandBus.execute(
      new TriagePatientCommand(id, dto)
    );
  }
}