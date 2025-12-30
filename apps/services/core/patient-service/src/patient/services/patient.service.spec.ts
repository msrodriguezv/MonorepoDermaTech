import { Test, TestingModule } from '@nestjs/testing';
import { PatientService } from './services/patient.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Patient } from './entities/patient.entity';
import { CreatePatientDto } from './dto/create-patient.dto';

// 1. MOCK DE LA BASE DE DATOS (Simulamos TypeORM)
const mockPatientRepository = {
  create: jest.fn().mockImplementation((dto) => dto),
  save: jest.fn().mockImplementation((patient) => Promise.resolve({ 
    id: 'uuid-test-123', 
    ...patient 
  })),
  findOne: jest.fn().mockResolvedValue(null), // Simulamos que no existe duplicado
  find: jest.fn().mockResolvedValue([]),
};

// 2. MOCK DE KAFKA (Simulamos el cliente de mensajes)
const mockKafkaClient = {
  emit: jest.fn(() => ({
    toPromise: jest.fn().mockResolvedValue('event_sent'), // Simulamos éxito
    subscribe: jest.fn(),
  })),
};

describe('PatientService', () => {
  let service: PatientService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PatientService,
        // Inyectamos los mocks en lugar de las conexiones reales
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

  // --- PRUEBA DEL REQUISITO DE TESIS ---
  it('should create a patient and try to emit a kafka event', async () => {
    const dto: CreatePatientDto = {
      userId: 'test-user-id',
      email: 'test@test.com',
      firstName: 'Test',
      lastName: 'User',
      birthDate: '2000-01-01',
      phone: '0999999999',
      medicalInfo: 'O+',
      allergies: ['None']
    };

    const result = await service.create(dto);

    // Verificamos que guardó en "Base de Datos"
    expect(result).toHaveProperty('id');
    expect(result.email).toEqual('test@test.com');
    
    // Verificamos que intentó llamar a Kafka (Requisito Event Driven)
    expect(mockKafkaClient.emit).toHaveBeenCalled();
  });
});