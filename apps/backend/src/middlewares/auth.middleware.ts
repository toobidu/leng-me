import { Request, Response, NextFunction } from 'express';
import { token_util } from '@/utils/token.util';
import { UnauthorizedException } from '@/utils/exceptions';
import { auth_repository } from '@/modules/auth/repository/auth.repository';

/**
 * Middleware bảo vệ các route yêu cầu xác thực
 * Tương đương với JwtAuthenticationFilter trong Spring Boot
 */
export const requireAuth = async (req: Request, _res: Response, next: NextFunction) => {
    try {
        // 1. Lấy token từ header Authorization: Bearer <token>
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return next(new UnauthorizedException('Không tìm thấy token xác thực'));
        }

        const token = authHeader.split(' ')[1];
        
        if (!token) {
            return next(new UnauthorizedException('Định dạng token không hợp lệ'));
        }

        // 2. Giải mã và verify token
        const decodedToken = token_util.verify_access_token(token);
        
        if (!decodedToken || typeof decodedToken === 'string' || !decodedToken.username) {
            return next(new UnauthorizedException('Token không hợp lệ hoặc đã hết hạn'));
        }

        // 3. (Tùy chọn nhưng khuyến nghị) Kiểm tra xem user có thực sự tồn tại trong DB không
        const user = await auth_repository.find_user_by_username(decodedToken.username);
        if (!user) {
             return next(new UnauthorizedException('Người dùng không còn tồn tại'));
        }

        // 4. Gán thông tin user vào request (Loại bỏ password_hash cho an toàn)
        const { password_hash, ...userWithoutPassword } = user;
        req.user = userWithoutPassword;

        // 5. Cho phép đi tiếp đến controller
        return next();
    } catch (error) {
        // Khối catch này giờ đây chủ yếu để bắt các lỗi từ await hoặc các lỗi runtime bất ngờ khác
        return next(error);
    }
};
