import { User } from '../../../../domain/entities/user.entity';
import { UserSchema } from '../entities/user.schema';
import { UserEmail } from '../../../../domain/value-objects/user-email.vo';
import { UserRole } from '@dermatech/shared-dtos'; 

/**
 * Data Mapper responsible for converting between Domain Entities and Persistence Schemas.
 * Ensures strict separation between the Domain Layer and Infrastructure Layer.
 */
export class UserMapper {
  
  /**
   * Converts a Persistence Schema (TypeORM) to a Domain Entity.
   * Used when reading from the database.
   */
  static toDomain(schema: UserSchema): User {
    // Reconstruct the Value Object
    const emailVO = new UserEmail(schema.email);
    
    return new User(
      schema.id,
      emailVO,
      schema.passwordHash,
      schema.role as UserRole, // Cast string to Enum
      schema.isActive,
      schema.createdAt,
      schema.updatedAt,
      schema.currentRefreshTokenHash, // Now mapped correctly
    );
  }

  /**
   * Converts a Domain Entity to a Persistence Schema (TypeORM).
   * Used when saving/updating to the database.
   */
  static toPersistence(domain: User): UserSchema {
    const schema = new UserSchema();
    
    schema.id = domain.getId();
    schema.email = domain.getEmail().email;
    schema.passwordHash = domain.getPasswordHash();
    schema.role = domain.getRole();
    schema.isActive = domain.getIsActive();
    schema.currentRefreshTokenHash = domain.getCurrentRefreshTokenHash() ?? null;
    schema.createdAt = domain.getCreatedAt();
    schema.updatedAt = domain.getUpdatedAt();

    return schema;
  }
}