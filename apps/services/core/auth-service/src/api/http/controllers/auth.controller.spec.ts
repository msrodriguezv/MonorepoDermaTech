import { Test, TestingModule } from '@nestjs/testing';
import { CommandBus, QueryBus } from '@nestjs/cqrs';

// Controller
import { AuthController } from './auth.controller';

// DTOs & Enums
import { RegisterUserDto } from '../dtos/register-user.dto';
import { LoginRequestDto } from '../dtos/login.request.dto';
import { TokenResponseDto } from '../dtos/token-response.dto';
import { ApiResponse, UserRole } from '@dermatech/shared-dtos';

describe('AuthController', () => {
  let controller: AuthController;
  let commandBus: jest.Mocked<CommandBus>;

  beforeEach(async () => {
    // Define mocks for dependencies
    const commandBusMock = {
      execute: jest.fn(),
    };
    
    const queryBusMock = {
      execute: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        {
          provide: CommandBus,
          useValue: commandBusMock,
        },
        {
          provide: QueryBus,
          useValue: queryBusMock,
        },
      ],
    }).compile();

    // Inject dependencies with safe typing
    controller = module.get<AuthController>(AuthController);
    commandBus = module.get(CommandBus);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('POST /auth/register', () => {
    it('should call RegisterUserCommand and return ApiResponse', async () => {
      // Arrange
      const dto = new RegisterUserDto();
      dto.email = 'test@uce.edu.ec';
      dto.password = 'Pass123!';
      
      // Use the actual Enum to ensure type safety
      dto.role = UserRole.STUDENT; 

      // Mock the Domain Entity returned by the CommandHandler
      const mockUserResult = {
        getId: () => '123-uuid',
        getEmail: () => ({ getValue: () => 'test@uce.edu.ec' }),
        getRole: () => UserRole.STUDENT,
        getIsActive: () => true,
      };

      commandBus.execute.mockResolvedValue(mockUserResult);

      // Act
      const result = await controller.register(dto);

      // Assert
      expect(commandBus.execute).toHaveBeenCalled();
      expect(result).toBeInstanceOf(ApiResponse);
      expect(result.success).toBe(true);
      expect(result.data.email).toBe('test@uce.edu.ec');
      expect(result.data.role).toBe(UserRole.STUDENT);
    });
  });

  describe('POST /auth/login', () => {
    it('should call LoginCommand and return Tokens', async () => {
      // Arrange
      const dto = new LoginRequestDto();
      dto.email = 'test@uce.edu.ec';
      dto.password = 'Pass123!';

      const mockTokenResponse: TokenResponseDto = {
        accessToken: 'access.token.jwt',
        refreshToken: 'refresh.token.jwt',
        expiresIn: 900,
      };

      commandBus.execute.mockResolvedValue(mockTokenResponse);

      // Act
      const result = await controller.login(dto);

      // Assert
      expect(commandBus.execute).toHaveBeenCalled();
      expect(result).toBeInstanceOf(ApiResponse);
      expect(result.success).toBe(true);
      expect(result.data).toEqual(mockTokenResponse);
    });
  });
});