import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/formatters.dart';

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
  final _scrollController = ScrollController();
  WebSocketChannel? _channel;
  bool _loading = true;
  String? _status;
  String? _error;
  Map<String, dynamic>? _atendimento;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _initChat() async {
    try {
      final atendimento = await widget.api.getAtendimento(widget.atendimentoId);
      final me = await widget.api.getMe();
      final status = atendimento['status']?.toString();
      _currentUserId = me['user']?['id']?.toString();
      if (status != 'EM_ANDAMENTO' && status != 'CONCLUIDO') {
        setState(() {
          _error = 'O chat só pode ser aberto quando o atendimento estiver em andamento ou encerrado.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _status = status;
        _atendimento = atendimento;
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
      _scrollToBottom();
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
        _scrollToBottom();
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
    final isReadOnly = _status == 'CONCLUIDO';

    return AppShell(
      appBar: AppBar(title: Text(isReadOnly ? 'Chat de consulta' : 'Chat em andamento')),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
                : Column(
                    children: [
                      AppSurface(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF2B4C7E), Color(0xFF1D9A6C)]),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.forum_outlined, color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_atendimento?['descricaoInicial']?.toString() ?? 'Atendimento', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Cliente: ${displayNameFromUser(_atendimento?['cliente'], fallback: 'Cliente')} · Apoiador: ${displayNameFromUser(_atendimento?['apoiador'], fallback: 'Aguardando apoio')}',
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Criado em: ${formatDateTime(_atendimento?['createdAt'])}',
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            if (_status != null) StatusChip(label: _status!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: AppSurface(
                          padding: const EdgeInsets.all(8),
                          child: ListView.separated(
                            controller: _scrollController,
                            itemCount: _msgs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final m = _msgs[index] as Map<String, dynamic>;
                              final senderId = m['user']?['id']?.toString() ?? m['userId']?.toString();
                              final senderName = displayNameFromUser(m['user'], fallback: 'Usuário');
                              final isMine = senderId != null && senderId == _currentUserId;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                child: Align(
                                  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 340),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isMine ? const Color(0xFF2B4C7E) : const Color(0xFFF8FAFF),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(18),
                                          topRight: const Radius.circular(18),
                                          bottomLeft: Radius.circular(isMine ? 18 : 6),
                                          bottomRight: Radius.circular(isMine ? 6 : 18),
                                        ),
                                        border: Border.all(
                                          color: isMine ? const Color(0xFF2B4C7E) : const Color(0xFFD9E2F2),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            senderName,
                                            style: TextStyle(
                                              color: isMine ? Colors.white : const Color(0xFF2B4C7E),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            m['mensagem']?.toString() ?? '',
                                            style: TextStyle(
                                              fontSize: 15,
                                              height: 1.35,
                                              color: isMine ? Colors.white : const Color(0xFF132238),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Text(
                                              formatDateTime(m['createdAt']),
                                              style: TextStyle(
                                                color: isMine ? Colors.white70 : Colors.grey.shade500,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_status == 'EM_ANDAMENTO')
                        AppSurface(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _ctrl,
                                  decoration: const InputDecoration(
                                    hintText: 'Escreva sua mensagem',
                                    prefixIcon: Icon(Icons.edit_outlined),
                                  ),
                                  minLines: 1,
                                  maxLines: 4,
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton(
                                onPressed: _send,
                                child: const Icon(Icons.send),
                              ),
                            ],
                          ),
                        )
                      else
                        AppSurface(
                          child: Row(
                            children: [
                              const Icon(Icons.visibility_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Atendimento encerrado. O chat está apenas para consulta.',
                                  style: TextStyle(color: Colors.grey.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
