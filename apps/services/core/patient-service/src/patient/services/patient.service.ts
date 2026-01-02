import { Inject, Injectable, Logger, BadRequestException, NotFoundException, InternalServerErrorException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ClientKafka } from '@nestjs/microservices';
import { Patient } from '../entities/patient.entity';
import { CreatePatientDto } from '../dto/create-patient.dto';
import { UpdatePatientDto } from '../dto/update-patient.dto';

@Injectable()
export class PatientService { 
  private readonly logger = new Logger(PatientService.name);

  constructor(
    @InjectRepository(Patient)
    private readonly patientRepository: Repository<Patient>,
    
    @Inject('PATIENT_KAFKA_CLIENT') 
    private readonly kafkaClient: ClientKafka,
  ) {}

  // --- CREATE ---
  async create(createPatientDto: CreatePatientDto) {
    const existing = await this.patientRepository.findOne({
      where: { userId: createPatientDto.userId }
    });

    if (existing) {
      throw new BadRequestException('The user already has a patient profile created.');
    }

    try {
      // Preparamos los datos correctamente para cumplir con el esquema JSON de la entidad
      const dataToSave = {
        ...createPatientDto,
        medicalInfo: {
          // 1. Si medicalInfo ya es un objeto, lo usamos; si no, objeto vacío
          ...(typeof createPatientDto.medicalInfo === 'object' ? createPatientDto.medicalInfo : {}),
          
          // 2. Integramos las alergias al objeto médico
          allergies: createPatientDto.allergies || [],

          // 3. Aseguramos que existan condiciones crónicas (o array vacío)
          chronicConditions: (createPatientDto.medicalInfo as any)?.chronicConditions || []
        }
      };

      // CORRECCIÓN: Creamos la entidad directamente (ya corregimos el DTO y dataToSave)
      const patient = this.patientRepository.create(dataToSave);
      
      const savedPatient = await this.patientRepository.save(patient);

      // --- KAFKA (FAIL-SAFE) ---
      this.kafkaClient
        .emit('patient.created', {
          id: savedPatient.id,
          userId: savedPatient.userId,
          email: savedPatient.email,
          fullName: `${savedPatient.firstName} ${savedPatient.lastName}`,
          timestamp: new Date().toISOString(),
        })
        .toPromise()
        .then(() => {
          this.logger.log(`✅ Event 'patient.created' sent successfully to Kafka`);
        })
        .catch((err) => {
          // FIX (Copilot): Logueamos el error real para poder depurar si falla
          this.logger.warn(`⚠️ Kafka is offline. Event saved in DB but not emitted.`);
          this.logger.error(`Kafka Error Details: ${err?.message || err}`, err?.stack);
        });

      return savedPatient;

    } catch (error) {
      this.handleDBExceptions(error);
    }
  }

  // --- READ ALL ---
  async findAll() {
    return await this.patientRepository.find();
  }

  // --- READ ONE ---
  async findOne(id: string) {
    const patient = await this.patientRepository.findOne({ where: { id } });
    if (!patient) throw new NotFoundException(`Patient with ID ${id} not found`);
    return patient;
  }

  // --- FIND BY USER ---
  async findByUser(userId: string) {
    return await this.patientRepository.find({ where: { userId } });
  }

  // --- UPDATE ---
  async update(id: string, updatePatientDto: UpdatePatientDto) {
    const patient = await this.findOne(id);
    this.patientRepository.merge(patient, updatePatientDto); 
    return this.patientRepository.save(patient);
  }

  // --- DELETE ---
  async remove(id: string) {
    const patient = await this.findOne(id);
    await this.patientRepository.remove(patient);
    return { message: 'Patient deleted successfully' };
  }

  private handleDBExceptions(error: any) {
    if (error.code === '23505') { 
       throw new BadRequestException('A record with these details already exists.');
    }
    this.logger.error(error);
    throw new InternalServerErrorException('Unexpected database error');
  }
}