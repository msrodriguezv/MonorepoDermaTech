import { validate } from 'class-validator';
import { RegisterUserDto } from './register-user.dto';
import { UserRole } from '../../enums/user-role.enum'; // Adjust path if needed

describe('RegisterUserDto', () => {
  /**
   * Test Suite for RegisterUserDto validation rules.
   * Ensures that decorators (@IsString, @MinLength, etc.) are working as expected.
   */

  it('should pass validation with valid data', async () => {
    // Arrange
    const dto = new RegisterUserDto();
    dto.email = 'test@uce.edu.ec';
    dto.password = 'StrongP@ss1!';
    dto.role = UserRole.STUDENT;

    // Act
    const errors = await validate(dto);

    // Assert
    expect(errors.length).toBe(0);
  });

  it('should fail validation if password is too weak', async () => {
    // Arrange
    const dto = new RegisterUserDto();
    dto.email = 'test@uce.edu.ec';
    dto.password = '12345'; // Weak password
    dto.role = UserRole.STUDENT;

    // Act
    const errors = await validate(dto);
    const passwordError = errors.find(err => err.property === 'password');

    // Assert
    expect(errors.length).toBeGreaterThan(0);
    expect(passwordError).toBeDefined();
    expect(passwordError?.constraints).toHaveProperty('minLength');
  });

  it('should fail validation if role is invalid', async () => {
    // Arrange
    const dto = new RegisterUserDto();
    dto.email = 'test@uce.edu.ec';
    dto.password = 'StrongP@ss1!';
    dto.role = 'INVALID_ROLE' as unknown as UserRole;

    // Act
    const errors = await validate(dto);

    // Assert
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].property).toBe('role');
  });
});