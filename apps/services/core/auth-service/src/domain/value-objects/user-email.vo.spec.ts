import { UserEmail, InvalidUserEmailError } from './user-email.vo';

describe('UserEmail Value Object', () => {
  it('should create a valid email instance', () => {
    const validEmail = 'student@uce.edu.ec';
    const userEmail = new UserEmail(validEmail);
    expect(userEmail.value).toBe(validEmail);
  });

  it('should throw InvalidUserEmailError for invalid email format', () => {
    const invalidEmail = 'invalid-email';
    expect(() => {
      new UserEmail(invalidEmail);
    }).toThrow(InvalidUserEmailError);
  });

  it('should throw error for empty string', () => {
    expect(() => {
      new UserEmail('');
    }).toThrow(InvalidUserEmailError);
  });

  it('should throw error for email without domain', () => {
    expect(() => {
      new UserEmail('user@');
    }).toThrow(InvalidUserEmailError);
  });
});