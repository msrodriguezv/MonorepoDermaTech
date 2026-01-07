import { BookAppointmentDto } from '../../../dto/book-appointment.dto';

/**
 * Command to book an appointment.
 * Merges the untrusted user input (DTO) with the trusted user identity (studentId).
 */
export class BookAppointmentCommand {
  constructor(
    public readonly studentId: string, // From JWT (Trusted)
    public readonly dto: BookAppointmentDto // From Body (Validated)
  ) {}
}