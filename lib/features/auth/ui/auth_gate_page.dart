import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/auth/state/auth_state.dart';

class AuthGatePage extends ConsumerStatefulWidget {
  const AuthGatePage({super.key, this.from});

  final String? from;

  @override
  ConsumerState<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends ConsumerState<AuthGatePage>
    with SingleTickerProviderStateMixin {
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _registerName = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _registerName.dispose();
    _registerEmail.dispose();
    _registerPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in to continue'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Login'),
            Tab(text: 'Register'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildLogin(auth), _buildRegister(auth)],
      ),
    );
  }

  Widget _buildLogin(AuthState auth) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _loginFormKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _loginEmail,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email required';
                }
                if (!value.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _loginPassword,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) => (value == null || value.length < 8)
                  ? 'Password too short'
                  : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      if (!_loginFormKey.currentState!.validate()) return;
                      final ok = await ref
                          .read(authControllerProvider.notifier)
                          .login(
                            email: _loginEmail.text.trim(),
                            password: _loginPassword.text.trim(),
                          );
                      if (!mounted || !ok) return;
                      _continueAfterAuth();
                    },
              child: auth.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Text(auth.error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegister(AuthState auth) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _registerFormKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _registerName,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _registerEmail,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Required';
                if (!value.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _registerPassword,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) =>
                  (value == null || value.length < 8) ? 'Min 8 chars' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      if (!_registerFormKey.currentState!.validate()) return;
                      final ok = await ref
                          .read(authControllerProvider.notifier)
                          .register(
                            fullName: _registerName.text.trim(),
                            email: _registerEmail.text.trim(),
                            password: _registerPassword.text.trim(),
                          );
                      if (!mounted || !ok) return;
                      _continueAfterAuth();
                    },
              child: auth.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create account'),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Text(auth.error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }

  void _continueAfterAuth() {
    final target = widget.from;
    if (target != null && target.isNotEmpty) {
      context.go(target);
      return;
    }
    context.go('/app');
  }
}
