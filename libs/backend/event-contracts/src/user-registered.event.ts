/**
 * Event Contract: Defines the data payload sent over Kafka when a user registers.
 * This ensures Auth Service (Producer) and Patient Service (Consumer) speak the same language.
 */
export class UserRegisteredEvent {
  constructor(
    public readonly userId: string, // THIS IS THE KEY LINK
    public readonly email: string,
    public readonly role: string,
  ) {}

  // Helper to ensure it sends as a clean JSON string
  toString() {
    return JSON.stringify({
      userId: this.userId,
      email: this.email,
      role: this.role,
    });
  }
}