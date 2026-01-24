import { User } from './user.entity';
import { UserEmail } from '../value-objects/user-email.vo';
import { UserRole } from '@dermatech/shared-dtos';

describe('User Entity', () => {
  const validEmail = 'test@example.com';
  const validPasswordHash = 'hashed_password_123';
  const validId = 'user-id-123';

  describe('getEmail()', () => {
    it('should return a UserEmail object instead of a string', () => {
      // Arrange
      const emailVO = new UserEmail(validEmail);
      const user = new User(
        validId,
        emailVO,
        validPasswordHash,
        UserRole.STUDENT
      );

      // Act
      const result = user.getEmail();

      // Assert
      expect(result).toBeInstanceOf(UserEmail);
    });

    it('should return the same UserEmail object that was provided in constructor', () => {
      // Arrange
      const emailVO = new UserEmail(validEmail);
      const user = new User(
        validId,
        emailVO,
        validPasswordHash,
        UserRole.STUDENT
      );

      // Act
      const result = user.getEmail();

      // Assert
      expect(result).toBe(emailVO);
    });

    it('should not return a string representation of the email', () => {
      // Arrange
      const emailVO = new UserEmail(validEmail);
      const user = new User(
        validId,
        emailVO,
        validPasswordHash,
        UserRole.STUDENT
      );

      // Act
      const result = user.getEmail();

      // Assert
      expect(typeof result).not.toBe('string');
      expect(result).not.toBe(validEmail);
    });

    it('should have access to email value through UserEmail.email property', () => {
      // Arrange
      const emailVO = new UserEmail(validEmail);
      const user = new User(
        validId,
        emailVO,
        validPasswordHash,
        UserRole.STUDENT
      );

      // Act
      const emailObject = user.getEmail();

      // Assert
      expect(emailObject.email).toBe(validEmail);
    });

    it('should allow comparison between UserEmail objects using equals method', () => {
      // Arrange
      const emailVO1 = new UserEmail(validEmail);
      const emailVO2 = new UserEmail(validEmail);
      const user = new User(
        validId,
        emailVO1,
        validPasswordHash,
        UserRole.STUDENT
      );

      // Act
      const result = user.getEmail();

      // Assert
      expect(result.equals(emailVO2)).toBe(true);
    });
  });

  describe('Basic User Entity Tests', () => {
    it('should create a user with all required properties', () => {
      // Arrange
      const emailVO = new UserEmail(validEmail);

      // Act
      const user = new User(
        validId,
        emailVO,
        validPasswordHash,
        UserRole.STUDENT
      );

      // Assert
      expect(user.getId()).toBe(validId);
      expect(user.getEmail()).toBe(emailVO);
      expect(user.getPasswordHash()).toBe(validPasswordHash);
      expect(user.getRole()).toBe(UserRole.STUDENT);
      expect(user.getIsActive()).toBe(true);
    });
  });
});
