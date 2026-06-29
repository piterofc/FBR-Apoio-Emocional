import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'create_atendimento_page.dart';
import 'chat_page.dart';
import '../widgets/app_shell.dart';
import '../widgets/formatters.dart';

class ClientAtendimentosPage extends StatefulWidget {
  final ApiService api;
  const ClientAtendimentosPage({super.key, required this.api});

  @override
  State<ClientAtendimentosPage> createState() => _ClientAtendimentosPageState();
}

class _ClientAtendimentosPageState extends State<ClientAtendimentosPage> {
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
      setState(() => _items = items.where((it) => it['clienteId']?.toString() == _userId).toList());
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
    return AppShell(
      appBar: AppBar(
        title: const Text('Meus Atendimentos'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meus atendimentos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text('Acompanhe o andamento e abra o chat quando ele estiver disponível.'),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final created = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateAtendimentoPage(api: widget.api)));
                    if (created == true) _fetch();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Novo'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: _items.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                Center(child: Text('Nenhum atendimento')),
                              ],
                            )
                          : ListView.builder(
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index] as Map<String, dynamic>;
                                final status = item['status']?.toString();
                                return Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    title: Text(item['descricaoInicial']?.toString() ?? 'Atendimento sem descrição', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 6),
                                        Text('Cliente: ${displayNameFromUser(item['cliente'], fallback: 'Cliente')}'),
                                        const SizedBox(height: 4),
                                        Text('Criado em: ${formatDateTime(item['createdAt'])}'),
                                        const SizedBox(height: 10),
                                        StatusChip(label: status ?? 'DESCONHECIDO'),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    onTap: () {
                                      if (status == 'EM_ANDAMENTO' || status == 'CONCLUIDO') {
                                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(api: widget.api, atendimentoId: item['id'].toString())));
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O chat só pode ser aberto quando o atendimento estiver em andamento ou encerrado.')));
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
