import { Test, TestingModule } from '@nestjs/testing';
import { AppService } from './app.service';

// 1. MOCK DE SUPABASE
const mockSupabaseClient = {
  from: jest.fn().mockReturnThis(),
  insert: jest.fn().mockResolvedValue({ error: null }),
};

// Interceptamos la librería
jest.mock('@supabase/supabase-js', () => ({
  createClient: jest.fn(() => mockSupabaseClient),
}));

describe('AppService', () => {
  let service: AppService;

  beforeEach(async () => {
    // Simulamos env vars
    process.env.SUPABASE_URL = 'https://fake.supabase.co';
    process.env.SUPABASE_KEY = 'fake-key';

    const module: TestingModule = await Test.createTestingModule({
      providers: [AppService],
    }).compile();

    service = module.get<AppService>(AppService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  // ✅ TEST CORREGIDO: Usamos getHello(), NO getData()
  it('should return "Running" message', () => {
    expect(service.getHello()).toContain('Running');
  });

  it('should detect infection if symptoms include fever', async () => {
    const data = {
      appointmentId: '123',
      qrData: 'abc',
      symptoms: ['dolor de cabeza', 'fiebre alta'],
    };

    await service.processTriage(data);

    expect(mockSupabaseClient.from).toHaveBeenCalledWith('triage_records');
    expect(mockSupabaseClient.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        ai_pre_diagnosis: 'POSIBLE INFECCION',
      })
    );
  });

  it('should verify routine checkup for mild symptoms', async () => {
    const data = {
      appointmentId: '456',
      qrData: 'xyz',
      symptoms: ['cansancio'],
    };

    await service.processTriage(data);

    expect(mockSupabaseClient.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        ai_pre_diagnosis: 'REVISION RUTINA',
      })
    );
  });
});