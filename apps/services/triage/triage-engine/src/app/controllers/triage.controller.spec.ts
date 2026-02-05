import { Test, TestingModule } from '@nestjs/testing';
import { TriageController } from './triage.controller';
import { TriageService } from '../services/triage.service';
import { AppointmentCreatedPayload } from '../dto/triage.dto';
import { KafkaContext } from '@nestjs/microservices';

describe('TriageController', () => {
  let controller: TriageController;
  let service: TriageService;

  // 1. Mock estricto del Servicio
  const mockTriageService = {
    processAppointmentEvent: jest.fn().mockResolvedValue(undefined),
  };

  // 2. Mock estricto del Contexto Kafka
  const mockKafkaContext = {
    getTopic: jest.fn().mockReturnValue('booking.appointment_created'),
    getMessage: jest.fn().mockReturnValue({}),
    getPartition: jest.fn().mockReturnValue(0),
    getArgs: jest.fn(),
    getArgByIndex: jest.fn(),
  } as unknown as KafkaContext;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [TriageController],
      providers: [
        {
          provide: TriageService,
          useValue: mockTriageService,
        },
      ],
    }).compile();

    controller = module.get<TriageController>(TriageController);
    service = module.get<TriageService>(TriageService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('handleNewAppointment', () => {
    it('should call service.processAppointmentEvent when payload is valid', async () => {
      // --- ARRANGE ---
      const payload: AppointmentCreatedPayload = {
        appointment_id: 'appt-123',
        student_id: 'student-456',
        symptoms: 'Fiebre alta',
        doctor_id: 'doc-789',
        start_time: '2026-02-04T10:00:00Z',
      };

      // --- ACT ---
      await controller.handleNewAppointment(payload, mockKafkaContext);

      // --- ASSERT ---
      expect(service.processAppointmentEvent).toHaveBeenCalledWith(payload);
    });

    it('should skip processing if appointment_id is missing', async () => {
      // --- ARRANGE ---
      const invalidPayload = {
        student_id: 'student-456',
        symptoms: 'Fiebre',
      } as AppointmentCreatedPayload;

      // --- ACT ---
      await controller.handleNewAppointment(invalidPayload, mockKafkaContext);

      // --- ASSERT ---
      expect(service.processAppointmentEvent).not.toHaveBeenCalled();
    });

    it('should skip processing if symptoms are missing', async () => {
      // --- ARRANGE ---
      const invalidPayload = {
        appointment_id: 'appt-123',
        student_id: 'student-456',
      } as AppointmentCreatedPayload;

      // --- ACT ---
      await controller.handleNewAppointment(invalidPayload, mockKafkaContext);

      // --- ASSERT ---
      expect(service.processAppointmentEvent).not.toHaveBeenCalled();
    });
  });
});