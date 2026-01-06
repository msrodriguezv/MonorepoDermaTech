import { IQueryHandler, QueryHandler } from '@nestjs/cqrs';
import { Logger } from '@nestjs/common';
import { GetPatientProfileQuery } from '../impl/get-patient-profile.query';
import { PatientService } from '../../../services/patient.service';
import { Patient } from '../../../entities/patient.entity';

/**
 * GetPatientProfileHandler
 * * Responsibility: Orchestrates data retrieval for the patient profile.
 * * Separation of Concerns: Keeps read logic separate from write logic (Commands).
 */
@QueryHandler(GetPatientProfileQuery)
export class GetPatientProfileHandler implements IQueryHandler<GetPatientProfileQuery> {
  private readonly logger = new Logger(GetPatientProfileHandler.name);

  constructor(private readonly patientService: PatientService) {}

  /**
   * Execution Logic:
   * 1. Receives the query intent.
   * 2. Delegates to the Service to fetch data safely.
   * @returns The Patient Entity.
   */
  async execute(query: GetPatientProfileQuery): Promise<Patient> {
    this.logger.debug(`CQRS: Reading profile for UserID: ${query.userId}`);
    return await this.patientService.findByUserId(query.userId);
  }
}