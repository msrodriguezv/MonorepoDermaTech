import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { Logger } from '@nestjs/common';
import { CreatePatientRootCommand } from '../impl/create-patient-root.command';
import { PatientService } from '../../../services/patient.service';

/**
 * CreatePatientRootHandler
 * * Responsibility: Orchestrates the creation of the empty patient record.
 * * Pattern: Decouples the Event Controller (Kafka) from the Domain Service.
 */
@CommandHandler(CreatePatientRootCommand)
export class CreatePatientRootHandler implements ICommandHandler<CreatePatientRootCommand> {
  private readonly logger = new Logger(CreatePatientRootHandler.name);

  constructor(private readonly patientService: PatientService) {}

  /**
   * Execution Logic:
   * 1. Logs the intent for audit purposes.
   * 2. Delegates the atomic creation to the Domain Service.
   */
  async execute(command: CreatePatientRootCommand): Promise<void> {
    this.logger.log(`[CQRS] Processing CreatePatientRootCommand for UserID: ${command.userId}`);
    
    // We await the service to ensure any DB errors are caught/logged properly
    await this.patientService.createRootPatient(command.userId, command.email);
  }
}