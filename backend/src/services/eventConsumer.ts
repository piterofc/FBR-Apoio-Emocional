import { connectRabbit } from './rabbitmq'
import { db } from '@/db/connection'
import { atendimentos } from '@/db/schema/atendimento'
import { eq } from 'drizzle-orm'

async function getUserSummary(userId: string) {
  return db.query.users.findFirst({
    where: (u) => eq(u.id, userId),
    columns: { id: true, nickname: true, email: true },
  })
}

const STATUS_QUEUE = 'status'
const CHAT_QUEUE = 'chat'

export async function startConsumers() {
  const ch = await connectRabbit()

  await ch.assertQueue(STATUS_QUEUE, { durable: true })
  await ch.assertQueue(CHAT_QUEUE, { durable: true })
  console.log('📥 Consumidor aguardando mensagens na fila', STATUS_QUEUE)
  console.log('📥 Consumidor aguardando mensagens na fila', CHAT_QUEUE)

  // allow concurrent message processing (tune as needed)
  try {
    ch.prefetch(10)
  } catch (err) {
    // ignore if channel doesn't support prefetch
  }

  ch.consume(STATUS_QUEUE, (msg: any) => {
    if (!msg) return

    // process in a detached async task to allow concurrent messages
    void (async () => {
      try {
        const content = msg.content.toString()
        const parsed = JSON.parse(content)
        const payload = parsed.payload || parsed
        console.log('✅ Status recebido:', payload)

        const atendimentoId = payload.atendimentoId
        const status = payload.status
        const apoiadorId = payload.apoiadorId ?? null

        if (!atendimentoId) {
          throw new Error('Payload missing atendimentoId')
        }

        // Atualizar o atendimento no banco
        const updates: any = { status }
        if (apoiadorId) updates.apoiadorId = apoiadorId

        await db.update(atendimentos).set(updates).where(eq(atendimentos.id, atendimentoId))

        console.log('🔁 Processamento de status concluído para:', atendimentoId)
        ch.ack(msg)
      } catch (err) {
        console.error('❌ Erro ao processar mensagem', err)
        try {
          ch.nack(msg, false, false)
        } catch (e) {
          // ignore
        }
      }
    })()
  })

  ch.consume(CHAT_QUEUE, (msg: any) => {
    if (!msg) return

    void (async () => {
      try {
        const content = msg.content.toString()
        const parsed = JSON.parse(content)
        const payload = parsed.payload || parsed
        console.log('💬 Mensagem de chat recebida:', payload)

        const atendimentoId = payload.atendimentoId
        const userId = payload.userId
        const mensagem = payload.mensagem || payload.text || payload.message
        const data = payload.data ? new Date(payload.data) : new Date()

        if (!atendimentoId || !userId || !mensagem) {
          throw new Error('Payload de chat incompleto')
        }

        const result = await db.insert((await import('@/db/schema/mensagem')).mensagens).values({
          atendimentoId: atendimentoId,
          userId: userId,
          mensagem: mensagem,
          createdAt: data,
        }).returning()

        // Broadcast to connected websocket clients
        try {
          const { broadcastToRoom } = await import('@/services/ws')
          const inserted = result[0]
          const user = await getUserSummary(userId)
          broadcastToRoom(atendimentoId, {
            id: inserted.id,
            atendimentoId: inserted.atendimentoId,
            userId: inserted.userId,
            user,
            mensagem: inserted.mensagem,
            createdAt: inserted.createdAt,
          })
        } catch (err) {
          console.error('❌ Erro ao broadcast de mensagem via websocket', err)
        }

        console.log('🔁 Processamento de chat concluído para atendimento:', atendimentoId)
        ch.ack(msg)
      } catch (err) {
        console.error('❌ Erro ao processar mensagem de chat', err)
        try {
          ch.nack(msg, false, false)
        } catch (e) {
          // ignore
        }
      }
    })()
  })
}
