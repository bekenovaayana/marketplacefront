import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email required';
                  }
                  if (!value.contains('@')) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => (value == null || value.length < 8)
                    ? 'Password too short'
                    : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        final ok = await ref
                            .read(authControllerProvider.notifier)
                            .login(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );
                        if (!context.mounted) {
                          return;
                        }
                        if (ok) {
                          context.go('/app');
                        }
                      },
                child: authState.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('Create account'),
              ),
              if (authState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    authState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
