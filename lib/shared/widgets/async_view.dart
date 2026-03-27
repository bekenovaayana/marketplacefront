import 'package:flutter/material.dart';

class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.isLoading,
    required this.error,
    required this.data,
    required this.builder,
    this.emptyMessage = 'No data',
  });

  final bool isLoading;
  final String? error;
  final T? data;
  final Widget Function(T data) builder;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error!));
    }
    if (data == null) {
      return Center(child: Text(emptyMessage));
    }
    return builder(data as T);
  }
}
