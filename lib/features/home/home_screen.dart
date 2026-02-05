import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/preference_keys.dart';
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
    final showFirstActionHint = ref.watch(showFirstActionHintProvider);

    // Check for pending paywall (e.g., after email sign-in from paywall sync)
    final pendingPaywallSource = ref.watch(pendingPaywallSourceProvider);
    if (pendingPaywallSource != null) {
      // Clear immediately to prevent re-triggering
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pendingPaywallSourceProvider.notifier).state = null;
        showPaywall(context, source: pendingPaywallSource);
      });
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                                  Row(
                                    children: [
                                      const Text(
                                        'Prosepal',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      if (isPro) ...[
                                        const SizedBox(width: 10),
                                        _ProPill(
                                          onTap: () async {
                                            final isLoggedIn = ref
                                                .read(authServiceProvider)
                                                .isLoggedIn;
                                            if (!isLoggedIn) {
                                              Log.info(
                                                'Pro badge tapped (anonymous)',
                                                {'source': 'home'},
                                              );
                                              context.push(
                                                '/auth?restore=true',
                                              );
                                            } else {
                                              final subscriptionService = ref
                                                  .read(
                                                    subscriptionServiceProvider,
                                                  );
                                              await subscriptionService
                                                  .showCustomerCenter();
                                            }
                                          },
                                        ),
                                      ],
                                    ],
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
                                    icon: Icons.calendar_month_outlined,
                                    onPressed: () =>
                                        context.pushNamed('calendar'),
                                    tooltip: 'Upcoming occasions',
                                  ),
                                  const SizedBox(width: 8),
                                  _IconButton(
                                    icon: Icons.history,
                                    onPressed: () =>
                                        context.pushNamed('history'),
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

                      // Usage indicator for free users only (Pro badge is in header)
                      if (!isPro) ...[
                        const SizedBox(height: 20),
                        if (!initStatus.revenueCatReady && !initStatus.timedOut)
                          const _UsageIndicatorShimmer()
                        else
                          UsageIndicator(
                            remaining: remaining,
                            isPro: false,
                            onUpgrade: () {
                              Log.info('Upgrade tapped', {'source': 'home'});
                              showPaywall(context, source: 'home', force: true);
                            },
                          ).animate().fadeIn(delay: 200.ms),
                      ],
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

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Search field
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _OccasionSearchField(
                    onChanged: (value) {
                      ref.read(occasionSearchProvider.notifier).state = value;
                      if (value.isNotEmpty) {
                        final count = ref
                            .read(filteredOccasionsProvider)
                            .length;
                        Log.info('Occasion search', {
                          'query': value,
                          'results': count,
                        });
                      }
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // First action hint banner (shows once for new users)
              if (showFirstActionHint)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.touch_app,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Tap any occasion to create your first message!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _dismissFirstActionHint(ref),
                            child: Icon(
                              Icons.close,
                              color: AppColors.primary.withValues(alpha: 0.6),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Occasion grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: OccasionGrid(
                  occasions: ref.watch(filteredOccasionsProvider),
                  showFirstActionHint: showFirstActionHint,
                  onHintDismissed: () => _dismissFirstActionHint(ref),
                  onOccasionSelected: (occasion) {
                    Log.info('Wizard started', {'occasion': occasion.name});
                    Log.event('occasion_tapped', {'occasion': occasion.name});
                    // Dismiss first action hint on occasion tap (not just close)
                    if (showFirstActionHint) {
                      _dismissFirstActionHint(ref);
                    }
                    ref.read(selectedOccasionProvider.notifier).state =
                        occasion;
                    // Clear search when selecting
                    ref.read(occasionSearchProvider.notifier).state = '';
                    context.pushNamed('generate');
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dismiss the first action hint and persist to SharedPreferences
Future<void> _dismissFirstActionHint(WidgetRef ref) async {
  ref.read(showFirstActionHintProvider.notifier).state = false;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(PreferenceKeys.hasSeenFirstActionHint, true);
  Log.info('First action hint dismissed');
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
  Widget build(BuildContext context) => Semantics(
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

/// Compact amber PRO pill badge (matches settings screen style).
class _ProPill extends StatelessWidget {
  const _ProPill({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Pro subscription active',
    button: onTap != null,
    hint: onTap != null ? 'Double tap to manage subscription' : null,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.proGold,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.proGoldDark, width: 2),
        ),
        child: const Text(
          'PRO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPro,
          ),
        ),
      ),
    ),
  );
}

/// Search field for filtering occasions.
class _OccasionSearchField extends StatefulWidget {
  const _OccasionSearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_OccasionSearchField> createState() => _OccasionSearchFieldState();
}

class _OccasionSearchFieldState extends State<_OccasionSearchField> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    onChanged: widget.onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: 'Search occasions...',
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
      suffixIcon: _hasText
          ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[400]),
              onPressed: () {
                _controller.clear();
                widget.onChanged('');
              },
            )
          : null,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}

/// Shimmer placeholder for UsageIndicator while RevenueCat loads.
class _UsageIndicatorShimmer extends StatelessWidget {
  const _UsageIndicatorShimmer();

  @override
  Widget build(BuildContext context) =>
      Container(
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
