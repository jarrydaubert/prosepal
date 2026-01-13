import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/providers/providers.dart';
import '../../core/errors/auth_errors.dart';
import '../../core/services/log_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

/// Shows the paywall as a modal bottom sheet with inline auth.
///
/// [source] identifies where the paywall was triggered from for analytics.
/// Returns `true` if user successfully subscribed, `false` otherwise.
Future<bool> showPaywall(BuildContext context, {String? source}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
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

  @override
  void dispose() {
    // Analytics: enriched dismiss tracking (skip if navigating to email auth)
    if (!_purchaseCompleted && !_navigatedToEmailAuth) {
      Log.info('Paywall dismissed', {
        'reason': 'no_purchase',
        'source': widget.source,
        'viewDurationSec': DateTime.now().difference(_openedAt).inSeconds,
        'hadAuthAttempt': _isAuthenticating,
        'selectedPackage': _selectedPackageIndex,
        'hadError': _error != null,
      });
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _loadOfferings();
    // Analytics: track paywall impression with source
    final isLoggedIn = ref.read(authServiceProvider).isLoggedIn;
    Log.info('Paywall shown', {
      'source': widget.source,
      'isLoggedIn': isLoggedIn,
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
      final offerings = await Purchases.getOfferings();
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
  // AUTH METHODS
  // ===========================================================================

  Future<void> _signInWithApple() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.signInWithApple().timeout(
        const Duration(minutes: 2),
        onTimeout: () =>
            throw Exception('Sign in timed out. Please try again.'),
      );
      if (response.user != null) {
        try {
          await ref.read(usageServiceProvider).syncFromServer();
        } catch (e) {
          Log.warning('Usage sync failed after auth', {'error': '$e'});
        }
        // Identify with RevenueCat (may restore existing subscription)
        await ref
            .read(subscriptionServiceProvider)
            .identifyUser(response.user!.id);

        // Force fetch fresh CustomerInfo to avoid race condition with listener
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

        // No Pro restored - close paywall and trigger purchase
        // This shows the payment dialog over home screen (not paywall)
        final packages = _offering?.availablePackages ?? [];
        if (packages.isNotEmpty && mounted) {
          final selectedPackage = packages[_selectedPackageIndex];
          Log.info('PaywallSheet: Apple sign-in success, closing for purchase');
          Navigator.of(context).pop(); // Close paywall first

          // Trigger purchase (system dialog appears over home screen)
          try {
            Log.info('Purchase started', {
              'package': selectedPackage.identifier,
            });
            final result = await Purchases.purchase(
              PurchaseParams.package(selectedPackage),
            );
            final purchasedPro = result.customerInfo.entitlements.active
                .containsKey('pro');
            Log.info('Purchase completed', {
              'package': selectedPackage.identifier,
              'hasPro': purchasedPro,
            });
            ref.invalidate(customerInfoProvider);
          } on PlatformException catch (e) {
            if (e.code != 'PURCHASE_CANCELLED' &&
                e.message?.contains('cancelled') != true &&
                e.message?.contains('canceled') != true) {
              Log.warning('Purchase failed', {'error': '$e'});
            }
          }
          return;
        }
      }
    } catch (e) {
      if (!AuthErrorHandler.isCancellation(e)) {
        _showError(AuthErrorHandler.getMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.signInWithGoogle().timeout(
        const Duration(minutes: 2),
        onTimeout: () =>
            throw Exception('Sign in timed out. Please try again.'),
      );
      if (response.user != null) {
        try {
          await ref.read(usageServiceProvider).syncFromServer();
        } catch (e) {
          Log.warning('Usage sync failed after auth', {'error': '$e'});
        }
        // Identify with RevenueCat (may restore existing subscription)
        await ref
            .read(subscriptionServiceProvider)
            .identifyUser(response.user!.id);

        // Force fetch fresh CustomerInfo to avoid race condition with listener
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

        // No Pro restored - close paywall and trigger purchase
        // This shows the payment dialog over home screen (not paywall)
        final packages = _offering?.availablePackages ?? [];
        if (packages.isNotEmpty && mounted) {
          final selectedPackage = packages[_selectedPackageIndex];
          Log.info(
            'PaywallSheet: Google sign-in success, closing for purchase',
          );
          Navigator.of(context).pop(); // Close paywall first

          // Trigger purchase (system dialog appears over home screen)
          try {
            Log.info('Purchase started', {
              'package': selectedPackage.identifier,
            });
            final result = await Purchases.purchase(
              PurchaseParams.package(selectedPackage),
            );
            final purchasedPro = result.customerInfo.entitlements.active
                .containsKey('pro');
            Log.info('Purchase completed', {
              'package': selectedPackage.identifier,
              'hasPro': purchasedPro,
            });
            ref.invalidate(customerInfoProvider);
          } on PlatformException catch (e) {
            if (e.code != 'PURCHASE_CANCELLED' &&
                e.message?.contains('cancelled') != true &&
                e.message?.contains('canceled') != true) {
              Log.warning('Purchase failed', {'error': '$e'});
            }
          }
          return;
        }
      }
    } catch (e) {
      if (!AuthErrorHandler.isCancellation(e)) {
        _showError(AuthErrorHandler.getMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _signInWithEmail() {
    final packages = _offering?.availablePackages ?? [];
    if (packages.isEmpty) return;

    final selectedPackage = packages[_selectedPackageIndex];
    Log.info('Paywall: Email auth selected', {
      'package': selectedPackage.identifier,
    });

    // Pass selected package for auto-purchase after auth
    _navigatedToEmailAuth = true;
    Navigator.of(context).pop(false);
    context.push(
      '/auth/email?autoPurchase=true&package=${Uri.encodeComponent(selectedPackage.identifier)}',
    );
  }

  // ===========================================================================
  // PURCHASE METHODS
  // ===========================================================================

  Future<void> _purchasePackage(Package package) async {
    if (_isPurchasing) return;

    setState(() => _isPurchasing = true);
    Log.info('Purchase started', {'package': package.identifier});

    try {
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
        _showError('Purchase did not complete. Please try again.');
      }
    } on PlatformException catch (e) {
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

    final authService = ref.read(authServiceProvider);
    if (!authService.isLoggedIn) {
      _showError('Please sign in first to restore purchases');
      return;
    }

    setState(() => _isRestoring = true);
    Log.info('Restore purchases started');

    try {
      final customerInfo = await Purchases.restorePurchases();
      final hasPro = customerInfo.entitlements.active.containsKey('pro');

      if (hasPro && mounted) {
        ref.invalidate(customerInfoProvider);
        Log.info('Restore completed', {'hasPro': true});
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
        _showError('No active subscription found for this account');
      }
    } on Exception catch (e) {
      Log.error('Restore error', {'error': '$e'});
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                : _buildContent(isLoggedIn),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isLoggedIn) {
    final packages = _offering?.availablePackages ?? [];
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          const Gap(AppSpacing.md),

          // Benefits
          _buildBenefits(),
          const Gap(AppSpacing.md),

          // Package selection
          _buildPackageSelector(packages),
          const Gap(AppSpacing.md),

          // Error message
          if (_error != null) ...[
            _buildErrorBanner(),
            const Gap(AppSpacing.sm),
          ],

          // Auth or Purchase section
          if (!isLoggedIn)
            _buildAuthSection()
          else
            _buildPurchaseSection(packages),

          const Gap(AppSpacing.md),

          // Footer links
          _buildFooter(),
          const Gap(AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Pro badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFFFF8A80)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.white, size: 20),
              Gap(6),
              Text(
                'Prosepal Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const Gap(16),
        const Text(
          'Never lost for words',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Gap(4),
        Text(
          'Heartfelt messages, whenever you need them',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildBenefits() {
    const benefits = [
      ('500/month', Icons.message_outlined),
      ('All occasions', Icons.celebration_outlined),
      ('Priority AI', Icons.bolt_outlined),
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

  Widget _buildPackageSelector(List<Package> packages) {
    return Column(
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
  }

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

  Widget _buildErrorBanner() {
    return Container(
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
  }

  Widget _buildAuthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Divider with text
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sign in to continue',
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
        const Gap(20),

        // Apple Sign In (iOS only)
        if (Platform.isIOS || Platform.isMacOS) ...[
          SizedBox(
            height: 50,
            child: SignInWithAppleButton(
              onPressed: _isAuthenticating ? () {} : _signInWithApple,
              style: SignInWithAppleButtonStyle.black,
            ),
          ),
          const Gap(12),
        ],

        // Google Sign In
        _AuthButton(
          onPressed: _isAuthenticating ? null : _signInWithGoogle,
          isLoading: _isAuthenticating,
          icon: Image.asset(
            'assets/images/icons/google_g.png',
            width: 24,
            height: 24,
          ),
          label: 'Continue with Google',
        ),
        const Gap(12),

        // Email Sign In
        _AuthButton(
          onPressed: _isAuthenticating ? null : _signInWithEmail,
          isLoading: false,
          icon: const Icon(Icons.email_outlined, size: 24),
          label: 'Continue with Email',
        ),
      ],
    );
  }

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
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
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
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
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
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
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
            const Gap(12),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
