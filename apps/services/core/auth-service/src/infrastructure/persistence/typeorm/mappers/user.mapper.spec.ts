import { UserMapper } from './user.mapper';
import { User } from '../../../../domain/entities/user.entity';
import { UserSchema } from '../entities/user.schema';
import { UserEmail } from '../../../../domain/value-objects/user-email.vo';
import { UserRole } from '@dermatech/shared-dtos';

describe('UserMapper', () => {
  /**
   * Ensures data integrity when transforming between Domain Entities and Persistence Schemas.
   */

  // Valid UUID for testing
  const userId = '123e4567-e89b-12d3-a456-426614174000';

  it('should map from Persistence Schema to Domain Entity', () => {
    // Arrange: Create a raw DB object (TypeORM Schema)
    const userSchema = new UserSchema();
    userSchema.id = userId;
    userSchema.email = 'mapper@test.com';
    userSchema.passwordHash = 'hashed_secret';
    userSchema.role = UserRole.DOCTOR;
    userSchema.isActive = true;

    // Act
    const domainEntity = UserMapper.toDomain(userSchema);

    // Assert
    expect(domainEntity).toBeInstanceOf(User);
    expect(domainEntity.getId()).toBe(userId);
    expect(domainEntity.getEmail().email).toBe('mapper@test.com');
    expect(domainEntity.getRole()).toBe(UserRole.DOCTOR);
  });

  it('should map from Domain Entity to Persistence Schema', () => {
    // Arrange: Create a Domain Entity
    const domainEntity = new User(
      userId,
      new UserEmail('domain@test.com'),
      'hashed_secret',
      UserRole.STUDENT,
      true
    );

    // Act
    const persistenceSchema = UserMapper.toPersistence(domainEntity);

    // Assert
    expect(persistenceSchema).toBeInstanceOf(UserSchema);
    expect(persistenceSchema.id).toBe(userId);
    expect(persistenceSchema.email).toBe('domain@test.com');
    // Ensure sensitive data is carried over correctly
    expect(persistenceSchema.passwordHash).toBe('hashed_secret');
  });
});