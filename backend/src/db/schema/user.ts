import { pgTable, text, uuid, timestamp} from "drizzle-orm/pg-core";
import { roleEnum } from "./roleEnum";

export const users = pgTable("users", {
    id: uuid().primaryKey().defaultRandom(),

    email: text("email").notNull().unique(),
    password: text("password").notNull(),
    nickname: text("nickname").notNull(),
    role: roleEnum("role").notNull().default('CLIENTE'),

    lastLogin: timestamp('last_login', { withTimezone: true }).defaultNow().notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
})