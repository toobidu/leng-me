import express, { type Express } from 'express';
import swaggerUi from 'swagger-ui-express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';

import { swagger_specs } from '@/config/swagger.config';
import { auth_router } from '@/modules/auth/router/auth.route';
import { user_router } from '@/modules/user/user.route';
import { error_middleware } from '@/middlewares/error.middleware';
import { HttpError } from '@/utils/http-error';
import { AppConstants } from '@/config/constants.config';

export const create_app = (): Express => {
  const app = express();

  // ─── Security Middlewares ─────────────────────────────────
  
  // 1. Helmet: Thiết lập các HTTP header bảo mật
  app.use(helmet());

  // 2. CORS: Cấu hình origin được phép gọi API (Trong thực tế nên thay '*' bằng domain frontend)
  app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    credentials: true, // Cho phép gửi cookie nếu cần
  }));

  // 3. Rate Limiting: Giới hạn số request từ 1 IP (Chống Brute-force & DDoS cơ bản)
  const limiter = rateLimit({
    windowMs: AppConstants.RATE_LIMIT_WINDOW_MS,
    max: AppConstants.RATE_LIMIT_MAX_REQUESTS,
    message: AppConstants.RATE_LIMIT_MESSAGE,
    standardHeaders: true,
    legacyHeaders: false,
  });
  app.use(limiter);

  // ─── Parsers ──────────────────────────────────────────────
  app.use(express.json({ limit: AppConstants.JSON_BODY_LIMIT }));
  app.use(express.urlencoded({ extended: true }));

  // ─── Health check ─────────────────────────────────────────
  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', uptime: process.uptime() });
  });

  // ─── Swagger API Docs ─────────────────────────────────────
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swagger_specs));

  // ─── Feature routers ──────────────────────────────────────
  app.use('/api/auth', auth_router);
  app.use('/api/users', user_router);

  // ─── 404 cho mọi route không match ────────────────────────
  app.use((req, _res, next) => {
    next(new HttpError(404, `Route ${req.method} ${req.originalUrl} not found`));
  });

  // ─── Error handler (LUÔN CUỐI) ────────────────────────────
  app.use(error_middleware);

  return app;
};
