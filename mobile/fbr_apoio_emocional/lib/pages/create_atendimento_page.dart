import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Atendimento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição inicial'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _submit, child: const Text('Criar'))
          ],
        ),
      ),
    );
  }
}
