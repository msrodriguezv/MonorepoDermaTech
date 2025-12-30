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

// Ports (Interfaces)
import { UserRepositoryPort } from '../../ports/user.repository.port';
import { CryptoServicePort } from '../../ports/crypto.service.port';
import { ExternalSystemPort } from '../../ports/external-system.port';

import { ClientKafka } from '@nestjs/microservices'; // Import Kafka Client Interface
import { UserRegisteredEvent } from '@dermatech/event-contracts';
/**
 * Application Service responsible for handling the user registration logic.
 * Orchestrates domain objects and infrastructure ports.
 */
@CommandHandler(RegisterUserCommand)
export class RegisterUserCommandHandler
  implements ICommandHandler<RegisterUserCommand>
{
  private readonly logger = new Logger(RegisterUserCommandHandler.name);

  /**
   * @param userRepository - Persistence adapter for User entity.
   * @param cryptoService - Service for hashing passwords securely.
   * @param externalSystem - Adapter for validating user enrollment (UCE).
   */
  constructor(
    @Inject('UserRepositoryPort')
    private readonly userRepository: UserRepositoryPort,
    @Inject('CryptoServicePort')
    private readonly cryptoService: CryptoServicePort,
    @Inject('ExternalSystemPort')
    private readonly externalSystem: ExternalSystemPort,
    // INJECT KAFKA CLIENT
    @Inject('KAFKA_SERVICE') 
    private readonly kafkaClient: ClientKafka
  ) {}

  /**
   * Executes the registration logic.
   * 1. Validates UCE Enrollment (External System).
   * 2. Validates if user already exists (with Timing Attack Mitigation).
   * 3. Creates Domain Value Objects.
   * 4. Hashes the password.
   * 5. Creates and Persists the Domain Entity.
   *
   * @param command - The data required for registration.
   * @throws ConflictException if the email is already registered.
   * @throws ForbiddenException if the user is not valid in the external system.
   * @returns The newly created User entity.
   */
  async execute(command: RegisterUserCommand): Promise<User> {
    // SECURITY: Avoid logging PII (command.email)
    this.logger.log('Processing new user registration request');

    // 1. External System Validation (Business Logic)
    // We enforce that the user must be a valid student in the external system
    // before performing database checks or expensive hashing operations.
    await this.externalSystem.validateStudentEnrollment(command.email);

    // 2. Check if user already exists
    // We use command.email because it is the raw string from the request
    const existingUser = await this.userRepository.findByEmail(command.email);

    if (existingUser) {
      // SECURITY: Timing Attack Mitigation.
      // We simulate a hashing operation so the response time is similar
      // regardless of whether the user exists or not.
      await this.cryptoService.hash('dummy_password_to_simulate_workload');

      this.logger.warn('Registration attempt failed: User already exists.');
      throw new ConflictException('User already exists');
    }

    // 3. Create Value Objects
    // Note: UserEmail constructor throws an error if format is invalid
    let emailVO: UserEmail;
    try {
      emailVO = new UserEmail(command.email);
    } catch (error) {
      // Log the specific error stack or message for debugging
      // without exposing sensitive data if possible.
      this.logger.error(
        `Invalid email format attempt`,
        error instanceof Error ? error.stack : String(error)
      );
      throw new BadRequestException('Invalid email format provided');
    }

    // 4. Hash the password
    const passwordHash = await this.cryptoService.hash(command.password);

    // 5. Create Domain Entity
    const newUser = new User(
      crypto.randomUUID(),
      emailVO,
      passwordHash,
      command.role
    );

    // 6. Persist the User
    const savedUser = await this.userRepository.save(newUser);

    // --- STEP: KAFKA SYNC ---
    // We emit the event so Patient Service can create the profile profile asynchronously.
    // The "userId" here is the link between the two databases.
    const event = new UserRegisteredEvent(
      savedUser.getId(), 
      savedUser.getEmail().email,
      savedUser.getRole()
    );

    // 'auth.user.registered' is the TOPIC name
    this.kafkaClient.emit('auth.user.registered', event);

    this.logger.log(
      `User registered successfully with ID: ${savedUser.getId()}`
    );

    return savedUser;
  }
}