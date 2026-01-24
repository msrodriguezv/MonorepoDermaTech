import { CommandHandler, ICommandHandler } from '@nestjs/cqrs';
import { Inject, UnauthorizedException, Logger } from '@nestjs/common';

// --- SHARED DTOs ---
import { 
  JwtPayload, 
  TokenResponseDto, 
  UserRole 
} from '@dermatech/shared-dtos';

import { LoginCommand } from './login.command';

// --- PORTS ---
import { UserRepositoryPort } from '../../ports/user.repository.port';
import { CryptoServicePort } from '../../ports/crypto.service.port';
import { TokenServicePort } from '../../ports/token.service.port';

/**
 * Application Service (Handler) responsible for User Authentication.
 * Implements the logic for validatin
 * g credentials, issuing JWTs, and enforcing Token Rotation.
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
    // Compare provided plain password with the stored hash using the Crypto Port
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

    // 4. Prepare Payload
    // We strictly type the payload to match the shared contract expected by Guards/Strategies.
    const payload: JwtPayload = { 
      sub: user.getId(), 
      email: user.getEmail().email, 
      role: user.getRole() as UserRole 
    };

    // 5. Generate Tokens
    const accessToken = await this.tokenService.generateAccessToken(payload);
    const refreshToken = await this.tokenService.generateRefreshToken(payload);

    // 6. Security: Store Refresh Token Hash (Token Rotation)
    // We NEVER store the plain refresh token. We store its hash.
    const refreshTokenHash = await this.cryptoService.hash(refreshToken);
    
    // Update the entity state
    user.setRefreshTokenHash(refreshTokenHash);
    
    // 7. Persist changes to DB
    await this.userRepository.save(user);

    this.logger.log(`User logged in successfully: ${user.getId()}`);

    // Ideally, fetch this from ConfigService. For now, we hardcode 1 hour (in ms)
    // to match the standard JWT expiration and satisfy the DTO contract.
    const expiresIn = 3600 * 1000; // 1 hour in milliseconds

    // 8. Return Response matching the Shared DTO
    // Frontend needs the user info immediately to update the UI state.
    return {
      accessToken,
      refreshToken,
      expiresIn,
      user: {
        id: user.getId(),
        email: user.getEmail().email,
        role: user.getRole(),
      }
    };
  }
}