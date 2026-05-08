import { pgTable, text, uuid, timestamp} from "drizzle-orm/pg-core";
import { users } from "./user";
import { atendimentoStatusEnum } from "./atendimentoStatusEnum";

export const atendimentos = pgTable("atendimentos", {
    id: uuid().primaryKey().defaultRandom(),

    clienteId: uuid("cliente_id").notNull().references(() => users.id),
    apoiadorId: uuid("apoiador_id").references(() => users.id),
    descricaoInicial: text("descricao_inicial").notNull(),
    status: atendimentoStatusEnum("status").notNull().default('PENDENTE'),

    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
})