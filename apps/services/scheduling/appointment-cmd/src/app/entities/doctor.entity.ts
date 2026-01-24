import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';

@Entity('doctors')
export class Doctor {
  
  @ApiProperty({ example: 'd19283-uuid...', description: 'Unique Doctor Profile ID' })
  @PrimaryGeneratedColumn('uuid', { name: 'doctor_id' })
  id: string;

  @ApiProperty({ example: 'user-uuid...', description: 'Link to Auth User' })
  @Index({ unique: true })
  @Column({ name: 'user_id' }) // Mapeamos snake_case de la DB a camelCase
  userId: string;

  @ApiProperty({ example: 'Gregory', description: 'Doctor First Name' })
  @Column({ name: 'first_name', length: 100 })
  firstName: string;

  @ApiProperty({ example: 'House', description: 'Doctor Last Name' })
  @Column({ name: 'last_name', length: 100 })
  lastName: string;

  @ApiProperty({ example: 'Nephrology', description: 'Medical Specialization' })
  @Column({ length: 100 })
  specialization: string;

  @ApiProperty({ example: 'MED-12345-EC', description: 'Professional License Number' })
  @Column({ name: 'license_number', length: 50 })
  licenseNumber: string;

  @ApiProperty({ example: 'Box 404', description: 'Physical Office/Consulting Room', required: false })
  @Column({ name: 'office_number', length: 20, nullable: true })
  officeNumber: string;

  @ApiProperty({ example: true, description: 'Is the doctor currently accepting appointments?' })
  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}