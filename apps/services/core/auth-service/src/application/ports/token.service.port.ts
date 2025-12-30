import { JwtPayload } from '@dermatech/shared-dtos';

/**
 * Interface defining the contract for Token operations.
 * Uses the shared JwtPayload to ensure consistency across microservices.
 */
export interface TokenServicePort {
  /**
   * Generates a short-lived JWT (e.g., 15 mins) for API access.
   */
  generateAccessToken(payload: JwtPayload): Promise<string>;

  /**
   * Generates a long-lived JWT (e.g., 7 days) for session renewal.
   */
  generateRefreshToken(payload: JwtPayload): Promise<string>;

  /**
   * Verifies and decodes a token. Throws error if invalid.
   */
  verifyToken(token: string): Promise<JwtPayload>;
}