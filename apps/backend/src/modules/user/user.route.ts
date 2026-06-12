import { Router } from 'express';
import { user_controller } from './user.controller';
import { requireAuth } from '@/middlewares/auth.middleware';

export const user_router = Router();

/**
 * @swagger
 * /api/users/me:
 *   get:
 *     summary: Get current logged-in user profile
 *     tags: [Users]
 *     security:
 *       - BearerAuth: []  # Yêu cầu token ở route này
 *     responses:
 *       200:
 *         description: Successfully retrieved user profile
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 data:
 *                   $ref: '#/components/schemas/UserResponse'
 *       401:
 *         description: Unauthorized (Token is missing or invalid)
 *
 * components:
 *   schemas:
 *     UserResponse:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *         username:
 *           type: string
 *         email:
 *           type: string
 *         full_name:
 *           type: string
 *         # Các thuộc tính khác của User, nhớ loại bỏ password_hash
 */
user_router.get('/me', requireAuth, user_controller.getMe);
