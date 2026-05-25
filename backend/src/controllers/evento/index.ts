import type { FastifyReply, FastifyRequest } from 'fastify'
import { z } from 'zod'
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

    await publishEvent('chat', body)

    return reply.status(202).send({ status: 'accepted' })
}