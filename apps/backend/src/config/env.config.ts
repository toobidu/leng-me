// ============================================================
//  ENV CONFIG — load .env + validate bằng Zod
// ============================================================
//  Tại sao validate?  → Nếu thiếu/sai env, app FAIL FAST ngay
//  khi khởi động, thay vì chết giữa chừng lúc đang serve request.
//
//  So với Spring Boot: ≈ @ConfigurationProperties + @Validated.
// ============================================================
import 'dotenv/config';
import { z } from 'zod';

const env_schema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().int().positive().default(8080),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),

  // ─── JWT ──────────────────────────────────────────────────
  //  2 secret RIÊNG cho access và refresh: nếu lộ 1 cái, cái kia
  //  vẫn an toàn. Production phải đặt chuỗi random đủ dài.
  JWT_ACCESS_SECRET: z.string().min(16, 'JWT_ACCESS_SECRET tối thiểu 16 ký tự'),
  JWT_REFRESH_SECRET: z.string().min(16, 'JWT_REFRESH_SECRET tối thiểu 16 ký tự'),
  // Hạn access token — chuỗi kiểu '15m', '1h' (đọc bởi jsonwebtoken).
  JWT_ACCESS_EXPIRES: z.string().default('15m'),
  // Hạn refresh token — tính bằng NGÀY (dùng để set expires_at trong DB).
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().default(7),
});

const parsed = env_schema.safeParse(process.env);

if (!parsed.success) {
  console.error('Invalid environment variables:');
  for (const issue of parsed.error.issues) {
    console.error(`  • ${issue.path.join('.')}: ${issue.message}`);
  }
  process.exit(1);
}

export const env = parsed.data;
export type Env = z.infer<typeof env_schema>;
