import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import {
  Inject,
  Logger,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import * as crypto from 'node:crypto';

import { RegisterUserCommand } from './register-user.command';
import { User } from '../../../domain/entities/user.entity';
import { UserEmail } from '../../../domain/value-objects/user-email.vo';
import { UserRegisteredEvent } from '@dermatech/event-contracts';

// --- PORTS IMPORTS ---
import { UserRepositoryPort } from '../../ports/user.repository.port';
import { CryptoServicePort } from '../../ports/crypto.service.port';
import { ExternalSystemPort } from '../../ports/external-system.port';
import { EventPublisherPort } from '../../ports/event.publisher.port';

/**
 * Application Service responsible for handling user registration.
 * Implements the Command Handler pattern from CQRS.
 * * ARCHITECTURE DECISION:
 * This handler prioritizes Data Consistency (Persistence) over Eventual Consistency (Kafka).
 * If the DB write succeeds but Event publishing fails, we still return success to the client
 * to prevent UX blocking (infinite spinners), while logging the error for reconciliation.
 */
@CommandHandler(RegisterUserCommand)
export class RegisterUserCommandHandler
  implements ICommandHandler<RegisterUserCommand>
{
  private readonly logger = new Logger(RegisterUserCommandHandler.name);

  constructor(
    @Inject('UserRepositoryPort')
    private readonly userRepository: UserRepositoryPort,
    @Inject('CryptoServicePort')
    private readonly cryptoService: CryptoServicePort,
    @Inject('ExternalSystemPort')
    private readonly externalSystem: ExternalSystemPort,
    @Inject('EventPublisherPort')
    private readonly eventPublisher: EventPublisherPort
  ) {}

  /**
   * Executes the registration business logic.
   * Flow:
   * 1. Validate External Enrollment.
   * 2. Validate User Uniqueness.
   * 3. Instantiate Domain Value Objects (Validation).
   * 4. Hash Password.
   * 5. Persist Entity (Critical Path).
   * 6. Publish Integration Event (Non-Blocking / Fail-Safe).
   */
  async execute(command: RegisterUserCommand): Promise<User> {
    this.logger.log(`Processing registration for: ${command.email}`);

    // 1. External System Validation
    // Validates if the user is a valid member in the external university system.
    const isEnrolled = await this.externalSystem.checkStudentEnrollment(command.email);
    
    if (!isEnrolled) {
        this.logger.warn(`Registration blocked: User ${command.email} not enrolled in external system.`);
        throw new BadRequestException('User is not enrolled in the external system');
    }

    // 2. Uniqueness Check
    const existingUser = await this.userRepository.findByEmail(command.email);

    if (existingUser) {
      // Mitigate Timing Attacks by simulating a hash operation
      await this.cryptoService.hash('dummy_password_to_simulate_workload');
      this.logger.warn(`Registration failed: Email ${command.email} already exists.`);
      throw new ConflictException('User already exists');
    }

    // 3. Value Object Creation
    let emailVO: UserEmail;
    try {
      emailVO = new UserEmail(command.email);
    } catch (error) {
      // Utilizing the error variable satisfies the linter
      this.logger.error(
        `Invalid email format: ${error instanceof Error ? error.message : error}`
      );
      throw new BadRequestException('Invalid email format provided');
    }

    // 4. Password Hashing
    const passwordHash = await this.cryptoService.hash(command.password);

    // 5. Domain Entity Creation
    const newUser = new User(
      crypto.randomUUID(),
      emailVO,
      passwordHash,
      command.role
    );

    // 6. Persistence (CRITICAL PATH)
    // Once saved, the user officially exists in the system database.
    const savedUser = await this.userRepository.save(newUser);
    this.logger.log(`User persisted successfully with ID: ${savedUser.getId()}`);

    // 7. Event Publishing (FAIL-SAFE)
    // We wrap this in a try-catch to ensure that infrastructure issues (Kafka down, Network partition)
    // do not rollback the successful DB creation or cause a HTTP 500/Timeout to the client.
    try {
      const event = new UserRegisteredEvent(
        savedUser.getId(), 
        savedUser.getEmail().email,
        savedUser.getRole()
      );

      this.logger.log('Attempting to publish UserRegisteredEvent to Message Broker...');
      
      // We await this to guarantee delivery if possible, but we catch errors if it fails/timeouts.
      await this.eventPublisher.publish('auth.user.registered', event);
      
      this.logger.log('Event published successfully.');
    } catch (error) {
      // CRITICAL: LOGGING FOR RECOVERY
      // We explicitly use the 'error' variable here to log the root cause 
      // and satisfy TypeScript 'no-unused-vars' rules.
      this.logger.error(
        `CRITICAL: User created but Event Publishing FAILED. Downstream services will not be notified. Error details: ${error}`
      );
      // Future TODO: Save to 'Outbox' table for retry mechanism.
    }

    // 8. Return Entity to Controller
    return savedUser;
  }
}