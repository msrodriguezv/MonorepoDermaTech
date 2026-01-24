/**
 * Domain Event: User Registered
 * Represents the fact that a new user has been successfully created in the system.
 */
export class UserRegisteredEvent {
  constructor(
    public readonly userId: string,
    public readonly email: string,
    public readonly role: string,
    public readonly occurredOn: Date = new Date(),
  ) {}
}