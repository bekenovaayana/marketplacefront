import 'package:flutter/material.dart';
import 'package:marketplace_frontend/features/profile/data/profile_models.dart';

class ProfileTrustCard extends StatelessWidget {
  const ProfileTrustCard({
    super.key,
    required this.profile,
    required this.completeness,
    required this.onTapMissingField,
  });

  final UserMeResponse profile;
  final ProfileCompletenessDto? completeness;
  final ValueChanged<String> onTapMissingField;

  @override
  Widget build(BuildContext context) {
    final percent = (completeness?.percentage ?? 0).clamp(0, 100) / 100.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trust and profile quality',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: (profile.trustScore.clamp(0, 100)) / 100.0,
                        strokeWidth: 5,
                      ),
                      Center(
                        child: Text(
                          '${profile.trustScore}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _chip(
                        context,
                        'Email verified',
                        profile.emailVerified,
                      ),
                      const SizedBox(height: 4),
                      _chip(
                        context,
                        'Phone verified',
                        profile.phoneVerified,
                      ),
                      const SizedBox(height: 4),
                      _chip(
                        context,
                        'Profile completed',
                        profile.profileCompleted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Profile completeness: ${completeness?.percentage ?? 0}%'),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: percent),
            if ((completeness?.missingFields.isNotEmpty ?? false)) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: completeness!.missingFields
                    .map(
                      (field) => ActionChip(
                        label: Text('Add $field'),
                        onPressed: () => onTapMissingField(field),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool isDone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDone ? Colors.green.shade700 : Colors.grey.shade800,
          fontSize: 12,
        ),
      ),
    );
  }
}
