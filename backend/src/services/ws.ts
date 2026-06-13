import type { WebSocket } from 'ws'

const rooms: Map<string, Set<WebSocket>> = new Map()
const socketUsers: WeakMap<WebSocket, string | undefined> = new WeakMap()

export function addToRoom(atendimentoId: string, socket: WebSocket, userId?: string) {
  const set = rooms.get(atendimentoId) || new Set<WebSocket>()
  set.add(socket)
  socketUsers.set(socket, userId)
  rooms.set(atendimentoId, set)
}

export function removeFromRoom(atendimentoId: string, socket: WebSocket) {
  const set = rooms.get(atendimentoId)
  if (!set) return
  set.delete(socket)
  socketUsers.delete(socket)
  if (set.size === 0) rooms.delete(atendimentoId)
}

export function broadcastToRoom(atendimentoId: string, payload: unknown) {
  const set = rooms.get(atendimentoId)
  if (!set) return
  const text = JSON.stringify(payload)
  for (const socket of Array.from(set)) {
    try {
      socket.send(text)
    } catch (err) {
      // ignore send errors
    }
  }
}

export default { addToRoom, removeFromRoom, broadcastToRoom }
