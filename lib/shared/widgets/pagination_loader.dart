import 'package:flutter/material.dart';

class PaginationLoader extends StatelessWidget {
  const PaginationLoader({
    super.key,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: isLoadingMore
            ? const CircularProgressIndicator()
            : OutlinedButton(
                onPressed: onLoadMore,
                child: const Text('Load more'),
              ),
      ),
    );
  }
}
