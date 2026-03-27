import 'package:flutter/material.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';

class SettingsStubScreen extends StatelessWidget {
  const SettingsStubScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      body: const Center(child: Text('Coming soon')),
    );
  }
}
