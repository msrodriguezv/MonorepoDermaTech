import { Test, TestingModule } from '@nestjs/testing';
import { PartnerController } from './partner.controller';
import { PartnerService } from '../services/partner.service';
import { ClientKafka } from '@nestjs/microservices';

describe('PartnerController', () => {
  let controller: PartnerController;
  let service: PartnerService;
  let kafkaClient: ClientKafka;

  // Mock del Servicio (Para aislar el controlador)
  const mockPartnerService = {
    getAvailablePartners: jest.fn(() => [{ id: 'TEST', name: 'Test Hospital' }]),
    processReferral: jest.fn((dto) => Promise.resolve({ success: true, data: { hospital: 'Test Hospital' } })),
  };

  const mockKafkaClient = {
    connect: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [PartnerController],
      providers: [
        {
          provide: PartnerService,
          useValue: mockPartnerService,
        },
        {
          provide: 'KAFKA_CLIENT',
          useValue: mockKafkaClient,
        },
      ],
    }).compile();

    controller = module.get<PartnerController>(PartnerController);
    service = module.get<PartnerService>(PartnerService);
    kafkaClient = module.get<ClientKafka>('KAFKA_CLIENT');
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('should connect to Kafka on init', async () => {
    await controller.onModuleInit();
    expect(kafkaClient.connect).toHaveBeenCalled();
  });

  it('should call getAvailablePartners', () => {
    controller.getPartners();
    expect(service.getAvailablePartners).toHaveBeenCalled();
  });

  it('should call processReferral', async () => {
    const dto = {
      patientId: '1',
      doctorId: 'D1',
      targetHospitalId: 'H1',
      reason: 'R1'
    };
    await controller.derivePatient(dto);
    expect(service.processReferral).toHaveBeenCalledWith(dto);
  });
});