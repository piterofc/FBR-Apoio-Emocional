import { z } from 'zod'
import { roleEnum } from '@/db/schema/roleEnum'

const postgresUuidSchema = z
  .string()
  .regex(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)

export const checkAuthHeadersSchema = z.object({
  'x-user-id': postgresUuidSchema,
})

const roleSchema = z.enum(roleEnum.enumValues)

export const meUserSchema = z.object({
  id: postgresUuidSchema,
  email: z.string().email(),
  nickname: z.string().min(2).max(100),
  role: roleSchema,
  lastLogin: z.date(),
  createdAt: z.date(),
  updatedAt: z.date(),
})

export const meResponseSchema = {
  200: z.object({
    user: meUserSchema,
  }),
  401: z.object({
    message: z.string(),
  }),
  404: z.object({
    message: z.string(),
  }),
  500: z.object({
    message: z.string(),
  }),
}

export const signupBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  nickname: z.string().min(2).max(100),
})

export const signupUserSchema = z.object({
  id: postgresUuidSchema,
  email: z.string().email(),
  nickname: z.string().min(2).max(100),
  lastLogin: z.date(),
  createdAt: z.date(),
  updatedAt: z.date(),
})

export const signupResponseSchema = {
  201: z.object({
    message: z.string(),
    user: signupUserSchema,
  }),
  400: z.object({
    message: z.string(),
  }),
  500: z.object({
    message: z.string(),
  }),
}

export const loginBodySchema = z.object({
  email: z.string().email(),
  password: z.string(),
})

export const loginResponseSchema = {
  200: z.object({
    message: z.string(),
    user: signupUserSchema,
  }),
  400: z.object({
    message: z.string(),
  }),
  401: z.object({
    message: z.string(),
  }),
  500: z.object({
    message: z.string(),
  }),
}

export const logoutResponseSchema = {
  200: z.object({
    message: z.string(),
  }),
  500: z.object({
    message: z.string(),
  }),
}