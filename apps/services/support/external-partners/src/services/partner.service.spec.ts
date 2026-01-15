import { Test, TestingModule } from '@nestjs/testing';
import { PartnerService } from './partner.service';
import { ClientKafka } from '@nestjs/microservices';
import { NotFoundException } from '@nestjs/common';

describe('PartnerService', () => {
  let service: PartnerService;
  let kafkaClient: ClientKafka;

  const mockKafkaClient = {
    emit: jest.fn(),
    connect: jest.fn(),
  };

  beforeEach(async () => {
    // 🧹 LIMPIEZA VITAL PARA QUE NO FALLEN LOS TESTS
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PartnerService,
        {
          provide: 'KAFKA_CLIENT',
          useValue: mockKafkaClient,
        },
      ],
    }).compile();

    service = module.get<PartnerService>(PartnerService);
    kafkaClient = module.get<ClientKafka>('KAFKA_CLIENT');
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('processReferral', () => {
    it('should process referral and emit Kafka event if hospital exists', async () => {
      const dto = {
        patientId: 'STUDENT-123',
        doctorId: 'DOC-MARIA',
        targetHospitalId: 'HOSPITAL-METRO',
        reason: 'Emergency',
      };

      const result = await service.processReferral(dto);

      expect(result.success).toBe(true);
      // Expect English name
      expect(result.data.hospital).toBe('Metropolitan Hospital');
      
      expect(kafkaClient.emit).toHaveBeenCalledWith(
        'referral.processed', 
        expect.objectContaining({
          hospitalName: 'Metropolitan Hospital'
        })
      );
    });

    it('should throw NotFoundException if hospital does not exist', async () => {
      const dto = {
        patientId: 'STUDENT-123',
        doctorId: 'DOC-MARIA',
        targetHospitalId: 'UNKNOWN-HOSPITAL',
        reason: 'Flu',
      };

      // Expect specific NestJS Exception
      await expect(service.processReferral(dto)).rejects.toThrow(NotFoundException);
      
      // Verify Kafka was NOT called
      expect(kafkaClient.emit).not.toHaveBeenCalled();
    });
  });
});