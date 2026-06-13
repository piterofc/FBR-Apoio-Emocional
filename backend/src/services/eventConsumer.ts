import { connectRabbit } from './rabbitmq'
import { db } from '@/db/connection'
import { atendimentos } from '@/db/schema/atendimento'
import { eq } from 'drizzle-orm'

const STATUS_QUEUE = 'status'
const CHAT_QUEUE = 'chat'

export async function startConsumers() {
  const ch = await connectRabbit()

  await ch.assertQueue(STATUS_QUEUE, { durable: true })
  await ch.assertQueue(CHAT_QUEUE, { durable: true })

  console.log('📥 Consumidor aguardando mensagens na fila', STATUS_QUEUE)
  console.log('📥 Consumidor aguardando mensagens na fila', CHAT_QUEUE)

  ch.consume(STATUS_QUEUE, async (msg: any) => {
    if (!msg) return

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
      ch.nack(msg, false, false)
    }
  })

  ch.consume(CHAT_QUEUE, async (msg: any) => {
    if (!msg) return

    try {
      const content = msg.content.toString()
      const payload = JSON.parse(content)
      console.log('💬 Mensagem de chat recebida:', payload)

      // await new Promise((res) => setTimeout(res, 1500))
      // Executar ação

      console.log('🔁 Processamento de chat concluído para:', payload)
      ch.ack(msg)
    } catch (err) {
      console.error('❌ Erro ao processar mensagem de chat', err)
      ch.nack(msg, false, false)
    }
  })
}
