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

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().int().positive().default(8080),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Invalid environment variables:');
  for (const issue of parsed.error.issues) {
    console.error(`  • ${issue.path.join('.')}: ${issue.message}`);
  }
  process.exit(1);
}

export const env = parsed.data;
export type Env = z.infer<typeof envSchema>;
