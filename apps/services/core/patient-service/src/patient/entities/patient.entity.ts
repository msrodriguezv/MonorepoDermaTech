import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';

/**
 * Class defining the structure of the JSONB column.
 * Converted from Interface to Class to ensure Swagger can read the schema properties.
 * Note: This stores static medical traits (Allergies/Blood Type).
 */
export class MedicalInfo {
  @ApiProperty({ example: 'O+', description: 'Blood type of the patient', required: false })
  bloodType?: string;

  @ApiProperty({ example: ['Penicillin', 'Peanuts'], description: 'List of known allergies', required: false })
  allergies?: string[];

  @ApiProperty({ example: ['Asthma'], description: 'List of chronic conditions', required: false })
  chronicConditions?: string[];
}

@Entity('student_profiles')
export class Patient {
  /**
   * Primary Key for the Patient Service.
   */
  @ApiProperty({ example: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', description: 'Unique Profile ID' })
  @PrimaryGeneratedColumn('uuid', { name: 'profile_id' })
  id: string;

  /**
   * LOGICAL REFERENCE to the Auth Service.
   */
  @ApiProperty({ example: 'd8139c6f-a928-4b71-aa84-a51da3fbae34', description: 'Reference to Auth User ID' })
  @Index({ unique: true })
  @Column()
  userId: string;

  @ApiProperty({ example: 'student@uce.edu.ec', description: 'Institutional email' })
  @Column()
  email: string;

  @ApiProperty({ example: 'Juan', description: 'First Name', nullable: true })
  @Column({ length: 100, nullable: true })
  firstName: string;

  @ApiProperty({ example: 'Perez', description: 'Last Name', nullable: true })
  @Column({ length: 100, nullable: true })
  lastName: string;

  @ApiProperty({ example: '1999-05-20', description: 'Date of Birth', nullable: true })
  @Column({ type: 'date', nullable: true })
  birthDate: Date;

  @ApiProperty({ example: '+593991234567', description: 'Contact phone number', nullable: true })
  @Column({ nullable: true })
  phone: string;

  // --- ACADEMIC FIELDS ---

  @ApiProperty({ example: 'Faculty of Engineering', description: 'Faculty name', nullable: true })
  @Column({ nullable: true })
  faculty: string;

  @ApiProperty({ example: 'Software Engineering', description: 'Career/Major', nullable: true })
  @Column({ nullable: true })
  career: string;

  @ApiProperty({ example: 5, description: 'Current semester number', nullable: true })
  @Column({ type: 'int', nullable: true })
  current_semester: number;

  /**
   * Profile Status Flag.
   */
  @ApiProperty({ example: true, description: 'Indicates if the profile has mandatory data' })
  @Column({ default: false })
  isProfileComplete: boolean;

  /**
   * Basic Medical Traits (JSONB).
   * Stores 'Static' medical data needed for quick identification (e.g., Blood Type).
   * Full clinical history is stored in the separate 'Medical History' Microservice (MongoDB).
   */
  @ApiProperty({ type: MedicalInfo, description: 'Basic medical traits stored as JSONB', nullable: true })
  @Column({ type: 'jsonb', nullable: true, default: {} })
  medicalInfo: MedicalInfo;

  @ApiProperty({ example: 'https://s3-bucket.aws.com/avatar.jpg', nullable: true })
  @Column({ nullable: true })
  avatarUrl: string;

  @ApiProperty({ example: 'IESS', description: 'Insurance Provider Name', nullable: true })
  @Column({ nullable: true })
  insuranceProvider: string;

  @ApiProperty()
  @CreateDateColumn()
  createdAt: Date;

  @ApiProperty()
  @UpdateDateColumn()
  updatedAt: Date;
}