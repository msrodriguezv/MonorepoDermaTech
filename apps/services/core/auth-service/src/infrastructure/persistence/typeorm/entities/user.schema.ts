import { Entity, Column, PrimaryColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { UserRole } from '@dermatech/shared-dtos';

/**
 * TypeORM Schema Definition for the 'users' table.
 * This class maps the Domain Entity to the PostgreSQL database structure.
 * Complies with Mandatory R11 (Database Usage).
 */
@Entity({ name: 'users' })
export class UserSchema {
  @PrimaryColumn('uuid')
  id: string;

  @Column({ unique: true, length: 150 })
  email: string;

  @Column({ name: 'password_hash' })
  passwordHash: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.STUDENT
  })
  role: UserRole;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}