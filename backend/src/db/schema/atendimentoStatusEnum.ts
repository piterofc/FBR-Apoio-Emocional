import {pgEnum} from "drizzle-orm/pg-core";

export const atendimentoStatusEnum = pgEnum('atendimento_status', ['PENDENTE', 'EM_ANDAMENTO', 'CONCLUIDO', 'CANCELADO']);