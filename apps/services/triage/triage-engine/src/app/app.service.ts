import { Injectable, Logger } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class AppService {
  private supabase: SupabaseClient;
  private readonly logger = new Logger(AppService.name);

  constructor() {
    // 1. Leer variables de entorno
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_KEY;

    // 2. Validación de seguridad (Para que no falle silenciosamente)
    if (!supabaseUrl || !supabaseKey) {
      this.logger.error('❌ Faltan las variables SUPABASE_URL o SUPABASE_KEY en el archivo .env');
      throw new Error('Configuración de Supabase incompleta');
    }

    // 3. Crear cliente
    this.supabase = createClient(supabaseUrl, supabaseKey);
    this.logger.log('✅ Conexión con Supabase Client inicializada correctamente');
  }

  getHello(): string {
    return 'Triage Engine (NestJS) is Running!';
  }

  async processTriage(data: any) {
    this.logger.log(`🔄 [Servicio] Procesando triage para appointment: ${data.appointmentId}`);

    // 1. Simulación temporal de IA (Pre-diagnóstico)
    const mockDiagnosis = this.mockAIAnalysis(data.symptoms);

    // 2. Guardar en Supabase
    const { error } = await this.supabase
      .from('triage_records') 
      .insert({
        appointment_id: data.appointmentId,
        qr_data: data.qrData,
        symptoms: data.symptoms,
        ai_pre_diagnosis: mockDiagnosis,
      });

    if (error) {
      this.logger.error(`❌ Error guardando en Supabase: ${error.message}`);
    } else {
      this.logger.log('✅ Registro guardado exitosamente en la tabla triage_records');
    }
  }

  // Función auxiliar privada
  private mockAIAnalysis(symptoms: string[]): string {
    if (!symptoms || !Array.isArray(symptoms)) return 'Datos insuficientes';

    const symptomsString = symptoms.join(' ').toLowerCase();
    if (symptomsString.includes('fiebre') || symptomsString.includes('sangre')) {
      return 'POSIBLE INFECCION';
    }
    return 'REVISION RUTINA';
  }
}