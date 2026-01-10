import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConflictException, InternalServerErrorException, Logger } from '@nestjs/common';

import { CreateDoctorHandler } from './create-doctor.handler';
import { CreateDoctorCommand } from '../impl/create-doctor.command';
import { Doctor } from '../../../entities/doctor.entity';

/**
 * Unit Test: CreateDoctorHandler
 * Scope: 
 * - Verifies business logic for creating a Doctor profile.
 * - Ensures correct interaction with TypeORM repository (findOne, create, save).
 * - Validates error handling for duplicates and database exceptions.
 */
describe('CreateDoctorHandler', () => {
  let handler: CreateDoctorHandler;
  let repository: Repository<Doctor>;

  // Mock DTO Data based on the structure used in the Handler
  const mockDto = {
    userId: 'user-123',
    firstName: 'Gregory',
    lastName: 'House',
    specialization: 'Diagnostic Medicine',
    licenseNumber: 'CMP-99999',
    officeNumber: 'Office 101',
    isActive: true,
  };

  // Mock Command containing the DTO
  const command = { dto: mockDto } as CreateDoctorCommand;

  // Mock Entity Result
  // Using Double Casting (as unknown as Doctor) to allow partial mocking of the Entity
  // This prevents TypeScript errors regarding missing internal TypeORM properties
  const mockDoctorEntity = {
    id: 'doc-uuid-1',
    userId: mockDto.userId,
    firstName: mockDto.firstName,
    lastName: mockDto.lastName,
    specialization: mockDto.specialization, 
    licenseNumber: mockDto.licenseNumber,
    officeNumber: mockDto.officeNumber,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  } as unknown as Doctor;

  // Mock Repository Definition
  const mockDoctorRepository = {
    create: jest.fn(),
    save: jest.fn(),
    findOne: jest.fn(), 
  };

  const mockLogger = {
    log: jest.fn(),
    error: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateDoctorHandler,
        {
          provide: getRepositoryToken(Doctor),
          useValue: mockDoctorRepository,
        },
        {
          provide: Logger,
          useValue: mockLogger,
        },
      ],
    }).compile();

    handler = module.get<CreateDoctorHandler>(CreateDoctorHandler);
    repository = module.get<Repository<Doctor>>(getRepositoryToken(Doctor));
  });

  it('should be defined', () => {
    expect(handler).toBeDefined();
  });

  describe('execute', () => {
    it('should successfully create and persist a new doctor profile', async () => {
      // Arrange: Repository returns null (User does not exist yet)
      mockDoctorRepository.findOne.mockResolvedValue(null);
      mockDoctorRepository.create.mockReturnValue(mockDoctorEntity);
      mockDoctorRepository.save.mockResolvedValue(mockDoctorEntity);

      // Act
      const result = await handler.execute(command);

      // Assert
      // 1. Verify duplication check using findOne with specific 'where' clause
      expect(repository.findOne).toHaveBeenCalledWith({ 
        where: { userId: mockDto.userId } 
      });
      
      // 2. Verify entity creation with correct DTO mapping
      expect(repository.create).toHaveBeenCalledWith({
        userId: mockDto.userId,
        firstName: mockDto.firstName,
        lastName: mockDto.lastName,
        specialization: mockDto.specialization,
        licenseNumber: mockDto.licenseNumber,
        officeNumber: mockDto.officeNumber,
        isActive: true,
      });

      // 3. Verify persistence
      expect(repository.save).toHaveBeenCalledWith(mockDoctorEntity);
      expect(result).toEqual(mockDoctorEntity);
    });

    it('should throw ConflictException if the user is already registered as a doctor', async () => {
      // Arrange: Repository returns an existing record
      mockDoctorRepository.findOne.mockResolvedValue(mockDoctorEntity);

      // Act & Assert
      await expect(handler.execute(command)).rejects.toThrow(ConflictException);
      
      // Verify that create and save were never called to prevent side effects
      expect(repository.create).not.toHaveBeenCalled();
      expect(repository.save).not.toHaveBeenCalled();
    });

    it('should throw ConflictException when Database throws Unique Violation (code 23505)', async () => {
      // Arrange: User check passes
      mockDoctorRepository.findOne.mockResolvedValue(null);
      mockDoctorRepository.create.mockReturnValue(mockDoctorEntity);

      // Simulate Postgres Error 23505 (Unique Constraint Violation)
      const dbError = new Error('Duplicate key value') as Error & { code: string };
      dbError.code = '23505';
      
      mockDoctorRepository.save.mockRejectedValue(dbError);

      // Act & Assert
      await expect(handler.execute(command)).rejects.toThrow(ConflictException);
    });

    it('should throw InternalServerErrorException for unexpected database errors', async () => {
        // Arrange
        mockDoctorRepository.findOne.mockResolvedValue(null);
        mockDoctorRepository.create.mockReturnValue(mockDoctorEntity);
        
        // Simulate generic connection error
        mockDoctorRepository.save.mockRejectedValue(new Error('Connection timeout'));
  
        // Act & Assert
        await expect(handler.execute(command)).rejects.toThrow(InternalServerErrorException);
    });
  });
});