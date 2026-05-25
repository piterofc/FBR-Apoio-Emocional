# Relatório de Integração - Sprint 2

## Resumo das ações realizadas:

- Adicionado RabbitMQ ao ambiente de desenvolvimento via `docker-compose`.
- Implementados producers nas rotas POST de prefixo (`/api/eventos/`) que publica eventos em cada fila.
- Implementado consumidor (`backend/src/services/eventConsumer.ts`) que processa mensagens assincronamente.
- Documentados formatos de eventos e instruções de execução.

## Conclusão:

Fluxo assíncrono demonstrado: producer publica e retorna imediatamente com `202 Accepted`; consumidor processa mensagens de forma independente.
