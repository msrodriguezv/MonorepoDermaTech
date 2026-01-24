/**
 * Command: LogoutCommand
 * * Responsibility: Carries the data required to perform a logout (the token).
 */
export class LogoutCommand {
  constructor(public readonly token: string) {}
}