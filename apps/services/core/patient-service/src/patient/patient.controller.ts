import { Controller, Get, Post, Body, Patch, Param, Delete, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { PatientService } from './patient.service'; // Importar SINGULAR
import { CreatePatientDto } from './dto/create-patient.dto';
import { UpdatePatientDto } from './dto/update-patient.dto';

@ApiTags('Patients')
@Controller()
export class PatientsController { // <--- Clase en PLURAL
  constructor(private readonly patientService: PatientService) {} // Inyectar SINGULAR

  // ... (resto de tus métodos)
  @Post()
  @ApiOperation({ summary: 'Crear perfil de paciente' })
  @ApiResponse({ status: 201, description: 'Perfil creado exitosamente.' })
  create(@Body() createPatientDto: CreatePatientDto) {
    return this.patientService.create(createPatientDto);
  }
  
  // ... Asegúrate de tener findAll, findOne, etc. aquí abajo
  @Get()
  findAll() { return this.patientService.findAll(); }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) { return this.patientService.findOne(id); }

  @Get('by-user/:userId')
  findOneByUser(@Param('userId', ParseUUIDPipe) userId: string) { return this.patientService.findOneByUserId(userId); }

  @Patch(':id')
  update(@Param('id', ParseUUIDPipe) id: string, @Body() updateDto: UpdatePatientDto) { return this.patientService.update(id, updateDto); }

  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string) { return this.patientService.remove(id); }
}