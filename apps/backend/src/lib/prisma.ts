// ============================================================
//  PRISMA CLIENT — Singleton
// ============================================================
//  Tại sao singleton?
//    • Mỗi PrismaClient mở 1 connection pool tới DB.
//    • Nếu cứ "new PrismaClient()" tùm lum → cạn connection,
//      đặc biệt khi ts-node-dev hot-reload nhiều lần.
//    • Trick "globalThis" giữ instance qua các lần reload trong dev.
//
//  So với Spring Boot: ≈ @Bean PrismaClient với scope=singleton.
//  Trong NestJS sau này sẽ bọc bằng @Injectable() PrismaService.
// ============================================================
import { PrismaClient } from '@prisma/client';
import { env } from '@/config/env.config';

const createPrismaClient = () =>
  new PrismaClient({
    log:
      env.NODE_ENV === 'development'
        ? ['query', 'error', 'warn']
        : ['error'],
  });

const globalForPrisma = globalThis as unknown as {
  prisma: ReturnType<typeof createPrismaClient> | undefined;
};

export const prisma = globalForPrisma.prisma ?? createPrismaClient();

if (env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}
