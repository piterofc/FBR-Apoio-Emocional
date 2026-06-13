import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'create_atendimento_page.dart';

class AtendimentosPage extends StatefulWidget {
  final ApiService api;
  const AtendimentosPage({super.key, required this.api});

  @override
  State<AtendimentosPage> createState() => _AtendimentosPageState();
}

class _AtendimentosPageState extends State<AtendimentosPage> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final items = await widget.api.listarAtendimentos();
      setState(() => _items = items);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _logout() async {
    await widget.api.clearToken();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atendimentos'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateAtendimentoPage(api: widget.api)));
          if (created == true) {
            _fetch();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: _items.isEmpty
                  ? ListView(children: const [Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Nenhum atendimento')))])
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index] as Map<String, dynamic>;
                        return ListTile(
                          title: Text('Atendimento ${item['id'] ?? ''}'),
                          subtitle: Text('Status: ${item['status'] ?? ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirmar'),
                                  content: const Text('Deseja excluir este atendimento?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir')),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                try {
                                  await widget.api.excluirAtendimento(item['id'].toString());
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Atendimento excluído')));
                                  _fetch();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                }
                              }
                            },
                          ),
                          onTap: () async {
                            // Abrir diálogo de edição simples
                            final descricaoController = TextEditingController(text: item['descricaoInicial']?.toString() ?? '');
                            String? status = item['status']?.toString();
                            final updated = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Editar Atendimento'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(controller: descricaoController, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrição')),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: status,
                                      items: const [
                                        DropdownMenuItem(value: 'PENDENTE', child: Text('PENDENTE')),
                                        DropdownMenuItem(value: 'EM_ANDAMENTO', child: Text('EM_ANDAMENTO')),
                                        DropdownMenuItem(value: 'CONCLUIDO', child: Text('CONCLUIDO')),
                                        DropdownMenuItem(value: 'CANCELADO', child: Text('CANCELADO')),
                                      ],
                                      onChanged: (v) => status = v,
                                      decoration: const InputDecoration(labelText: 'Status'),
                                    )
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                  TextButton(
                                      onPressed: () async {
                                        try {
                                          await widget.api.atualizarAtendimento(item['id'].toString(), descricaoInicial: descricaoController.text, status: status);
                                          Navigator.of(ctx).pop(true);
                                        } catch (e) {
                                          Navigator.of(ctx).pop(false);
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                        }
                                      },
                                      child: const Text('Salvar')),
                                ],
                              ),
                            );

                            if (updated == true) _fetch();
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
