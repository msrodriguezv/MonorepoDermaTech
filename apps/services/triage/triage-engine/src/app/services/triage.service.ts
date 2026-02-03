import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';
import { ConfigService } from '@nestjs/config';
import { TriageRecord } from '../entities/triage-record.entity';
import { AppointmentCreatedPayload, AiDiagnosisResponse, QrGenerationResponse } from '../dto/triage.dto';

@Injectable()
export class TriageService {
  private readonly logger = new Logger(TriageService.name);
  
  private readonly AI_SERVICE_URL: string;
  private readonly QR_SERVICE_URL: string;

  constructor(
    @InjectRepository(TriageRecord)
    private readonly triageRepo: Repository<TriageRecord>,
    private readonly httpService: HttpService,
    private readonly configService: ConfigService
  ) {
    this.AI_SERVICE_URL = this.configService.get<string>('AI_SERVICE_URL', 'http://ai-agent:5000/analyze');
    this.QR_SERVICE_URL = this.configService.get<string>('QR_SERVICE_URL', 'http://qr-ingest:8080/generate');
  }

  async processAppointmentEvent(payload: AppointmentCreatedPayload): Promise<void> {
    const { appointment_id, student_id, symptoms } = payload;
    
    this.logger.log(`🩺 [Orchestrator] Starting Triage for Appointment: ${appointment_id}`);

    try {
      // PARALLEL EXECUTION: Llamamos a IA y QR al mismo tiempo para ganar velocidad
      const [aiResult, qrResult] = await Promise.allSettled([
        this.callAiAgent(symptoms),
        this.callQrGenerator(appointment_id, student_id)
      ]);

      // Extract Results (con valores por defecto si fallan)
      const diagnosisData = aiResult.status === 'fulfilled' ? aiResult.value : { diagnosis: 'PENDIENTE REVISION', priority_level: 1 };
      const qrData = qrResult.status === 'fulfilled' ? qrResult.value : { qr_code_base64: null };

      if (aiResult.status === 'rejected') this.logger.error('❌ AI Service Failed');
      if (qrResult.status === 'rejected') this.logger.error('❌ QR Service Failed');

      // Persistence
      const record = this.triageRepo.create({
        appointmentId: appointment_id,
        studentId: student_id,
        symptoms: symptoms,
        aiPreDiagnosis: diagnosisData.diagnosis,
        priorityLevel: diagnosisData.priority_level,
        qrCode: qrData.qr_code_base64
      });

      await this.triageRepo.save(record);
      
      this.logger.log(`✅ [Orchestrator] Triage completed & saved for ${appointment_id}`);
      
      // TODO: Emitir evento 'triage.completed' a RabbitMQ para enviar email

    } catch (error) {
      const err = error as Error;
      this.logger.error(`❌ [Orchestrator] Critical Error: ${err.message}`, err.stack);
    }
  }

  // --- HTTP WRAPPERS ---

  private async callAiAgent(symptoms: string): Promise<AiDiagnosisResponse> {
    // Si estamos en modo dev sin IA real, devolvemos mock
    if (this.configService.get('MOCK_AI') === 'true') {
        return { diagnosis: 'MOCK DIAGNOSIS: DERMATITIS', priority_level: 2, confidence: 0.95 };
    }

    const { data } = await lastValueFrom(
      this.httpService.post<AiDiagnosisResponse>(this.AI_SERVICE_URL, { text: symptoms })
    );
    return data;
  }

  private async callQrGenerator(appointmentId: string, studentId: string): Promise<QrGenerationResponse> {
    if (this.configService.get('MOCK_QR') === 'true') {
        return { qr_code_base64: 'base64_mock...', qr_content: appointmentId };
    }

    // El servicio de Go espera { content: string }
    const content = JSON.stringify({ a: appointmentId, s: studentId }); 
    const { data } = await lastValueFrom(
      this.httpService.post<QrGenerationResponse>(this.QR_SERVICE_URL, { content })
    );
    return data;
  }
}