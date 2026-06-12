import jwt, { SignOptions } from 'jsonwebtoken';
import { env } from '@/config/env.config';

export const token_util = {
    /**
     * Tạo access token
     * @param payload Dữ liệu người dùng muốn lưu vào token. 
     * Lưu ý: Không nên lưu các thông tin nhạy cảm như password.
     * Nên lưu: id, username, roles, ...
     * @returns Access token
     */
    generate_access_token: (payload: any) => {
        const signOptions: SignOptions = {};
        if (env.JWT_ACCESS_EXPIRES) {
            signOptions.expiresIn = env.JWT_ACCESS_EXPIRES as SignOptions['expiresIn'];
        }
        return jwt.sign(payload, env.JWT_ACCESS_SECRET, signOptions);
    },

    /**
     * Tạo refresh token
     * @param payload Dữ liệu người dùng muốn lưu vào token
     * @returns Refresh token
     */
    generate_refresh_token: (payload: any) => {
        // Refresh token cũng có thể dùng chung payload hoặc payload gọn nhẹ hơn
        const signOptions: SignOptions = {
            expiresIn: `${env.REFRESH_TOKEN_TTL_DAYS}d`, // Convert số ngày sang định dạng 'Xd' của jsonwebtoken
        };
        return jwt.sign(payload, env.JWT_REFRESH_SECRET, signOptions);
    },

    /**
     * Giải mã access token
     * @param token Token cần giải mã
     * @returns Dữ liệu trong token (payload)
     */
    verify_access_token: (token: string) => {
        try {
            return jwt.verify(token, env.JWT_ACCESS_SECRET);
        } catch (error) {
            return null; // Token không hợp lệ hoặc đã hết hạn
        }
    },
    
    /**
     * Giải mã refresh token
     * @param token Token cần giải mã
     * @returns Dữ liệu trong token (payload)
     */
    verify_refresh_token: (token: string) => {
        try {
            return jwt.verify(token, env.JWT_REFRESH_SECRET);
        } catch (error) {
            return null; // Token không hợp lệ hoặc đã hết hạn
        }
    },
};
