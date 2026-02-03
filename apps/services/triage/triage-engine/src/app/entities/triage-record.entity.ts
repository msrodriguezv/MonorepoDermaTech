import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

@Entity('triage_records')
export class TriageRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', name: 'appointment_id' })
  @Index()
  appointmentId: string;

  @Column({ type: 'uuid', name: 'student_id' })
  studentId: string;

  @Column({ name: 'qr_code', type: 'text', nullable: true })
  qrCode: string;

  @Column({ type: 'text', name: 'symptoms' }) 
  symptoms: string;

  @Column({ name: 'ai_pre_diagnosis', type: 'text', nullable: true })
  aiPreDiagnosis: string;

  @Column({ name: 'priority_level', type: 'int', default: 1 })
  priorityLevel: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}