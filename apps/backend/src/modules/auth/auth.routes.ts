// ============================================================
//  AUTH ROUTES — khai báo endpoint của module auth
// ============================================================
//  Gắn validate_body(schema) TRƯỚC controller → request sai bị chặn
//  ngay, controller chỉ nhận data sạch.
//
//  ≈ @RequestMapping("/api/auth") trong Spring Boot.
// ============================================================
import { Router } from 'express';
import { auth_controller } from './auth.controller';
import { register_schema, login_schema, refresh_schema } from './auth.dto';
import { validate_body } from '@/middlewares/validate.middleware';
import { require_auth } from '@/middlewares/auth.middleware';

export const auth_router: Router = Router();

// ─── Public ─────────────────────────────────────────────────
auth_router.post('/register', validate_body(register_schema), auth_controller.register);
auth_router.post('/login', validate_body(login_schema), auth_controller.login);
auth_router.post('/refresh', validate_body(refresh_schema), auth_controller.refresh);
auth_router.post('/logout', validate_body(refresh_schema), auth_controller.logout);

// ─── Protected (cần access token) ───────────────────────────
auth_router.get('/me', require_auth, auth_controller.me);
