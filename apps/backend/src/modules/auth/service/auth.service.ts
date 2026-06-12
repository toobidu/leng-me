import {auth_repository} from '../repository/auth.repository';
import {LoginRequest, RegisterRequest} from '../dto/auth.dto';
import {password_util} from '@/utils/password.util';
import {ConflictException, UnauthorizedException} from '@/utils/exceptions';
import {token_util} from '@/utils/token.util';

export const auth_service = {
    register: async (payload: RegisterRequest) => {
        // check existing
        const [user_by_username, user_by_email, user_by_phone_number] = await Promise.all([
            auth_repository.find_user_by_username(payload.username),
            auth_repository.find_user_by_email(payload.email),
            auth_repository.find_user_by_phone_number(payload.phone_number)
        ]);

        if (user_by_username) throw new ConflictException('Username đã tồn tại');
        if (user_by_email) throw new ConflictException('Email đã tồn tại');
        if (user_by_phone_number) throw new ConflictException('Số điện thoại đã tồn tại')

        const hashedPassword = await password_util.hash(payload.password_hash);

        // tạo user mới
        const new_user = await auth_repository.create_user({
            username: payload.username,
            email: payload.email,
            password_hash: hashedPassword,
            full_name: payload.full_name,
            first_name: payload.first_name,
            last_name: payload.last_name,
            date_of_birth: payload.date_of_birth,
            gender: payload.gender,
            address: payload.address,
        });


        const {password_hash, ...infor_user_without_password} = new_user;
        return infor_user_without_password;
    },

    login: async (payload: LoginRequest) => {
        const user = await auth_repository.find_user_by_username(payload.username);
        if (!user) {
            throw new UnauthorizedException('Tên đăng nhập hoặc mật khẩu không đúng');
        }

        const is_password_valid = await password_util.compare(payload.password_hash, user.password_hash);
        if (!is_password_valid) {
            throw new UnauthorizedException('Tên đăng nhập hoặc mật khẩu không đúng');
        }

        // Thông tin sẽ được lưu vào payload của token
        // Chỉ nên lưu những thông tin không nhạy cảm và cần thiết cho việc xác thực, phân quyền
        const token_payload = {
            id: user.id,
            username: user.username,
            // roles: user.roles, // Ví dụ: nếu có vai trò
        };

        const access_token = token_util.generate_access_token(token_payload);
        const refresh_token = token_util.generate_refresh_token(token_payload);

        return {
            access_token,
            refresh_token,
        };
    }
};
