import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { Inject, Logger, BadRequestException } from '@nestjs/common';
import * as crypto from 'node:crypto';

import { RegisterUserCommand } from './register-user.command';
import { User } from '../../../domain/entities/user.entity';
import { UserEmail } from '../../../domain/value-objects/user-email.vo';

// Ports (Interfaces)
import { UserRepositoryPort } from '../../ports/user.repository.port';
import { CryptoServicePort } from '../../ports/crypto.service.port';

/**
 * Application Service responsible for handling the user registration logic.
 * Orchestrates domain objects and infrastructure ports.
 */
@CommandHandler(RegisterUserCommand)
export class RegisterUserCommandHandler implements ICommandHandler<RegisterUserCommand> {
  private readonly logger = new Logger(RegisterUserCommandHandler.name);

  /**
   * @param userRepository - Persistence adapter for User entity.
   * @param cryptoService - Service for hashing passwords securely.
   */
  constructor(
    @Inject('UserRepositoryPort') private readonly userRepository: UserRepositoryPort,
    @Inject('CryptoServicePort') private readonly cryptoService: CryptoServicePort,
  ) {}

  /**
   * Executes the registration logic.
   * 1. Validates if user already exists.
   * 2. Hashes the password.
   * 3. Creates the Domain Entity.
   * 4. Persists the user.
   *
   * @param command - The data required for registration.
   * @throws ConflictException if the email is already registered.
   * @returns The newly created User entity (without sensitive data ideally).
   */
  async execute(command: RegisterUserCommand): Promise<User> {
    this.logger.log(`Processing registration for email: ${command.email} with role: ${command.role}`);

    // 1. Check if user already exists
    const existingUser = await this.userRepository.findByEmail(command.email);
    if (existingUser) {
      this.logger.warn('Registration attempt failed: User already exists.');
      this.logger.debug(`Email conflict: ${command.email}`); 
      throw new BadRequestException('User already exists');
    }

    // 2. Hash the password
    const passwordHash = await this.cryptoService.hash(command.password);

    // 3. Create Value Objects and Domain Entity
    // Note: UserEmail constructor throws an error if format is invalid
    let emailVO: UserEmail;
    try {
      new UserEmail(command.email);
    } catch {
      this.logger.error(`Invalid email format attempt`); 
      throw new BadRequestException('Invalid email format provided');
  }

    // ALL: Mandatory R5 - If Role is STUDENT, we must validate against "Mock IDP UCE" here.
    // We will implement the IdentityProviderPort later to fulfill this requirement.

    const newUser = new User(
      crypto.randomUUID(), // Ensure you have crypto available or use a UUID lib
      emailVO,
      passwordHash,
      command.role,
    );

    // 4. Persist the User
    const savedUser = await this.userRepository.save(newUser);
    
    this.logger.log(`User registered successfully with ID: ${savedUser.getId()}`);

    return savedUser;
  }
}