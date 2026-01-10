import { Test, TestingModule } from '@nestjs/testing';
import { EventBus } from '@nestjs/cqrs';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository, LessThan, MoreThan } from 'typeorm';
import { NotFoundException, ConflictException, BadRequestException, InternalServerErrorException, Logger } from '@nestjs/common';

import { BookAppointmentHandler } from './book-appointment.handler';
import { BookAppointmentCommand } from '../impl/book-appointment.command';
import { Appointment, AppointmentStatus } from '../../../entities/appointment.entity';
import { Doctor } from '../../../entities/doctor.entity';
import { AppointmentCreatedEvent } from '../../events/impl/appointment-created.event';

/**
 * Unit Test: BookAppointmentHandler
 * Scope: 
 * - Verifies booking logic (Time validation, Doctor status, Overlaps).
 * - Ensures Event publishing.
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
  const startTime = new Date('2025-01-20T10:00:00Z');
  const endTime = new Date('2025-01-20T10:30:00Z');

  const mockDto = {
    doctorId: mockDoctorId,
    startTime: startTime.toISOString(),
    endTime: endTime.toISOString(),
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
    startTime: startTime,
    endTime: endTime,
    status: AppointmentStatus.SCHEDULED,
    createdAt: new Date(),
  } as Appointment;

  // Mocks Definitions
  const mockAppointmentRepository = {
    create: jest.fn(),
    save: jest.fn(),
    findOne: jest.fn(), // Used for Overlap Check
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
      mockAppointmentRepository.findOne.mockResolvedValue(null);    // No conflicts
      mockAppointmentRepository.create.mockReturnValue(mockAppointment);
      mockAppointmentRepository.save.mockResolvedValue(mockAppointment);

      // Act
      const result = await handler.execute(command);

      // Assert
      // 1. Doctor Validation
      expect(doctorRepository.findOneBy).toHaveBeenCalledWith({ id: mockDoctorId });
      
      // 2. Overlap Check (TypeORM syntax verification)
      expect(appointmentRepository.findOne).toHaveBeenCalledWith({
        where: {
          doctorId: mockDoctorId,
          status: AppointmentStatus.SCHEDULED,
          startTime: LessThan(new Date(mockDto.endTime)),
          endTime: MoreThan(new Date(mockDto.startTime)),
        }
      });

      // 3. Persistence
      expect(appointmentRepository.create).toHaveBeenCalled();
      expect(appointmentRepository.save).toHaveBeenCalled();

      // 4. Event Publishing
      expect(eventBus.publish).toHaveBeenCalledWith(expect.any(AppointmentCreatedEvent));
      
      expect(result).toEqual(mockAppointment);
    });

    it('should throw BadRequestException if Start Time is >= End Time', async () => {
      // Arrange: Invalid time
      const badDto = { ...mockDto, endTime: mockDto.startTime }; // Equal times
      const badCommand = new BookAppointmentCommand(mockStudentId, badDto);

      // Act & Assert
      await expect(handler.execute(badCommand)).rejects.toThrow(BadRequestException);
      expect(doctorRepository.findOneBy).not.toHaveBeenCalled();
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
      // Simulate existing conflicting appointment found in DB
      mockAppointmentRepository.findOne.mockResolvedValue(mockAppointment);

      // Act & Assert
      await expect(handler.execute(command)).rejects.toThrow(ConflictException);
      // Ensure we don't save
      expect(appointmentRepository.save).not.toHaveBeenCalled();
    });

    it('should throw InternalServerErrorException on unexpected DB errors', async () => {
        // Arrange
        mockDoctorRepository.findOneBy.mockResolvedValue(mockDoctor);
        mockAppointmentRepository.findOne.mockResolvedValue(null);
        
        // Simulate DB crash during save
        mockAppointmentRepository.save.mockRejectedValue(new Error('DB Connection Failed'));
  
        // Act & Assert
        await expect(handler.execute(command)).rejects.toThrow(InternalServerErrorException);
    });
  });
});