import bcrypt from 'bcrypt';

const SALT_ROUNDS = 10;

export const password_util = {
  hash: async (password: string): Promise<string> => {
    return await bcrypt.hash(password, SALT_ROUNDS);
  },
  compare: async (password: string, hash: string): Promise<boolean> => {
    return await bcrypt.compare(password, hash);
  },
};