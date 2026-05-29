// ============================================================
//  USER REPOSITORY — lớp duy nhất "chạm" vào Prisma cho User
// ============================================================
//  Vai trò:
//    • Cô lập query DB ở 1 chỗ → dễ test, dễ thay ORM sau này.
//    • KHÔNG chứa business logic (validate, check trùng email, ...).
//
//  ≈ interface UserRepository extends JpaRepository<User, Long>.
//  Note: Prisma client tự là 1 dạng repository rồi → thật ra
//  layer này MỎNG. Nhiều project Node bỏ luôn để dùng prisma trực tiếp
//  trong service. Mình giữ vì bạn quen mô hình Spring + dễ test mock.
// ============================================================
import type { Prisma } from '@prisma/client';
import { prisma } from '@/lib/prisma';

export const userRepository = {
  findAll: () => prisma.user.findMany({ orderBy: { createdAt: 'desc' } }),

  findById: (id: string) => prisma.user.findUnique({ where: { id } }),

  findByEmail: (email: string) => prisma.user.findUnique({ where: { email } }),

  create: (data: Prisma.UserCreateInput) => prisma.user.create({ data }),

  update: (id: string, data: Prisma.UserUpdateInput) =>
    prisma.user.update({ where: { id }, data }),

  delete: (id: string) => prisma.user.delete({ where: { id } }),
};
