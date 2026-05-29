// ============================================================
//  ENTRY POINT — khởi động server + graceful shutdown
// ============================================================
//  ≈ public static void main() + @SpringBootApplication.
// ============================================================
import { createApp } from './app';
import { env } from '@/config/env.config';
import { prisma } from '@/lib/prisma';

const app = createApp();

const server = app.listen(env.PORT, () => {
  console.log(`Server đang chạy: http://localhost:${env.PORT}`);
  console.log(`Health check:    http://localhost:${env.PORT}/health`);
  console.log(`Users API:       http://localhost:${env.PORT}/api/users`);
});

// ─── Graceful shutdown ─────────────────────────────────────
//  Khi nhận tín hiệu kill (Ctrl+C, docker stop, ...) thì:
//    1. Ngừng nhận request mới
//    2. Đợi request đang chạy xong
//    3. Disconnect Prisma (đóng connection pool)
//    4. Exit clean
//  Tránh connection rò rỉ, request bị cắt giữa chừng.
// ───────────────────────────────────────────────────────────
const shutdown = async (signal: string) => {
  console.log(`\n${signal} received, shutting down...`);
  server.close(async () => {
    await prisma.$disconnect();
    console.log('Bye.');
    process.exit(0);
  });
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
