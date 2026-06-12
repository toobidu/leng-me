import type {Prisma} from '@prisma/client';
import {prisma} from '@/lib/prisma';

export const auth_repository = {
    create_user: async (data: Prisma.UserCreateInput) => {
        return prisma.user.create({
            data,
        });
    },

    find_user_by_username: async (username: string) => {
        return prisma.user.findFirst({
            where: {
                username,
            },
        });
    },

    find_user_by_email: async (email: string) => {
        return prisma.user.findFirst({
            where: {
                email,
            }
        })
    },

    find_user_by_phone_number: async (phone_number: string) => {
        return prisma.user.findFirst({
                where: {
                    phone_number,
                }
            }
        )
    }
};
