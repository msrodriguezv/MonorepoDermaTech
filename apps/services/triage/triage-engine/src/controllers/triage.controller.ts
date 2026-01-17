import { Controller, Logger } from '@nestjs/common';
import { EventPattern, Payload } from '@nestjs/microservices';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TriageRecord } from '../entities/triage-record.entity';
// 👇 Importamos esto para generar UUIDs válidos nativamente
import { randomUUID } from 'crypto';

@Controller()
export class TriageController {
  private readonly logger = new Logger(TriageController.name);

  constructor(
    @InjectRepository(TriageRecord)
    private readonly triageRepo: Repository<TriageRecord>,
  ) {}

  @EventPattern('appointment.created')
  async handleNewAppointment(@Payload() data: any) {
    this.logger.log('📨 ¡Evento recibido desde GO! Procesando...');
    this.logger.debug(`Payload recibido: ${JSON.stringify(data)}`);

    try {
      // 👇 TRUCO DE MAGIA:
      // Si recibimos un ID tipo "EST-..." (que no es UUID), generamos uno nuevo
      // para que la base de datos no falle.
      let finalAppointmentId = data.appointmentId || data.studentId;
      
      // Verificación simple: Si tiene "EST-", no es UUID.
      if (typeof finalAppointmentId === 'string' && finalAppointmentId.startsWith('EST')) {
        this.logger.warn(`⚠️ El ID "${finalAppointmentId}" no es un UUID válido para la BD. Generando uno temporal...`);
        finalAppointmentId = randomUUID(); // Genera ej: 'a0eebc99-...'
      }

      const newTriageEntry = this.triageRepo.create({
        appointmentId: finalAppointmentId, // Ahora seguro es un UUID
        symptoms: data.symptoms,
        // Guardamos el ID original del estudiante dentro del QR para no perder el rastro
        qrData: data.qrData || `QR-${data.studentId}-${Date.now()}`,
        severityLevel: 'PENDING',
        aiPreDiagnosis: null
      });

      const saved = await this.triageRepo.save(newTriageEntry);
      
      this.logger.log(`💾 Triage guardado exitosamente en Supabase. ID: ${saved.id}`);
      this.logger.log('✅ Flujo completado: Go (Validado) -> Kafka -> NestJS (UUID generado) -> Supabase');
    
    } catch (error) {
      this.logger.error('❌ Error al guardar en Supabase:', error);
    }
  }
}