import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn, Index } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { Doctor } from './doctor.entity';

/**
 * Enum representing the lifecycle of an appointment.
 */
export enum AppointmentStatus {
  SCHEDULED = 'SCHEDULED',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
  NO_SHOW = 'NO_SHOW',
}

@Entity('appointments')
@Index(['doctorId', 'startTime']) // Composite index for quick overlap checks
export class Appointment {
  
  @ApiProperty({ example: 'b5e4c3a2-uuid...', description: 'Unique Appointment ID' })
  @PrimaryGeneratedColumn('uuid', { name: 'appointment_id' })
  id: string;

  /**
   * Foreign Key to the Doctor Entity.
   * We use @ManyToOne because a Doctor has many Appointments.
   */
  @ApiProperty({ example: 'd19283-uuid...', description: 'Assigned Doctor ID' })
  @Column({ name: 'doctor_id' })
  doctorId: string;

  @ManyToOne(() => Doctor)
  @JoinColumn({ name: 'doctor_id' })
  doctor: Doctor;

  /**
   * Reference to the Patient (Student) via their Auth User ID.
   * We don't join strictly with a Patient entity table here to keep services decoupled (Microservices pattern),
   * but we store the ID to know who booked it.
   */
  @ApiProperty({ example: 'student-uuid...', description: 'Student User ID (Auth)' })
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

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}