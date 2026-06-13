import { db } from '../../db/connection'
import { atendimentos } from '../../db/schema/atendimento'

import { eq } from 'drizzle-orm'
import publishEvent from '@/services/eventProducer'
import type { FastifyReply, FastifyRequest } from 'fastify'

export async function listarAtendimentos(req: FastifyRequest, reply: FastifyReply) {
    try {
        const lista = await db.query.atendimentos.findMany({
            columns: {
                id: true,
                clienteId: true,
                apoiadorId: true,
                status: true,
                createdAt: true,
                updatedAt: true,
            },
        })
        return reply.status(200).send(lista)
    } catch (error) {
        console.error(error)
        return reply.status(500).send({ message: "Erro ao listar atendimentos" })
    }
}

export async function obterAtendimento(req: FastifyRequest, reply: FastifyReply) {
    try {
        const { id } = req.params as { id: string }
        const atendimento = await db.query.atendimentos.findFirst({
            where: (a) => eq(a.id, id),
            columns: {
                id: true,
                clienteId: true,
                apoiadorId: true,
                status: true,
                createdAt: true,
                updatedAt: true,
            },
        })
        return reply.status(200).send(atendimento)
    } catch (error) {
        console.error(error)
        return reply.status(500).send({ message: "Erro ao obter atendimento" })
    }
}

export async function criarAtendimento(req: FastifyRequest, reply: FastifyReply) {
    try {
        const { descricaoInicial } = req.body as { descricaoInicial: string }
        const novoAtendimento = await db.insert(atendimentos).values({
            clienteId: req.user?.id || '', // Supondo que o ID do cliente esteja disponível no objeto de usuário
            descricaoInicial,
            status: 'PENDENTE', // Status inicial do atendimento
        }).returning();
        return reply.status(201).send({ atendimento: novoAtendimento[0] })
    } catch (error) {
        console.error(error)
        return reply.status(500).send({ message: "Erro ao criar atendimento" })
    }
}

export async function atualizarAtendimento(req: FastifyRequest, reply: FastifyReply) {
    try {
        const { id } = req.params as { id: string }
        const { descricaoInicial, status } = req.body as {
            descricaoInicial?: string
            status?: 'PENDENTE' | 'EM_ANDAMENTO' | 'CONCLUIDO' | 'CANCELADO'
        }
        const atendimentoExistente = await db.query.atendimentos.findFirst({
            where: (a) => eq(a.id, id),
        })
        if (!atendimentoExistente) {
            return reply.status(404).send({ message: "Atendimento não encontrado" })
        }
        // Se o status estiver mudando para EM_ANDAMENTO, e o atendimento ainda não tiver apoiador,
        // setamos o apoiador como o usuário autenticado (se disponível).
        const updates: any = {}
        if (descricaoInicial !== undefined) updates.descricaoInicial = descricaoInicial
        if (status !== undefined) updates.status = status

        // Se houver mudança de status, publicar evento para a fila e retornar 202
        if (status !== undefined) {
            const eventPayload = {
                payload: {
                    atendimentoId: id,
                    status,
                    apoiadorId: req.user?.id ?? null,
                    data: new Date().toISOString(),
                },
            }

            await publishEvent('status', eventPayload)

            // Atualizar outros campos (descricao) imediatamente se presente
            if (descricaoInicial !== undefined) {
                updates.descricaoInicial = descricaoInicial
                await db.update(atendimentos).set(updates).where(eq(atendimentos.id, id))
            }

            return reply.status(202).send({ message: 'Status update queued' })
        }

        const atendimentoAtualizado = await db.update(atendimentos)
            .set(updates)
            .where(eq(atendimentos.id, id))
            .returning();

        return reply.status(200).send({ atendimento: atendimentoAtualizado[0] })
    } catch (error) {
        console.error(error)
        return reply.status(500).send({ message: "Erro ao atualizar atendimento" })
    }
}

export async function excluirAtendimento(req: FastifyRequest, reply: FastifyReply) {
    try {
        const { id } = req.params as { id: string }
        await db.delete(atendimentos).where(eq(atendimentos.id, id))
        return reply.status(204).send()
    } catch (error) {
        console.error(error)
        return reply.status(500).send({ message: "Erro ao excluir atendimento" })
    }
}