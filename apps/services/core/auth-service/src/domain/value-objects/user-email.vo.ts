// apps/services/core/auth-service/src/domain/value-objects/user-email.vo.ts
export class InvalidUserEmailError extends Error {
  constructor() {
    super('Invalid email format'); // generic message secure
    this.name = 'InvalidUserEmailError';
  }
}

export class UserEmail {
  private readonly email: string;
  public readonly value: string;

  constructor(email: string) {
    if (!this.validate(email)) {
      throw new InvalidUserEmailError();
    }
    this.email = email;
  }

  private validate(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);;
  }

  public getValue(): string {
    return this.email;
  }

  public equals(other: UserEmail): boolean {
    return this.email === other.getValue();
  }
}