/**
 * Port definition for External Systems verification.
 * Follows the Dependency Inversion Principle (DIP).
 * The Application layer depends on this abstraction, not on the concrete implementation.
 */
export interface ExternalSystemPort {
  /**
   * Verifies if the user is enrolled and active in the External University System.
   * @param email - The user's email to verify.
   * @throws ForbiddenException if the user is not valid.
   */
  validateStudentEnrollment(email: string): Promise<void>;
}