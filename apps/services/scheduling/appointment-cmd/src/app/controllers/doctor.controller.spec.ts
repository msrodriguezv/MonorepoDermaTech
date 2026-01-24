import { Test, TestingModule } from '@nestjs/testing';
import { CommandBus } from '@nestjs/cqrs';
import { DoctorController } from './doctor.controller';
import { CreateDoctorDto } from '../dto/create-doctor.dto';
import { CreateDoctorCommand } from '../cqrs/commands/impl/create-doctor.command';
import { Doctor } from '../entities/doctor.entity';
import { Logger } from '@nestjs/common';

/**
 * Unit Test: DoctorController
 * Scope: 
 * - Verifies HTTP endpoint interaction.
 * - Ensures DTOs are passed correctly to the CommandBus.
 * - Guards are mocked out (Unit Test scope).
 */
describe('DoctorController', () => {
  let controller: DoctorController;
  let commandBus: CommandBus;

  // Mock Data
  const dto: CreateDoctorDto = {
    userId: 'user-123',
    firstName: 'Dr. House',
    lastName: 'Gregory',
    specialization: 'Diagnostic Medicine',
    licenseNumber: 'CMP-12345',
    officeNumber: '101'
  };

  const mockDoctorResult = {
    id: 'doc-uuid-1',
    ...dto,
    specialty: dto.specialization, // Mapped
    cmp: dto.licenseNumber,        // Mapped
    isActive: true,
  } as unknown as Doctor;

  // Mock CommandBus
  const mockCommandBus = {
    execute: jest.fn(),
  };

  const mockLogger = {
    log: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [DoctorController],
      providers: [
        {
          provide: CommandBus,
          useValue: mockCommandBus,
        },
        {
          provide: Logger,
          useValue: mockLogger,
        }
      ],
    }).compile();

    controller = module.get<DoctorController>(DoctorController);
    commandBus = module.get<CommandBus>(CommandBus);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('createDoctor (POST /doctors)', () => {
    it('should delegate execution to CommandBus and return the result', async () => {
      // Arrange
      mockCommandBus.execute.mockResolvedValue(mockDoctorResult);

      // Act
      const result = await controller.createDoctor(dto);

      // Assert
      // Verify that the controller wrapped the DTO in the correct Command
      expect(commandBus.execute).toHaveBeenCalledWith(expect.any(CreateDoctorCommand));
      
      // Strict check: Verify command payload
      const calledCommand = mockCommandBus.execute.mock.calls[0][0] as CreateDoctorCommand;
      expect(calledCommand.dto).toEqual(dto);

      expect(result).toEqual(mockDoctorResult);
    });

    it('should propagate exceptions thrown by the CommandHandler', async () => {
      // Arrange: Simulate Handler throwing an error (e.g. Conflict)
      const error = new Error('Doctor already exists');
      mockCommandBus.execute.mockRejectedValue(error);

      // Act & Assert
      await expect(controller.createDoctor(dto)).rejects.toThrow(error);
    });
  });
});