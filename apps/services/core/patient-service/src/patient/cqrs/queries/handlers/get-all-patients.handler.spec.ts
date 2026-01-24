import { Test, TestingModule } from '@nestjs/testing';
import { GetAllPatientsHandler } from './get-all-patients.handler';
import { PatientService } from '../../../services/patient.service';
import { GetAllPatientsQuery } from '../impl/get-all-patients.query';
import { Patient } from '../../../entities/patient.entity';

describe('GetAllPatientsHandler', () => {
  let handler: GetAllPatientsHandler;
  let patientService: PatientService;

  // Mock Data: Represents a dummy patient record for testing assertions.
  const mockPatientArray: Patient[] = [
    {
      id: 'uuid-1',
      userId: 'auth-uid-1',
      email: 'student@uce.edu.ec',
      firstName: 'John',
      lastName: 'Doe',
      isProfileComplete: true,
      createdAt: new Date(),
      updatedAt: new Date(),
      // ... include other required fields as per your Entity definition if strict mode complains
    } as Patient,
  ];

  // Mock Service: Intercepts calls to PatientService methods.
  const mockPatientService = {
    findAll: jest.fn().mockResolvedValue(mockPatientArray),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetAllPatientsHandler,
        {
          provide: PatientService,
          useValue: mockPatientService,
        },
      ],
    }).compile();

    handler = module.get<GetAllPatientsHandler>(GetAllPatientsHandler);
    patientService = module.get<PatientService>(PatientService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(handler).toBeDefined();
  });

  it('should call PatientService.findAll and return a list of patients', async () => {
    // Arrange
    const query = new GetAllPatientsQuery();

    // Act
    const result = await handler.execute(query);

    // Assert
    expect(patientService.findAll).toHaveBeenCalledTimes(1);
    expect(result).toEqual(mockPatientArray);
    expect(result.length).toBe(1);
  });
});