import { UpdateProfileDto } from '../../../dto/update-profile.dto';

/**
 * UpdateProfileCommand
 * * Represents the intent to complete or update the patient's personal profile.
 * * Architecture: CQRS (Command Side).
 * * Context: Triggered by the REST API (PUT /patients/me) after JWT validation.
 */
export class UpdateProfileCommand {
  /**
   * @param userId - The unique UUID extracted safely from the JWT Token by the Controller.
   * @param dto - The validated payload containing personal and medical details.
   */
  constructor(
    public readonly userId: string,
    public readonly dto: UpdateProfileDto,
  ) {}
}