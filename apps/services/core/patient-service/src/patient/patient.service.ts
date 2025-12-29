import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Patient } from './entities/patient.entity';
import { UpdatePatientDto } from './dto/update-patient.dto';

@Injectable()
export class PatientService {
  private readonly logger = new Logger(PatientService.name);

  constructor(
    @InjectRepository(Patient)
    private patientRepo: Repository<Patient>,
  ) {}

  // 1. EVENT DRIVEN: Se ejecuta automáticamente cuando Auth crea un usuario
  async createInitialProfile(userId: string, email: string) {
    const exists = await this.patientRepo.findOneBy({ userId });
    if (exists) return;

    this.logger.log(`Creating profile for user ${userId}`);
    const patient = this.patientRepo.create({
      userId,
      email,
      firstName: 'Usuario',
      lastName: 'Nuevo',
    });
    return this.patientRepo.save(patient);
  }

  // 2. Obtener mi propio perfil
  async findOne(userId: string) {
    const patient = await this.patientRepo.findOneBy({ userId });
    if (!patient) throw new NotFoundException('Perfil de paciente no encontrado');
    return patient;
  }

  // 3. Actualizar datos
  async update(userId: string, dto: UpdatePatientDto) {
    const patient = await this.findOne(userId);
    
    // Fusionamos los datos nuevos con los existentes
    const updated = this.patientRepo.merge(patient, {
      ...dto,
      // Tratamiento especial para objetos anidados si fuera necesario
    });
    
    return this.patientRepo.save(updated);
  }
}