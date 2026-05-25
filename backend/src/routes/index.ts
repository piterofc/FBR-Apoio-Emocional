import type { FastifyInstance } from 'fastify'

import { authRoutes } from './auth/index'
import { atendimentoRoutes } from './atendimento/index'
import { eventosRoutes } from './events/index'

export async function rotas(app: FastifyInstance) {
  app.register(authRoutes, {
    prefix: '/api/auth',
  })

  app.register(atendimentoRoutes, {
    prefix: '/api/atendimento',
  })

  app.register(eventosRoutes, {
    prefix: '/api/eventos',
  })
}