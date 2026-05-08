import crypto from 'crypto'
import bcrypt from 'bcrypt'

import { db } from '@/db/connection'
import { users } from '@/db/schema/user'

import { eq } from 'drizzle-orm'
import type { FastifyReply, FastifyRequest } from 'fastify'

import { gerarTokenSetarCookie } from '@/services/auth/index'

export async function me(req: FastifyRequest, reply: FastifyReply) {
    try {
        if (!req.user?.id) {
            return reply.status(401).send({
                message: 'Unauthorized',
            })
        }

        const userId = req.user.id.toString()

        const user = await db.query.users.findFirst({
            where: (u) => eq(u.id, userId),
            columns: {
                password: false, // Tirando a senha da resposta
            },
        })

        if (!user) {
            return reply.status(404).send({
                message: 'User not found',
            })
        }

        return reply.status(200).send({ user: user });
    } catch (err) {
        console.error('Error in me:', err)
        return reply.status(500).send({
            message: 'Internal server error',
        })
    }
}

export async function signup(req: FastifyRequest, reply: FastifyReply) {
    try {
        const { email, password, nickname } = req.body as {
            email: string
            password: string
            nickname: string
        }

        if (!email || !password || !nickname) {
            return reply.status(400).send({
                message: 'Email, password and nickname are required',
            })
        }

        const existingUser = await db.query.users.findFirst({
            where: (u) => eq(u.email, email),
            columns: {
                id: true,
            },
        })

        if (existingUser) {
            return reply.status(400).send({
                message: 'An account with this email already exists',
            })
        }

        const hashedPassword = await bcrypt.hash(password, 12)

        const newUser = await db.insert(users).values({
            email,
            password: hashedPassword,
            nickname,
        }).returning()

        // Login
        gerarTokenSetarCookie(newUser[0].id, reply)

        const { password: _, ...userData } = newUser[0] // Excluindo a senha da resposta

        return reply.status(201).send({
            message: 'User created successfully',
            user: userData,
        })
    } catch (err) {
        console.error('Error in signup:', err)
        return reply.status(500).send({
            message: 'Internal server error',
        })
    }
}

export async function login(req: FastifyRequest, reply: FastifyReply) {
    try {
        const { email, password } = req.body as {
            email: string
            password: string
        }

        if (!email || !password) {
            return reply.status(400).send({
                message: 'Email and password are required',
            })
        }

        const user = await db.query.users.findFirst({
            where: (u) => eq(u.email, email),
        })

        if (!user) {
            return reply.status(400).send({
                message: 'Invalid email or password',
            })
        }

        const passwordMatch = await bcrypt.compare(password, user.password)

        if (!passwordMatch) {
            return reply.status(400).send({
                message: 'Invalid email or password',
            })
        }

        // Login
        gerarTokenSetarCookie(user.id, reply)

        const { password: _, ...userData } = user // Excluindo a senha da resposta

        return reply.status(200).send({
            message: 'Login successful',
            user: userData,
        })
    } catch (err) {
        console.error('Error in login:', err)
        return reply.status(500).send({
            message: 'Internal server error',
        })
    }
}

export async function logout(req: FastifyRequest, reply: FastifyReply) {
    try {
        // Para logout, basta limpar o cookie do token
        reply.clearCookie('token')
        return reply.status(200).send({
            message: 'Logout successful',
        })
    } catch (err) {
        console.error('Error in logout:', err)
        return reply.status(500).send({
            message: 'Internal server error',
        })
    }
}