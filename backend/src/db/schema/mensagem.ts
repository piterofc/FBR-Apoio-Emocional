import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'
import { atendimentos } from './atendimento'
import { users } from './user'

export const mensagens = pgTable('mensagens', {
  id: uuid().primaryKey().defaultRandom(),
  atendimentoId: uuid('atendimento_id').references(() => atendimentos.id),
  userId: uuid('user_id').references(() => users.id),
  mensagem: text('mensagem').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
})

export type Mensagem = typeof mensagens
