import { Test, TestingModule } from '@nestjs/testing';
import { Logger } from '@nestjs/common';
import { PublishAppointmentCreatedHandler } from './publish-appointment-created.handler';
import { AppointmentCreatedEvent } from '../impl/appointment-created.event';
import { of } from 'rxjs';

describe('PublishAppointmentCreatedHandler', () => {
  let handler: PublishAppointmentCreatedHandler;
  
  // Mocks
  let mockKafkaClient: any;
  let mockLogger: any;

  beforeEach(async () => {
    // 1. Configurar Mocks completos (incluyendo connect/subscribe para que no fallen los hooks)
    mockKafkaClient = {
      emit: jest.fn().mockReturnValue(of({})),
      connect: jest.fn().mockResolvedValue(true),
      subscribeToResponseOf: jest.fn(),
      close: jest.fn(),
    };

    mockLogger = {
      log: jest.fn(),
      error: jest.fn(),
      warn: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PublishAppointmentCreatedHandler,
        {
          provide: 'KAFKA_SERVICE_APPOINTMENT', // El token correcto
          useValue: mockKafkaClient,
        },
        // Opcional: Si quisieras mockear el logger interno, pero Nest lo maneja bien.
      ],
    }).compile();

    handler = module.get<PublishAppointmentCreatedHandler>(PublishAppointmentCreatedHandler);
    
    // IMPORTANTE: Silenciamos el logger real para no ensuciar la terminal con errores falsos
    (handler as any).logger = mockLogger;
  });

  it('should be defined', () => {
    expect(handler).toBeDefined();
  });

  describe('handle', () => {
    it('should transform the event and emit it to Kafka topic "booking.events"', async () => {
      // --- PREPARACIÓN ---
      const eventDate = new Date('2025-01-20T10:00:00Z');
      const event = new AppointmentCreatedEvent(
        'appt-123',
        'doc-456',
        'student-789',
        eventDate,
      );

      // 🔥 TRUCO CLAVE: Forzamos la conexión a TRUE manualmente
      // Accedemos a la propiedad privada usando 'as any' para saltar la restricción de TypeScript
      (handler as any).isKafkaConnected = true;

      // --- EJECUCIÓN ---
      await handler.handle(event);

      // --- VERIFICACIÓN ---
      expect(mockKafkaClient.emit).toHaveBeenCalledWith(
        'booking.events',
        expect.objectContaining({
          event_id: 'appt-123',
          type: 'booking.appointment_created',
          data: expect.objectContaining({
            appointment_id: 'appt-123',
            doctor_id: 'doc-456',
            student_id: 'student-789'
          })
        })
      );
    });

    it('should NOT emit if Kafka is disconnected', async () => {
      const event = new AppointmentCreatedEvent('1', '2', '3', new Date());

      // Simulamos desconexión
      (handler as any).isKafkaConnected = false;

      await handler.handle(event);

      // Verificamos que NO se llamó a emit
      expect(mockKafkaClient.emit).not.toHaveBeenCalled();
    });
  });
});