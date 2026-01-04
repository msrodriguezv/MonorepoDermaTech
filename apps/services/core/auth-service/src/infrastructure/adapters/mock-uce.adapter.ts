import { Injectable, Logger, ForbiddenException } from '@nestjs/common';
import { ExternalSystemPort } from '../../application/ports/external-system.port';

/**
 * Smart Mock Adapter for the External University System.
 * * STRATEGY CHANGE:
 * Instead of a strict whitelist (which blocks valid testing with random emails),
 * this mock uses a "Pattern Matching" strategy:
 * * 1. DEFAULT ALLOW: Any email ending in @uce.edu.ec is considered ACTIVE.
 * 2. SPECIFIC BLOCK: Emails containing keywords like 'graduado', 'debt', 'baja'
 * trigger specific failure scenarios for testing purposes.
 */
@Injectable()
export class MockUceAdapter implements ExternalSystemPort {
  private readonly logger = new Logger(MockUceAdapter.name);

  async checkStudentEnrollment(email: string): Promise<boolean> {
    this.logger.debug(`[MockUCE] Verifying enrollment for: ${email}`);
    
    // 1. Simulate Network Latency
    await new Promise((resolve) => setTimeout(resolve, 300));

    const normalizedEmail = email.toLowerCase();

    // ---------------------------------------------------------
    // RULE 1: STRICT DOMAIN VALIDATION
    // ---------------------------------------------------------
    if (!normalizedEmail.endsWith('@uce.edu.ec')) {
      this.logger.warn(`[MockUCE] REJECTED: Invalid domain for ${email}`);
      throw new ForbiddenException(
        'Registration restricted to @uce.edu.ec domain.'
      );
    }

    // ---------------------------------------------------------
    // RULE 2: SIMULATED FAILURE SCENARIOS
    // ---------------------------------------------------------
    
    // Scenario: Alumni / Graduated
    if (normalizedEmail.includes('graduado') || normalizedEmail.includes('alumni')) {
        this.logger.warn(`[MockUCE] REJECTED: User ${email} simulates ALUMNI status.`);
        throw new ForbiddenException(
            'Registration failed. User is an Alumni/Graduated. Service only for currently enrolled students.'
        );
    }

    // Scenario: Financial Debt / Blocked
    if (normalizedEmail.includes('deuda') || normalizedEmail.includes('bloqueado')) {
        this.logger.warn(`[MockUCE] REJECTED: User ${email} simulates BLOCKED status.`);
        throw new ForbiddenException(
            'University system rejected the registration due to administrative status (Financial Hold).'
        );
    }

    // Scenario: Withdrawn / Dropout
    if (normalizedEmail.includes('retirado') || normalizedEmail.includes('baja')) {
        this.logger.warn(`[MockUCE] REJECTED: User ${email} simulates WITHDRAWN status.`);
        throw new ForbiddenException(
            'Registration failed. Student status is WITHDRAWN/DROPOUT.'
        );
    }

    // ---------------------------------------------------------
    // RULE 3: DEFAULT SUCCESS
    // ---------------------------------------------------------
    // If it has the correct domain and no "bad words", we assume it's a valid student.
    this.logger.log(`[MockUCE] APPROVED: Student ${email} is verified as ACTIVE.`);
    return true; 
  }
}