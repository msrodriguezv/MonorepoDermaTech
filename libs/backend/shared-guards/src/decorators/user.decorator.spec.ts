import { Controller, Get, INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import * as request from 'supertest';
import { Request, Response, NextFunction } from 'express'; // Strict types from Express
import { User } from './user.decorator';

// Define the exact shape of the User object for testing purposes
interface MockUser {
  userId: string;
  role: string;
}

// Extend the Express Request interface to include 'user' without using 'any'
// This satisfies TypeScript strict mode
interface RequestWithUser extends Request {
  user?: MockUser;
}

describe('UserDecorator', () => {
  let app: INestApplication;

  // Dummy Controller to test the decorator application
  @Controller('test')
  class TestController {
    @Get()
    testEndPoint(@User() user: MockUser) {
      // The decorator should inject the user object here
      return user; 
    }
  }

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [TestController],
    }).compile();

    app = moduleFixture.createNestApplication();

    // Simulated Global Middleware (Strictly Typed)
    // This mocks the behavior of JwtAuthGuard/Passport attaching the user to the request
    app.use((req: RequestWithUser, res: Response, next: NextFunction) => {
      // Typed assignment, completely avoiding 'any'
      req.user = { userId: '123', role: 'STUDENT' };
      next();
    });

    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('should extract user from request', async () => {
    // Perform a real HTTP request using Supertest
    return request(app.getHttpServer())
      .get('/test')
      .expect(200)
      .expect((res) => {
        // Safe type casting of the response body
        const body = res.body as MockUser; 
        expect(body).toEqual({ userId: '123', role: 'STUDENT' });
      });
  });
});