# Documentação dos Eventos

---

## Evento 1 - Modificação de Status

Esse evento acontece após a modificação de status de um atendimento pela rota `POST /api/eventos/status`.

| Campo          | Descrição                                         |
| -------------- | ------------------------------------------------- |
| Nome do evento | `status`                                          |
| Produtor       | `publicarStatus`                                  |
| Consumidor     | `eventConsumer`                                   |
| Fila utilizada | `status`                                          |
| Objetivo       | Alterar status de atendimento                     |

## Exemplo de Payload

```json
{
  "atendimentoId": UUID,
  "status": "atendido",
  "apoiadorId": UUID,
  "data": "2026-05-25T21:00:00.000Z"
}
```