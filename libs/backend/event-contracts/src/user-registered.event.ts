/**
 * Event Contract: Defines the data payload sent over Kafka when a user registers.
 * This ensures Auth Service (Producer) and Patient Service (Consumer) speak the same language.
 */
export class UserRegisteredEvent {
  
  public readonly userId: string;

  public readonly email: string;

  public readonly role: string;

  constructor(userId: string, email: string, role: string) {
    this.userId = userId;
    this.email = email;
    this.role = role;
  }

  /**
   * Helper to ensure the event payload is serialized as a clean JSON string.
   */
  toString(): string {
    return JSON.stringify({
      userId: this.userId,
      email: this.email,
      role: this.role,
    });
  }
}