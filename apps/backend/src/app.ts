// ============================================================
//  APP FACTORY — tạo Express app
// ============================================================
//  Tách create_app() ra khỏi index.ts giúp:
//    • Test integration dễ (test gọi create_app() rồi supertest).
//    • Tách concerns: file này define "app là gì",
//                     index.ts lo "khởi động server".
//
//  Thứ tự middleware QUAN TRỌNG:
//    1. Parsers (json, urlencoded)
//    2. Logger / CORS / Helmet
//    3. Routes
//    4. 404 handler
//    5. Error middleware (PHẢI ĐẶT CUỐI CÙNG)
// ============================================================
import express, { type Express } from 'express';
import { auth_router } from '@/modules/auth/auth.routes';
import { error_middleware } from '@/middlewares/error.middleware';
import { HttpError } from '@/utils/http-error';

export const create_app = (): Express => {
  const app = express();

  // ─── Parsers ──────────────────────────────────────────────
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true }));

  // ─── Health check ─────────────────────────────────────────
  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', uptime: process.uptime() });
  });

  // ─── Feature routers ──────────────────────────────────────
  app.use('/api/auth', auth_router);

  // ─── 404 cho mọi route không match ────────────────────────
  app.use((req, _res, next) => {
    next(new HttpError(404, `Route ${req.method} ${req.originalUrl} not found`));
  });

  // ─── Error handler (LUÔN CUỐI) ────────────────────────────
  app.use(error_middleware);

  return app;
};
