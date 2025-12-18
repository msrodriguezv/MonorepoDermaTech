// apps/services/core/auth-service/src/domain/entities/user.entity.ts

import { UserRole } from '@dermatech/shared-dtos'; 
import { UserEmail } from '../value-objects/user-email.vo';

export class User {
  private readonly id: string;
  private email: UserEmail;
  private passwordHash: string;
  private role: UserRole;
  private isActive: boolean;
  private readonly createdAt: Date;
  private updatedAt: Date;

  constructor(
    id: string,
    email: UserEmail,
    passwordHash: string,
    role: UserRole,
    isActive = true, 
    createdAt = new Date(),
    updatedAt = new Date(),
  ) {
    this.id = id;
    this.email = email;
    this.passwordHash = passwordHash;
    this.role = role;
    this.isActive = isActive;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  // --- Getters ---
  public getId(): string { return this.id; }
  public getEmail(): string { return this.email.getValue(); }
  public getPasswordHash(): string { return this.passwordHash; }
  public getRole(): UserRole { return this.role; }
  public getIsActive(): boolean { return this.isActive; }

  // --- Domain Methods ---
  public changePassword(newHash: string): void {
    this.passwordHash = newHash;
    this.updatedAt = new Date();
  }

  public activate(): void {
    this.isActive = true;
    this.updatedAt = new Date();
  }

  public deactivate(): void {
    this.isActive = false;
    this.updatedAt = new Date();
  }
}