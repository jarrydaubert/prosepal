import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/providers/providers.dart';
import '../../core/services/log_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

/// Custom paywall screen with branded UI and RevenueCat purchase handling.
///
/// Uses [Purchases.purchase] with [PurchaseParams] for full UI control while
/// RevenueCat handles the purchase flow, receipt validation, and entitlements.
///
/// Per RevenueCat docs (2025), this approach is recommended when you need
/// custom UI beyond what PaywallView provides.
class CustomPaywallScreen extends ConsumerStatefulWidget {
  const CustomPaywallScreen({super.key});

  @override
  ConsumerState<CustomPaywallScreen> createState() =>
      _CustomPaywallScreenState();
}

class _CustomPaywallScreenState extends ConsumerState<CustomPaywallScreen> {
  Offering? _offering;
  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  int _selectedPackageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    // Check if RevenueCat is configured before calling SDK
    final subscriptionService = ref.read(subscriptionServiceProvider);
    if (!subscriptionService.isConfigured) {
      Log.warning('Paywall: RevenueCat not configured, dismissing');
      if (mounted) {
        setState(() => _isLoading = false);
        // Navigate away gracefully
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          }
        });
      }
      return;
    }

    try {
      final offerings = await Purchases.getOfferings();
      // Debug: Log currency info (only in debug builds)
      if (kDebugMode) {
        for (final pkg in offerings.current?.availablePackages ?? []) {
          debugPrint(
            'RevenueCat: ${pkg.storeProduct.identifier} - '
            '${pkg.storeProduct.currencyCode} - ${pkg.storeProduct.priceString}',
          );
        }
      }
      if (mounted) {
        setState(() {
          _offering = offerings.current;
          _isLoading = false;
          // Default to annual if available (best value)
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
      Log.error('Paywall: Failed to load offerings', {'error': '$e'});
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _purchasePackage(Package package) async {
    if (_isPurchasing) return;

    setState(() => _isPurchasing = true);
    Log.info('Purchase started', {'package': package.identifier});

    try {
      // Identify with RevenueCat before purchase (only creates customer on purchase)
      final authService = ref.read(authServiceProvider);
      if (authService.isLoggedIn && authService.currentUser?.id != null) {
        await ref
            .read(subscriptionServiceProvider)
            .identifyUser(authService.currentUser!.id);
      }

      final result = await Purchases.purchase(PurchaseParams.package(package));
      final hasPro = result.customerInfo.entitlements.active.containsKey('pro');
      Log.info('Purchase result', {
        'hasPro': hasPro,
        'customerId': result.customerInfo.originalAppUserId,
      });

      if (hasPro && mounted) {
        ref.invalidate(customerInfoProvider);
        Log.info('Purchase completed successfully');

        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;

        // Step 1: Check if user is signed in - prompt to create account if not
        final isLoggedIn = ref.read(authServiceProvider).isLoggedIn;
        Log.info('Purchase: Checking auth state', {'isLoggedIn': isLoggedIn});

        if (!isLoggedIn) {
          Log.info('Purchase: Redirecting to auth for account creation');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Create an account to secure your Pro subscription',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Use push so user can dismiss with X and return to paywall
            context.push('/auth?redirect=home');
          }
          return;
        }

        // Biometrics can be enabled from settings - keep purchase flow simple
        // Step 3: Go home after purchase
        Log.info('Purchase: Navigating to home');
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
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
      } else if (!hasPro && mounted) {
        Log.warning('Purchase: Completed but no pro entitlement');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Purchase completed but subscription not active. Please contact support.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        Log.info('Purchase: Cancelled by user');
      } else {
        Log.error('Purchase failed', e, StackTrace.current);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchase failed: ${e.message}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      Log.error('Purchase failed unexpectedly', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (_isRestoring) return;

    // Check if already Pro - no need to restore, just navigate away
    final currentPro = await ref.read(subscriptionServiceProvider).isPro();
    if (currentPro) {
      Log.info('Restore: Already has Pro subscription, navigating to home');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              Gap(AppSpacing.sm),
              Text('You already have an active subscription!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate away from paywall since user is Pro
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
      return;
    }

    setState(() => _isRestoring = true);
    Log.info('Restore purchases started');

    try {
      // Identify with RevenueCat before restore to link purchases to user
      final authService = ref.read(authServiceProvider);
      if (authService.isLoggedIn && authService.currentUser?.id != null) {
        await ref
            .read(subscriptionServiceProvider)
            .identifyUser(authService.currentUser!.id);
      }

      final customerInfo = await Purchases.restorePurchases();
      final hasPro = customerInfo.entitlements.active.containsKey('pro');
      Log.info('Restore purchases completed', {'hasPro': hasPro});

      if (!mounted) return;

      if (hasPro) {
        ref.invalidate(customerInfoProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                Gap(AppSpacing.sm),
                Text('Subscription restored!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigate back after restore success
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous purchases found'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on PlatformException catch (e) {
      Log.warning('Restore purchases failed', {'error': '$e'});
      if (mounted) {
        final isNetworkError =
            e.code == 'NETWORK_ERROR' ||
            e.message?.toLowerCase().contains('network') == true ||
            e.message?.toLowerCase().contains('internet') == true ||
            e.message?.toLowerCase().contains('offline') == true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNetworkError
                  ? 'Check your internet connection and try again'
                  : 'Unable to restore purchases. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on Exception catch (e) {
      Log.warning('Restore purchases failed', {'error': '$e'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to restore purchases. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final packages = _offering?.availablePackages ?? [];

    if (packages.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const Gap(16),
                const Text('Unable to load subscription options'),
                const Gap(16),
                TextButton(
                  onPressed: () {
                    Log.info('Paywall dismissed', {'reason': 'load_error'});
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      Log.info('Paywall dismissed', {'reason': 'user_closed'});
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content - prices first, features below
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    _buildHero(context),
                    const Gap(AppSpacing.md),
                    // Prices immediately visible
                    _buildPackageSelector(packages),
                    const Gap(AppSpacing.lg),
                    _buildFeatures(),
                    const Gap(AppSpacing.md),
                    _buildSocialProof(context),
                    const Gap(AppSpacing.md),
                  ],
                ),
              ),
            ),

            // Fixed bottom section
            _buildBottomSection(packages),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 28)),
            const Gap(AppSpacing.sm),
            Text(
              'Go Pro',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),
        const Gap(AppSpacing.xs),
        Text(
          'Unlimited messages for every occasion',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 100.ms),
      ],
    );
  }

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What you get:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const Gap(AppSpacing.sm),
        _buildFeatureRow(
          Icons.auto_awesome,
          '500 messages/month',
          '3 options each = 1,500 ideas',
        ).animate().fadeIn(delay: 200.ms),
        _buildFeatureRow(
          Icons.celebration_outlined,
          '40 occasions',
          'Birthday, wedding, sympathy & more',
        ).animate().fadeIn(delay: 250.ms),
        _buildFeatureRow(
          Icons.history,
          'Message history',
          'Save and revisit your favorites',
        ).animate().fadeIn(delay: 300.ms),
        _buildFeatureRow(
          Icons.fingerprint,
          'Biometric lock',
          'Keep messages private',
        ).animate().fadeIn(delay: 350.ms),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialProof(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Text(
              'Perfect for birthdays, thank yous, and heartfelt moments',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildPackageSelector(List<Package> packages) {
    return Column(
      children: List.generate(packages.length, (index) {
        final package = packages[index];
        final isSelected = _selectedPackageIndex == index;
        final isAnnual = package.packageType == PackageType.annual;
        final weeklyEquivalent = _getWeeklyEquivalent(package);

        return GestureDetector(
          onTap: () => setState(() => _selectedPackageIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Radio indicator
                Container(
                  width: 22,
                  height: 22,
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
                const Gap(AppSpacing.md),
                // Package details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getPackageTitle(package),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (isAnnual) ...[
                            const Gap(AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BEST VALUE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Gap(2),
                      Text(
                        _getPackageSubtitle(package),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Price column - shows both total and per-week
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      package.storeProduct.priceString,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      weeklyEquivalent,
                      style: TextStyle(
                        fontSize: 11,
                        color: isAnnual ? AppColors.success : Colors.grey[500],
                        fontWeight: isAnnual
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Calculate weekly equivalent price for comparison.
  /// Returns empty string on error or if price is invalid/zero.
  String _getWeeklyEquivalent(Package package) {
    try {
      final price = package.storeProduct.price;
      // Guard against zero/negative prices (e.g., free trials)
      if (price <= 0) return '';

      final currencySymbol = package.storeProduct.currencyCode == 'USD'
          ? '\$'
          : package.storeProduct.priceString
                .replaceAll(RegExp(r'[0-9.,]'), '')
                .trim();

      switch (package.packageType) {
        case PackageType.weekly:
          return 'per week';
        case PackageType.monthly:
          final weekly = price / 4.33;
          return '$currencySymbol${weekly.toStringAsFixed(2)}/wk';
        case PackageType.annual:
          final weekly = price / 52;
          return '$currencySymbol${weekly.toStringAsFixed(2)}/wk';
        default:
          return '';
      }
    } catch (_) {
      return '';
    }
  }

  Widget _buildBottomSection(List<Package> packages) {
    final selectedPackage = packages[_selectedPackageIndex];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Subscribe button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPurchasing
                    ? null
                    : () => _purchasePackage(selectedPackage),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.6,
                  ),
                ),
                child: _isPurchasing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const Gap(AppSpacing.sm),
            // Restore + Terms + Privacy
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _isRestoring ? null : _restorePurchases,
                  child: _isRestoring
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Restore',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                ),
                Text('•', style: TextStyle(color: Colors.grey[400])),
                TextButton(
                  onPressed: () => context.push('/terms'),
                  child: Text(
                    'Terms',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
                Text('•', style: TextStyle(color: Colors.grey[400])),
                TextButton(
                  onPressed: () => context.push('/privacy'),
                  child: Text(
                    'Privacy',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            // Legal text
            Text(
              'Cancel anytime. Subscription auto-renews.',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getPackageTitle(Package package) {
    switch (package.packageType) {
      case PackageType.weekly:
        return 'Weekly';
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.annual:
        return 'Yearly';
      case PackageType.lifetime:
        return 'Lifetime';
      default:
        return package.storeProduct.title;
    }
  }

  String _getPackageSubtitle(Package package) {
    switch (package.packageType) {
      case PackageType.weekly:
        return 'Billed weekly';
      case PackageType.monthly:
        return 'Billed monthly';
      case PackageType.annual:
        return 'Billed yearly — save 50%';
      case PackageType.lifetime:
        return 'One-time purchase';
      default:
        return '';
    }
  }
}
