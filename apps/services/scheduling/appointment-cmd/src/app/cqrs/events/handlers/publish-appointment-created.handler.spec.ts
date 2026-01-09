import { Test, TestingModule } from '@nestjs/testing';
import { ClientKafka } from '@nestjs/microservices';
import { Logger } from '@nestjs/common';
import { PublishAppointmentCreatedHandler } from './publish-appointment-created.handler';
import { AppointmentCreatedEvent } from '../impl/appointment-created.event';

/**
 * Unit Test: PublishAppointmentCreatedHandler
 * Scope: 
 * - Verifies that internal domain events are correctly transformed into integration events.
 * - Ensures the Kafka Client 'emit' method is called with the correct topic and payload.
 */
describe('PublishAppointmentCreatedHandler', () => {
  let handler: PublishAppointmentCreatedHandler;
  let kafkaClient: ClientKafka;

  // Mock Data
  const eventDate = new Date('2025-01-20T10:00:00Z');
  const internalEvent = new AppointmentCreatedEvent(
    'appt-123',
    'doc-456',
    'student-789',
    eventDate,
  );

  // Mock Kafka Client
  const mockKafkaClient = {
    emit: jest.fn(),
  };

  const mockLogger = {
    log: jest.fn(),
    error: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PublishAppointmentCreatedHandler,
        {
          provide: 'KAFKA_SERVICE', // Must match the @Inject token in the handler
          useValue: mockKafkaClient,
        },
        {
          provide: Logger,
          useValue: mockLogger,
        },
      ],
    }).compile();

    handler = module.get<PublishAppointmentCreatedHandler>(PublishAppointmentCreatedHandler);
    kafkaClient = module.get<ClientKafka>('KAFKA_SERVICE');
  });

  it('should be defined', () => {
    expect(handler).toBeDefined();
  });

  describe('handle', () => {
    it('should transform the event and emit it to Kafka topic "booking.events"', async () => {
      // Act
      await handler.handle(internalEvent);

      // Assert
      // 1. Verify the Topic Name
      expect(kafkaClient.emit).toHaveBeenCalledWith(
        'booking.events',
        expect.any(Object) // We check the payload structure below
      );

      // 2. Verify Payload Structure (The Contract)
      const expectedPayload = {
        event_id: 'appt-123',
        type: 'booking.appointment_created',
        data: {
          appointment_id: 'appt-123',
          doctor_id: 'doc-456',
          student_id: 'student-789',
          start_time: eventDate,
        },
      };

      // We access the second argument of the first call to 'emit'
      const actualPayload = (kafkaClient.emit as jest.Mock).mock.calls[0][1];
      
      // We match specific fields, ignoring 'occurred_on' dynamic date
      expect(actualPayload).toEqual(expect.objectContaining({
        event_id: expectedPayload.event_id,
        type: expectedPayload.type,
        data: expectedPayload.data,
      }));
    });
  });
});