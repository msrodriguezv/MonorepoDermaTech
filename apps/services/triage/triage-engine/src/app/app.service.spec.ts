import { Test, TestingModule } from '@nestjs/testing';
import { AppService } from './app.service';
import { HttpService } from '@nestjs/axios';
import axios from 'axios'; // Importamos axios para mockearlo

// 1. MOCK DE SUPABASE
const mockSupabaseClient = {
  from: jest.fn().mockReturnThis(),
  insert: jest.fn().mockResolvedValue({ error: null }),
};

// 2. MOCK DE AXIOS (Esto es la clave)
jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

jest.mock('@supabase/supabase-js', () => ({
  createClient: jest.fn(() => mockSupabaseClient),
}));

describe('AppService', () => {
  let service: AppService;

  beforeEach(async () => {
    process.env.SUPABASE_URL = 'https://fake.supabase.co';
    process.env.SUPABASE_KEY = 'fake-key';
    process.env.N8N_WEBHOOK_URL = 'http://fake-n8n.com';

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AppService,
        // Si tu servicio usa HttpService inyectado, dejamos el provider vacío o mockeado
        // Si usa axios directo, esto no afecta pero es buena práctica
        {
          provide: HttpService,
          useValue: { post: jest.fn() }, 
        },
      ],
    }).compile();

    service = module.get<AppService>(AppService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should detect infection if symptoms include fever', async () => {
    const data = {
      appointmentId: '123',
      qrData: 'abc',
      symptoms: ['dolor de cabeza', 'fever alta'],
    };

    // CONFIGURAMOS EL MOCK DE AXIOS DIRECTO
    mockedAxios.post.mockResolvedValue({
      data: { diagnosis: 'POSIBLE INFECCION' },
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {} as undefined,
    });

    await service.processTriage(data);

    expect(mockSupabaseClient.from).toHaveBeenCalledWith('triage_records');
    expect(mockSupabaseClient.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        ai_pre_diagnosis: 'POSIBLE INFECCION',
      }),
    );
  });

  it('should verify routine checkup for mild symptoms', async () => {
    const data = {
      appointmentId: '456',
      qrData: 'xyz',
      symptoms: ['cansancio'],
    };

    // CONFIGURAMOS EL MOCK DE AXIOS DIRECTO PARA RUTINA
    mockedAxios.post.mockResolvedValue({
      data: { diagnosis: 'REVISION RUTINA' },
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {} as undefined,
    });

    await service.processTriage(data);

    expect(mockSupabaseClient.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        ai_pre_diagnosis: 'REVISION RUTINA',
      }),
    );
  });
});