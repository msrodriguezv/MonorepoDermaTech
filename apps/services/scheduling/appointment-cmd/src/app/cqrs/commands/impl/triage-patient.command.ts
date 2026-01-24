import { TriageDecisionDto } from '../../../dto/triage-decision.dto';

/**
 * Command payload to register the nurse's decision.
 * Triggers the state transition from SCHEDULED to WAITING_FOR_DOCTOR or REFERRED.
 */
export class TriagePatientCommand {
  constructor(
    public readonly appointmentId: string,
    public readonly dto: TriageDecisionDto
  ) {}
}