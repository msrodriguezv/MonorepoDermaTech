import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn, Index } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { Doctor } from './doctor.entity';

/**
 * Enum representing the lifecycle of an appointment within the clinical workflow.
 */
export enum AppointmentStatus {
  SCHEDULED = 'SCHEDULED',                   // Initial state: Appointment booked
  WAITING_FOR_DOCTOR = 'WAITING_FOR_DOCTOR', // Triage completed, patient waiting for doctor
  COMPLETED = 'COMPLETED',                   // Consultation finished successfully
  CANCELLED = 'CANCELLED',                   // Appointment cancelled by user or admin
  NO_SHOW = 'NO_SHOW',                       // Patient did not attend
  REFERRED = 'REFERRED',                     // Patient referred to an external institution
}

@Entity('appointments')
@Index(['doctorId', 'startTime']) // Composite index for optimized overlap checks
export class Appointment {
  
  @ApiProperty({ example: 'b5e4c3a2-uuid...', description: 'Unique Appointment ID' })
  @PrimaryGeneratedColumn('uuid', { name: 'appointment_id' })
  id: string;

  /**
   * Foreign Key referencing the Doctor entity.
   * Established via ManyToOne relationship.
   */
  @ApiProperty({ example: 'd19283-uuid...', description: 'Assigned Doctor ID' })
  @Column({ name: 'doctor_id' })
  doctorId: string;

  @ManyToOne(() => Doctor)
  @JoinColumn({ name: 'doctor_id' })
  doctor: Doctor;

  /**
   * Reference to the Patient (Student) via their Auth User ID.
   * Decoupled reference to maintain microservices independence.
   */
  @ApiProperty({ example: 'student-uuid...', description: 'Student User ID (Auth System)' })
  @Column({ name: 'student_user_id' })
  studentId: string;

  @ApiProperty({ example: '2024-01-20T10:00:00Z', description: 'Appointment Start Time (ISO 8601)' })
  @Column({ name: 'start_time', type: 'timestamptz' })
  startTime: Date;

  @ApiProperty({ example: '2024-01-20T10:30:00Z', description: 'Appointment End Time (ISO 8601)' })
  @Column({ name: 'end_time', type: 'timestamptz' })
  endTime: Date;

  @ApiProperty({ enum: AppointmentStatus, example: AppointmentStatus.SCHEDULED })
  @Column({ 
    type: 'varchar', 
    length: 20, 
    default: AppointmentStatus.SCHEDULED 
  })
  status: AppointmentStatus;

  /**
   * Clinical notes added by the nurse during the triage process.
   * Stores vital signs or preliminary observations.
   */

  @ApiProperty({ example: 'Manchas rojas en la cara', description: 'Patient reported symptoms' })
  @Column({ name: 'symptoms', type: 'text', nullable: true })
  symptoms: string;

  @ApiProperty({ example: 'BP: 120/80, Weight: 70kg, No fever.', description: 'Triage notes added by the nurse' })
  @Column({ name: 'nurse_notes', type: 'text', nullable: true })
  nurseNotes: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}