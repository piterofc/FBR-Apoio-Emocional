import amqplib, { Channel, ChannelModel, Connection } from 'amqplib'
import { env } from '../env'

let connection: ChannelModel | null = null
let channel: Channel | null = null

export async function connectRabbit(): Promise<Channel> {
  if (channel) return channel
  const url = env.RABBITMQ_URL
  connection = await amqplib.connect(url)
  channel = await connection.createChannel()
  return channel
}

export async function closeRabbit(): Promise<void> {
  try {
    if (channel) await channel.close()
    if (connection) await connection.close()
  } catch (err) {
    // ignore
  } finally {
    channel = null
    connection = null
  }
}

export function getChannel(): Channel {
  if (!channel) throw new Error('RabbitMQ channel not initialized')
  return channel
}
