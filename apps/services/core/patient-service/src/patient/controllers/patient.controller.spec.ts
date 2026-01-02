import { Test, TestingModule } from '@nestjs/testing';
import { PatientsController } from './patient.controller';
import { PatientService } from '../services/patient.service';
import { CommandBus, QueryBus } from '@nestjs/cqrs';
import { CreatePatientDto } from '../dto/create-patient.dto';

describe('PatientsController', () => {
  let controller: PatientsController;
  let commandBus: CommandBus;

  // Mock  CommandBus 
  const mockCommandBus = { execute: jest.fn() };
  const mockQueryBus = { execute: jest.fn() };
  
  // Mock service
  const mockPatientService = {
    findAll: jest.fn(),
    findOne: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PatientsController],
      providers: [
        { provide: CommandBus, useValue: mockCommandBus },
        { provide: QueryBus, useValue: mockQueryBus },
        { provide: PatientService, useValue: mockPatientService },
      ],
    }).compile();

    controller = module.get<PatientsController>(PatientsController);
    commandBus = module.get<CommandBus>(CommandBus);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('create', () => {
    it('debería ejecutar un Command a través del CommandBus', async () => {
      const dto: CreatePatientDto = {
        userId: 'user-123',
        email: 'gio@test.com',
        firstName: 'Gio',
        lastName: 'Rodriguez',
        birthDate: '1995-05-15',
        phone: '0991234567',
        medicalInfo: { bloodType: 'O+' },
        allergies: ['None'],
        insuranceProvider: 'IESS'
      };

      const expectedResult = { id: 'uuid-123', ...dto };
      mockCommandBus.execute.mockResolvedValue(expectedResult);

      const result = await controller.create(dto);

      expect(result).toEqual(expectedResult);
      expect(mockCommandBus.execute).toHaveBeenCalled(); 
    });
  });
});