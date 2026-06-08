// ============================================================
//  AUTH CONTROLLER — nhận request, gọi service, trả response
// ============================================================
//  KHÔNG chứa logic nghiệp vụ — chỉ "dịch" HTTP ↔ service.
//  Body đã được validate_body parse sẵn (đúng kiểu RegisterInput...).
//
//  ≈ @RestController trong Spring Boot.
// ============================================================
import type { Request, Response } from 'express';
import { auth_service } from './auth.service';
import type { RegisterInput, LoginInput, RefreshInput } from './auth.dto';
import { HttpError } from '@/utils/http-error';

// Trích thông tin client để lưu vào refresh_tokens (audit/bảo mật).
const client_context = (req: Request) => ({
  user_agent: req.headers['user-agent'] ?? null,
  ip: req.ip ?? null,
});

export const auth_controller = {
  // POST /api/auth/register
  async register(req: Request, res: Response): Promise<void> {
    const result = await auth_service.register(req.body as RegisterInput, client_context(req));
    res.status(201).json(result);
  },

  // POST /api/auth/login
  async login(req: Request, res: Response): Promise<void> {
    const result = await auth_service.login(req.body as LoginInput, client_context(req));
    res.status(200).json(result);
  },

  // POST /api/auth/refresh
  async refresh(req: Request, res: Response): Promise<void> {
    const { refresh_token } = req.body as RefreshInput;
    const tokens = await auth_service.refresh(refresh_token, client_context(req));
    res.status(200).json(tokens);
  },

  // POST /api/auth/logout
  async logout(req: Request, res: Response): Promise<void> {
    const { refresh_token } = req.body as RefreshInput;
    await auth_service.logout(refresh_token);
    res.status(204).send();
  },

  // GET /api/auth/me  (route có require_auth → req.user chắc chắn tồn tại)
  async me(req: Request, res: Response): Promise<void> {
    if (!req.user) {
      // Về lý thuyết không xảy ra vì đã qua require_auth — chặn cho chắc.
      throw new HttpError(401, 'Chưa đăng nhập');
    }
    const user = await auth_service.get_me(req.user.id);
    res.status(200).json(user);
  },
};
