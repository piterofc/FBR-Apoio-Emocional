import type { FastifyInstance } from 'fastify'
import { z } from 'zod'

import { publicarStatus, publicarChat } from '../../controllers/evento/index'

export const bodySchema = z.object({
  payload: z.record(z.string(), z.unknown()),
})

export async function eventosRoutes(app: FastifyInstance) {
  app.post(
    '/status',
    {
      schema: {
        tags: ['Eventos'],
        summary: 'Publicar evento de status',
        description: 'Publica um evento de status na fila do RabbitMQ.',
        body: bodySchema,
      },
    },
    publicarStatus
  )

  app.post(
    '/chat',
    {
      schema: {
        tags: ['Eventos'],
        summary: 'Publicar evento de chat',
        description: 'Publica um evento de chat na fila do RabbitMQ.',
        body: bodySchema,
      },
    },
    publicarChat
  )

}
