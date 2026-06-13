import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'create_atendimento_page.dart';
import 'chat_page.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Atendimentos'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateAtendimentoPage(api: widget.api)));
          if (created == true) _fetch();
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
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(api: widget.api, atendimentoId: item['id'].toString()))),
                        );
                      },
                    ),
            ),
    );
  }
}
