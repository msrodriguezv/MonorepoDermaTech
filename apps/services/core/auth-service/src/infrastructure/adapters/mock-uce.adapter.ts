import { Injectable, Logger, ForbiddenException } from '@nestjs/common';
import { ExternalSystemPort } from '../../application/ports/external-system.port';

/**
 * Mock Adapter for the External University System.
 * Simulates network latency and validates domain rules using an in-memory database
 * to replicate real-world scenarios (Active, Alumni, Withdrawn).
 */
@Injectable()
export class MockUceAdapter implements ExternalSystemPort {
  private readonly logger = new Logger(MockUceAdapter.name);

  // SIMULATED DATABASE
  // This dictionary acts as the "Source of Truth" for the University Registry.
  private readonly uceStudentDatabase = {
    // Valid Student
    'estudiante.activo@uce.edu.ec': { status: 'ACTIVE', faculty: 'MEDICINE' },
    // Valid Student (Alternative)
    'juan.perez@uce.edu.ec': { status: 'ACTIVE', faculty: 'ENGINEERING' },
    // Invalid: Graduated student
    'maria.graduada@uce.edu.ec': { status: 'ALUMNI', faculty: 'LAW' }, 
    // Invalid: Student dropped out
    'pedro.retirado@uce.edu.ec': { status: 'WITHDRAWN', faculty: 'ARTS' },
    // Invalid: Administrative block (e.g. debt)
    'roberto.deuda@uce.edu.ec': { status: 'BLOCKED_FINANCIAL', faculty: 'ECONOMICS' }
  };

  async validateStudentEnrollment(email: string): Promise<void> {
    this.logger.debug(`[MockUCE] Verifying enrollment for: ${email}`);
    
    // 1. Simulate Network Latency (Realism)
    await new Promise((resolve) => setTimeout(resolve, 300));

    // 2. Validate Domain Policy (First Barrier)
    if (!email.endsWith('@uce.edu.ec')) {
      this.logger.warn(`[MockUCE] Verification Failed: Invalid domain for ${email}`);
      throw new ForbiddenException(
        'Registration restricted to @uce.edu.ec domain.'
      );
    }

    // 3. Lookup in Simulated Database
    // We normalize to lowercase to ensure consistent matching
    const studentRecord = this.uceStudentDatabase[email.toLowerCase()];

    // CASE A: Student does not exist in the University Registry
    // This happens if someone invents a fake email like "hacker@uce.edu.ec"
    if (!studentRecord) {
      this.logger.warn(`[MockUCE] Verification Failed: Email ${email} not found in registry.`);
      throw new ForbiddenException(
        'Student identifier not found in University records. Please verify your institutional email.'
      );
    }

    // 4. Validate Academic Status (Business Logic)
    switch (studentRecord.status) {
      case 'ACTIVE':
        this.logger.log(`[MockUCE] Success: Student ${email} is ACTIVE (${studentRecord.faculty}).`);
        return; // Validation Passed

      case 'ALUMNI':
        this.logger.warn(`[MockUCE] Rejected: User ${email} is ALUMNI.`);
        throw new ForbiddenException(
          'Registration failed. User is an Alumni/Graduated. Service only for currently enrolled students.'
        );

      case 'WITHDRAWN':
        this.logger.warn(`[MockUCE] Rejected: User ${email} is WITHDRAWN.`);
        throw new ForbiddenException(
          'Registration failed. Student status is WITHDRAWN/DROPOUT.'
        );

      case 'BLOCKED_FINANCIAL':
        this.logger.warn(`[MockUCE] Rejected: User ${email} is BLOCKED.`);
        throw new ForbiddenException(
          'University system rejected the registration due to administrative status.'
        );

      default:
        this.logger.error(`[MockUCE] Unknown status for ${email}`);
        throw new ForbiddenException('Unexpected error retrieving student status.');
    }
  }
}