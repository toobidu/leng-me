import { Router } from 'express';
import { auth_controller } from '../controller/auth.controller';

export const auth_router = Router();

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/RegisterRequest'
 *     responses:
 *       201:
 *         description: User registered successfully
 *       400:
 *         description: Invalid input data
 *       409:
 *         description: Username or email already exists
 */
auth_router.post('/register', auth_controller.register);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login a user
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/LoginRequest'
 *     responses:
 *       200:
 *         description: Login successful, returns tokens
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LoginResponse'
 *       401:
 *         description: Invalid username or password
 */
auth_router.post('/login', auth_controller.login);

// --- Swagger Component Schemas ---

/**
 * @swagger
 * components:
 *   schemas:
 *     RegisterRequest:
 *       type: object
 *       required:
 *         - username
 *         - email
 *         - password_hash
 *         - full_name
 *         - first_name
 *         - last_name
 *         - date_of_birth
 *         - gender
 *         - address
 *       properties:
 *         username:
 *           type: string
 *           maxLength: 50
 *         email:
 *           type: string
 *           format: email
 *         phone_number:
 *           type: string
 *           maxLength: 20
 *         password_hash:
 *           type: string
 *           format: password
 *           minLength: 12
 *           maxLength: 255
 *         full_name:
 *           type: string
 *           maxLength: 100
 *         first_name:
 *           type: string
 *           maxLength: 50
 *         last_name:
 *           type: string
 *           maxLength: 50
 *         date_of_birth:
 *           type: string
 *           format: date
 *         gender:
 *           $ref: '#/components/schemas/Gender'
 *         address:
 *           type: string
 *
 *     LoginRequest:
 *       type: object
 *       required:
 *         - username
 *         - password_hash
 *       properties:
 *         username:
 *           type: string
 *         password_hash:
 *           type: string
 *           format: password
 *
 *     LoginResponse:
 *       type: object
 *       properties:
 *         access_token:
 *           type: string
 *         refresh_token:
 *           type: string
 *
 *     Gender:
 *       type: string
 *       enum: [MALE, FEMALE]
 */
