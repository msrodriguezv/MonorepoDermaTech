import { Controller, Get, Body, Patch, UseGuards, Req } from '@nestjs/common';
import { PatientService } from './patient.service';
import { UpdatePatientDto } from './dto/update-patient.dto';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { EventPattern, Payload } from '@nestjs/microservices';

@ApiTags('Patients')
@Controller('patient')
export class PatientController {
  constructor(private readonly patientService: PatientService) {}

  // --- KAFKA CONSUMER (Lineamiento Event Driven) ---
  // Escucha cuando Auth dice "Usuario Registrado"
  @EventPattern('user.registered')
  async handleUserRegistered(@Payload() data: { userId: string; email: string }) {
    await this.patientService.createInitialProfile(data.userId, data.email);
  }

  // --- REST API (Protegido con JWT) ---
  
  @Get('me')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Obtener mi perfil médico' })
  getProfile(@Req() req) {
    // req.user viene de JwtStrategy
    return this.patientService.findOne(req.user.userId);
  }

  @Patch('me')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Actualizar mis datos' })
  updateProfile(@Req() req, @Body() dto: UpdatePatientDto) {
    return this.patientService.update(req.user.userId, dto);
  }
}