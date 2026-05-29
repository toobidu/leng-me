// ============================================================
//  USER CONTROLLER — xử lý HTTP req/res
// ============================================================
//  Trách nhiệm DUY NHẤT:
//    • Lấy data từ req (params, body, query)
//    • Gọi service
//    • Format response
//  KHÔNG có business logic, KHÔNG chạm DB trực tiếp.
//
//  ≈ @RestController trong Spring Boot.
//
//  Lưu ý Express 5: async error tự động pass đến errorMiddleware,
//  không cần try/catch hay wrap "asyncHandler" như Express 4.
// ============================================================
import type { Request, Response } from 'express';
import { userService } from './user.service';
import type { CreateUserDto, UpdateUserDto } from './user.dto';

export const userController = {
  // GET /users
  list: async (_req: Request, res: Response) => {
    const users = await userService.list();
    res.json(users);
  },

  // GET /users/:id
  getById: async (req: Request<{ id: string }>, res: Response) => {
    const user = await userService.getById(req.params.id);
    res.json(user);
  },

  // POST /users
  create: async (req: Request<unknown, unknown, CreateUserDto>, res: Response) => {
    const user = await userService.create(req.body);
    res.status(201).json(user);
  },

  // PATCH /users/:id
  update: async (
    req: Request<{ id: string }, unknown, UpdateUserDto>,
    res: Response,
  ) => {
    const user = await userService.update(req.params.id, req.body);
    res.json(user);
  },

  // DELETE /users/:id
  remove: async (req: Request<{ id: string }>, res: Response) => {
    await userService.remove(req.params.id);
    res.status(204).send();
  },
};
