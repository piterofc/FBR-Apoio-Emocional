import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_service.dart';

class ChatPage extends StatefulWidget {
  final ApiService api;
  final String atendimentoId;
  const ChatPage({super.key, required this.api, required this.atendimentoId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<dynamic> _msgs = [];
  final _ctrl = TextEditingController();
  WebSocketChannel? _channel;
  bool _loading = true;
  String? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      final atendimento = await widget.api.getAtendimento(widget.atendimentoId);
      final status = atendimento['status']?.toString();
      if (status != 'EM_ANDAMENTO' && status != 'CONCLUIDO') {
        setState(() {
          _error = 'O chat só pode ser aberto quando o atendimento estiver em andamento ou encerrado.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _status = status;
      });

      await _loadHistory();

      if (status == 'EM_ANDAMENTO') {
        await _connect();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    try {
      final msgs = await widget.api.fetchMessages(widget.atendimentoId);
      if (!mounted) return;
      setState(() => _msgs = msgs);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _connect() async {
    final token = await widget.api.getToken();
    if (_status != 'EM_ANDAMENTO') return;
    final base = widget.api.baseUrl;
    final wsScheme = base.startsWith('https') ? 'wss' : 'ws';
    final host = base.replaceFirst(RegExp(r'^https?://'), '');
    final uri = Uri.parse('$wsScheme://$host/ws?atendimentoId=${widget.atendimentoId}&token=$token');

    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen((data) {
      try {
        final m = jsonDecode(data as String) as Map<String, dynamic>;
        setState(() {
          _msgs.add(m);
        });
      } catch (e) {
        // ignore
      }
    }, onError: (err) async {
      // try reconnect after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _connect();
    }, onDone: () async {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _connect();
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (_status != 'EM_ANDAMENTO') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mensagens só podem ser enviadas quando o atendimento estiver em andamento.')));
      return;
    }
    try {
      await widget.api.sendChatMessage(widget.atendimentoId, text);
      _ctrl.clear();
      // optimistic UI: message will arrive via websocket broadcast
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_status == 'CONCLUIDO' ? 'Chat - Consulta' : 'Chat')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
              : Column(
                  children: [
                    Expanded(
                        child: ListView.builder(
                      itemCount: _msgs.length,
                      itemBuilder: (context, index) {
                        final m = _msgs[index] as Map<String, dynamic>;
                        return ListTile(
                          title: Text(m['mensagem'] ?? ''),
                          subtitle: Text(m['userId'] ?? ''),
                          trailing: Text(m['createdAt']?.toString() ?? ''),
                        );
                      },
                    )),
                    if (_status == 'EM_ANDAMENTO')
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Mensagem'))),
                            IconButton(onPressed: _send, icon: const Icon(Icons.send))
                          ],
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Atendimento encerrado. Chat em modo consulta.'),
                      )
                  ],
                ),
    );
  }
}
