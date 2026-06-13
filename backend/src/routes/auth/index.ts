import type { FastifyInstance } from "fastify";
import jwt from "jsonwebtoken";
import { env } from "@/env";

import {
  me,
  signup,
  login,
  logout,
} from "../../controllers/auth/index";

import * as schemas from "../../controllers/auth/schemas";

const {
  meResponseSchema,
  signupBodySchema,
  signupResponseSchema,
  loginBodySchema,
  loginResponseSchema,
  logoutResponseSchema,
} = schemas;

export async function authRoutes(app: FastifyInstance) {
  app.get(
    "/me",
    {
      schema: {
        tags: ["Auth"],
        summary: "Obter informações do usuário",
        description:
          "Retorna o usuário autenticado com sessão válida.",
        response: meResponseSchema,
      },
      preHandler: async (request, reply) => {
        // aceitar token via cookie ou Authorization header
        let token = request.cookies?.token as string | undefined;
        if (!token) {
          const authHeader = (request.headers as any).authorization || (request.headers as any).Authorization;
          if (typeof authHeader === 'string' && authHeader.startsWith('Bearer ')) {
            token = authHeader.split(' ')[1];
          }
        }

        if (!token) {
          return reply.status(401).send({ message: 'Unauthorized' });
        }

        try {
          const decoded = jwt.verify(token, env.JWT_SECRET || '') as { userId: string };
          request.user = { id: decoded.userId };
        } catch (err) {
          return reply.status(401).send({ message: 'Unauthorized' });
        }
      },
    },
    me,
  );

  app.post(
    "/signup",
    {
      schema: {
        tags: ["Auth"],
        summary: "Criar conta",
        description: "Criar uma nova conta e logar usuário",
        body: signupBodySchema,
        response: signupResponseSchema,
      },
    },
    signup,
  );

  app.post(
    "/login",
    {
      schema: {
        tags: ["Auth"],
        summary: "Login",
        description: "Autenticar e logar usuário",
        body: loginBodySchema,
        response: loginResponseSchema,
      },
    },
    login,
  );

  app.post(
    "/logout",
    {
      schema: {
        tags: ["Auth"],
        summary: "Logout",
        description: "Deslogar o usuário",
        response: logoutResponseSchema,
      },
    },
    logout,
  );
}
