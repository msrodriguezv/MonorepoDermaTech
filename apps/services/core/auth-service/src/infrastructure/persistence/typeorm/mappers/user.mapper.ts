import { User } from '../../../../domain/entities/user.entity';
import { UserSchema } from '../entities/user.schema';
import { UserEmail } from '../../../../domain/value-objects/user-email.vo';

/**
 * Data Mapper responsible for converting between Domain Entities and Persistence Schemas.
 * Ensures strict separation between the Domain Layer and Infrastructure Layer.
 */
export class UserMapper {
  
  /**
   * Converts a Persistence Schema (TypeORM) to a Domain Entity.
   */
  static toDomain(schema: UserSchema): User {
    const emailVO = new UserEmail(schema.email);
    
    return new User(
      schema.id,
      emailVO,
      schema.passwordHash,
      schema.role,
      schema.isActive,
      schema.createdAt,
      schema.updatedAt,
    );
  }

  /**
   * Converts a Domain Entity to a Persistence Schema (TypeORM).
   */
  static toPersistence(domain: User): UserSchema {
    const schema = new UserSchema();
    schema.id = domain.getId();
    schema.email = domain.getEmail();
    schema.passwordHash = domain.getPasswordHash();
    schema.role = domain.getRole();
    schema.isActive = domain.getIsActive();
    // createdAt and updatedAt are handled automatically by TypeORM on creation/update,
    // but we map them for consistency if they exist.
    return schema;
  }
}