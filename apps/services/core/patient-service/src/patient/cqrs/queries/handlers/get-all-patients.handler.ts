import { IQueryHandler, QueryHandler } from '@nestjs/cqrs';
import { Logger } from '@nestjs/common';
import { GetAllPatientsQuery } from '../impl/get-all-patients.query';
import { PatientService } from '../../../services/patient.service';
import { Patient } from '../../../entities/patient.entity';

/**
 * Handler for GetAllPatientsQuery.
 * Executes the business logic to fetch all patient records via the Domain Service.
 */
@QueryHandler(GetAllPatientsQuery)
export class GetAllPatientsHandler implements IQueryHandler<GetAllPatientsQuery> {
  private readonly logger = new Logger(GetAllPatientsHandler.name);

  constructor(
    private readonly patientService: PatientService
  ) {}

  /**
   * Execution method for the Query.
   * @param query - The query object. We use its metadata for secure logging to satisfy linter rules.
   * @returns Promise<Patient[]> - A list of all registered patients.
   */
  async execute(query: GetAllPatientsQuery): Promise<Patient[]> {
    // [SECURE LOGGING] 
    // We log the *Action Name* (metadata) to satisfy the 'no-unused-vars' rule.
    // We DO NOT log the content (JSON.stringify) to prevent accidental data leaks (PII/Security).
    this.logger.log(`Async Query Executing: ${query.constructor.name}`);
    
    return await this.patientService.findAll();
  }
}