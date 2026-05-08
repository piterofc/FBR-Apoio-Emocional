import { z } from 'zod'
import { atendimentoStatusEnum } from '@/db/schema/atendimentoStatusEnum'

const postgresUuidSchema = z
  .string()
  .regex(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)

const statusAtendimentoSchema = z.enum(atendimentoStatusEnum.enumValues);

export const atendimentoSchema = z.object({
    id: postgresUuidSchema,
    clienteId: postgresUuidSchema,
    apoiadorId: postgresUuidSchema.nullable(),
    descricaoInicial: z.string(),
    status: statusAtendimentoSchema,
    createdAt: z.date(),
    updatedAt: z.date(),
})

export const listarAtendimentosResponseSchema = {
    200: z.array(atendimentoSchema),
    500: z.object({
        message: z.string(),
    }),
}

export const atendimentoResponseSchema = {
    200: z.object({
        atendimento: atendimentoSchema,
    }),
    404: z.object({
        message: z.string(),
    }),
    500: z.object({
        message: z.string(),
    }),
}

export const createBodySchema = z.object({
    descricaoInicial: z.string(),
})

export const createResponseSchema = {
    201: z.object({
        atendimento: atendimentoSchema,
    }),
    500: z.object({
        message: z.string(),
    }),
}

export const updateBodySchema = z.object({
    descricaoInicial: z.string().optional(),
    status: statusAtendimentoSchema.optional(),
})

export const updateResponseSchema = {
    200: z.object({
        atendimento: atendimentoSchema,
    }),
    404: z.object({
        message: z.string(),
    }),
    500: z.object({
        message: z.string(),
    }),
}

export const deleteResponseSchema = {
    204: z.object({
        message: z.string(),
    }),
    500: z.object({
        message: z.string(),
    }),
}
