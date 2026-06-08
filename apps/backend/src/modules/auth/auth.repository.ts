// ============================================================
//  AUTH REPOSITORY — mọi truy vấn DB của module auth
// ============================================================
//  Tách riêng tầng data access: service KHÔNG gọi prisma trực tiếp,
//  chỉ gọi qua repository. Sau này đổi ORM / mock test dễ hơn.
//
//  ≈ @Repository / Spring Data JPA interface.
// ============================================================
import type { Prisma } from '@prisma/client';
import { prisma } from '@/lib/prisma';

export const auth_repository = {
  // ─── User ─────────────────────────────────────────────────
  find_user_by_username: (username: string) =>
    prisma.user.findUnique({ where: { username } }),

  find_user_by_email: (email:string) =>
    prisma.user.findUnique({ where: { email } }),

  find_user_by_id: (id: number) => prisma.user.findUnique({ where: { id } }),

  create_user: (data: Prisma.UserCreateInput) => prisma.user.create({ data }),

  // ─── Refresh token ────────────────────────────────────────
  create_refresh_token: (data: {
    user_id: number;
    token_hash: string;
    expires_at: Date;
    user_agent?: string | null;
    ip_address?: string | null;
  }) => prisma.refreshToken.create({ data }),

  find_refresh_token_by_hash: (token_hash: string) =>
    prisma.refreshToken.findUnique({ where: { token_hash } }),

  // Đánh dấu 1 refresh token là đã thu hồi (logout / xoay vòng).
  revoke_refresh_token: (id: number) =>
    prisma.refreshToken.update({
      where: { id },
      data: { revoked: true, revoked_at: new Date() },
    }),

  // Thu hồi TẤT CẢ refresh token còn hiệu lực của 1 user (đổi mật khẩu, logout-all).
  revoke_all_user_tokens: (user_id: number) =>
    prisma.refreshToken.updateMany({
      where: { user_id, revoked: false },
      data: { revoked: true, revoked_at: new Date() },
    }),
};
