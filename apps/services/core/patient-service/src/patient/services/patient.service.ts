import { Injectable, Logger, NotFoundException, BadRequestException, InternalServerErrorException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Patient, MedicalInfo } from '../entities/patient.entity';
import { UpdateProfileDto } from '../dto/update-profile.dto.';
/**
 * PatientService (Final Strict Version)
 * * Domain Service encompassing all business logic for the Patient Context.
 * * Scope:
 * 1. System Actions: Idempotent creation of root records via Kafka events.
 * 2. Student Actions: Self-management of profile data.
 * 3. Admin Actions: Full CRUD capabilities.
 */
@Injectable()
export class PatientService {
  private readonly logger = new Logger(PatientService.name);

  constructor(
    @InjectRepository(Patient)
    private readonly patientRepository: Repository<Patient>,
  ) {}

  // ===========================================================================
  // 1. SYSTEM / EVENT DRIVEN LOGIC (Kafka Triggered)
  // ===========================================================================

  /**
   * Creates a root patient record. Called by the CQRS Handler when 'user.registered' occurs.
   * Ensures idempotency to handle potential duplicate events from the broker.
   */
  async createRootPatient(userId: string, email: string): Promise<void> {
    const existing = await this.patientRepository.findOne({ where: { userId } });
    if (existing) {
      this.logger.warn(`Idempotency check: Record already exists for UserID: ${userId}`);
      return;
    }

    try {
      const newPatient = this.patientRepository.create({
        userId,
        email,
        isProfileComplete: false,
        medicalInfo: {} // Initialize as empty JSON object
      });
      await this.patientRepository.save(newPatient);
      this.logger.log(`✅ Root patient created via Event for: ${email}`);
    } catch (error) {
      this.handleDBExceptions(error);
    }
  }

  // ===========================================================================
  // 2. STUDENT LOGIC (Mobile App / Self-Service)
  // ===========================================================================

  /**
   * Updates the authenticated user's profile.
   * Performs strict mapping from DTO to Entity/JSONB fields.
   */
  async updateProfile(userId: string, dto: UpdateProfileDto): Promise<Patient> {
    const patient = await this.findByUserId(userId); // Reuses helper method

    // Map Standard Fields
    patient.firstName = dto.firstName;
    patient.lastName = dto.lastName;
    patient.phone = dto.phone;
    patient.birthDate = new Date(dto.birthDate); // String -> Date conversion

    if (dto.avatarUrl) patient.avatarUrl = dto.avatarUrl;
    if (dto.insuranceProvider) patient.insuranceProvider = dto.insuranceProvider;

    // Map JSONB Fields (Medical Info) with strict typing
    // We use the 'MedicalInfo' interface to prevent 'any' usage here
    const currentInfo = patient.medicalInfo || {};
    const updatedMedicalInfo: MedicalInfo = {
      ...currentInfo,
      bloodType: dto.bloodType,
      allergies: dto.allergies ?? [], // Nullish coalescing to ensure array type
      chronicConditions: dto.chronicConditions ?? []
    };
    patient.medicalInfo = updatedMedicalInfo;

    // Set Flag
    patient.isProfileComplete = true;

    return await this.patientRepository.save(patient);
  }

  /**
   * Helper to find a patient by their Auth User ID.
   */
  async findByUserId(userId: string): Promise<Patient> {
    const patient = await this.patientRepository.findOne({ 
      where: { userId },
    });
    if (!patient) throw new NotFoundException(`Patient profile not found for UserID: ${userId}`);
    return patient;
  }

  // ===========================================================================
  // 3. ADMIN LOGIC (Web Dashboard / CRUD)
  // ===========================================================================

  /**
   * ADMIN ONLY: Retrieve all patients.
   */
  async findAll(): Promise<Patient[]> {
    return await this.patientRepository.find({
      order: { createdAt: 'DESC' }
    });
  }

  /**
   * ADMIN ONLY: Retrieve a single patient by their Database Primary Key (UUID).
   */
  async findOne(id: string): Promise<Patient> {
    const patient = await this.patientRepository.findOne({ 
      where: { id },
    });
    if (!patient) throw new NotFoundException(`Patient with ID ${id} not found`);
    return patient;
  }

  /**
   * ADMIN ONLY: Hard delete a patient record.
   */
  async remove(id: string): Promise<{ message: string }> {
    const patient = await this.findOne(id); // Ensure existence first
    await this.patientRepository.remove(patient);
    this.logger.warn(`Patient ID ${id} deleted by Admin`);
    return { message: 'Patient deleted successfully' };
  }

  // ===========================================================================
  // 4. HELPERS
  // ===========================================================================

  /**
   * Standardized error handling for Database operations.
   * FIXED: Replaced 'any' with 'unknown' to comply with linting rules.
   * Performs type assertion to safely access the error code.
   */
  private handleDBExceptions(error: unknown): never {
    this.logger.error('Database Error', error);
    
    // Safe type casting: We assume the error *might* be an object with a code property
    const dbError = error as { code?: string; message?: string };

    // Postgres Error Code 23505: Unique Violation
    if (dbError?.code === '23505') {
      throw new BadRequestException('A record with these unique details already exists.');
    }
    
    throw new InternalServerErrorException('Unexpected error in Patient Service');
  }
}