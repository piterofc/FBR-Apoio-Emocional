import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_shell.dart';

class LoginPage extends StatefulWidget {
  final ApiService api;
  const LoginPage({super.key, required this.api});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() => _loading = true);
    try {
      await widget.api.login(_emailController.text, _passwordController.text);
      // após login, buscar user e roteamento por role
      final me = await widget.api.getMe();
      final role = me['user']?['role']?.toString();
      if (!mounted) return;
      if (role == 'APOIADOR') {
        Navigator.pushReplacementNamed(context, '/apoiador');
      } else {
        Navigator.pushReplacementNamed(context, '/client');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<String?> _askNickname() async {
    final nicknameController = TextEditingController();
    String? errorText;

    final nickname = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Como você quer ser chamado?'),
          content: TextField(
            controller: nicknameController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Nome de exibição',
              hintText: 'Ex.: Ana, João, Carol',
              prefixIcon: const Icon(Icons.badge_outlined),
              errorText: errorText,
            ),
            onChanged: (value) {
              if (errorText != null && value.trim().isNotEmpty) {
                setDialogState(() => errorText = null);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = nicknameController.text.trim();
                if (value.isEmpty) {
                  setDialogState(() => errorText = 'Informe um nome para continuar.');
                  return;
                }
                Navigator.of(ctx).pop(value);
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nicknameController.dispose();
    });
    return nickname?.trim();
  }

  void _signup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha email e senha antes de criar a conta.')));
      return;
    }

    final nickname = await _askNickname();
    if (nickname == null || nickname.isEmpty) return;

    setState(() => _loading = true);
    try {
      await widget.api.signup(email, password, nickname);
      final me = await widget.api.getMe();
      final role = me['user']?['role']?.toString();
      if (!mounted) return;
      if (role == 'APOIADOR') {
        Navigator.pushReplacementNamed(context, '/apoiador');
      } else {
        Navigator.pushReplacementNamed(context, '/client');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: AppBar(toolbarHeight: 0),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2B4C7E), Color(0xFF1D9A6C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.favorite_border, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'FBR Apoio Emocional',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.05),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entre para acompanhar atendimentos, conversar em tempo real e manter o suporte organizado.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                  else
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _login,
                            icon: const Icon(Icons.login),
                            label: const Text('Entrar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _signup,
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Criar conta'),
                          ),
                        ),
                      ],
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
