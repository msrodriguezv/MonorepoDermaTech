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
 */
@CommandHandler(RegisterUserCommand)
export class RegisterUserCommandHandler
  implements ICommandHandler<RegisterUserCommand>
{
  private readonly logger = new Logger(RegisterUserCommandHandler.name);

  /**
   * @param userRepository - Persistence adapter for User entity.
   * @param cryptoService - Service for hashing passwords securely.
   * @param externalSystem - Adapter for validating user enrollment in external systems (UCE).
   * @param eventPublisher - Port for publishing domain/integration events asynchronously.
   */
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
   * * Flow:
   * 1. Validate External Enrollment.
   * 2. Validate User Uniqueness.
   * 3. Instantiate Domain Value Objects (Validation).
   * 4. Hash Password.
   * 5. Persist Entity.
   * 6. Publish Integration Event.
   */
  async execute(command: RegisterUserCommand): Promise<User> {
    this.logger.log('Processing new user registration request');

    // 1. External System Validation
    // Verifies if the user is a valid member in the external university system.
    const isEnrolled = await this.externalSystem.checkStudentEnrollment(command.email);
    
    if (!isEnrolled) {
        throw new BadRequestException('User is not enrolled in the external system');
    }

    // 2. Uniqueness Check
    const existingUser = await this.userRepository.findByEmail(command.email);

    if (existingUser) {
      // Mitigate Timing Attacks by simulating a hash operation
      await this.cryptoService.hash('dummy_password_to_simulate_workload');
      this.logger.warn('Registration attempt failed: User already exists.');
      throw new ConflictException('User already exists');
    }

    // 3. Value Object Creation
    // UserEmail constructor validates format logic internally.
    let emailVO: UserEmail;
    try {
      emailVO = new UserEmail(command.email);
    } catch (error) {
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

    // 6. Persistence
    const savedUser = await this.userRepository.save(newUser);

    // 7. Event Publishing
    // Publishes the event so other microservices can react to the new user.
    const event = new UserRegisteredEvent(
      savedUser.getId(), 
      savedUser.getEmail().email,
      savedUser.getRole()
    );

    await this.eventPublisher.publish('auth.user.registered', event);

    this.logger.log(`User registered successfully with ID: ${savedUser.getId()}`);

    return savedUser;
  }
}