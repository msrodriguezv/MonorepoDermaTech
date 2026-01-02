/**
 * Port definition for External System interactions.
 * Hexagonal Architecture: This defines the contract that adapters must implement.
 */
export abstract class ExternalSystemPort {
  /**
   * Verifies if a student is enrolled in the external system.
   * @param email The email to validate.
   * @returns Promise<boolean> - true if enrolled, false otherwise.
   */
  abstract checkStudentEnrollment(email: string): Promise<boolean>;
}