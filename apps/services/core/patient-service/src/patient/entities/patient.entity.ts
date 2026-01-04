import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

/**
 * Interface defining the structure of the JSONB column.
 * Kept here for type safety within the entity.
 * Note: This stores static medical traits (Allergies/Blood Type), 
 * NOT the clinical history/records which belong to the Medical History Microservice.
 */
export interface MedicalInfo {
  bloodType?: string;
  allergies?: string[];
  chronicConditions?: string[];
}

@Entity('patients')
export class Patient {
  /**
   * Primary Key for the Patient Service.
   */
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * LOGICAL REFERENCE to the Auth Service.
   */
  @Index({ unique: true })
  @Column()
  userId: string;

  @Column()
  email: string;

  @Column({ length: 100, nullable: true })
  firstName: string;

  @Column({ length: 100, nullable: true })
  lastName: string;

  @Column({ type: 'date', nullable: true })
  birthDate: Date;

  @Column({ nullable: true })
  phone: string;

  /**
   * Profile Status Flag.
   */
  @Column({ default: false })
  isProfileComplete: boolean;

  /**
   * Basic Medical Traits (JSONB).
   * Stores 'Static' medical data needed for quick identification (e.g., Blood Type).
   * Full clinical history is stored in the separate 'Medical History' Microservice (MongoDB).
   */
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
}