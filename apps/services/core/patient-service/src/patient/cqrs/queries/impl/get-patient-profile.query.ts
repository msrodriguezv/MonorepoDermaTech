/**
 * GetPatientProfileQuery
 * * Represents the intent to retrieve a patient's demographic profile.
 * * Architecture: CQRS (Query Side).
 * * Context: Triggered by REST API (GET /patients/me).
 */
export class GetPatientProfileQuery {
  /**
   * @param userId - The unique UUID from the authenticated user token.
   */
  constructor(public readonly userId: string) {}
}