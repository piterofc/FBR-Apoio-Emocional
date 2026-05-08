import type { FastifyInstance } from 'fastify'

import { authRoutes } from './auth/index'
import { atendimentoRoutes } from './atendimento/index'

export async function rotas(app: FastifyInstance) {
  app.register(authRoutes, {
    prefix: '/api/auth',
  })

  app.register(atendimentoRoutes, {
    prefix: '/api/atendimento',
  })
}