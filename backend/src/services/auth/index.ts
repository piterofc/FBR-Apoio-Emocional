import { env } from '@/env'
import type { FastifyReply } from 'fastify'
import jwt from 'jsonwebtoken'

export function gerarTokenSetarCookie(userId: string, reply: FastifyReply) {
    const token = jwt.sign({ userId }, env.JWT_SECRET, {
        expiresIn: '7d', // Validade de 7 dias
    })

    reply.setCookie('token', token, {
        path: '/',
        httpOnly: true,
        sameSite: 'strict',
        maxAge: 7 * 24 * 60 * 60, // 7 dias em segundos
        secure: process.env.NODE_ENV === 'production',
    })

    return token
}