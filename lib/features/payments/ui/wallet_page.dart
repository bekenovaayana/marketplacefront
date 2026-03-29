import 'package:flutter/material.dart';
import 'package:marketplace_frontend/features/wallet/ui/wallet_screen.dart';

/// Вход из профиля: **GET /wallet** или **/api/wallet**, пополнение **POST** с тем же fallback путей.
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) => const WalletScreen();
}
