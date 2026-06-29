import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_page.dart';
import '../widgets/app_shell.dart';
import '../widgets/formatters.dart';

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

    return AppShell(
      appBar: AppBar(
        title: const Text('Área do apoiador'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fila e acompanhamento', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Pegue um atendimento, acompanhe os em andamento e consulte os concluídos em um só lugar.', style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _SectionTitle(title: 'Pendentes', count: pendentes.length),
                          const SizedBox(height: 8),
                          ...pendentes.map((item) {
                            final it = item as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                title: Text(it['descricaoInicial']?.toString() ?? 'Sem descrição', style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text('Cliente: ${displayNameFromUser(it['cliente'], fallback: 'Cliente')}'),
                                    const SizedBox(height: 4),
                                    Text('Criado em: ${formatDateTime(it['createdAt'])}'),
                                  ],
                                ),
                                trailing: FilledButton(onPressed: () => _pegarAtendimento(it['id'].toString()), child: const Text('Pegar')),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          _SectionTitle(title: 'Meus atendimentos em andamento', count: meusAtivos.length),
                          const SizedBox(height: 8),
                          ...meusAtivos.map((item) {
                            final it = item as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                title: Text(it['descricaoInicial']?.toString() ?? 'Sem descrição', style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text('Cliente: ${displayNameFromUser(it['cliente'], fallback: 'Cliente')}'),
                                    const SizedBox(height: 4),
                                    Text('Criado em: ${formatDateTime(it['createdAt'])}'),
                                  ],
                                ),
                                trailing: FilledButton.tonal(onPressed: () => _concluirAtendimento(it['id'].toString()), child: const Text('Concluir')),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(api: widget.api, atendimentoId: it['id'].toString()))),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          _SectionTitle(title: 'Meus atendimentos concluídos', count: meusConcluidos.length),
                          const SizedBox(height: 8),
                          ...meusConcluidos.map((item) {
                            final it = item as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                title: Text(it['descricaoInicial']?.toString() ?? 'Sem descrição', style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text('Cliente: ${displayNameFromUser(it['cliente'], fallback: 'Cliente')}'),
                                    const SizedBox(height: 4),
                                    Text('Criado em: ${formatDateTime(it['createdAt'])}'),
                                  ],
                                ),
                                trailing: const Icon(Icons.chat_bubble_outline),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(api: widget.api, atendimentoId: it['id'].toString()))),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2B4C7E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ],
    );
  }
}
