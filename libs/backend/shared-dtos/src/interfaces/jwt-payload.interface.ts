import { UserRole } from '../enums/user-role.enum';

/**
 * Standard structure for the JSON Web Token (JWT) payload.
 * This interface must be respected by the Auth Service (signer) and Gateway/Guards (verifiers).
 */
export interface JwtPayload {
  /**
   * Subject: Unique User ID (UUID).
   */
  sub: string;

  /**
   * User's email address.
   */
  email: string;

  /**
   * User's assigned role for authorization.
   */
  role: UserRole;

  /**
   * Issued At: Unix timestamp when the token was created.
   */
  iat?: number;

  /**
   * Expiration Time: Unix timestamp when the token expires.
   */
  exp?: number;
}