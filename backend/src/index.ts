import fastifyCookie from '@fastify/cookie'
import { fastifyCors } from '@fastify/cors'
import fastifySwagger from '@fastify/swagger'
import ScalarApiReference from '@scalar/fastify-api-reference'
import { fastify } from 'fastify'
import {
  jsonSchemaTransform,
  serializerCompiler,
  validatorCompiler,
  type ZodTypeProvider,
} from 'fastify-type-provider-zod'

import { rotas } from './routes/index'
import { startConsumers } from './services/eventConsumer'
import { addToRoom, removeFromRoom } from './services/ws'
import { WebSocketServer } from 'ws'
import jwt from 'jsonwebtoken'
import { env } from './env'

const app = fastify().withTypeProvider<ZodTypeProvider>()

app.setValidatorCompiler(validatorCompiler)
app.setSerializerCompiler(serializerCompiler)

app.register(fastifyCors, {
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  credentials: true,
})

app.register(fastifyCookie)

app.register(fastifySwagger, {
  openapi: {
    info: {
      title: 'FBR Apoio Emocional API',
      description: 'API documentation for FBR Apoio Emocional',
      version: '1.0.0',
    },
  },
  transform: jsonSchemaTransform,
})

app.register(ScalarApiReference, { routePrefix: '/docs' })

app.register(rotas)

app.get('/status', async () => {
  return { status: 'ok' }
})

// WebSocket: handled on raw server upgrade using `ws` to avoid plugin version mismatch

async function start() {
  try {
    await app.listen({ port: 8080, host: '0.0.0.0' })

    console.log('🔥 HTTP server running on http://localhost:8080')
    console.log('📘 API docs available at http://localhost:8080/docs')

    // Attach WebSocket server to the underlying HTTP server
    const wss = new WebSocketServer({ noServer: true })
    // on upgrade, validate token and add socket to room
    app.server.on('upgrade', (request, socket, head) => {
      try {
        const url = new URL(request.url || '', `http://${request.headers.host}`)
        const atendimentoId = url.searchParams.get('atendimentoId')
        const token = url.searchParams.get('token')
        if (!atendimentoId || !token) {
          socket.destroy()
          return
        }

        const decoded = jwt.verify(token, env.JWT_SECRET) as { userId: string }

        wss.handleUpgrade(request, socket, head, (ws) => {
          addToRoom(atendimentoId, ws as any, decoded.userId)
          ws.on('close', () => removeFromRoom(atendimentoId, ws as any))
        })
      } catch (err) {
        socket.destroy()
      }
    })

    // Inicia consumidores de eventos no mesmo processo
    void startConsumers().catch((err) => {
      console.error('🚨 Falha ao iniciar consumidor de eventos', err)
    })
  } catch (err) {
    console.error('🚨 Failed to start server', err)
    process.exit(1)
  }
}

void start()