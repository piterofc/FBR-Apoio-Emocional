import { connectRabbit } from './rabbitmq'

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
      const payload = JSON.parse(content)
      console.log('✅ Status recebido:', payload)

      // await new Promise((res) => setTimeout(res, 1500))
      // Executar ação

      console.log('🔁 Processamento de status concluído para:', payload)
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
