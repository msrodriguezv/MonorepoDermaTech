import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { CommandBus } from '@nestjs/cqrs'; 

import { PatientService } from '../services/patient.service';
import { CreatePatientDto } from '../dto/create-patient.dto';
import { UpdatePatientDto } from '../dto/update-patient.dto';
import { CreatePatientCommand } from '../cqrs/create-patient.command'; 

// --- 1. NUEVOS IMPORTS ---
import { AddMedicalRecordDto } from '../dto/add-medical-record.dto';
import { AddMedicalRecordCommand } from '../cqrs/add-medical-record.command';

@ApiTags('Patients')
@Controller('patients')
export class PatientsController {
  constructor(
    private readonly patientsService: PatientService,
    private readonly commandBus: CommandBus, 
  ) {}

  /**
   * Endpoint to create a new patient profile.
   * Route: POST /api/patients/create
   * Uses CQRS Pattern (CommandBus)
   */
  @Post('create')
  @UseGuards(AuthGuard('jwt'))
  @ApiOperation({ summary: 'Create a new patient (CQRS)' })
  @ApiResponse({ status: 201, description: 'The patient has been successfully created.' })
  @ApiResponse({ status: 400, description: 'Bad Request. Validation failed.' })
  async create(@Body() createPatientDto: CreatePatientDto) {
    return await this.commandBus.execute(
      new CreatePatientCommand(createPatientDto),
    );
  }

  // --- 2. NUEVO ENDPOINT (MEDICAL RECORDS) ---
  /**
   * Endpoint to add a photo and description (Medical Record) to a patient.
   * Route: POST /api/patients/:id/medical-record
   */
  @Post(':id/medical-record')
  @UseGuards(AuthGuard('jwt'))
  @ApiOperation({ summary: 'Add a lesion photo and description' })
  @ApiResponse({ status: 201, description: 'Medical record added successfully.' })
  async addMedicalRecord(
    @Param('id') id: string,
    @Body() addDto: AddMedicalRecordDto,
  ) {
    // Despachamos el comando al Handler
    return await this.commandBus.execute(
      new AddMedicalRecordCommand(id, addDto),
    );
  }

  // --- LOS DEMÁS MÉTODOS SIGUEN IGUAL (Queries) ---

  @Get('list')
  @ApiOperation({ summary: 'List all patients' })
  @ApiResponse({ status: 200, description: 'List of all patients returned successfully.' })
  findAll() {
    return this.patientsService.findAll();
  }

  @Get('detail/:id')
  @ApiOperation({ summary: 'Get patient details by ID' })
  @ApiResponse({ status: 200, description: 'Patient details returned.' })
  @ApiResponse({ status: 404, description: 'Patient not found.' })
  findOne(@Param('id') id: string) {
    return this.patientsService.findOne(id);
  }

  @Get('doctor-list/:userId')
  @ApiOperation({ summary: 'List patients by Doctor/User ID' })
  findByUser(@Param('userId') userId: string) {
    return this.patientsService.findByUser(userId);
  }

  @Patch('update/:id')
  @ApiOperation({ summary: 'Update patient information' })
  @ApiResponse({ status: 200, description: 'Patient updated successfully.' })
  update(@Param('id') id: string, @Body() updatePatientDto: UpdatePatientDto) {
    return this.patientsService.update(id, updatePatientDto);
  }

  @Delete('delete/:id')
  @ApiOperation({ summary: 'Delete a patient record' })
  @ApiResponse({ status: 200, description: 'Patient deleted successfully.' })
  remove(@Param('id') id: string) {
    return this.patientsService.remove(id);
  }
}