import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException } from '@nestjs/common';
import { LoginHandler } from './login.handler';
import { LoginCommand } from './login.command';

// Domain Imports
import { User } from '../../../domain/entities/user.entity';
import { UserEmail } from '../../../domain/value-objects/user-email.vo';
import { UserRole } from '@dermatech/shared-dtos';

// Ports Imports (Interfaces)
import { UserRepositoryPort } from '../../ports/user.repository.port';
import { CryptoServicePort } from '../../ports/crypto.service.port';
import { TokenServicePort } from '../../ports/token.service.port';

// Mock Constants
const MOCK_EMAIL = 'test@uce.edu.ec';
const MOCK_PASS = 'SecurePass123!';
const MOCK_HASH = 'hashed_password';
const MOCK_USER_ID = '123-uuid';
const MOCK_ACCESS_TOKEN = 'access_token_jwt';
const MOCK_REFRESH_TOKEN = 'refresh_token_jwt';
const MOCK_REFRESH_HASH = 'hashed_refresh_token';

describe('LoginHandler', () => {
  let handler: LoginHandler;
  
  // Clean Code Fix: Explicitly type the mocks using jest.Mocked<Interface>
  // This enables intellisense for mock methods (mockReturnValue, etc.) without using 'any'.
  let userRepository: jest.Mocked<UserRepositoryPort>;
  let cryptoService: jest.Mocked<CryptoServicePort>;
  let tokenService: jest.Mocked<TokenServicePort>;

  beforeEach(async () => {
    // 1. Define Mocks with strict structure matching the Interfaces
    const mockUserRepository = {
      findByEmail: jest.fn(),
      save: jest.fn(),
    };

    const mockCryptoService = {
      compare: jest.fn(),
      hash: jest.fn(),
    };

    const mockTokenService = {
      generateAccessToken: jest.fn(),
      generateRefreshToken: jest.fn(),
      verifyToken: jest.fn(), // Required if interface has it
    };

    // 2. Setup Testing Module
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LoginHandler,
        { 
          provide: 'UserRepositoryPort', 
          useValue: mockUserRepository 
        },
        { 
          provide: 'CryptoServicePort', 
          useValue: mockCryptoService 
        },
        { 
          provide: 'TokenServicePort', 
          useValue: mockTokenService 
        },
      ],
    }).compile();

    handler = module.get<LoginHandler>(LoginHandler);
    
    // 3. Retrieve injected mocks with correct typing
    userRepository = module.get('UserRepositoryPort');
    cryptoService = module.get('CryptoServicePort');
    tokenService = module.get('TokenServicePort');
  });

  // --- TEST CASES ---

  it('should be defined', () => {
    expect(handler).toBeDefined();
  });

  it('should return tokens when credentials are valid', async () => {
    // Arrange
    const command = new LoginCommand(MOCK_EMAIL, MOCK_PASS);
    
    const mockUser = new User(
      MOCK_USER_ID, 
      new UserEmail(MOCK_EMAIL), 
      MOCK_HASH, 
      UserRole.STUDENT
    );

    // Mock behaviors (No 'any' needed here anymore)
    userRepository.findByEmail.mockResolvedValue(mockUser);
    cryptoService.compare.mockResolvedValue(true); // Password matches
    tokenService.generateAccessToken.mockResolvedValue(MOCK_ACCESS_TOKEN);
    tokenService.generateRefreshToken.mockResolvedValue(MOCK_REFRESH_TOKEN);
    cryptoService.hash.mockResolvedValue(MOCK_REFRESH_HASH);

    // Act
    const result = await handler.execute(command);

    // Assert
    expect(result).toEqual({
      accessToken: MOCK_ACCESS_TOKEN,
      refreshToken: MOCK_REFRESH_TOKEN,
      expiresIn: 900,
    });
    
    // Verify interactions
    expect(userRepository.save).toHaveBeenCalledTimes(1); 
    
    // We verify that the domain entity state was actually updated
    expect(mockUser.getCurrentRefreshTokenHash()).toBe(MOCK_REFRESH_HASH);
  });

  it('should throw UnauthorizedException if user does not exist', async () => {
    // Arrange
    userRepository.findByEmail.mockResolvedValue(null);

    // Act & Assert
    await expect(handler.execute(new LoginCommand(MOCK_EMAIL, MOCK_PASS)))
      .rejects.toThrow(UnauthorizedException);
  });

  it('should throw UnauthorizedException if password does not match', async () => {
    // Arrange
    const mockUser = new User(
      MOCK_USER_ID, 
      new UserEmail(MOCK_EMAIL), 
      MOCK_HASH, 
      UserRole.STUDENT
    );

    userRepository.findByEmail.mockResolvedValue(mockUser);
    cryptoService.compare.mockResolvedValue(false); // Wrong password

    // Act & Assert
    await expect(handler.execute(new LoginCommand(MOCK_EMAIL, MOCK_PASS)))
      .rejects.toThrow(UnauthorizedException);
  });

  it('should throw UnauthorizedException if user is inactive', async () => {
    // Arrange
    const mockUser = new User(
      MOCK_USER_ID, 
      new UserEmail(MOCK_EMAIL), 
      MOCK_HASH, 
      UserRole.STUDENT,
      false // Inactive
    );

    userRepository.findByEmail.mockResolvedValue(mockUser);
    cryptoService.compare.mockResolvedValue(true);

    // Act & Assert
    await expect(handler.execute(new LoginCommand(MOCK_EMAIL, MOCK_PASS)))
      .rejects.toThrow(UnauthorizedException);
  });
});