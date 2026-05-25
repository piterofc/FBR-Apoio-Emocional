#!/usr/bin/env node
import publishEvent from '../services/eventProducer'

async function main() {
  const args = process.argv.slice(2)
  const type = args[0] || 'test:event'
  const payload = {
    type,
    timestamp: new Date().toISOString(),
    data: { sample: 'hello from send_event' },
  }

  await publishEvent('events', payload)
  console.log('📤 Evento enviado:', payload)
  process.exit(0)
}

void main().catch((err) => {
  console.error(err)
  process.exit(1)
})
