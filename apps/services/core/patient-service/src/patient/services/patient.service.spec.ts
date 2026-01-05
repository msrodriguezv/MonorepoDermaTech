import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { PatientService } from './patient.service';
import { Patient } from '../entities/patient.entity';
import { UpdateProfileDto } from '../dto/update-profile.dto.';

/**
 * Unit Tests for PatientService
 * * Requirement #8: Unit Testing.
 * * Goal: Validate business logic in isolation using mocked TypeORM methods.
 */
describe('PatientService', () => {
  let service: PatientService;
  let repository: Repository<Patient>;

  // Mock Data (Sample inputs)
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

  // Mock Repository Factory
  // Added 'findOneBy' which is used in the service implementation
  const mockPatientRepository = {
    findOne: jest.fn(),
    findOneBy: jest.fn(), // <--- ESTO FALTABA
    create: jest.fn(),
    save: jest.fn(),
    find: jest.fn(),
    remove: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PatientService,
        {
          provide: getRepositoryToken(Patient),
          useValue: mockPatientRepository,
        },
      ],
    }).compile();

    service = module.get<PatientService>(PatientService);
    repository = module.get<Repository<Patient>>(getRepositoryToken(Patient));
  });

  afterEach(() => {
    jest.clearAllMocks(); // Clear call history between tests
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  // ===========================================================================
  // 1. TEST: Create Root Patient (Idempotency)
  // ===========================================================================
  describe('createRootPatient', () => {
    it('should create a new patient if one does not exist', async () => {
      // Arrange: Repo cannot find existing user via findOneBy
      // Mocking findOneBy instead of findOne
      mockPatientRepository.findOneBy.mockResolvedValue(null);
      mockPatientRepository.create.mockReturnValue(mockPatientEntity);
      mockPatientRepository.save.mockResolvedValue(mockPatientEntity);

      // Act
      await service.createRootPatient(mockUserId, mockEmail);

      // Assert
      // Checking findOneBy
      expect(repository.findOneBy).toHaveBeenCalledWith({ userId: mockUserId });
      expect(repository.create).toHaveBeenCalledWith({
        userId: mockUserId,
        email: mockEmail,
        isProfileComplete: false,
        medicalInfo: {},
      });
      expect(repository.save).toHaveBeenCalled();
    });

    it('should NOT create a patient if one already exists (Idempotency)', async () => {
      // Arrange: Repo finds an existing user
      // Mocking findOneBy
      mockPatientRepository.findOneBy.mockResolvedValue(mockPatientEntity);

      // Act
      await service.createRootPatient(mockUserId, mockEmail);

      // Assert
      expect(repository.create).not.toHaveBeenCalled();
      expect(repository.save).not.toHaveBeenCalled();
    });

    it('should throw BadRequestException if DB throws unique violation (code 23505)', async () => {
      // Arrange
      // Mocking findOneBy
      mockPatientRepository.findOneBy.mockResolvedValue(null);
      mockPatientRepository.create.mockReturnValue(mockPatientEntity);
      // Simulate that when trying to save, the DB fails with code 23505
      mockPatientRepository.save.mockRejectedValue({ code: '23505' });

      // Act & Assert
      await expect(service.createRootPatient(mockUserId, mockEmail))
        .rejects
        .toThrow(BadRequestException); 
    });
  });

  // ===========================================================================
  // 2. TEST: Update Profile
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

    it('should update and return the patient when found', async () => {
      // Arrange
      // findByUserId uses findOneBy internally
      mockPatientRepository.findOneBy.mockResolvedValue({ ...mockPatientEntity, medicalInfo: {} });
      mockPatientRepository.save.mockImplementation((patient) => Promise.resolve(patient));

      // Act
      const result = await service.updateProfile(mockUserId, updateDto);

      // Assert
      expect(repository.findOneBy).toHaveBeenCalledWith({ userId: mockUserId });
      expect(result.firstName).toBe(updateDto.firstName);
      expect(result.isProfileComplete).toBe(true);
      expect(result.medicalInfo.bloodType).toBe('O+');
      expect(result.medicalInfo.allergies).toContain('Dust');
    });

    it('should throw NotFoundException if patient does not exist', async () => {
      // Arrange
      // Mocking findOneBy
      mockPatientRepository.findOneBy.mockResolvedValue(null);

      // Act & Assert
      await expect(service.updateProfile(mockUserId, updateDto)).rejects.toThrow(NotFoundException);
    });
  });

  // ===========================================================================
  // 3. TEST: Admin CRUD
  // ===========================================================================
  describe('findAll', () => {
    it('should return an array of patients', async () => {
      const patientsArray = [mockPatientEntity];
      mockPatientRepository.find.mockResolvedValue(patientsArray);

      const result = await service.findAll();
      expect(result).toEqual(patientsArray);
      expect(repository.find).toHaveBeenCalledWith({ order: { createdAt: 'DESC' } });
    });
  });

  describe('remove', () => {
    it('should delete a patient if found', async () => {
      // findOne usually implies finding by ID, verify if your service uses findOneBy({ id })
      // Based on logs, it uses findOneBy
      mockPatientRepository.findOneBy.mockResolvedValue(mockPatientEntity);
      mockPatientRepository.remove.mockResolvedValue(mockPatientEntity);

      const result = await service.remove(mockPatientEntity.id);
      
      expect(repository.findOneBy).toHaveBeenCalledWith({ id: mockPatientEntity.id });
      expect(repository.remove).toHaveBeenCalledWith(mockPatientEntity);
      expect(result).toEqual({ message: 'Patient deleted successfully' });
    });

    it('should throw NotFoundException if trying to delete non-existent patient', async () => {
      //  Mocking findOneBy
      mockPatientRepository.findOneBy.mockResolvedValue(null);

      await expect(service.remove('bad-id')).rejects.toThrow(NotFoundException);
    });
  });
});