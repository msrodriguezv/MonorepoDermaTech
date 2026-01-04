import { Test, TestingModule } from '@nestjs/testing';
import { PatientController } from './patient.controller';
import { CommandBus, QueryBus } from '@nestjs/cqrs';
import { JwtAuthGuard, RolesGuard } from '@dermatech/shared-guards';
import { UserRole } from '@dermatech/shared-dtos';

// Import Commands and Queries used in the controller
import { UpdateProfileCommand } from '../cqrs/commands/impl/update-profile.command';
import { GetPatientProfileQuery } from '../cqrs/queries/impl/get-patient-profile.query';
import { UpdateProfileDto } from '../dto/update-profile.dto.'; // Adjust path if necessary (removed extra dot if typo)

describe('PatientController', () => {
  let controller: PatientController;
  let commandBus: CommandBus;
  let queryBus: QueryBus;

  // Mocks for CQRS buses
  const mockCommandBus = { execute: jest.fn() };
  const mockQueryBus = { execute: jest.fn() };

  beforeEach(async () => {
    // Reset mocks before each test to ensure clean state
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [PatientController],
      providers: [
        { provide: CommandBus, useValue: mockCommandBus },
        { provide: QueryBus, useValue: mockQueryBus },
      ],
    })
    // Override Guards to bypass security logic during unit testing
    .overrideGuard(JwtAuthGuard)
    .useValue({ canActivate: () => true })
    .overrideGuard(RolesGuard)
    .useValue({ canActivate: () => true })
    .compile();

    controller = module.get<PatientController>(PatientController);
    commandBus = module.get<CommandBus>(CommandBus);
    queryBus = module.get<QueryBus>(QueryBus);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  /**
   * Test for: @Put('me') updateMyProfile
   */
  it('should dispatch UpdateProfileCommand when calling updateMyProfile', async () => {
    // 1. Mock User extracted from Token
    const mockUser = { sub: 'user-123', email: 'student@uce.edu.ec', role: UserRole.STUDENT };
    
    // 2. Mock DTO body
    const mockDto = new UpdateProfileDto();
    mockDto.firstName = 'Jefferson';
    
    // 3. Execute Controller Method
    await controller.updateMyProfile(mockUser, mockDto);

    // 4. Verify CommandBus was called with correct arguments
    expect(commandBus.execute).toHaveBeenCalledTimes(1);
    expect(commandBus.execute).toHaveBeenCalledWith(expect.any(UpdateProfileCommand));
    
    // Optional: Verify the Command contains the correct data
    expect(commandBus.execute).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'user-123', dto: mockDto })
    );
  });

  /**
   * Test for: @Get('me') getMyProfile
   */
  it('should dispatch GetPatientProfileQuery when calling getMyProfile', async () => {
    // 1. Mock User extracted from Token
    const mockUser = { sub: 'user-123', email: 'student@uce.edu.ec', role: UserRole.STUDENT };

    // 2. Execute Controller Method
    await controller.getMyProfile(mockUser);

    // 3. Verify QueryBus was called
    expect(queryBus.execute).toHaveBeenCalledTimes(1);
    expect(queryBus.execute).toHaveBeenCalledWith(expect.any(GetPatientProfileQuery));
    
    // Optional: Verify the Query contains the correct userId
    expect(queryBus.execute).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'user-123' })
    );
  });
});