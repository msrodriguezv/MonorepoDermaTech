// apps/services/core/auth-service/src/domain/value-objects/user-email.vo.ts
export class InvalidUserEmailError extends Error {
  constructor() {
    super('Invalid email format. Expected standard format like "user@domain.com"'); // generic message secure
    this.name = 'InvalidUserEmailError';
  }
}

export class UserEmail {
  public readonly email: string;

  constructor(email: string) {
    if (!this.validate(email)) {
      throw new InvalidUserEmailError();
    }
    this.email = email;
  }

  private validate(email: string): boolean {
    // FIX: More robust Email Regex
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return emailRegex.test(email);
  }

  public equals(other: UserEmail): boolean {
    return this.email === other.email;
  }
}