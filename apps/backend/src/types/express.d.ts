// ============================================================
//  Mở rộng kiểu Express.Request — thêm req.user
// ============================================================
//  Sau khi require_auth verify JWT, nó gắn thông tin user vào
//  req.user. Khai báo này giúp TypeScript biết req.user tồn tại
//  ở MỌI controller phía sau (thay vì (req as any).user).
//
//  ≈ Spring Security: SecurityContextHolder.getContext().getAuthentication()
// ============================================================
import 'express';

declare global {
  namespace Express {
    interface Request {
      user?: {
        id: number;
        username: string;
      };
    }
  }
}

export {};
