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

const create_prisma_client = () =>
  new PrismaClient({
    log:
      env.NODE_ENV === 'development'
        ? ['query', 'error', 'warn']
        : ['error'],
  });

const global_for_prisma = globalThis as unknown as {
  prisma: ReturnType<typeof create_prisma_client> | undefined;
};

export const prisma = global_for_prisma.prisma ?? create_prisma_client();

if (env.NODE_ENV !== 'production') {
  global_for_prisma.prisma = prisma;
}
