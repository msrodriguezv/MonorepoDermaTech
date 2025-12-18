import { UserRole } from '@dermatech/shared-dtos';

/**
 * Command to trigger the user registration process.
 * Carries the immutable data required to create a new user account.
 * Implements the CQRS Command pattern.
 */
export class RegisterUserCommand {
  /**
   * @param email - The candidate's email address.
   * @param password - The raw password (to be hashed).
   * @param role - The role to be assigned (STUDENT, DOCTOR, etc.).
   */
  constructor(
    public readonly email: string,
    public readonly password: string,
    public readonly role: UserRole,
  ) {}
}