import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/features/payments/state/payments_controller.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';

/// Dev / legacy payment lab. Promotions use **кошелёк** → экран «Продвижение».
class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  final _listingIdController = TextEditingController();
  final _amountController = TextEditingController(text: '10');

  @override
  void dispose() {
    _listingIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsControllerProvider);
    final controller = ref.read(paymentsControllerProvider.notifier);
    return AppScaffold(
      title: 'Payments (lab)',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Промо из кошелька: Профиль → Продвижение или Кошелёк.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _listingIdController,
            decoration: const InputDecoration(labelText: 'Listing ID'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Payment Amount'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: state.isLoading
                ? null
                : () async {
                    final id = int.tryParse(_listingIdController.text.trim()) ?? 0;
                    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
                    await controller.createPayment(listingId: id, amount: amount);
                  },
            child: const Text('Create payment'),
          ),
          ElevatedButton(
            onPressed: state.isLoading ? null : controller.simulatePaymentSuccess,
            child: const Text('Simulate payment success'),
          ),
          const SizedBox(height: 16),
          if (state.message != null)
            Text(state.message!, style: const TextStyle(color: Colors.green)),
          if (state.error != null)
            Text(state.error!, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
