import { Injectable, Logger, NotFoundException, BadRequestException, InternalServerErrorException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Patient, MedicalInfo } from '../entities/patient.entity';
import { UpdateProfileDto } from '../dto/update-profile.dto.'; 

/**
 * PatientService (Production Ready)
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
    // 1. Idempotency Check: Prevent duplicate profiles
    const existing = await this.patientRepository.findOneBy({ userId });
    
    if (existing) {
      this.logger.warn(`[Logic] Idempotency check: Record already exists for UserID: ${userId}`);
      return;
    }

    try {
      // 2. Entity Creation
      const newPatient = this.patientRepository.create({
        userId, 
        email,
        isProfileComplete: false,
        medicalInfo: {} // Initialize as empty JSON object (Postgres JSONB)
      });

      // 3. Persistence
      await this.patientRepository.save(newPatient);

      // 4. Success Log (Audit)
      this.logger.log(`Root patient created via Event for: ${email} (ID: ${userId})`);
      
    } catch (error) {
      this.handleDBExceptions(error);
    }
  }

  // ===========================================================================
  // 2. STUDENT LOGIC (Mobile App / Self-Service)
  // ===========================================================================

  /**
   * Updates the authenticated user's profile.
   * Performs strict mapping from DTO to Entity/JSONB fields to prevent over-posting.
   */
  async updateProfile(userId: string, dto: UpdateProfileDto): Promise<Patient> {
    const patient = await this.findByUserId(userId); 

    // --- 1. Map Standard Personal Fields ---
    // We use '??' to keep existing data if the DTO field is undefined (partial update)
    patient.firstName = dto.firstName ?? patient.firstName;
    patient.lastName = dto.lastName ?? patient.lastName;
    patient.phone = dto.phone ?? patient.phone;
    
    if (dto.birthDate) {
        patient.birthDate = new Date(dto.birthDate); 
    }

    // --- 2. Map Academic Fields (NEW) ---
    patient.faculty = dto.faculty ?? patient.faculty;
    patient.career = dto.career ?? patient.career;
    patient.current_semester = dto.current_semester ?? patient.current_semester;
    // Note: student_code excluded as per requirements.

    // --- 3. Optional Fields ---
    patient.avatarUrl = dto.avatarUrl ?? patient.avatarUrl;
    patient.insuranceProvider = dto.insuranceProvider ?? patient.insuranceProvider;

    // --- 4. Map JSONB Fields (Medical Info) ---
    // We merge current info with new info to avoid data loss
    const currentInfo = patient.medicalInfo || {};
    
    const updatedMedicalInfo: MedicalInfo = {
      ...currentInfo,
      bloodType: dto.bloodType ?? currentInfo.bloodType, // Update or keep existing
      allergies: dto.allergies ?? currentInfo.allergies ?? [], 
      chronicConditions: dto.chronicConditions ?? currentInfo.chronicConditions ?? []
    };
    
    patient.medicalInfo = updatedMedicalInfo;

    // Set Completion Flag
    patient.isProfileComplete = true;

    return await this.patientRepository.save(patient);
  }

  /**
   * Helper to find a patient by their Auth User ID.
   * Throws NotFoundException if the record is missing.
   */
  async findByUserId(userId: string): Promise<Patient> {
    const patient = await this.patientRepository.findOneBy({ userId });
    
    if (!patient) {
        throw new NotFoundException(`Patient profile not found for UserID: ${userId}`);
    }
    return patient;
  }

  // ===========================================================================
  // 3. ADMIN LOGIC (Web Dashboard / CRUD)
  // ===========================================================================

  /**
   * ADMIN ONLY: Retrieve all patients ordered by creation date.
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
    const patient = await this.patientRepository.findOneBy({ id });
    
    if (!patient) {
        throw new NotFoundException(`Patient with ID ${id} not found`);
    }
    return patient;
  }

  /**
   * ADMIN ONLY: Hard delete a patient record.
   */
  async remove(id: string): Promise<{ message: string }> {
    const patient = await this.findOne(id); // Ensure existence first
    await this.patientRepository.remove(patient);
    
    this.logger.warn(`[Audit] Patient ID ${id} deleted by Admin`);
    return { message: 'Patient deleted successfully' };
  }

  // ===========================================================================
  // 4. HELPERS
  // ===========================================================================

  /**
   * Standardized error handling for Database operations.
   * Handles Postgres specific error codes (e.g., unique violations).
   */
  private handleDBExceptions(error: unknown): never {
    this.logger.error('Database Error', error);
    
    const dbError = error as { code?: string; message?: string };

    // Postgres Error Code 23505: Unique Violation
    if (dbError?.code === '23505') {
      throw new BadRequestException('A record with these unique details already exists.');
    }
    
    throw new InternalServerErrorException('Unexpected error in Patient Service');
  }
}