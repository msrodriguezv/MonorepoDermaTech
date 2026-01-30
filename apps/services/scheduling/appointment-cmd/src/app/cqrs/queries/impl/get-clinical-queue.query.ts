import { AppointmentStatus } from '../../../entities/appointment.entity';

/**
 * Query to fetch the clinical queue based on status.
 * Used by Nurses (SCHEDULED) and Doctors (WAITING_FOR_DOCTOR).
 */
export class GetClinicalQueueQuery {
  constructor(
    public readonly status: AppointmentStatus,
    public readonly doctorId?: string // Optional: Only if filtering by doctor
  ) {}
}