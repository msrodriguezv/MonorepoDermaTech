import { Test, TestingModule } from '@nestjs/testing';
import { EventBus } from '@nestjs/cqrs';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException, ConflictException, BadRequestException, InternalServerErrorException, Logger } from '@nestjs/common';

import { BookAppointmentHandler } from './book-appointment.handler';
import { BookAppointmentCommand } from '../impl/book-appointment.command';
import { Appointment, AppointmentStatus } from '../../../entities/appointment.entity';
import { Doctor } from '../../../entities/doctor.entity';
import { AppointmentCreatedEvent } from '../../events/impl/appointment-created.event';

/**
 * Unit Test: BookAppointmentHandler
 * Scope: 
 * - Verifies booking logic (Auto-calculated EndTime, Doctor status, Overlaps via QueryBuilder).
 * - Ensures Event publishing with Symptoms.
 * - Handles specific Business Exceptions.
 */
describe('BookAppointmentHandler', () => {
  let handler: BookAppointmentHandler;
  
  // Repositories
  let appointmentRepository: Repository<Appointment>;
  let doctorRepository: Repository<Doctor>;
  let eventBus: EventBus;

  // Mock Data Generators
  const mockStudentId = 'student-uuid-123';
  const mockDoctorId = 'doctor-uuid-456';
  
  // We use a future date to avoid "Cannot book in the past" error
  const futureDate = new Date();
  futureDate.setDate(futureDate.getDate() + 1); // Tomorrow
  futureDate.setHours(10, 0, 0, 0);

  const startTimeStr = futureDate.toISOString();
  const symptoms = 'Manchas rojas y erupciones';

  const mockDto = {
    doctorId: mockDoctorId,
    startTime: startTimeStr,
    // endTime is removed from DTO as logic now calculates it in Backend
    symptoms: symptoms,
  };

  const command = new BookAppointmentCommand(mockStudentId, mockDto);

  const mockDoctor = {
    id: mockDoctorId,
    isActive: true,
  } as Doctor;

  const mockAppointment = {
    id: 'appt-uuid-789',
    studentId: mockStudentId,
    doctorId: mockDoctorId,
    startTime: futureDate,
    endTime: new Date(futureDate.getTime() + 30 * 60000), // +30 mins
    status: AppointmentStatus.SCHEDULED,
    createdAt: new Date(),
    symptoms: symptoms,
  } as Appointment;

  // --- MOCKING QUERY BUILDER (Crucial for TypeORM chaining) ---
  const mockQueryBuilder = {
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    getOne: jest.fn(), // Return value set in individual tests
  };

  const mockAppointmentRepository = {
    create: jest.fn(),
    save: jest.fn(),
    // We inject the mockQueryBuilder when createQueryBuilder is called
    createQueryBuilder: jest.fn(() => mockQueryBuilder),
  };

  const mockDoctorRepository = {
    findOneBy: jest.fn(),
  };

  const mockEventBus = {
    publish: jest.fn(),
  };

  const mockLogger = {
    log: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BookAppointmentHandler,
        { provide: getRepositoryToken(Appointment), useValue: mockAppointmentRepository },
        { provide: getRepositoryToken(Doctor), useValue: mockDoctorRepository },
        { provide: EventBus, useValue: mockEventBus },
        { provide: Logger, useValue: mockLogger },
      ],
    }).compile();

    handler = module.get<BookAppointmentHandler>(BookAppointmentHandler);
    appointmentRepository = module.get<Repository<Appointment>>(getRepositoryToken(Appointment));
    doctorRepository = module.get<Repository<Doctor>>(getRepositoryToken(Doctor));
    eventBus = module.get<EventBus>(EventBus);
  });

  it('should be defined', () => {
    expect(handler).toBeDefined();
  });

  describe('execute', () => {
    it('should successfully book an appointment when slot is free and doctor is active', async () => {
      // Arrange
      mockDoctorRepository.findOneBy.mockResolvedValue(mockDoctor); // Doctor exists & active
      mockQueryBuilder.getOne.mockResolvedValue(null);              // No overlap found
      mockAppointmentRepository.create.mockReturnValue(mockAppointment);
      mockAppointmentRepository.save.mockResolvedValue(mockAppointment);

      // Act
      const result = await handler.execute(command);

      // Assert
      // 1. Doctor Validation
      expect(doctorRepository.findOneBy).toHaveBeenCalledWith({ id: mockDoctorId });
      
      // 2. Overlap Check (Verify QueryBuilder usage)
      expect(appointmentRepository.createQueryBuilder).toHaveBeenCalledWith('appointment');
      expect(mockQueryBuilder.where).toHaveBeenCalledWith('appointment.doctorId = :doctorId', { doctorId: mockDoctorId });
      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith('appointment.status = :status', { status: AppointmentStatus.SCHEDULED });
      // We check that overlap logic was called (checking Start < EndB and End > StartB)
      expect(mockQueryBuilder.andWhere).toHaveBeenCalledTimes(3); 

      // 3. Persistence
      expect(appointmentRepository.create).toHaveBeenCalledWith(expect.objectContaining({
        studentId: mockStudentId,
        doctorId: mockDoctorId,
        symptoms: symptoms, // Check mapping
        // We ensure logic calculated the 30 min duration correctly
        endTime: expect.any(Date), 
      }));
      
      expect(appointmentRepository.save).toHaveBeenCalled();

      // 4. Event Publishing
      expect(eventBus.publish).toHaveBeenCalledWith(expect.any(AppointmentCreatedEvent));
      
      expect(result).toEqual(mockAppointment);
    });

    it('should throw BadRequestException if Start Time is in the past', async () => {
      // Arrange: Past date
      const pastDate = new Date();
      pastDate.setDate(pastDate.getDate() - 1);
      
      const pastDto = { ...mockDto, startTime: pastDate.toISOString() };
      const pastCommand = new BookAppointmentCommand(mockStudentId, pastDto);

      // Act & Assert
      await expect(handler.execute(pastCommand)).rejects.toThrow(BadRequestException);
      expect(doctorRepository.findOneBy).not.toHaveBeenCalled(); // Should fail fast
    });

    it('should throw NotFoundException if Doctor does not exist', async () => {
      // Arrange
      mockDoctorRepository.findOneBy.mockResolvedValue(null);

      // Act & Assert
      await expect(handler.execute(command)).rejects.toThrow(NotFoundException);
    });

    it('should throw ConflictException if Doctor is inactive', async () => {
      // Arrange
      mockDoctorRepository.findOneBy.mockResolvedValue({ ...mockDoctor, isActive: false });

      // Act & Assert
      await expect(handler.execute(command)).rejects.toThrow(ConflictException);
    });

    it('should throw ConflictException if there is a Time Overlap (Double Booking)', async () => {
      // Arrange
      mockDoctorRepository.findOneBy.mockResolvedValue(mockDoctor);
      // Simulate existing conflicting appointment found via QueryBuilder
      mockQueryBuilder.getOne.mockResolvedValue(mockAppointment);

      // Act & Assert
      await expect(handler.execute(command)).rejects.toThrow(ConflictException);
      
      // Ensure we don't save
      expect(appointmentRepository.save).not.toHaveBeenCalled();
      expect(eventBus.publish).not.toHaveBeenCalled();
    });

    it('should throw InternalServerErrorException (or propagate error) on unexpected DB errors', async () => {
       // Arrange
       mockDoctorRepository.findOneBy.mockResolvedValue(mockDoctor);
       mockQueryBuilder.getOne.mockResolvedValue(null);
       mockAppointmentRepository.create.mockReturnValue(mockAppointment);
       
       // Simulate DB crash during save
       mockAppointmentRepository.save.mockRejectedValue(new InternalServerErrorException('DB Connection Failed'));
 
       // Act & Assert
       await expect(handler.execute(command)).rejects.toThrow(InternalServerErrorException);
    });
  });
});