import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_page.dart';

class ApoiadorAtendimentosPage extends StatefulWidget {
  final ApiService api;
  const ApoiadorAtendimentosPage({super.key, required this.api});

  @override
  State<ApoiadorAtendimentosPage> createState() => _ApoiadorAtendimentosPageState();
}

class _ApoiadorAtendimentosPageState extends State<ApoiadorAtendimentosPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final me = await widget.api.getMe();
      _userId = me['user']?['id']?.toString();
    } catch (e) {
      // ignore
    }
    await _fetch();
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

  Future<void> _pegarAtendimento(String id) async {
    try {
      await widget.api.atualizarAtendimento(id, status: 'EM_ANDAMENTO');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Atendimento pego')));
      await _fetch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _concluirAtendimento(String id) async {
    try {
      await widget.api.atualizarAtendimento(id, status: 'CONCLUIDO');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Atendimento concluído')));
      await _fetch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _logout() async {
    await widget.api.clearToken();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final pendentes = _items.where((it) => it['status'] == 'PENDENTE').toList();
    final meusAtivos = _items.where((it) => it['status'] == 'EM_ANDAMENTO' && it['apoiadorId']?.toString() == _userId).toList();
    final meusConcluidos = _items.where((it) => it['status'] == 'CONCLUIDO' && it['apoiadorId']?.toString() == _userId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apoiador - Atendimentos'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pendentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...pendentes.map((item) {
                        final it = item as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            title: Text('Atendimento ${it['id'] ?? ''}'),
                            subtitle: Text(it['descricaoInicial']?.toString() ?? ''),
                            trailing: ElevatedButton(onPressed: () => _pegarAtendimento(it['id'].toString()), child: const Text('Pegar')),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      const Text('Meus Atendimentos Ativos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...meusAtivos.map((item) {
                        final it = item as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            title: Text('Atendimento ${it['id'] ?? ''}'),
                            subtitle: Text(it['descricaoInicial']?.toString() ?? ''),
                            trailing: ElevatedButton(onPressed: () => _concluirAtendimento(it['id'].toString()), child: const Text('Concluir')),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatPage(api: widget.api, atendimentoId: it['id'].toString()),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      const Text('Meus Atendimentos Concluídos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...meusConcluidos.map((item) {
                        final it = item as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            title: Text('Atendimento ${it['id'] ?? ''}'),
                            subtitle: Text(it['descricaoInicial']?.toString() ?? ''),
                            trailing: const Icon(Icons.chat_bubble_outline),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatPage(api: widget.api, atendimentoId: it['id'].toString()),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
