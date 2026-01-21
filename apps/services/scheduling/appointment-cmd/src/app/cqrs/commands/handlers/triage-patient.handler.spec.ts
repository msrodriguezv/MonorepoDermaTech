import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException } from '@nestjs/common';

import { TriagePatientHandler } from './triage-patient.handler';
import { TriagePatientCommand } from '../impl/triage-patient.command';
import { Appointment, AppointmentStatus } from '../../../entities/appointment.entity';
import { TriageDecisionDto, TriageOutcome } from '../../../dto/triage-decision.dto';

describe('TriagePatientHandler', () => {
  let handler: TriagePatientHandler;
  let repo: Repository<Appointment>;

  // Mocking the Database Repository
  // We don't want to hit the real DB during unit tests
  const mockRepo = {
    findOneBy: jest.fn(),
    save: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TriagePatientHandler,
        {
          provide: getRepositoryToken(Appointment),
          useValue: mockRepo,
        },
      ],
    }).compile();

    handler = module.get<TriagePatientHandler>(TriagePatientHandler);
    repo = module.get<Repository<Appointment>>(getRepositoryToken(Appointment));
  });

  it('should be defined', () => {
    expect(handler).toBeDefined();
  });

  it('should successfully triage a patient to the doctor', async () => {
    // ARRANGE: Prepare data
    const command = new TriagePatientCommand('appointment-123', {
      outcome: TriageOutcome.PASS_TO_DOCTOR,
      notes: 'Patient stable',
    });

    const existingAppointment = new Appointment();
    existingAppointment.id = 'appointment-123';
    existingAppointment.status = AppointmentStatus.SCHEDULED;

    // Mock DB responses
    mockRepo.findOneBy.mockResolvedValue(existingAppointment);
    mockRepo.save.mockImplementation((a) => Promise.resolve(a));

    // ACT: Execute logic
    const result = await handler.execute(command);

    // ASSERT: Verify results
    expect(repo.findOneBy).toHaveBeenCalledWith({ id: 'appointment-123' });
    expect(result.status).toEqual(AppointmentStatus.WAITING_FOR_DOCTOR); // Check state change
    expect(result.nurseNotes).toEqual('Patient stable');
    expect(repo.save).toHaveBeenCalled();
  });

  it('should throw NotFoundException if appointment does not exist', async () => {
    // ARRANGE
    const command = new TriagePatientCommand('wrong-id', {
      outcome: TriageOutcome.PASS_TO_DOCTOR,
    });

    mockRepo.findOneBy.mockResolvedValue(null); // DB returns nothing

    // ACT & ASSERT
    await expect(handler.execute(command)).rejects.toThrow(NotFoundException);
  });
});