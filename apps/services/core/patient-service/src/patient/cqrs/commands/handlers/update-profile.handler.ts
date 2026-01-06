import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { Logger } from '@nestjs/common';
import { UpdateProfileCommand } from '../impl/update-profile.command';
import { PatientService } from '../../../services/patient.service';
import { Patient } from '../../../entities/patient.entity';

/**
 * UpdateProfileHandler
 * * Responsibility: Orchestrates the profile update process initiated by the Student.
 */
@CommandHandler(UpdateProfileCommand)
export class UpdateProfileHandler implements ICommandHandler<UpdateProfileCommand> {
  private readonly logger = new Logger(UpdateProfileHandler.name);

  constructor(private readonly patientService: PatientService) {}

  /**
   * Execution Logic:
   * 1. Receives the strictly typed command.
   * 2. Delegates the update logic to the PatientService.
   * @returns The updated Patient Entity to be returned to the Frontend.
   */
  async execute(command: UpdateProfileCommand): Promise<Patient> {
    this.logger.log(`CQRS: Processing UpdateProfileCommand for UserID: ${command.userId}`);

    return await this.patientService.updateProfile(command.userId, command.dto);
  }
}