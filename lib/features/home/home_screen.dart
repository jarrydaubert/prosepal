import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';
import '../../shared/molecules/molecules.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import 'widgets/occasion_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(remainingGenerationsProvider);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withValues(alpha: 0.04), Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prosepal',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              Text(
                                'The right words, right now',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Semantics(
                            label: 'Settings',
                            button: true,
                            child: IconButton(
                              onPressed: () => context.pushNamed('settings'),
                              icon: const Icon(Icons.settings_outlined),
                              tooltip: 'Settings',
                            ),
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.lg),
                      // Usage indicator
                      UsageIndicator(
                        remaining: remaining,
                        isPro: isPro,
                        onUpgrade: () => context.pushNamed('paywall'),
                        onProTap: () async {
                          final subscriptionService = ref.read(subscriptionServiceProvider);
                          await subscriptionService.showCustomerCenter();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Text(
                    "What's the occasion?",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(AppSpacing.md)),

              // Occasion grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                sliver: OccasionGrid(
                  onOccasionSelected: (occasion) {
                    ref.read(selectedOccasionProvider.notifier).state =
                        occasion;
                    context.pushNamed('generate');
                  },
                ),
              ),

              const SliverToBoxAdapter(child: Gap(AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }
}

// Now using UsageIndicator from shared/molecules/usage_indicator.dart
