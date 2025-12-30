import { Injectable, Logger, BadRequestException, NotFoundException, InternalServerErrorException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Patient } from './entities/patient.entity';
import { CreatePatientDto } from './dto/create-patient.dto';
import { UpdatePatientDto } from './dto/update-patient.dto';

@Injectable()
export class PatientService { 
  private readonly logger = new Logger(PatientService.name);

  constructor(
    @InjectRepository(Patient)
    private readonly patientRepository: Repository<Patient>,
  ) {}

  // --- CREATE ---
  async create(createPatientDto: CreatePatientDto) {
    // Check if a profile already exists for this user
    const existing = await this.patientRepository.findOne({
      where: { userId: createPatientDto.userId }
    });

    if (existing) {
      throw new BadRequestException('The user already has a patient profile created.');
    }

    try {
      // Using 'as any' to bypass strict type checking for medicalInfo JSON structure
      const patient = this.patientRepository.create(createPatientDto as any);
      return await this.patientRepository.save(patient);
    } catch (error) {
      this.handleDBExceptions(error);
    }
  }

  // --- READ ALL ---
  async findAll() {
    return await this.patientRepository.find();
  }

  // --- READ ONE BY UUID ---
  async findOne(id: string) {
    const patient = await this.patientRepository.findOne({ where: { id } });
    if (!patient) throw new NotFoundException(`Patient with ID ${id} not found`);
    return patient;
  }

  // --- FIND BY USER ID (Doctor List) ---
  // CORRECTION: Renamed to match Controller and changed to .find() to return a list
  async findByUser(userId: string) {
    const patients = await this.patientRepository.find({ where: { userId } });
    // Returns an empty array [] if no patients are found, which is correct for a list
    return patients;
  }

  // --- UPDATE ---
  async update(id: string, updatePatientDto: UpdatePatientDto) {
    const patient = await this.findOne(id);
    // Using 'as any' to allow partial updates including JSON fields
    this.patientRepository.merge(patient, updatePatientDto as any);
    return await this.patientRepository.save(patient);
  }

  // --- DELETE ---
  async remove(id: string) {
    const patient = await this.findOne(id);
    await this.patientRepository.remove(patient);
    return { message: 'Patient deleted successfully' };
  }

  // --- ERROR HANDLING ---
  private handleDBExceptions(error: any) {
    if (error.code === '23505') { // Postgres unique violation code
       throw new BadRequestException('A record with these details already exists.');
    }
    this.logger.error(error);
    throw new InternalServerErrorException('Unexpected database error');
  }
}