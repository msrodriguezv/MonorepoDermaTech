import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

@Entity('patients')
export class Patient {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // Enlace lógico con Auth-Service (Indexado para búsquedas rápidas)
  @Index({ unique: true })
  @Column()
  userId: string;

  @Column()
  email: string;

  @Column({ nullable: true })
  firstName: string;

  @Column({ nullable: true })
  lastName: string;

  @Column({ type: 'date', nullable: true })
  birthDate: Date;

  @Column({ nullable: true })
  phone: string;

  // ESTRATEGIA JSONB (Ahorro de tablas + Flexibilidad médica)
  @Column({ type: 'jsonb', nullable: true, default: {} })
  medicalInfo: {
    bloodType: string;
    allergies: string[];
    chronicConditions: string[];
  };

  // INTEGRACIÓN PAAS (Supabase URL)
  @Column({ nullable: true })
  avatarUrl: string;

  @Column({ nullable: true })
  insuranceProvider: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}