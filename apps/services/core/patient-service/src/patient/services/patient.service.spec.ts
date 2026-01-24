import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { PatientService } from './patient.service';
import { Patient } from '../entities/patient.entity';
import { UpdateProfileDto } from '../dto/update-profile.dto';

/**
 * Unit Tests for PatientService
 * * Scope:
 * - Validates business logic for Patient creation, updates, and deletion.
 * - Ensures correct interaction with the Persistence Layer (TypeORM) via Mocks.
 * - Verifies Idempotency and Error Handling (Unique constraints, Not Found errors).
 */
describe('PatientService', () => {
  let service: PatientService;
  let repository: Repository<Patient>;

  // Mock Data Definition
  const mockUserId = 'user-uuid-123';
  const mockEmail = 'test@uce.edu.ec';
  
  const mockPatientEntity = {
    id: 'patient-uuid-abc',
    userId: mockUserId,
    email: mockEmail,
    isProfileComplete: false,
    medicalInfo: {},
    createdAt: new Date(),
    updatedAt: new Date(),
  } as Patient;

  // Mock Repository Definition
  // Includes specific methods used by the service logic (findOneBy, create, save, etc.)
  const mockPatientRepository = {
    findOne: jest.fn(),
    findOneBy: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    find: jest.fn(),
    remove: jest.fn(),
  };

  // Mock Logger to prevent console output during test execution
  const mockLogger = {
    warn: jest.fn(),
    error: jest.fn(),
    log: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PatientService,
        {
          provide: getRepositoryToken(Patient),
          useValue: mockPatientRepository,
        },
        // Explicitly provide Logger to avoid internal instantiation issues or 'any' casting
        {
          provide: Logger,
          useValue: mockLogger,
        }
      ],
    }).compile();

    service = module.get<PatientService>(PatientService);
    repository = module.get<Repository<Patient>>(getRepositoryToken(Patient));
  });

  afterEach(() => {
    jest.clearAllMocks(); 
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  // ===========================================================================
  // Feature: Create Root Patient (Idempotency)
  // ===========================================================================
  describe('createRootPatient', () => {
    it('should create a new patient profile if one does not exist', async () => {
      // Arrange: Simulate that the user does not exist in the database
      mockPatientRepository.findOneBy.mockResolvedValue(null);
      mockPatientRepository.create.mockReturnValue(mockPatientEntity);
      mockPatientRepository.save.mockResolvedValue(mockPatientEntity);

      // Act
      await service.createRootPatient(mockUserId, mockEmail);

      // Assert: Verify repository interaction sequence
      expect(repository.findOneBy).toHaveBeenCalledWith({ userId: mockUserId });
      expect(repository.create).toHaveBeenCalledWith({
        userId: mockUserId,
        email: mockEmail,
        isProfileComplete: false,
        medicalInfo: {},
      });
      expect(repository.save).toHaveBeenCalled();
    });

    it('should enforce idempotency by NOT creating a duplicate profile if one exists', async () => {
      // Arrange: Simulate that the user already has a profile
      mockPatientRepository.findOneBy.mockResolvedValue(mockPatientEntity);

      // Act
      await service.createRootPatient(mockUserId, mockEmail);

      // Assert: Verify that write operations were skipped
      expect(repository.findOneBy).toHaveBeenCalledWith({ userId: mockUserId });
      expect(repository.create).not.toHaveBeenCalled();
      expect(repository.save).not.toHaveBeenCalled();
    });

    it('should handle database unique constraint violations gracefully', async () => {
      // Arrange
      mockPatientRepository.findOneBy.mockResolvedValue(null);
      
      // Construct a typed Error object to simulate a driver-level unique constraint error
      const error = new Error('Unique Violation') as Error & { code: string };
      error.code = '23505'; // Postgres Unique Violation Code
      
      mockPatientRepository.save.mockRejectedValue(error);
      mockPatientRepository.create.mockReturnValue(mockPatientEntity);

      // Act & Assert
      await expect(service.createRootPatient(mockUserId, mockEmail))
        .rejects
        .toThrow(BadRequestException); 
    });
  });

  // ===========================================================================
  // Feature: Update Profile
  // ===========================================================================
  describe('updateProfile', () => {
    const updateDto: UpdateProfileDto = {
      firstName: 'Juan',
      lastName: 'Perez',
      phone: '0999999999',
      birthDate: '2000-01-01',
      bloodType: 'O+',
      allergies: ['Dust'],
    };

    it('should update and return the patient entity when found', async () => {
      // Arrange
      // First call retrieves the existing entity
      mockPatientRepository.findOneBy.mockResolvedValue({ ...mockPatientEntity, medicalInfo: {} });
      
      // Second call saves and returns the entity
      mockPatientRepository.save.mockImplementation((patient: Patient) => Promise.resolve(patient));

      // Act
      const result = await service.updateProfile(mockUserId, updateDto);

      // Assert
      expect(repository.findOneBy).toHaveBeenCalledWith({ userId: mockUserId });
      expect(result.firstName).toBe(updateDto.firstName);
      expect(result.isProfileComplete).toBe(true);
      
      // Verify nested object updates
      expect(result.medicalInfo.bloodType).toBe('O+');
      expect(result.medicalInfo.allergies).toContain('Dust');
    });

    it('should throw NotFoundException if the patient profile does not exist', async () => {
      // Arrange
      mockPatientRepository.findOneBy.mockResolvedValue(null);

      // Act & Assert
      await expect(service.updateProfile(mockUserId, updateDto)).rejects.toThrow(NotFoundException);
    });
  });

  // ===========================================================================
  // Feature: Admin Data Retrieval
  // ===========================================================================
  describe('findAll', () => {
    it('should retrieve an array of all patient profiles', async () => {
      // Arrange
      const patientsArray = [mockPatientEntity];
      mockPatientRepository.find.mockResolvedValue(patientsArray);

      // Act
      const result = await service.findAll();

      // Assert
      expect(result).toEqual(patientsArray);
      expect(repository.find).toHaveBeenCalledWith({ order: { createdAt: 'DESC' } });
    });
  });

  // ===========================================================================
  // Feature: Delete Profile
  // ===========================================================================
  describe('remove', () => {
    it('should delete a patient profile if the ID exists', async () => {
      // Arrange
      mockPatientRepository.findOneBy.mockResolvedValue(mockPatientEntity);
      mockPatientRepository.remove.mockResolvedValue(mockPatientEntity);

      // Act
      const result = await service.remove(mockPatientEntity.id);
      
      // Assert
      expect(repository.findOneBy).toHaveBeenCalledWith({ id: mockPatientEntity.id });
      expect(repository.remove).toHaveBeenCalledWith(mockPatientEntity);
      expect(result).toEqual({ message: 'Patient deleted successfully' });
    });

    it('should throw NotFoundException when attempting to delete a non-existent patient', async () => {
      // Arrange
      mockPatientRepository.findOneBy.mockResolvedValue(null);

      // Act & Assert
      await expect(service.remove('non-existent-id')).rejects.toThrow(NotFoundException);
    });
  });
});