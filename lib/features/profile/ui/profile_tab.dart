import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/profile/state/my_active_listings_controller.dart';
import 'package:marketplace_frontend/features/profile/state/profile_controller.dart';
import 'package:marketplace_frontend/features/profile/ui/widgets/profile_my_listings_panel.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/widgets/skeleton_box.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab>
    with AutomaticKeepAliveClientMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _requestedProfileLoad = false;
  bool _listingsBootstrapped = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapListings() async {
    final n = ref.read(myActiveListingsProvider.notifier);
    await n.ensureCategories();
    if (mounted) await n.refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String tt(String k) => AppStrings.of(context, k);
    final auth = ref.watch(authControllerProvider);

    if (!auth.isAuthenticated) {
      _listingsBootstrapped = false;
      _requestedProfileLoad = false;
    }

    if (auth.isAuthenticated && !_requestedProfileLoad) {
      _requestedProfileLoad = true;
      Future.microtask(
        () => ref.read(profileControllerProvider.notifier).load(),
      );
    }
    if (auth.isAuthenticated && !_listingsBootstrapped) {
      _listingsBootstrapped = true;
      Future.microtask(_bootstrapListings);
    }

    final pstate = ref.watch(profileControllerProvider);
    final profile = pstate.profile;

    if (auth.isGuest) {
      return Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Text(
              tt('profileSignInSubtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: tt('profileEmail')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: tt('profilePassword')),
            ),
            const SizedBox(height: 8),
            if (auth.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  ErrorMapper.friendly(auth.error),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        final ok = await ref
                            .read(authControllerProvider.notifier)
                            .login(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            );
                        if (ok && mounted) {
                          _passwordController.clear();
                          await _bootstrapListings();
                        }
                      },
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(tt('profileSignIn')),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/register'),
              child: Text(tt('profileCreateAccount')),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(tt('profileEdit')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push('/auth-gate?from=/profile/edit'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: Text(tt('profilePromoteShort')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/auth-gate?from=/promote'),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(profileControllerProvider.notifier).load();
          await ref.read(myActiveListingsProvider.notifier).refresh();
        },
        child: ListView(
          key: const PageStorageKey('profile_tab_list'),
          padding: const EdgeInsets.all(16),
          children: [
            if (pstate.isLoading) ...[
              const SkeletonBox(height: 16, width: 140),
              const SizedBox(height: 10),
              const SkeletonBox(height: 42),
            ],
            if (pstate.error != null)
              ListTile(
                title: Text(
                  ErrorMapper.friendly(pstate.error),
                  style: const TextStyle(color: Colors.red),
                ),
                trailing: TextButton(
                  onPressed: () =>
                      ref.read(profileControllerProvider.notifier).load(),
                  child: Text(tt('retry')),
                ),
              ),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      ((profile?.avatarUrl ?? '').isNotEmpty)
                          ? NetworkImage(profile!.avatarUrl!)
                          : null,
                  child: (profile?.avatarUrl ?? '').isEmpty
                      ? const Icon(Icons.person_outline)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pstate.isLoading
                            ? '…'
                            : (profile?.fullName.isNotEmpty == true
                                  ? profile!.fullName
                                  : '—'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final changed =
                              await context.push<bool>('/profile/edit');
                          if (changed == true && mounted) {
                            await ref
                                .read(profileControllerProvider.notifier)
                                .load();
                            await ref
                                .read(myActiveListingsProvider.notifier)
                                .refresh();
                          }
                        },
                        child: Text(tt('profileEdit')),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (!mounted) return;
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  child: Text(tt('logout')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: Text(tt('profilePromoteShort')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final changed = await context.push<bool>('/promote');
                  if (changed == true && mounted) {
                    await ref
                        .read(myActiveListingsProvider.notifier)
                        .refresh();
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            const ProfileMyListingsPanel(),
          ],
        ),
      ),
    );
  }
}
