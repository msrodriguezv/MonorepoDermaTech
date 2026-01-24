import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { JwtPayload } from '@dermatech/shared-dtos';

export const User = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): JwtPayload => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);