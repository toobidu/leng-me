import { Request, Response, NextFunction } from 'express';
import { login_request, register_request } from '../dto/auth.dto';
import { auth_service } from '../service/auth.service';

export const auth_controller = {
  register: async (req: Request, res: Response, next: NextFunction) => {
    try {
      // 1. Validate dữ liệu đầu vào (Request Body)
      const validatedData = register_request.parse(req.body);

      // 2. Gọi service xử lý nghiệp vụ đăng kí
      const newUser = await auth_service.register(validatedData);

      // 3. Trả về kết quả thành công
      res.status(201).json({
        message: 'Đăng kí tài khoản thành công',
        data: newUser,
      });
    } catch (error) {
      next(error); // Chuyển lỗi cho Error Handler chung (ZodError hoặc Error từ Service)
    }
  },

  login: async (req: Request, res: Response, next: NextFunction) => {
    try {
      // 1. Validate dữ liệu đầu vào (Request Body)
      const validatedData = login_request.parse(req.body);

      // 2. Gọi service xử lý nghiệp vụ đăng nhập
      const tokens = await auth_service.login(validatedData);

      // 3. Trả về kết quả thành công
      res.status(200).json({
        message: 'Đăng nhập thành công',
        data: tokens,
      });
    } catch (error) {
      next(error); // Chuyển lỗi cho Error Handler chung (ZodError hoặc Error từ Service)
    }
  },
};
