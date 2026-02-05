import { Test, TestingModule } from '@nestjs/testing';
import { TriageService } from './triage.service';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TriageRecord } from '../entities/triage-record.entity';
import { of } from 'rxjs';
import { AxiosResponse } from 'axios';
import { AppointmentCreatedPayload, AiDiagnosisResponse, QrGenerationResponse } from '../dto/triage.dto';

// 1. Definimos el Payload Mock COMPLETO según la interfaz
const mockPayload: AppointmentCreatedPayload = {
  appointment_id: 'appt-123',
  student_id: 'student-456',
  symptoms: 'Fiebre alta y dolor de cabeza',
  doctor_id: 'doc-789',    
  start_time: '2026-02-04T10:00:00Z',
};

describe('TriageService', () => {
  let service: TriageService;
  let httpService: HttpService;
  let triageRepo: Repository<TriageRecord>;

  // 2. Definición de Mocks con Tipado Estricto
  const mockTriageRepo = {
    create: jest.fn(),
    save: jest.fn(),
  };

  const mockHttpService = {
    post: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn((key: string, defaultValue?: string) => defaultValue),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TriageService,
        {
          provide: getRepositoryToken(TriageRecord),
          useValue: mockTriageRepo,
        },
        {
          provide: HttpService,
          useValue: mockHttpService,
        },
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
      ],
    }).compile();

    service = module.get<TriageService>(TriageService);
    httpService = module.get<HttpService>(HttpService);
    triageRepo = module.get<Repository<TriageRecord>>(getRepositoryToken(TriageRecord));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('processAppointmentEvent', () => {
    it('should orchestrate AI and QR calls and save the record', async () => {
      // --- ARRANGE ---
      
      // Mock AI Response
      const aiData: AiDiagnosisResponse = { 
        diagnosis: 'POSIBLE INFECCION', 
        priority_level: 1, 
        confidence: 0.9 
      };
      
      const aiResponse: AxiosResponse<AiDiagnosisResponse> = {
        data: aiData,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: { headers: {} as undefined },
      };

      // Mock QR Response
      const qrData: QrGenerationResponse = { 
        qr_code_base64: 'base64string...', 
        qr_content: 'test' 
      };

      const qrResponse: AxiosResponse<QrGenerationResponse> = {
        data: qrData,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: { headers: {} as undefined },
      };

      // Configuramos el mock para devolver Observables secuenciales
      jest.spyOn(mockHttpService, 'post')
        .mockReturnValueOnce(of(aiResponse)) // Primera llamada (AI)
        .mockReturnValueOnce(of(qrResponse)); // Segunda llamada (QR)

      // Mock del Repo create/save
      mockTriageRepo.create.mockReturnValue({ ...mockPayload, aiPreDiagnosis: aiData.diagnosis });
      mockTriageRepo.save.mockResolvedValue({ id: 1, ...mockPayload });

      // --- ACT ---
      await service.processAppointmentEvent(mockPayload);

      // --- ASSERT ---
      expect(httpService.post).toHaveBeenCalledTimes(2);
      
      expect(triageRepo.create).toHaveBeenCalledWith(expect.objectContaining({
        appointmentId: mockPayload.appointment_id,
        studentId: mockPayload.student_id,
        aiPreDiagnosis: 'POSIBLE INFECCION',
        qrCode: 'base64string...',
      }));
      
      expect(triageRepo.save).toHaveBeenCalled();
    });

    it('should handle API failures gracefully and save default values', async () => {
      // --- ARRANGE ---
      // Simulamos error lanzando excepción al intentar hacer post
      jest.spyOn(mockHttpService, 'post').mockImplementation(() => {
        throw new Error('Service Unavailable');
      });

      mockTriageRepo.create.mockReturnValue({ ...mockPayload, aiPreDiagnosis: 'PENDIENTE REVISION' });

      // --- ACT ---
      await service.processAppointmentEvent(mockPayload);

      // --- ASSERT ---
      // Debe guardar valores por defecto definidos en el try/catch del servicio
      expect(triageRepo.create).toHaveBeenCalledWith(expect.objectContaining({
        appointmentId: mockPayload.appointment_id,
        aiPreDiagnosis: 'PENDIENTE REVISION', // Fallback
        qrCode: null, // Fallback
      }));

      expect(triageRepo.save).toHaveBeenCalled();
    });
  });
});