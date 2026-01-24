import { Test, TestingModule } from '@nestjs/testing';
import { CreatePatientRootHandler } from './create-patient-root.handler';
import { PatientService } from '../../../services/patient.service';
import { CreatePatientRootCommand } from '../impl/create-patient-root.command';

/**
 * Unit Test: CreatePatientRootHandler
 * * Goal: Verify that the CQRS Handler correctly calls the Domain Service.
 */
describe('CreatePatientRootHandler', () => {
  let handler: CreatePatientRootHandler;
  let service: PatientService;

  const mockPatientService = {
    createRootPatient: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreatePatientRootHandler,
        { provide: PatientService, useValue: mockPatientService },
      ],
    }).compile();

    handler = module.get<CreatePatientRootHandler>(CreatePatientRootHandler);
    service = module.get<PatientService>(PatientService);
  });

  it('should call service.createRootPatient with correct data', async () => {
    const command = new CreatePatientRootCommand('user-123', 'test@uce.edu.ec');
    
    await handler.execute(command);

    expect(service.createRootPatient).toHaveBeenCalledWith('user-123', 'test@uce.edu.ec');
  });
});