import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn } from 'typeorm';
import { Patient } from './patient.entity';

@Entity('medical_records')
export class MedicalRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'text' })
  photoUrl: string; // Aquí guardamos el LINK de la foto (Supabase Storage)

  @Column({ type: 'text' })
  description: string; // El motivo de la cita

  @CreateDateColumn()
  createdAt: Date;

  @ManyToOne(() => Patient, (patient) => patient.medicalRecords, { onDelete: 'CASCADE' })
  patient: Patient;
}