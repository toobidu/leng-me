import { z } from 'zod';
import { Gender } from '@prisma/client';
import { AppConstants } from '@/config/constants.config';

const { USER } = AppConstants;

/**
 * Đăng kí
 */
export const register_request = z.object({
  username: z.string().max(USER.USERNAME_MAX_LENGTH),
  email: z.string(),
  phone_number: z.string().max(USER.PHONE_NUMBER_MAX_LENGTH),
  password_hash: z.string().min(USER.PASSWORD_MIN_LENGTH).max(USER.PASSWORD_MAX_LENGTH),
  full_name: z.string().max(USER.FULL_NAME_MAX_LENGTH),
  first_name: z.string().max(USER.FIRST_NAME_MAX_LENGTH),
  last_name: z.string().max(USER.LAST_NAME_MAX_LENGTH),
  date_of_birth: z.date(),
  gender: z.enum([Gender.MALE, Gender.FEMALE]),
  address: z.string(),
})

/**
 * Đăng nhập
 */
export const login_request = z.object({
  username: z.string().max(USER.USERNAME_MAX_LENGTH),
  password_hash: z.string(),
})

/**
 * Trả về token
 */
export const login_response = z.object({
  access_token: z.string(),
  refresh_token: z.string(),
})

export type RegisterRequest=z.infer<typeof register_request>;
export type LoginRequest=z.infer<typeof login_request>;
export type LoginResponse=z.infer<typeof login_response>;
