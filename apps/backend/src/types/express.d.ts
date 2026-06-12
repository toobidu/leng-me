// src/types/express.d.ts
import { User } from '@prisma/client';

declare global {
  namespace Express {
    export interface Request {
      user?: Omit<User, 'password_hash'>; // Gắn thông tin user đã được giải mã từ token vào request
    }
  }
}
