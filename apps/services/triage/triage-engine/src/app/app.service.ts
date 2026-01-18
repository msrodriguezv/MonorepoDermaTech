import { Injectable, Logger } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import axios from 'axios';

@Injectable()
export class AppService {
  private supabase: SupabaseClient;
  private readonly logger = new Logger(AppService.name);
  
  private readonly N8N_URL = 'http://localhost:5678/webhook-test/ai-analysis';

  constructor() {
    this.supabase = createClient(
      process.env.SUPABASE_URL || '',
      process.env.SUPABASE_KEY || ''
    );
  }

  getHello(): string {
    return 'Triage Engine w/ AI Agent Running';
  }

  async processTriage(data: any) {
    this.logger.log(`🔄 Procesando paciente: ${data.appointmentId}`);

    let aiDiagnosis = 'PENDIENTE';
    let severity = '1'; // Valor por defecto como string (varchar en tu tabla)

    try {
      this.logger.log('📡 Enviando datos a n8n...');
      const response = await axios.post(this.N8N_URL, {
        symptoms: data.symptoms,
        qrData: data.qrData
      });

      if (response.data) {
        aiDiagnosis = response.data.diagnosis || 'SIN DIAGNOSTICO';
        // Capturamos el score de severidad del nuevo prompt
        severity = String(response.data.severity_score || '1');
        
        this.logger.log(`🤖 IA Respondió: ${aiDiagnosis} (Nivel: ${severity})`);
      }

    } catch (error) {
      this.logger.error(`❌ Error conectando con n8n: ${error.message}`);
      aiDiagnosis = 'ERROR_IA_TIMEOUT';
    }

    // Guardado final en Supabase con tus columnas reales
    const { error } = await this.supabase.from('triage_records').insert({
      appointment_id: data.appointmentId,
      qr_data: data.qrData,
      symptoms: data.symptoms,
      ai_pre_diagnosis: aiDiagnosis,
      severity_level: severity
    });

    if (error) {
      this.logger.error('❌ Error guardando en DB:', error.message);
    } else {
      this.logger.log('✅ Registro dermatológico completado exitosamente.');
    }
  }
}