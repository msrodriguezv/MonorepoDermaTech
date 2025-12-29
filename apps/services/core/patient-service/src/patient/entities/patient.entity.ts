import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

// Definimos la interfaz para el JSONB para tener tipado fuerte en TypeScript
export interface MedicalInfo {
  bloodType: string;
  allergies: string[];
  chronicConditions: string[];
}

@Entity('patients')
export class Patient {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // Enlace con Auth
  @Index({ unique: true })
  @Column()
  userId: string;

  @Column()
  email: string;

  // CORRECCIÓN: Quitamos nullable. Un perfil DEBE tener nombres.
  @Column({ length: 100 }) 
  firstName: string;

  @Column({ length: 100 })
  lastName: string;

  @Column({ type: 'date' })
  birthDate: Date;

  @Column({ nullable: true })
  phone: string;

  // TU ESTRATEGIA JSONB (Conservada y Tipada)
  @Column({ type: 'jsonb', nullable: true, default: {} })
  medicalInfo: MedicalInfo;

  // TU INTEGRACIÓN PAAS
  @Column({ nullable: true })
  avatarUrl: string;

  @Column({ nullable: true })
  insuranceProvider: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}