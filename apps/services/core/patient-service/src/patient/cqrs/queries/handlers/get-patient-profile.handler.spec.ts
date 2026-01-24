import { Test, TestingModule } from '@nestjs/testing';
import { GetPatientProfileHandler } from './get-patient-profile.handler';
import { PatientService } from '../../../services/patient.service';
import { GetPatientProfileQuery } from '../impl/get-patient-profile.query';

describe('GetPatientProfileHandler', () => {
  let handler: GetPatientProfileHandler;
  let service: PatientService;

  const mockService = {
    findByUserId: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetPatientProfileHandler,
        { provide: PatientService, useValue: mockService },
      ],
    }).compile();

    handler = module.get<GetPatientProfileHandler>(GetPatientProfileHandler);
    service = module.get<PatientService>(PatientService);
  });

  it('should call service.findByUserId with correct ID', async () => {
    const userId = 'user-123';
    const query = new GetPatientProfileQuery(userId);
    
    await handler.execute(query);

    expect(service.findByUserId).toHaveBeenCalledWith(userId);
  });
});