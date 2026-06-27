import type { FastifyReply, FastifyRequest } from 'fastify'
import { z } from 'zod'
import { db } from '@/db/connection'
import { atendimentos } from '@/db/schema/atendimento'
import { eq } from 'drizzle-orm'
import publishEvent from '../../services/eventProducer'
import { bodySchema } from '@/routes/events'

export async function publicarStatus(req: FastifyRequest, reply: FastifyReply) {
    const body = req.body as z.infer<typeof bodySchema>
    if (!body) return reply.status(400).send({ message: 'Body faltante!' })

    await publishEvent('status', body)

    return reply.status(202).send({ status: 'accepted' })
}

export async function publicarChat (req: FastifyRequest, reply: FastifyReply) {
    const body = req.body as z.infer<typeof bodySchema>
    if (!body) return reply.status(400).send({ message: 'Body faltante!' })

        const atendimentoId = body.payload?.atendimentoId as string | undefined
        const atendimento = atendimentoId
            ? await db.query.atendimentos.findFirst({
                    where: (a) => eq(a.id, atendimentoId),
                    columns: {
                        id: true,
                        status: true,
                    },
                })
            : null

        if (!atendimentoId || !atendimento) {
            return reply.status(404).send({ message: 'Atendimento não encontrado' })
        }

        if (atendimento.status !== 'EM_ANDAMENTO') {
            return reply.status(409).send({
                message: 'Mensagens só podem ser enviadas quando o atendimento estiver em andamento',
            })
        }

    await publishEvent('chat', body)

    return reply.status(202).send({ status: 'accepted' })
}