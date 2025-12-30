
import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { PatientService } from './patient.service';
import { CreatePatientDto } from './dto/create-patient.dto';
import { UpdatePatientDto } from './dto/update-patient.dto';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Patients') 
@Controller('patients') 
export class PatientsController {
  constructor(private readonly patientsService: PatientService) {}

  /**
   * Endpoint to create a new patient profile.
   * Route: POST /api/patients/create
   */
  @Post('create')
  @ApiOperation({ summary: 'Create a new patient' })
  @ApiResponse({ status: 201, description: 'The patient has been successfully created.' })
  @ApiResponse({ status: 400, description: 'Bad Request. Validation failed.' })
  create(@Body() createPatientDto: CreatePatientDto) {
    return this.patientsService.create(createPatientDto);
  }

  /**
   * Endpoint to retrieve the list of all registered patients.
   * Route: GET /api/patients/list
   */
  @Get('list')
  @ApiOperation({ summary: 'List all patients' })
  @ApiResponse({ status: 200, description: 'List of all patients returned successfully.' })
  findAll() {
    return this.patientsService.findAll();
  }

  /**
   * Endpoint to get details of a specific patient by their ID (UUID).
   * Route: GET /api/patients/detail/{id}
   */
  @Get('detail/:id')
  @ApiOperation({ summary: 'Get patient details by ID' })
  @ApiResponse({ status: 200, description: 'Patient details returned.' })
  @ApiResponse({ status: 404, description: 'Patient not found.' })
  findOne(@Param('id') id: string) {
    return this.patientsService.findOne(id);
  }

  /**
   * Endpoint to list all patients associated with a specific user/doctor.
   * Route: GET /api/patients/doctor-list/{userId}
   */
  @Get('doctor-list/:userId')
  @ApiOperation({ summary: 'List patients by Doctor/User ID' })
  findByUser(@Param('userId') userId: string) {
    return this.patientsService.findByUser(userId);
  }

  /**
   * Endpoint to update an existing patient's information.
   * Route: PATCH /api/patients/update/{id}
   */
  @Patch('update/:id')
  @ApiOperation({ summary: 'Update patient information' })
  @ApiResponse({ status: 200, description: 'Patient updated successfully.' })
  update(@Param('id') id: string, @Body() updatePatientDto: UpdatePatientDto) {
    return this.patientsService.update(id, updatePatientDto);
  }

  /**
   * Endpoint to delete a patient record (Soft delete or Hard delete depending on service logic).
   * Route: DELETE /api/patients/delete/{id}
   */
  @Delete('delete/:id')
  @ApiOperation({ summary: 'Delete a patient record' })
  @ApiResponse({ status: 200, description: 'Patient deleted successfully.' })
  remove(@Param('id') id: string) {
    return this.patientsService.remove(id);
  }
}