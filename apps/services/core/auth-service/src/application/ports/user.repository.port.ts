// apps/services/core/auth-service/src/application/ports/user.repository.port.ts

import { User } from '../../domain/entities/user.entity';

/**
 * Output Port: Defines the interface for user persistence.
 * Implemented by the Infrastructure layer.
 */
export interface UserRepositoryPort {
  save(user: User): Promise<User>;
  findByEmail(email: string): Promise<User | null>;
  findById(id: string): Promise<User | null>;
}