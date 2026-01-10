import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { Logger, ConflictException, InternalServerErrorException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CreateDoctorCommand } from '../impl/create-doctor.command';
import { Doctor } from '../../../entities/doctor.entity';

/**
 * Interface to type-safe the database error object.
 * Prevents usage of 'any' when accessing Postgres specific error codes.
 */
interface DatabaseError extends Error {
  code?: string;
}

@CommandHandler(CreateDoctorCommand)
export class CreateDoctorHandler implements ICommandHandler<CreateDoctorCommand> {
  private readonly logger = new Logger(CreateDoctorHandler.name);

  constructor(
    @InjectRepository(Doctor)
    private readonly doctorRepository: Repository<Doctor>,
  ) {}

  /**
   * Executes the creation logic for a Doctor.
   * Flow: Validate Uniqueness -> Create Entity -> Persist -> (Future: Publish Event).
   */
  async execute(command: CreateDoctorCommand): Promise<Doctor> {
    const { dto } = command;
    this.logger.log(`[CQRS] Processing CreateDoctorCommand for UserID: ${dto.userId}`);

    try {
      // 1. Check for existing doctor linked to this user
      const existing = await this.doctorRepository.findOne({ 
        where: { userId: dto.userId } 
      });

      if (existing) {
        throw new ConflictException('This user is already registered as a Doctor.');
      }

      // 2. Create Entity instance
      const doctor = this.doctorRepository.create({
        userId: dto.userId,
        firstName: dto.firstName,
        lastName: dto.lastName,
        specialization: dto.specialization,
        licenseNumber: dto.licenseNumber,
        officeNumber: dto.officeNumber,
        isActive: dto.isActive ?? true,
      });

      // 3. Persist to PostgreSQL
      const savedDoctor = await this.doctorRepository.save(doctor);
      
      this.logger.log(`✅ Doctor created successfully: ${savedDoctor.id}`);

      // TODO: Here we will publish 'doctor.created' event to Kafka in the next iteration.

      return savedDoctor;

    } catch (error) {
      if (error instanceof ConflictException) throw error;
      
      // Type assertion to access properties safely without 'any'
      const dbError = error as DatabaseError;

      this.logger.error(`Failed to create doctor: ${dbError.message}`, dbError.stack);

      // Handle Postgres unique constraint violation (code 23505) if race condition occurs
      if (dbError.code === '23505') {
        throw new ConflictException('License number or User ID already exists.');
      }
      
      throw new InternalServerErrorException('Could not create doctor profile');
    }
  }
}