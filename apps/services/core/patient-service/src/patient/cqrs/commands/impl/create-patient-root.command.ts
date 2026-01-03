/**
 * CreatePatientRootCommand
 * * Represents the intent to initialize a base patient record.
 * * Architecture: CQRS (Command Side).
 * * Context: Triggered strictly by the 'user.registered' event from Auth Service.
 * * Data Source: Trusted internal payload from the Message Broker (Kafka).
 */
export class CreatePatientRootCommand {
  /**
   * @param userId - The unique UUID provided by the Auth Service (Authentication ID).
   * @param email - The user's registered email address.
   */
  constructor(
    public readonly userId: string,
    public readonly email: string,
  ) {}
}