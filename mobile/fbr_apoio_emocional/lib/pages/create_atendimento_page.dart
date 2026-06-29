import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_shell.dart';

class CreateAtendimentoPage extends StatefulWidget {
  final ApiService api;
  const CreateAtendimentoPage({super.key, required this.api});

  @override
  State<CreateAtendimentoPage> createState() => _CreateAtendimentoPageState();
}

class _CreateAtendimentoPageState extends State<CreateAtendimentoPage> {
  final _descricaoController = TextEditingController();
  bool _loading = false;

  void _submit() async {
    final desc = _descricaoController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Descrição é obrigatória')));
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.api.criarAtendimento(desc);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: AppBar(title: const Text('Novo Atendimento')),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Descreva o que está acontecendo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'Quanto mais contexto você trouxer, melhor fica a organização do atendimento.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição inicial',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                  else
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Criar atendimento'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
