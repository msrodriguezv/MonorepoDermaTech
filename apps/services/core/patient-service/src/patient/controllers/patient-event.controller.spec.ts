import { Test, TestingModule } from '@nestjs/testing';
import { CommandBus } from '@nestjs/cqrs';
import { PatientEventController } from './patient-event.controller';
import { UserRegisteredEvent } from '@dermatech/event-contracts';
import { UserRole } from '@dermatech/shared-dtos';
import { CreatePatientRootCommand } from '../cqrs/commands/impl/create-patient-root.command';

describe('PatientEventController', () => {
  let controller: PatientEventController;
  let commandBus: CommandBus;

  const mockCommandBus = {
    execute: jest.fn(),
  };

  beforeEach(async () => {
    // 1. Reset mocks before configuring the module to avoid "polluted" state from previous tests
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [PatientEventController],
      providers: [
        { provide: CommandBus, useValue: mockCommandBus },
      ],
    }).compile();

    controller = module.get<PatientEventController>(PatientEventController);
    commandBus = module.get<CommandBus>(CommandBus);
  });

  it('should dispatch CreatePatientRootCommand when role is STUDENT', async () => {
    const event = new UserRegisteredEvent('user-1', 'student@uce.edu.ec', UserRole.STUDENT);

    await controller.handleUserRegistered(event);

    expect(commandBus.execute).toHaveBeenCalledTimes(1);
    expect(commandBus.execute).toHaveBeenCalledWith(expect.any(CreatePatientRootCommand));
  });

  it('should NOT dispatch command if role is ADMIN', async () => {
    const event = new UserRegisteredEvent('user-2', 'admin@uce.edu.ec', UserRole.ADMIN);

    await controller.handleUserRegistered(event);

    // Now this will pass because we cleared the history in beforeEach
    expect(commandBus.execute).not.toHaveBeenCalled();
  });
});