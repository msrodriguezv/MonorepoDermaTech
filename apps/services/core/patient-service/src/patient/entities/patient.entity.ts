import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index, OneToMany } from 'typeorm';
import { MedicalRecord } from './medical-record.entity';

// Interfaz para el JSONB
export interface MedicalInfo {
  bloodType: string;
  allergies: string[];
  chronicConditions: string[];
}

@Entity('patients')
export class Patient { // <--- ASEGÚRATE QUE DIGA 'export class'
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column()
  userId: string;

  @Column()
  email: string;

  @Column({ length: 100 }) 
  firstName: string;

  @Column({ length: 100 })
  lastName: string;

  @Column({ type: 'date' })
  birthDate: Date;

  @Column({ nullable: true })
  phone: string;

  @Column({ type: 'jsonb', nullable: true, default: {} })
  medicalInfo: MedicalInfo;

  @Column({ nullable: true })
  avatarUrl: string;

  @Column({ nullable: true })
  insuranceProvider: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // RELACIÓN 1 a N
  @OneToMany(() => MedicalRecord, (record) => record.patient)
  medicalRecords: MedicalRecord[];
} 
// <--- ¡IMPORTANTE! VERIFICA QUE ESTA ÚLTIMA LLAVE ESTÉ PRESENTE