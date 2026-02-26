import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';
import '../../shared/molecules/molecules.dart';
import '../../shared/theme/app_colors.dart';
import 'widgets/occasion_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(remainingGenerationsProvider);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prosepal',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'The right words, right now',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        _SettingsButton(
                          onPressed: () => context.pushNamed('settings'),
                        ),
                      ],
                    )
                        .animate(key: const ValueKey('header'))
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    // Usage indicator
                    UsageIndicator(
                      remaining: remaining,
                      isPro: isPro,
                      onUpgrade: () => context.pushNamed('paywall'),
                      onProTap: () async {
                        final subscriptionService =
                            ref.read(subscriptionServiceProvider);
                        await subscriptionService.showCustomerCenter();
                      },
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
            ),

            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text(
                  "What's the occasion?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Occasion grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: OccasionGrid(
                onOccasionSelected: (occasion) {
                  ref.read(selectedOccasionProvider.notifier).state = occasion;
                  context.pushNamed('generate');
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// COMPONENTS
// =============================================================================

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Settings',
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Icon(
            Icons.settings_outlined,
            color: AppColors.primary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
