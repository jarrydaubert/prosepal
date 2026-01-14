import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';
import '../../core/services/log_service.dart';
import '../../shared/components/components.dart';
import '../../shared/theme/app_colors.dart';
import '../paywall/paywall_sheet.dart';
import 'widgets/occasion_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initStatus = ref.watch(initStatusProvider);
    final remaining = ref.watch(remainingGenerationsProvider);
    final isPro = ref.watch(isProProvider);

    // Check for pending paywall (e.g., after email sign-in from paywall sync)
    final pendingPaywallSource = ref.watch(pendingPaywallSourceProvider);
    if (pendingPaywallSource != null) {
      // Clear immediately to prevent re-triggering
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pendingPaywallSourceProvider.notifier).state = null;
        showPaywall(context, source: pendingPaywallSource);
      });
    }

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
                            Row(
                              children: [
                                _IconButton(
                                  icon: Icons.history,
                                  onPressed: () => context.pushNamed('history'),
                                  tooltip: 'Message history',
                                ),
                                const SizedBox(width: 8),
                                _IconButton(
                                  icon: Icons.settings_outlined,
                                  onPressed: () =>
                                      context.pushNamed('settings'),
                                  tooltip: 'Settings',
                                ),
                              ],
                            ),
                          ],
                        )
                        .animate(key: const ValueKey('header'))
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    // Usage indicator (shimmer while RevenueCat loads, fallback if timed out)
                    if (!initStatus.revenueCatReady && !initStatus.timedOut)
                      const _UsageIndicatorShimmer()
                    else
                      UsageIndicator(
                        remaining: remaining,
                        isPro: isPro,
                        onUpgrade: () {
                          Log.info('Upgrade tapped', {'source': 'home'});
                          // Always show paywall - it has inline auth
                          showPaywall(context, source: 'home');
                        },
                        onProTap: () async {
                          final isLoggedIn = ref
                              .read(authServiceProvider)
                              .isLoggedIn;
                          if (!isLoggedIn) {
                            // Anonymous Pro user - prompt to sign in to protect subscription
                            Log.info('Pro badge tapped (anonymous)', {
                              'source': 'home',
                            });
                            context.push('/auth?restore=true');
                          } else {
                            // Signed in - show customer center
                            final subscriptionService = ref.read(
                              subscriptionServiceProvider,
                            );
                            await subscriptionService.showCustomerCenter();
                          }
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
                  Log.info('Wizard started', {'occasion': occasion.name});
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

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip = '',
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
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
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for UsageIndicator while RevenueCat loads.
class _UsageIndicatorShimmer extends StatelessWidget {
  const _UsageIndicatorShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: Row(
            children: [
              // Circle placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              // Text placeholders
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.grey[100]);
  }
}
