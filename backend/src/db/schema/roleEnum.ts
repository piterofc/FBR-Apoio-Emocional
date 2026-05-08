import {pgEnum} from "drizzle-orm/pg-core";

export const roleEnum = pgEnum('user_role', ['CLIENTE', 'APOIADOR']);