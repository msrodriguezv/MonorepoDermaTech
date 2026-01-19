import { Test, TestingModule } from '@nestjs/testing';
import { AppService } from './app.service';
import { HttpService } from '@nestjs/axios';
import { of } from 'rxjs';

// 1. MOCK DE SUPABASE
const mockSupabaseClient = {
  from: jest.fn().mockReturnThis(),
  insert: jest.fn().mockResolvedValue({ error: null }),
};

// Interceptamos la librería de Supabase
jest.mock('@supabase/supabase-js', () => ({
  createClient: jest.fn(() => mockSupabaseClient),
}));

describe('AppService', () => {
  let service: AppService;
  let httpService: HttpService;

  // 2. MOCK DE HTTP SERVICE (Para n8n)
  const mockHttpService = {
    post: jest.fn(),
  };

  beforeEach(async () => {
    // Simulamos variables de entorno necesarias
    process.env.SUPABASE_URL = 'https://fake.supabase.co';
    process.env.SUPABASE_KEY = 'fake-key';
    process.env.N8N_WEBHOOK_URL = 'http://fake-n8n.com';

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AppService,
        {
          provide: HttpService,
          useValue: mockHttpService, // Inyectamos el mock en lugar del real
        },
      ],
    }).compile();

    service = module.get<AppService>(AppService);
    httpService = module.get<HttpService>(HttpService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should return "Running" message', () => {
    expect(service.getHello()).toContain('Running');
  });

  it('should detect infection if symptoms include fever', async () => {
    const data = {
      appointmentId: '123',
      qrData: 'abc',
      symptoms: ['dolor de cabeza', 'fever alta'],
    };

    // SIMULAMOS que n8n responde con éxito y da el diagnóstico esperado
    mockHttpService.post.mockReturnValue(of({ 
      data: { diagnosis: 'POSIBLE INFECCION' } 
    }));

    await service.processTriage(data);

    expect(mockSupabaseClient.from).toHaveBeenCalledWith('triage_records');
    expect(mockSupabaseClient.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        ai_pre_diagnosis: 'POSIBLE INFECCION', // Ahora sí recibirá esto
      })
    );
  });

  it('should verify routine checkup for mild symptoms', async () => {
    const data = {
      appointmentId: '456',
      qrData: 'xyz',
      symptoms: ['cansancio'],
    };

    // SIMULAMOS que n8n responde con un diagnóstico de rutina
    mockHttpService.post.mockReturnValue(of({ 
      data: { diagnosis: 'REVISION RUTINA' } 
    }));

    await service.processTriage(data);

    expect(mockSupabaseClient.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        ai_pre_diagnosis: 'REVISION RUTINA',
      })
    );
  });
});