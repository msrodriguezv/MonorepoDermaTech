import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';

describe('AppController', () => {
  let appController: AppController;

  // Creamos un Mock del servicio (aunque tu controlador aún no lo use en el cuerpo de las funciones, el constructor lo pide)
  const mockAppService = {
    getHello: jest.fn().mockReturnValue('Hello'),
  };

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        {
          provide: AppService,
          useValue: mockAppService,
        },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  it('should be defined', () => {
    expect(appController).toBeDefined();
  });

  // 1. Prueba de descubrimiento de Partners
  describe('getAvailablePartners', () => {
    it('should return a list of medical partners', () => {
      const result = appController.getAvailablePartners();
      expect(Array.isArray(result)).toBe(true);
      expect(result[0]).toHaveProperty('name', 'Saint Mary Clinic');
    });
  });

  // 2. Prueba de creación de Referral (Referencia médica)
  describe('createReferral', () => {
    it('should create a referral and return a tracking ID', () => {
      const mockDto = { patientId: 'p-123', targetPartnerId: 'CLINIC-1' } as any;
      const result = appController.createReferral(mockDto);
      expect(result.success).toBe(true);
      expect(result.data.referralId).toContain('REF-');
    });
  });

  // 3. Prueba de estado de la referencia
  describe('checkReferralStatus', () => {
    it('should return the status of a specific referral', () => {
      const result = appController.checkReferralStatus('REF-123');
      expect(result.referralId).toBe('REF-123');
      expect(result.status).toBe('ACCEPTED');
    });
  });

  // 4. Prueba del Webhook
  describe('handlePartnerWebhook', () => {
    it('should acknowledge the received event', () => {
      const mockPayload = { eventType: 'STATUS_CHANGED', data: {} } as any;
      const result = appController.handlePartnerWebhook(mockPayload);
      expect(result.received).toBe(true);
      expect(result).toHaveProperty('processingId');
    });
  });
});