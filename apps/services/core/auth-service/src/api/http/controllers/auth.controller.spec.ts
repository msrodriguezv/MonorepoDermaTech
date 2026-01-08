import { Test, TestingModule } from '@nestjs/testing';
import { CommandBus, QueryBus } from '@nestjs/cqrs';
import { AuthController } from './auth.controller';
import { 
  RegisterUserDto, 
  UserRole, 
  LoginRequestDto, 
  TokenResponseDto,
  ApiResponse,
  RefreshTokenDto 
} from '@dermatech/shared-dtos';

// Command Imports
import { RefreshTokenCommand } from '../../../application/commands/refresh-token/refresh-token.command';
import { LogoutCommand } from '../../../application/commands/logout/logout.command';

describe('AuthController', () => {
  let controller: AuthController;
  let commandBus: CommandBus;

  beforeEach(async () => {
    // 1. Create Clean Mocks using jest.fn()
    const mockCommandBus = { execute: jest.fn() };
    const mockQueryBus = { execute: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        // Inject the mocks ensuring they match the Bus classes
        { provide: CommandBus, useValue: mockCommandBus },
        { provide: QueryBus, useValue: mockQueryBus },
      ],
    }).compile();

    controller = module.get<AuthController>(AuthController);
    commandBus = module.get<CommandBus>(CommandBus);
  });

  describe('POST /auth/register', () => {
    it('should call RegisterUserCommand and return ApiResponse with user data', async () => {
      // Arrange
      const dto = new RegisterUserDto();
      dto.email = 'test@uce.edu.ec';
      dto.password = 'StrongP@ss1!';
      dto.role = UserRole.STUDENT;

      // We create a "Mock Entity" object.
      // The controller expects a Domain Entity with methods (getId, getEmail), 
      // not a plain DTO. This prevents "user.getId is not a function" error.
      const mockUserEntity = {
        getId: jest.fn().mockReturnValue('123-uuid'),
        // We simulate the Value Object structure inside the entity
        getEmail: jest.fn().mockReturnValue({ email: dto.email }),
        getRole: jest.fn().mockReturnValue(dto.role),
        getIsActive: jest.fn().mockReturnValue(true),
      };

      // Cast the execute method to jest.Mock to access .mockResolvedValue()
      (commandBus.execute as jest.Mock).mockResolvedValue(mockUserEntity);

      // Act
      const result = await controller.register(dto);

      // Assert
      expect(commandBus.execute).toHaveBeenCalled();
      
      // Verify standardized response wrapper
      expect(result).toBeInstanceOf(ApiResponse);
      expect(result.success).toBe(true);
      
      // Verify data integrity matches what the controller extracted from the entity
      expect(result.data.id).toBe('123-uuid');
      expect(result.data.email).toBe(dto.email);
      expect(result.data.role).toBe(dto.role);
    });
  });

  describe('POST /auth/login', () => {
    it('should call LoginCommand and return ApiResponse with tokens', async () => {
      // Arrange
      const dto = new LoginRequestDto();
      dto.email = 'doctor@uce.edu.ec';
      dto.password = 'SecurePass!';

      // For login, the handler returns a DTO (TokenResponse), not an entity.
      // So here a plain object is correct.
      const expectedTokenResponse: TokenResponseDto = {
        accessToken: 'valid_access_token',
        refreshToken: 'valid_refresh_token',
        expiresIn: 3600000,
        user: {
          id: 'user-id',
          email: dto.email,
          role: UserRole.DOCTOR,
        },
      };

      // Mock the return value for login command
      (commandBus.execute as jest.Mock).mockResolvedValue(expectedTokenResponse);

      // Act
      const result = await controller.login(dto);

      // Assert
      expect(commandBus.execute).toHaveBeenCalled();
      expect(result).toBeInstanceOf(ApiResponse);
      expect(result.success).toBe(true);
      
      // Verify token data
      expect(result.data.accessToken).toBe('valid_access_token');
      expect(result.data.expiresIn).toBe(3600000);
    });
  });

  describe('POST /auth/refresh', () => {
    it('should call RefreshTokenCommand and return new tokens', async () => {
      // Arrange
      const dto = new RefreshTokenDto();
      dto.refreshToken = 'valid_refresh_token_string';

      const expectedResponse: TokenResponseDto = {
        accessToken: 'new_access_token',
        refreshToken: 'valid_refresh_token_string',
        expiresIn: 900, // 15 min
        user: {
          id: 'user-id',
          email: 'test@uce.edu.ec',
          role: UserRole.STUDENT,
        },
      };

      // Mock the command bus response
      (commandBus.execute as jest.Mock).mockResolvedValue(expectedResponse);

      // Act
      const result = await controller.refresh(dto);

      // Assert
      // Verify the correct command was dispatched
      expect(commandBus.execute).toHaveBeenCalledWith(expect.any(RefreshTokenCommand));
      
      // Verify the argument passed to the command matches the DTO
      expect(commandBus.execute).toHaveBeenCalledWith(
        expect.objectContaining({ refreshToken: dto.refreshToken })
      );

      // Verify response wrapper
      expect(result).toBeInstanceOf(ApiResponse);
      expect(result.success).toBe(true);
      expect(result.data.accessToken).toBe('new_access_token');
    });
  });

  describe('POST /auth/logout', () => {
    it('should extract token from header, call LogoutCommand, and return success', async () => {
      // Arrange
      // Simulate raw header with 'Bearer ' prefix
      const authHeader = 'Bearer eyJhbGciOiJIUz...'; 
      const expectedCleanToken = 'eyJhbGciOiJIUz...';

      // Logout command usually returns void, we mock a resolved promise
      (commandBus.execute as jest.Mock).mockResolvedValue(undefined);

      // Act
      const result = await controller.logout(authHeader);

      // Assert
      // 1. Verify CommandBus was called
      expect(commandBus.execute).toHaveBeenCalledWith(expect.any(LogoutCommand));

      // 2. Verify logic: Ensure 'Bearer ' was stripped before sending to Command
      expect(commandBus.execute).toHaveBeenCalledWith(
        expect.objectContaining({ token: expectedCleanToken })
      );

      // 3. Verify Response
      expect(result).toBeInstanceOf(ApiResponse);
      expect(result.success).toBe(true);
      expect(result.message).toBe('Logout successful');
    });
  });
});