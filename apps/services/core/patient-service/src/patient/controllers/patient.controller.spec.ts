import { Test, TestingModule } from '@nestjs/testing';
import { PatientsController } from './controllers/patient.controller';
import { PatientService } from './services/patient.service';

describe('PatientController', () => {
  let controller: PatientsController;
  let service: PatientService;

  const mockPatient = {
    id: 'uuid-test-1',
    firstName: 'Gio',
    email: 'gio@test.com',
    userId: 'user-123',
    birthDate: '1995-05-15',
  };

  // Simulamos el Servicio completo
  const mockPatientService = {
    create: jest.fn().mockResolvedValue(mockPatient),
    findAll: jest.fn().mockResolvedValue([mockPatient]),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PatientsController],
      providers: [
        {
          provide: PatientService,
          useValue: mockPatientService,
        },
      ],
    }).compile();

    controller = module.get<PatientsController>(PatientsController);
    service = module.get<PatientService>(PatientService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('create', () => {
    it('debería llamar al servicio para crear un paciente', async () => {
      const dto = {
        firstName: 'Gio',
        lastName: 'Rodriguez',
        email: 'gio@test.com',
        userId: 'user-123',
        birthDate: '1995-05-15',
        phone: '0991234567',
      };

      const result = await controller.create(dto as any);
      
      expect(result).toEqual(mockPatient);
      expect(service.create).toHaveBeenCalledWith(dto);
    });
  });
});