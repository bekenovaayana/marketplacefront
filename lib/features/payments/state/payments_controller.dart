import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/features/payments/data/payments_api.dart';

class PaymentsState {
  const PaymentsState({
    this.isLoading = false,
    this.message,
    this.lastPayment,
    this.error,
  });

  final bool isLoading;
  final String? message;
  final PaymentDto? lastPayment;
  final String? error;

  PaymentsState copyWith({
    bool? isLoading,
    String? message,
    PaymentDto? lastPayment,
    String? error,
    bool clearFeedback = false,
  }) {
    return PaymentsState(
      isLoading: isLoading ?? this.isLoading,
      message: clearFeedback ? null : (message ?? this.message),
      lastPayment: lastPayment ?? this.lastPayment,
      error: clearFeedback ? null : (error ?? this.error),
    );
  }
}

final paymentsControllerProvider =
    StateNotifierProvider<PaymentsController, PaymentsState>((ref) {
  return PaymentsController(ref.watch(paymentsApiProvider));
});

class PaymentsController extends StateNotifier<PaymentsState> {
  PaymentsController(this._paymentsApi) : super(const PaymentsState());

  final PaymentsApi _paymentsApi;

  Future<void> createPayment({
    required int listingId,
    required double amount,
  }) async {
    state = state.copyWith(isLoading: true, clearFeedback: true);
    try {
      final payment = await _paymentsApi.createPayment(
        listingId: listingId,
        amount: amount,
      );
      state = state.copyWith(
        isLoading: false,
        lastPayment: payment,
        message: 'Payment created: #${payment.id}',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> simulatePaymentSuccess() async {
    final payment = state.lastPayment;
    if (payment == null) {
      state = state.copyWith(error: 'Create payment first');
      return;
    }
    state = state.copyWith(isLoading: true, clearFeedback: true);
    try {
      final updated = await _paymentsApi.simulateSuccess(payment.id);
      state = state.copyWith(
        isLoading: false,
        lastPayment: updated,
        message: 'Payment successful',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

}
