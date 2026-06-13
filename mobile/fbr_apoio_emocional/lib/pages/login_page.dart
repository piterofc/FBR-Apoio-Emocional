import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _signup() async {
    setState(() => _loading = true);
    try {
      await widget.api.signup(_emailController.text, _passwordController.text, 'mobile');
      final me = await widget.api.getMe();
      final role = me['user']?['role']?.toString();
      if (!mounted) return;
      if (role == 'APOIADOR') {
        Navigator.pushReplacementNamed(context, '/apoiador');
      } else {
        Navigator.pushReplacementNamed(context, '/client');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(onPressed: _login, child: const Text('Login')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(onPressed: _signup, child: const Text('Signup')),
                      ),
                    ],
                  )
          ],
        ),
      ),
    );
  }
}
