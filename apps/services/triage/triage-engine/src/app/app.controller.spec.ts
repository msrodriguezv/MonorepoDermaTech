import { Test, TestingModule } from '@nestjs/testing';
import { AppService } from './app.service';

// 1. CREAMOS EL MOCK (El doble de acción de Supabase)
const mockSupabaseClient = {
  from: jest.fn().mockReturnThis(), // Finge hacer .from('tabla')
  insert: jest.fn().mockResolvedValue({ error: null }), // Finge hacer .insert() y responde "ok"
};

// Interceptamos la librería real para que no se conecte a internet
jest.mock('@supabase/supabase-js', () => ({
  createClient: jest.fn(() => mockSupabaseClient),
}));

describe('AppService', () => {
  let service: AppService;

  beforeEach(async () => {
    // Simulamos variables de entorno para que el constructor no falle
    process.env.SUPABASE_URL = 'https://fake.supabase.co';
    process.env.SUPABASE_KEY = 'fake-key';

    const module: TestingModule = await Test.createTestingModule({
      providers: [AppService],
    }).compile();

    service = module.get<AppService>(AppService);
  });

  afterEach(() => {
    jest.clearAllMocks(); // Limpiamos contadores después de cada test
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  // 🧪 TEST 1: Verificar el saludo
  it('should return "Running" message', () => {
    expect(service.getHello()).toContain('Running');
  });

  // 🧪 TEST 2: Verificar la Lógica de la IA (Caso Grave)
  it('should detect infection if symptoms include fever', async () => {
    const data = {
      appointmentId: '123',
      qrData: 'abc',
      symptoms: ['dolor de cabeza', 'fiebre alta'], // Tiene "fiebre"
    };

    // Ejecutamos la función
    await service.processTriage(data);

    // Verificamos que se llamó a Supabase con el diagnóstico correcto
    expect(mockSupabaseClient.from).toHaveBeenCalledWith('triage_records');
    expect(mockSupabaseClient.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        ai_pre_diagnosis: 'POSIBLE INFECCION', // 👈 Esto es lo que validamos
        symptoms: data.symptoms,
      })
    );
  });

  // 🧪 TEST 3: Verificar la Lógica de la IA (Caso Leve)
  it('should verify routine checkup for mild symptoms', async () => {
    const data = {
      appointmentId: '456',
      qrData: 'xyz',
      symptoms: ['cansancio'], // No tiene palabras clave graves
    };

    await service.processTriage(data);

    expect(mockSupabaseClient.insert).toHaveBeenCalledWith(
      expect.objectContaining({
        ai_pre_diagnosis: 'REVISION RUTINA', // 👈 Validamos lógica inversa
      })
    );
  });
});