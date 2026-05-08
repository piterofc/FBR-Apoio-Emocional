import type { FastifyInstance } from "fastify";
import { authenticate } from "@/middlewares/auth";

import {
  listarAtendimentos,
  obterAtendimento,
  criarAtendimento,
  atualizarAtendimento,
  excluirAtendimento
} from "../../controllers/atendimento/index";

import * as schemas from "../../controllers/atendimento/schemas";
import { ZodTypeProvider } from "fastify-type-provider-zod";
import { z } from "zod";

const {
  listarAtendimentosResponseSchema,
  atendimentoResponseSchema,
  createBodySchema,
  createResponseSchema,
  updateBodySchema,
  updateResponseSchema,
  deleteResponseSchema
} = schemas;

export async function atendimentoRoutes(app: FastifyInstance) {
  const appWithZod = app.withTypeProvider<ZodTypeProvider>();

  appWithZod.addHook("preHandler", authenticate);

  appWithZod.get(
    "/",
    {
      schema: {
        tags: ["Atendimento"],
        summary: "Obter lista de atendimentos",
        description:
          "Retorna a lista de atendimentos disponíveis.",
        // response: listarAtendimentosResponseSchema,
      },
    },
    listarAtendimentos,
  );

  appWithZod.get(
    "/:id",
    {
      schema: {
        tags: ["Atendimento"],
        summary: "Obter detalhes de um atendimento",
        description:
          "Retorna os detalhes de um atendimento específico.",
        // response: atendimentoResponseSchema,
      },
    },
    obterAtendimento,
  );

  appWithZod.post(
    "/",
    {
      schema: {
        tags: ["Atendimento"],
        summary: "Criar um novo atendimento",
        description: "Cria um novo atendimento com as informações fornecidas.",
        body: createBodySchema,
        // response: createResponseSchema,
      },
    },
    criarAtendimento,
  );

  appWithZod.patch(
    "/:id",
    {
      schema: {
        tags: ["Atendimento"],
        summary: "Atualizar um atendimento",
        description: "Atualiza um atendimento existente com as informações fornecidas.",
        body: updateBodySchema,
        // response: updateResponseSchema,
      },
    },
    atualizarAtendimento,
  );

  appWithZod.delete(
    "/:id",
    {
      schema: {
        tags: ["Atendimento"],
        summary: "Excluir um atendimento",
        description: "Exclui um atendimento existente.",
        // response: deleteResponseSchema,
      },
    },
    excluirAtendimento,
  );

}