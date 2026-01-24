import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

@Entity('triage_records') // 👈 Este será el nombre real de la tabla en Supabase
export class TriageRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // 🔗 RELACIÓN: Conectamos lógicamente con tu tabla 'appointments'
  // No necesitamos importar la otra entidad aquí si no vamos a hacer Joins complejos desde este microservicio,
  // basta con guardar el ID de referencia.
  @Column({ type: 'uuid', name: 'appointment_id' })
  @Index() // Crea un índice para búsquedas rápidas
  appointmentId: string;

  @Column({ name: 'qr_data', type: 'text' })
  qrData: string;

  // Postgres permite guardar JSON directo. Perfecto para una lista de síntomas variable.
  @Column({ type: 'jsonb', default: [] })
  symptoms: any;

  @Column({ name: 'ai_pre_diagnosis', type: 'text', nullable: true })
  aiPreDiagnosis: string;

  @Column({ name: 'severity_level', type: 'varchar', length: 50, nullable: true })
  severityLevel: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}