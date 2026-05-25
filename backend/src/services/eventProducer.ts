import { connectRabbit } from './rabbitmq'

export async function publishEvent(queue: string, payload: unknown) {
  const ch = await connectRabbit()
  await ch.assertQueue(queue, { durable: true })
  const buf = Buffer.from(JSON.stringify(payload))
  ch.sendToQueue(queue, buf, { persistent: true })
}

export default publishEvent
