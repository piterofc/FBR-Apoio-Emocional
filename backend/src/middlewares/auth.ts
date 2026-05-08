import type { FastifyReply, FastifyRequest } from 'fastify'
import jwt from 'jsonwebtoken'
import { env } from '@/env.ts'

export async function authenticate(request: FastifyRequest, reply: FastifyReply) {
  const token = request.cookies?.token

  if (!token) {
    return reply.status(401).send({ message: 'Unauthorized' })
  }

  try {
    const decoded = jwt.verify(token, env.JWT_SECRET) as { userId: string }
    request.user = { id: decoded.userId }
  } catch (err) {
    return reply.status(401).send({ message: 'Unauthorized' })
  }
}

export default authenticate
