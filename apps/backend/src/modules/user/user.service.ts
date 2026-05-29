// ============================================================
//  USER SERVICE — business logic
// ============================================================
//  Đây là nơi đặt MỌI luật nghiệp vụ:
//    • Kiểm tra tồn tại trước khi update/delete
//    • Chặn email trùng khi create
//    • Transaction nếu có nhiều bước
//    • Gọi service khác (vd: gửi email welcome)
//
//  ≈ @Service class trong Spring Boot.
//  KHÔNG chạm req/res ở đây — đó là việc của controller.
// ============================================================
import { userRepository } from './user.repository';
import { HttpError } from '@/utils/http-error';
import type { CreateUserDto, UpdateUserDto } from './user.dto';

// Helper riêng — vừa load user vừa throw 404 nếu không có
const findOrThrow = async (id: string) => {
  const user = await userRepository.findById(id);
  if (!user) throw new HttpError(404, `User ${id} not found`);
  return user;
};

export const userService = {
  list: () => userRepository.findAll(),

  getById: (id: string) => findOrThrow(id),

  create: async (dto: CreateUserDto) => {
    const existing = await userRepository.findByEmail(dto.email);
    if (existing) throw new HttpError(409, 'Email đã được sử dụng');
    return userRepository.create(dto);
  },

  update: async (id: string, dto: UpdateUserDto) => {
    await findOrThrow(id);

    // Nếu user đổi email → check trùng (trừ chính mình)
    if (dto.email) {
      const other = await userRepository.findByEmail(dto.email);
      if (other && other.id !== id) {
        throw new HttpError(409, 'Email đã được sử dụng');
      }
    }

    return userRepository.update(id, dto);
  },

  remove: async (id: string) => {
    await findOrThrow(id);
    await userRepository.delete(id);
  },
};
