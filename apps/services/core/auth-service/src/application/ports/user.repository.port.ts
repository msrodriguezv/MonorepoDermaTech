import { User } from '../../domain/entities/user.entity';

export interface UserRepositoryPort {
  save(user: User): Promise<User>;
  findByEmail(email: string): Promise<User | null>;
  findById(id: string): Promise<User | null>;
  
  /**
   * Updates the refresh token for a specific user.
   * Used for Token Rotation and Logout processes.
   * @param id The User ID (UUID).
   * @param refreshToken The new hashed token or null to revoke access.
   */
  updateRefreshToken(id: string, refreshToken: string | null): Promise<void>;
}