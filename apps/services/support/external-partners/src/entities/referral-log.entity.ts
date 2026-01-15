import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity('referral_logs') 
export class ReferralLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  patientId: string;

  @Column()
  doctorId: string;

  @Column()
  hospitalId: string;

  @Column()
  hospitalName: string;

  @Column()
  reason: string;

  @Column()
  referralCode: string;

  @CreateDateColumn()
  createdAt: Date;
}