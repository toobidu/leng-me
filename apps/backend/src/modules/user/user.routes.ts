// ============================================================
//  USER ROUTES — wiring URL ↔ controller, có middleware validate
// ============================================================
//  ≈ @RequestMapping("/users") + path mapping trong Spring Boot.
//
//  Convention REST:
//    GET    /users        → list
//    GET    /users/:id    → detail
//    POST   /users        → create     (validate body)
//    PATCH  /users/:id    → update     (validate body)
//    DELETE /users/:id    → remove
// ============================================================
import { Router } from 'express';
import { userController } from './user.controller';
import { validateBody } from '@/middlewares/validate.middleware';
import { createUserSchema, updateUserSchema } from './user.dto';

export const userRouter = Router();

userRouter.get('/', userController.list);
userRouter.get('/:id', userController.getById);
userRouter.post('/', validateBody(createUserSchema), userController.create);
userRouter.patch('/:id', validateBody(updateUserSchema), userController.update);
userRouter.delete('/:id', userController.remove);
