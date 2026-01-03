import { Roles, ROLES_KEY } from './roles.decorator';
import { UserRole } from '../../../shared-dtos/src/enums/user-role.enum';

/**
 * Unit Test: Roles Decorator
 * * Goal: Ensure the decorator correctly sets metadata on the target.
 */
describe('RolesDecorator', () => {
  it('should set the roles metadata with the provided roles', () => {
    // 1. Define a dummy class/method to decorate
    class TestClass {
      @Roles(UserRole.ADMIN, UserRole.DOCTOR)
      testMethod() { return; }
    }

    // 2. Extract the metadata stored by the decorator
    // We get the metadata from the method 'testMethod' of the prototype
    const metadata = Reflect.getMetadata(ROLES_KEY, TestClass.prototype.testMethod);

    // 3. Assertions
    expect(metadata).toBeDefined();
    expect(metadata).toEqual([UserRole.ADMIN, UserRole.DOCTOR]);
  });
});