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

async function start() {
  try {
    await app.listen({ port: 8080, host: '0.0.0.0' })

    console.log('🔥 HTTP server running on http://localhost:8080')
    console.log('📘 API docs available at http://localhost:8080/docs')
  } catch (err) {
    console.error('🚨 Failed to start server', err)
    process.exit(1)
  }
}

void start()