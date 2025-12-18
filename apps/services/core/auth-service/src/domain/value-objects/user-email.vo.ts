// apps/services/core/auth-service/src/domain/value-objects/user-email.vo.ts

export class UserEmail {
  private readonly email: string;

  constructor(email: string) {
    if (!this.validate(email)) {
      throw new Error('Invalid email format');
    }
    this.email = email;
  }

  private validate(email: string): boolean {
    // Standard Regex for Email Validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  public getValue(): string {
    return this.email;
  }

  public equals(other: UserEmail): boolean {
    return this.email === other.getValue();
  }
}