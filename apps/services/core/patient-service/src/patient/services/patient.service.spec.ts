import { Test, TestingModule } from '@nestjs/testing';
// 1. Servicio: Está en la misma carpeta, usamos ./
import { PatientService } from './patient.service';
import { getRepositoryToken } from '@nestjs/typeorm';
// 2. Entidad: Salimos un nivel (../) a entities
import { Patient } from '../entities/patient.entity';
// 3. DTO: Salimos un nivel (../) a dto (ESTA ES LA CORRECCIÓN DE COPILOT)
import { CreatePatientDto } from '../dto/create-patient.dto';

// --- MOCKS ---
const mockPatientRepository = {
  create: jest.fn().mockImplementation((dto) => dto),
  save: jest.fn().mockImplementation((patient) => Promise.resolve({ 
    id: 'uuid-test-123', 
    ...patient 
  })),
  findOne: jest.fn().mockResolvedValue(null),
  find: jest.fn().mockResolvedValue([]),
  merge: jest.fn(),
  remove: jest.fn(),
};

const mockKafkaClient = {
  emit: jest.fn(() => ({
    toPromise: jest.fn().mockResolvedValue('event_sent'),
    subscribe: jest.fn(),
  })),
};

describe('PatientService', () => {
  let service: PatientService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PatientService,
        {
          provide: getRepositoryToken(Patient),
          useValue: mockPatientRepository,
        },
        {
          provide: 'PATIENT_KAFKA_CLIENT',
          useValue: mockKafkaClient,
        },
      ],
    }).compile();

    service = module.get<PatientService>(PatientService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should create a patient and try to emit a kafka event', async () => {
    const dto: CreatePatientDto = {
      userId: 'test-user-id',
      email: 'test@test.com',
      firstName: 'Test',
      lastName: 'User',
      birthDate: '2000-01-01',
      phone: '0999999999',
      medicalInfo: { bloodType: 'O+' },
      allergies: ['None']
    };

    const result = await service.create(dto);

    expect(result).toBeDefined();
    expect(result).toHaveProperty('id');
    expect(result?.email).toEqual('test@test.com'); // Uso de ?. seguro
    
    expect(mockKafkaClient.emit).toHaveBeenCalled();
  });
});