import { Request, Response, NextFunction } from 'express';

export const user_controller = {
  getMe: (req: Request, res: Response, next: NextFunction) => {
    try {
      // Thông tin user đã được middleware `requireAuth` giải mã và gắn vào req.user
      const currentUser = req.user;
      res.status(200).json({
        message: 'Lấy thông tin người dùng thành công',
        data: currentUser,
      });
    } catch (error) {
      next(error);
    }
  },
};
