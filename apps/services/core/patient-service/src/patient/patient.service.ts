import { Injectable, Logger, BadRequestException, NotFoundException, InternalServerErrorException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Patient } from './entities/patient.entity';
import { CreatePatientDto } from './dto/create-patient.dto';
import { UpdatePatientDto } from './dto/update-patient.dto';

@Injectable()
export class PatientService { // <--- SINGULAR (Sin la S al final)
  private readonly logger = new Logger(PatientService.name);

  constructor(
    @InjectRepository(Patient)
    private readonly patientRepository: Repository<Patient>,
  ) {}

  // --- CREAR ---
  async create(createPatientDto: CreatePatientDto) {
    const existing = await this.patientRepository.findOne({
      where: { userId: createPatientDto.userId }
    });

    if (existing) {
      throw new BadRequestException('El usuario ya tiene un perfil de paciente creado.');
    }

    try {
      const patient = this.patientRepository.create(createPatientDto);
      return await this.patientRepository.save(patient);
    } catch (error) {
      this.handleDBExceptions(error);
    }
  }

  // --- LEER TODOS ---
  async findAll() {
    return await this.patientRepository.find();
  }

  // --- LEER UNO ---
  async findOne(id: string) {
    const patient = await this.patientRepository.findOne({ where: { id } });
    if (!patient) throw new NotFoundException(`Paciente con ID ${id} no encontrado`);
    return patient;
  }

  // --- BUSCAR POR USER ID ---
  async findOneByUserId(userId: string) {
    const patient = await this.patientRepository.findOne({ where: { userId } });
    if (!patient) {
      throw new NotFoundException(`No se encontró perfil para el usuario ${userId}`);
    }
    return patient;
  }

  // --- ACTUALIZAR ---
  async update(id: string, updatePatientDto: UpdatePatientDto) {
    const patient = await this.findOne(id);
    this.patientRepository.merge(patient, updatePatientDto);
    return await this.patientRepository.save(patient);
  }

  // --- ELIMINAR ---
  async remove(id: string) {
    const patient = await this.findOne(id);
    await this.patientRepository.remove(patient);
    return { message: 'Paciente eliminado correctamente' };
  }

  private handleDBExceptions(error: any) {
    this.logger.error(error);
    throw new InternalServerErrorException('Error inesperado en base de datos');
  }
}