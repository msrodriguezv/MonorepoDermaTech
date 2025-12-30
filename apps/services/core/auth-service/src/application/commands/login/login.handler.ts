import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { Inject, UnauthorizedException, Logger } from '@nestjs/common';

// Shared Library Import (Crucial for Type Safety)
import { JwtPayload } from '@dermatech/shared-dtos';

import { LoginCommand } from './login.command';
import { TokenResponseDto } from '../../../api/http/dtos/token-response.dto';

// Ports (Hexagonal Architecture Interfaces)
import { UserRepositoryPort } from '../../ports/user.repository.port';
import { CryptoServicePort } from '../../ports/crypto.service.port';
import { TokenServicePort } from '../../ports/token.service.port';

/**
 * Application Service (Handler) responsible for User Authentication.
 * Implements the logic for validating credentials and issuing JWTs.
 */
@CommandHandler(LoginCommand)
export class LoginHandler implements ICommandHandler<LoginCommand> {
  private readonly logger = new Logger(LoginHandler.name);

  constructor(
    @Inject('UserRepositoryPort') 
    private readonly userRepository: UserRepositoryPort,
    @Inject('CryptoServicePort') 
    private readonly cryptoService: CryptoServicePort,
    @Inject('TokenServicePort') 
    private readonly tokenService: TokenServicePort,
  ) {}

  /**
   * Executes the login logic:
   * 1. Validate User existence.
   * 2. Validate Password match.
   * 3. Validate Account status (Active).
   * 4. Generate JWT Tokens (Access & Refresh).
   * 5. Persist Refresh Token Hash (Token Rotation Strategy).
   */
  async execute(command: LoginCommand): Promise<TokenResponseDto> {
    const { email, password } = command;
    this.logger.log(`Processing login attempt for email: ${email}`);

    // 1. Find User by Email
    const user = await this.userRepository.findByEmail(email);
    if (!user) {
      // SECURITY: Use generic error message to prevent User Enumeration attacks.
      this.logger.warn(`Login failed: User not found for email ${email}`);
      throw new UnauthorizedException('Invalid credentials');
    }

    // 2. Validate Password
    const isPasswordValid = await this.cryptoService.compare(password, user.getPasswordHash());
    if (!isPasswordValid) {
      this.logger.warn(`Login failed: Invalid password for user ID ${user.getId()}`);
      throw new UnauthorizedException('Invalid credentials');
    }

    // 3. Check Active Status
    if (!user.getIsActive()) {
      this.logger.warn(`Login prevented: User ${user.getId()} is inactive.`);
      throw new UnauthorizedException('User account is inactive');
    }

    // 4. Generate Tokens
    // We strictly type the payload to match the shared contract expected by other microservices.
    const payload: JwtPayload = { 
      sub: user.getId(), 
      email: user.getEmail().email, // Ensure your UserEmail VO has getValue()
      role: user.getRole() 
    };

    const accessToken = await this.tokenService.generateAccessToken(payload);
    const refreshToken = await this.tokenService.generateRefreshToken(payload);

    // 5. Security: Store Refresh Token Hash (Token Rotation)
    // This requires the 'setRefreshTokenHash' method to exist in your User Entity.
    const refreshTokenHash = await this.cryptoService.hash(refreshToken);
    user.setRefreshTokenHash(refreshTokenHash);
    
    // 6. Update User in DB (Persist the new hash)
    await this.userRepository.save(user);

    this.logger.log(`User logged in successfully: ${user.getId()}`);

    return {
      accessToken,
      refreshToken,
      expiresIn: 900, // 15 minutes (should match your JWT config)
    };
  }
}