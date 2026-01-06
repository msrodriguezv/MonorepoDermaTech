import { UserRole } from '@dermatech/shared-dtos'; 
import { UserEmail } from '../value-objects/user-email.vo';

/**
 * Domain Entity representing a User in the system.
 * Encapsulates state and business logic strictly.
 */
export class User {
  private readonly id: string;
  private email: UserEmail;
  private passwordHash: string;
  private role: UserRole;
  private isActive: boolean;
  private updatedAt: Date;
  private readonly createdAt: Date;
  
  // Nullable because a user might not be logged in immediately after creation
  private currentRefreshTokenHash?: string | null;

  constructor(
    id: string,
    email: UserEmail,
    passwordHash: string,
    role: UserRole,
    isActive = true,
    createdAt = new Date(),
    updatedAt = new Date(),
    // FIX: Added this argument to the constructor to solve the TS error
    currentRefreshTokenHash: string | null = null, 
  ) {
    this.id = id;
    this.email = email;
    this.passwordHash = passwordHash;
    this.role = role;
    this.isActive = isActive;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.currentRefreshTokenHash = currentRefreshTokenHash;
  }

  // --- Getters ---
  public getId(): string { return this.id; }
  
  public getEmail(): UserEmail { return this.email; }
  
  public getPasswordHash(): string { return this.passwordHash; }
  
  public getRole(): UserRole { return this.role; }
  
  public getIsActive(): boolean { return this.isActive; }

  public getCreatedAt(): Date { return this.createdAt; }

  public getUpdatedAt(): Date { return this.updatedAt; }

  // Getter for persistence usage only (Infrastructure layer)
  public getCurrentRefreshTokenHash(): string | null | undefined {
    return this.currentRefreshTokenHash;
  }

  // --- Domain Logic Methods ---

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

  // --- Token Rotation / Session Management ---

  /**
   * Sets the hash of the current valid refresh token.
   * This invalidates any previous refresh tokens (Token Rotation Strategy).
   */
  public setRefreshTokenHash(hash: string): void {
    this.currentRefreshTokenHash = hash;
    this.updatedAt = new Date(); // Audit update
  }

  /**
   * Clears the refresh token hash (Logout).
   * Effectively invalidates the current session.
   */
  public clearRefreshToken(): void {
    this.currentRefreshTokenHash = null;
    this.updatedAt = new Date();
  }

  /**
   * Validates if the incoming refresh token matches the one stored in the entity.
   * Vital for preventing token reuse attacks.
   */
  public validateRefreshToken(incomingHash: string): boolean {
    if (!this.currentRefreshTokenHash) return false;
    return this.currentRefreshTokenHash === incomingHash;
  }
}