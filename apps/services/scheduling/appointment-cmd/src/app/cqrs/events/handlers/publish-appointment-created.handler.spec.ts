import { Test, TestingModule } from '@nestjs/testing';
import { ClientKafka } from '@nestjs/microservices';
import { PublishAppointmentCreatedHandler } from './publish-appointment-created.handler';
import { AppointmentCreatedEvent } from '../impl/appointment-created.event';
import { of } from 'rxjs';

describe('PublishAppointmentCreatedHandler', () => {
  let handler: PublishAppointmentCreatedHandler;
  let kafkaClient: ClientKafka;

  // Creamos un Mock tipado parcialmente para ClientKafka
  const mockKafkaClient: Partial<Record<keyof ClientKafka, jest.Mock>> = {
    emit: jest.fn().mockReturnValue(of({})),
    connect: jest.fn().mockResolvedValue(null),
    close: jest.fn().mockResolvedValue(null),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PublishAppointmentCreatedHandler,
        {
          provide: 'KAFKA_SERVICE_APPOINTMENT',
          useValue: mockKafkaClient,
        },
      ],
    }).compile();

    handler = module.get<PublishAppointmentCreatedHandler>(PublishAppointmentCreatedHandler);
    kafkaClient = module.get<ClientKafka>('KAFKA_SERVICE_APPOINTMENT');
  });

  it('should be defined', () => {
    expect(handler).toBeDefined();
  });

  describe('handle', () => {
    it('should connect via onModuleInit, transform the event and emit it to Kafka', async () => {
      // Arrange
      const eventDate = new Date('2025-01-20T10:00:00Z');
      const symptoms = 'Dolor de cabeza intenso';
      
      const event = new AppointmentCreatedEvent(
        'appt-123',
        'doc-456',
        'student-789',
        eventDate,
        symptoms,
      );

      // Act
      // 1. Simulamos el ciclo de vida real: NestJS llama a onModuleInit al arrancar.
      // Esto establece isKafkaConnected = true internamente sin usar hacks (as any).
      await handler.onModuleInit();
      
      // 2. Ejecutamos el handler
      await handler.handle(event);

      // Assert
      expect(kafkaClient.connect).toHaveBeenCalled();
      expect(kafkaClient.emit).toHaveBeenCalledWith(
        'booking.appointment_created',
        {
          appointment_id: 'appt-123',
          doctor_id: 'doc-456',
          student_id: 'student-789',
          start_time: eventDate.toISOString(),
          symptoms: symptoms,
        }
      );
    });

    it('should NOT emit if module has not been initialized (disconnected)', async () => {
      // Arrange
      const event = new AppointmentCreatedEvent(
        '1', '2', '3', new Date(), 'test symptoms'
      );

      await handler.handle(event);

      expect(kafkaClient.emit).not.toHaveBeenCalled();
    });
  });
});