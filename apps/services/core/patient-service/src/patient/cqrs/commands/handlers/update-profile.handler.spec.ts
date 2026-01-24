import { Test, TestingModule } from '@nestjs/testing';
import { UpdateProfileHandler } from './update-profile.handler';
import { PatientService } from '../../../services/patient.service';
import { UpdateProfileCommand } from '../impl/update-profile.command';
import { UpdateProfileDto } from '../../../dto/update-profile.dto';

/**
 * Unit Test: UpdateProfileHandler
 */
describe('UpdateProfileHandler', () => {
  let handler: UpdateProfileHandler;
  let service: PatientService;

  const mockService = {
    updateProfile: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UpdateProfileHandler,
        { provide: PatientService, useValue: mockService },
      ],
    }).compile();

    handler = module.get<UpdateProfileHandler>(UpdateProfileHandler);
    service = module.get<PatientService>(PatientService);
  });

  it('should delegate profile updates to the service', async () => {
    const dto = new UpdateProfileDto();
    dto.firstName = 'Test';
    const command = new UpdateProfileCommand('user-123', dto);

    await handler.execute(command);

    expect(service.updateProfile).toHaveBeenCalledWith('user-123', dto);
  });
});