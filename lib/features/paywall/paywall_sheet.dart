import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/config/preference_keys.dart';
import '../../core/errors/auth_errors.dart';
import '../../core/providers/providers.dart';
import '../../core/services/log_service.dart';
import '../../core/services/remote_config_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

const _paywallCooldown = Duration(hours: 24);
const _proEntitlementId = 'pro';

/// Shows the paywall as a modal bottom sheet with inline auth.
///
/// [source] identifies where the paywall was triggered from for analytics.
/// Returns `true` if user successfully subscribed, `false` otherwise.
Future<bool> showPaywall(
  BuildContext context, {
  String? source,
  bool force = false,
}) async {
  final remoteConfig = RemoteConfigService.instance;
  if (!remoteConfig.isPaywallEnabled) {
    Log.warning('Paywall blocked by Remote Config kill switch', {
      'source': source,
      'key': 'paywall_enabled',
    });
    return false;
  }
  if (!remoteConfig.isPremiumEnabled) {
    Log.warning('Paywall blocked by Remote Config premium kill switch', {
      'source': source,
      'key': 'premium_enabled',
    });
    return false;
  }

  final container = ProviderScope.containerOf(context);
  final prefs = container.read(sharedPreferencesProvider);

  // Refresh entitlement state before showing paywall to avoid stale unlock UX.
  final subscriptionService = container.read(subscriptionServiceProvider);
  if (subscriptionService.isConfigured) {
    final customerInfo = await subscriptionService.getCustomerInfo();
    final hasPro =
        customerInfo?.entitlements.active.containsKey(_proEntitlementId) ??
        false;
    if (hasPro && !force) {
      Log.info('Paywall skipped: active entitlement after refresh', {
        'source': source,
      });
      return false;
    }
  }

  if (!force) {
    final lastDismissed = prefs.getString(PreferenceKeys.paywallLastDismissed);
    final lastDismissedAt = lastDismissed == null
        ? null
        : DateTime.tryParse(lastDismissed);
    if (lastDismissedAt != null) {
      final elapsed = DateTime.now().difference(lastDismissedAt);
      if (elapsed < _paywallCooldown) {
        Log.info('Paywall suppressed due to cooldown', {
          'source': source,
          'elapsedMinutes': elapsed.inMinutes,
        });
        return false;
      }
    }
  }

  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PaywallSheet(source: source),
      ) ??
      false;
}

/// Bottom sheet paywall with inline auth.
///
/// Pattern: Sign in → Purchase (single surface, no navigation)
class PaywallSheet extends ConsumerStatefulWidget {
  const PaywallSheet({super.key, this.source});

  /// Analytics: where the paywall was triggered from (home, generate, settings, etc.)
  final String? source;

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  Offering? _offering;
  bool _isLoadingOfferings = true;
  bool _isAuthenticating = false;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  bool _purchaseCompleted = false;
  bool _navigatedToEmailAuth = false;
  int _selectedPackageIndex = 0;
  String? _error;
  late final DateTime _openedAt;
  late final SharedPreferences _prefs;

  @override
  void dispose() {
    // Analytics: enriched dismiss tracking (skip if navigating to email auth)
    if (!_purchaseCompleted && !_navigatedToEmailAuth) {
      final viewDurationSec = DateTime.now().difference(_openedAt).inSeconds;
      unawaited(
        _prefs.setString(
          PreferenceKeys.paywallLastDismissed,
          DateTime.now().toIso8601String(),
        ),
      );
      Log.info('Paywall dismissed', {
        'reason': 'no_purchase',
        'source': widget.source,
        'viewDurationSec': viewDurationSec,
        'hadAuthAttempt': _isAuthenticating,
        'selectedPackage': _selectedPackageIndex,
        'hadError': _error != null,
      });
      Log.event('paywall_dismissed', {
        'source': widget.source ?? 'unknown',
        'view_duration_sec': viewDurationSec,
      });
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _prefs = ref.read(sharedPreferencesProvider);
    _loadOfferings();
    // Analytics: track paywall impression with source
    final isLoggedIn = ref.read(authServiceProvider).isLoggedIn;
    Log.info('Paywall shown', {
      'source': widget.source,
      'isLoggedIn': isLoggedIn,
    });
    Log.event('paywall_shown', {
      'source': widget.source ?? 'unknown',
      'is_logged_in': isLoggedIn,
    });
  }

  Future<void> _loadOfferings() async {
    final subscriptionService = ref.read(subscriptionServiceProvider);
    if (!subscriptionService.isConfigured) {
      Log.warning('PaywallSheet: RevenueCat not configured');
      if (mounted) {
        setState(() {
          _isLoadingOfferings = false;
          _error = 'Unable to load subscriptions. Please try again later.';
        });
      }
      return;
    }

    try {
      // Route through ISubscriptionService for testability
      final offerings = await subscriptionService.getOfferings();
      if (offerings == null) {
        Log.warning('PaywallSheet: No offerings returned');
        if (mounted) {
          setState(() {
            _isLoadingOfferings = false;
            _error = 'Unable to load subscriptions. Please try again later.';
          });
        }
        return;
      }

      // Log currency info (visible in diagnostics)
      for (final pkg in offerings.current?.availablePackages ?? []) {
        Log.info('RevenueCat package', {
          'id': pkg.storeProduct.identifier,
          'currency': pkg.storeProduct.currencyCode,
          'price': pkg.storeProduct.priceString,
        });
      }
      if (mounted) {
        setState(() {
          _offering = offerings.current;
          _isLoadingOfferings = false;
          final packages = offerings.current?.availablePackages ?? [];
          final annualIndex = packages.indexWhere(
            (p) => p.packageType == PackageType.annual,
          );
          if (annualIndex >= 0) {
            _selectedPackageIndex = annualIndex;
          }
        });
      }
    } on Exception catch (e) {
      Log.error('PaywallSheet: Failed to load offerings', {'error': '$e'});
      if (mounted) {
        setState(() {
          _isLoadingOfferings = false;
          _error = 'Unable to load subscriptions. Please try again later.';
        });
      }
    }
  }

  // ===========================================================================
  // SYNC AUTH METHODS (Optional - for cross-device sync, no auto-purchase)
  // ===========================================================================

  /// Sign in with Apple for sync purposes only.
  /// Does NOT auto-trigger purchase - user can tap "Continue" button after.
  Future<void> _signInForSync() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    // Capture services before async to avoid ref access after unmount
    final authService = ref.read(authServiceProvider);
    final usageService = ref.read(usageServiceProvider);
    final subscriptionService = ref.read(subscriptionServiceProvider);

    try {
      final response = await authService.signInWithApple().timeout(
        const Duration(minutes: 2),
        onTimeout: () =>
            throw Exception('Sign in timed out. Please try again.'),
      );
      if (response.user != null) {
        try {
          await usageService.syncFromServer();
        } on Exception catch (e) {
          Log.warning('Usage sync failed after auth', {'error': '$e'});
        }
        // Identify with RevenueCat (may restore existing subscription)
        await subscriptionService.identifyUser(response.user!.id);

        // Force fetch fresh CustomerInfo
        ref.invalidate(customerInfoProvider);
        final hasPro = await ref
            .read(checkProStatusProvider.future)
            .timeout(const Duration(seconds: 5), onTimeout: () => false);

        if (hasPro && mounted) {
          Log.info('PaywallSheet: Apple sign-in restored Pro, closing');
          _purchaseCompleted = true;
          Navigator.of(context).pop(true);
          return;
        }

        // No Pro restored - stay on paywall, user can tap Continue
        Log.info('PaywallSheet: Apple sign-in for sync complete');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signed in! Tap Continue to subscribe.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } on Exception catch (e) {
      if (!AuthErrorHandler.isCancellation(e)) {
        _showError(AuthErrorHandler.getMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  /// Sign in with Google for sync purposes only.
  Future<void> _signInWithGoogleForSync() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    // Capture services before async to avoid ref access after unmount
    final authService = ref.read(authServiceProvider);
    final usageService = ref.read(usageServiceProvider);
    final subscriptionService = ref.read(subscriptionServiceProvider);

    try {
      final response = await authService.signInWithGoogle().timeout(
        const Duration(minutes: 2),
        onTimeout: () =>
            throw Exception('Sign in timed out. Please try again.'),
      );
      if (response.user != null) {
        try {
          await usageService.syncFromServer();
        } on Exception catch (e) {
          Log.warning('Usage sync failed after auth', {'error': '$e'});
        }
        await subscriptionService.identifyUser(response.user!.id);

        ref.invalidate(customerInfoProvider);
        final hasPro = await ref
            .read(checkProStatusProvider.future)
            .timeout(const Duration(seconds: 5), onTimeout: () => false);

        if (hasPro && mounted) {
          Log.info('PaywallSheet: Google sign-in restored Pro, closing');
          _purchaseCompleted = true;
          Navigator.of(context).pop(true);
          return;
        }

        Log.info('PaywallSheet: Google sign-in for sync complete');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signed in! Tap Continue to subscribe.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } on Exception catch (e) {
      if (!AuthErrorHandler.isCancellation(e)) {
        _showError(AuthErrorHandler.getMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  /// Sign in with Email for sync purposes only.
  /// Uses autoPurchase=false so email auth will re-show paywall after sign-in.
  void _signInWithEmailForSync() {
    Log.info('Paywall: Email auth for sync selected');
    _navigatedToEmailAuth = true;
    Navigator.of(context).pop(false);
    // showPaywallAfterAuth=true will reopen paywall if user doesn't have Pro
    context.push('/auth/email?showPaywallAfterAuth=true');
  }

  // ===========================================================================
  // PURCHASE METHODS
  // ===========================================================================

  Future<void> _purchasePackage(Package package) async {
    if (_isPurchasing) return;

    setState(() => _isPurchasing = true);
    Log.info('Purchase started', {'package': package.identifier});

    // Capture service references before async operations
    final authService = ref.read(authServiceProvider);
    final subscriptionService = ref.read(subscriptionServiceProvider);

    try {
      // Identify user with RevenueCat before purchase (links purchase to account)
      if (authService.isLoggedIn && authService.currentUser?.id != null) {
        await subscriptionService.identifyUser(authService.currentUser!.id);
      }

      // Route through ISubscriptionService for testability
      // Service returns true if 'pro' entitlement is now active
      final hasPro = await subscriptionService.purchasePackage(package);

      Log.info('Purchase result', {'hasPro': hasPro});

      if (hasPro && mounted) {
        ref.invalidate(customerInfoProvider);
        Log.info('Purchase completed', {'package': package.identifier});
        HapticFeedback.heavyImpact();
        _purchaseCompleted = true;

        // Close sheet with success
        Navigator.of(context).pop(true);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  Gap(AppSpacing.sm),
                  Text('Welcome to Pro!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (!hasPro && mounted) {
        // Purchase returned false - could be cancellation or failure
        // Service already logs the specific reason, just show generic message
        // Note: User cancellation is handled silently by the service
        _showError('Purchase did not complete. Please try again.');
      }
    } on PlatformException catch (e) {
      // PlatformException may still bubble up from service in some edge cases
      Log.warning('Purchase platform exception', {
        'code': e.code,
        'message': e.message,
      });
      if (e.code == 'PURCHASE_CANCELLED') {
        Log.info('Purchase cancelled', {'package': package.identifier});
      } else {
        _showError('Purchase failed: ${e.message}');
      }
    } on Exception catch (e) {
      Log.error('Purchase error', {'error': '$e'});
      _showError('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (_isRestoring) return;

    // Note: No login required - Apple ties restore to Apple ID, not app account
    // RevenueCat handles this correctly for anonymous users

    setState(() => _isRestoring = true);
    Log.info('Restore purchases started');

    // Capture service reference before async operations
    final subscriptionService = ref.read(subscriptionServiceProvider);

    try {
      // Route through ISubscriptionService for testability
      // Service returns true if 'pro' entitlement is now active
      final hasPro = await subscriptionService.restorePurchases();

      Log.info('Restore completed', {'hasPro': hasPro});

      if (hasPro && mounted) {
        ref.invalidate(customerInfoProvider);
        HapticFeedback.mediumImpact();
        _purchaseCompleted = true;

        Navigator.of(context).pop(true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  Gap(AppSpacing.sm),
                  Text('Pro subscription restored!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (mounted) {
        _showError('No active subscription found');
      }
    } on Exception catch (e) {
      Log.error('Restore error', {'error': '$e', 'type': e.runtimeType});
      _showError('Could not restore purchases. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  void _showError(String message) {
    setState(() => _error = message);
  }

  void _dismissError() {
    setState(() => _error = null);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authServiceProvider).isLoggedIn;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: isTablet
              ? screenSize.height * 0.75
              : screenSize.height * 0.92,
          maxWidth: isTablet ? 500 : double.infinity,
        ),
        margin: isTablet ? const EdgeInsets.only(bottom: 40) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(24),
            bottom: isTablet ? const Radius.circular(24) : Radius.zero,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Content
            Flexible(
              child: _isLoadingOfferings
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _buildContent(isLoggedIn, isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isLoggedIn, bool isTablet) {
    final packages = _offering?.availablePackages ?? [];
    final spacing = isTablet ? AppSpacing.sm : AppSpacing.md;
    if (packages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: _error != null ? AppColors.error : Colors.grey,
            ),
            const Gap(16),
            Text(
              _error ?? 'Unable to load subscription options',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoadingOfferings = true;
                      _error = null;
                    });
                    _loadOfferings();
                  },
                  child: const Text('Retry'),
                ),
                const Gap(16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? AppSpacing.lg : AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          Gap(spacing),

          // Benefits
          _buildBenefits(),
          Gap(spacing),

          // Package selection
          _buildPackageSelector(packages),
          Gap(spacing),

          // Error message
          if (_error != null) ...[
            _buildErrorBanner(),
            const Gap(AppSpacing.sm),
          ],

          // Purchase section - available to ALL users (Apple 5.1.1 compliance)
          _buildPurchaseSection(packages),
          Gap(spacing),

          // Optional: Sign in to sync across devices (only show if not logged in)
          if (!isLoggedIn) ...[_buildSyncSection(), Gap(spacing)],

          // Footer links (Terms & Privacy - Apple 3.1.2 compliance)
          _buildFooter(),
          Gap(spacing),
        ],
      ),
    );
  }

  Widget _buildHeader() => Column(
    children: [
      // Pro badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.proGold, AppColors.proGoldDark],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: AppColors.textOnPro, size: 20),
            Gap(6),
            Text(
              'Prosepal Pro',
              style: TextStyle(
                color: AppColors.textOnPro,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      const Gap(16),
      const Text(
        'You nailed that message',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const Gap(4),
      Text(
        _contextSubtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        textAlign: TextAlign.center,
      ),
    ],
  );

  /// Context-aware subtitle based on where paywall was triggered
  String get _contextSubtitle => switch (widget.source) {
    'generate' => "You've used your free message—keep the inspiration flowing",
    'home_limit' => 'Unlock unlimited messages for every occasion',
    'first_message' =>
      'Unlock unlimited messages for birthdays, thank yous, and more',
    'settings' => 'Get unlimited access to every occasion',
    'onboarding' => 'Get unlimited access to every occasion',
    _ => 'Unlock unlimited messages for every occasion',
  };

  Widget _buildBenefits() {
    const benefits = [
      ('Unlimited messages', Icons.all_inclusive),
      ('Every occasion', Icons.celebration_outlined),
      ('Instant inspiration', Icons.bolt_outlined),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: benefits
          .map(
            (b) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(b.$2, color: AppColors.primary, size: 24),
                const Gap(4),
                Text(
                  b.$1,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildPackageSelector(List<Package> packages) => Column(
    children: List.generate(packages.length, (index) {
      final pkg = packages[index];
      final isSelected = index == _selectedPackageIndex;
      final isAnnual = pkg.packageType == PackageType.annual;

      return GestureDetector(
        onTap: () {
          if (_selectedPackageIndex != index) {
            Log.info('Package selected', {'package': pkg.identifier});
          }
          setState(() => _selectedPackageIndex = index);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.white,
          ),
          child: Row(
            children: [
              // Radio indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const Gap(12),
              // Package info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _packageTitle(pkg.packageType),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.black,
                          ),
                        ),
                        if (isAnnual) ...[
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _savingsText(packages),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(4),
                    Text(
                      _packageSubtitle(pkg),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Price
              Text(
                pkg.storeProduct.priceString,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isSelected ? AppColors.primary : Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }),
  );

  String _packageTitle(PackageType type) {
    switch (type) {
      case PackageType.annual:
        return 'Annual';
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.weekly:
        return 'Weekly';
      default:
        return 'Subscribe';
    }
  }

  String _packageSubtitle(Package pkg) {
    final type = pkg.packageType;
    final price = pkg.storeProduct.price;
    final currencySymbol = pkg.storeProduct.priceString.replaceAll(
      RegExp(r'[\d.,\s]'),
      '',
    );

    // Show per-week cost for all plans to enable easy comparison
    switch (type) {
      case PackageType.annual:
        final weekly = price / 52;
        return 'Just $currencySymbol${weekly.toStringAsFixed(2)}/week';
      case PackageType.monthly:
        final weekly = price / 4.33; // avg weeks per month
        return '$currencySymbol${weekly.toStringAsFixed(2)}/week';
      case PackageType.weekly:
        return '$currencySymbol${price.toStringAsFixed(2)}/week';
      default:
        return '';
    }
  }

  String _savingsText(List<Package> packages) {
    final monthly = packages.firstWhere(
      (p) => p.packageType == PackageType.monthly,
      orElse: () => packages.first,
    );
    final annual = packages.firstWhere(
      (p) => p.packageType == PackageType.annual,
      orElse: () => packages.first,
    );

    if (monthly.packageType != PackageType.monthly ||
        annual.packageType != PackageType.annual) {
      return 'BEST VALUE';
    }

    final monthlyYearCost = monthly.storeProduct.price * 12;
    final annualCost = annual.storeProduct.price;
    final savings = ((monthlyYearCost - annualCost) / monthlyYearCost * 100)
        .round();

    return savings > 0 ? 'SAVE $savings%' : 'BEST VALUE';
  }

  Widget _buildErrorBanner() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
        const Gap(8),
        Expanded(
          child: Text(
            _error!,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ),
        GestureDetector(
          onTap: _dismissError,
          child: const Icon(Icons.close, color: AppColors.error, size: 18),
        ),
      ],
    ),
  );

  /// Optional sign-in section for syncing purchases across devices.
  /// This is NOT required to purchase - just for cross-device sync.
  Widget _buildSyncSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Divider with text
      Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Sync across devices',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
      const Gap(12),

      // Explanation text
      Text(
        'Sign in to access your subscription on all your devices',
        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        textAlign: TextAlign.center,
      ),
      const Gap(16),

      // Apple Sign In (iOS only)
      if (Platform.isIOS || Platform.isMacOS) ...[
        SizedBox(
          height: 44,
          child: SignInWithAppleButton(
            onPressed: _isAuthenticating ? () {} : _signInForSync,
          ),
        ),
        const Gap(10),
      ],

      // Google Sign In
      _AuthButton(
        onPressed: _isAuthenticating ? null : _signInWithGoogleForSync,
        isLoading: _isAuthenticating,
        icon: Image.asset(
          'assets/images/icons/google_g.png',
          width: 20,
          height: 20,
        ),
        label: 'Sign in with Google',
        compact: true,
      ),
      const Gap(10),

      // Email Sign In
      _AuthButton(
        onPressed: _isAuthenticating ? null : _signInWithEmailForSync,
        isLoading: false,
        icon: const Icon(Icons.email_outlined, size: 20),
        label: 'Sign in with Email',
        compact: true,
      ),
    ],
  );

  Widget _buildPurchaseSection(List<Package> packages) {
    final selectedPackage = packages[_selectedPackageIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subscribe button
        ElevatedButton(
          onPressed: _isPurchasing
              ? null
              : () => _purchasePackage(selectedPackage),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.proGold,
            foregroundColor: AppColors.textOnPro,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: AppColors.proGold.withValues(alpha: 0.6),
          ),
          child: _isPurchasing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPro,
                  ),
                )
              : const Text(
                  'Continue Creating',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
        const Gap(8),

        // Legal compliance: cancel/renewal disclosure (Apple requirement)
        Text(
          'Auto-renews. Cancel anytime in App Store settings.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
        const Gap(12),

        // Restore button
        Center(
          child: TextButton(
            onPressed: _isRestoring ? null : _restorePurchases,
            child: _isRestoring
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Restore Purchases',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
          ),
        ),
        const Gap(4),
        // Maybe Later - explicit dismiss for better analytics
        Center(
          child: TextButton(
            onPressed: () {
              Log.info('Paywall dismissed via Maybe Later', {
                'source': widget.source,
              });
              Navigator.of(context).pop(false);
            },
            child: Text(
              'Maybe Later',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      TextButton(
        onPressed: () => context.push('/terms'),
        child: Text(
          'Terms',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ),
      Text('•', style: TextStyle(color: Colors.grey[400])),
      TextButton(
        onPressed: () => context.push('/privacy'),
        child: Text(
          'Privacy',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ),
    ],
  );
}

// =============================================================================
// AUTH BUTTON COMPONENT
// =============================================================================

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.onPressed,
    required this.isLoading,
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: compact ? 44 : 50,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          Gap(compact ? 8 : 12),
          Text(
            label,
            style: TextStyle(
              fontSize: compact
                  ? 16
                  : 16, // Increased compact from 14 to match Apple button
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
