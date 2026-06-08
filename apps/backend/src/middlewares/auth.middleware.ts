// ============================================================
//  AUTH MIDDLEWARE — bảo vệ route bằng access token (JWT)
// ============================================================
//  Dùng:  router.get('/me', require_auth, controller.me)
//
//  Luồng:
//    1. Đọc header "Authorization: Bearer <token>"
//    2. Verify chữ ký + hạn (verify_access_token)
//    3. Gắn req.user = { id, username } cho controller phía sau dùng
//    4. Thiếu/sai/hết hạn token → 401
//
//  ≈ Spring Security: OncePerRequestFilter đặt Authentication vào context.
// ============================================================
import type { Request, Response, NextFunction } from 'express';
import { verify_access_token } from '@/lib/tokens';
import { HttpError } from '@/utils/http-error';

export const require_auth = (req: Request, _res: Response, next: NextFunction): void => {
  const header = req.headers.authorization;

  if (!header?.startsWith('Bearer ')) {
    throw new HttpError(401, 'Thiếu access token (Authorization: Bearer <token>)');
  }

  const token = header.slice('Bearer '.length).trim();

  try {
    const payload = verify_access_token(token);
    req.user = { id: payload.sub, username: payload.username };
    next();
  } catch {
    // jwt throw khi sai chữ ký hoặc TokenExpiredError
    throw new HttpError(401, 'Access token không hợp lệ hoặc đã hết hạn');
  }
};
