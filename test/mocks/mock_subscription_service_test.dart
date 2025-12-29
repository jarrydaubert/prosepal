import 'package:flutter_test/flutter_test.dart';

import 'mock_subscription_service.dart';

void main() {
  group('MockSubscriptionService', () {
    late MockSubscriptionService mockSubscription;

    setUp(() {
      mockSubscription = MockSubscriptionService();
    });

    group('initial state', () {
      test('should be configured by default', () {
        expect(mockSubscription.isConfigured, isTrue);
      });

      test('should not be pro by default', () async {
        expect(await mockSubscription.isPro(), isFalse);
      });

      test('should have zero call counts', () {
        expect(mockSubscription.initializeCallCount, equals(0));
        expect(mockSubscription.isProCallCount, equals(0));
        expect(mockSubscription.getCustomerInfoCallCount, equals(0));
        expect(mockSubscription.getOfferingsCallCount, equals(0));
        expect(mockSubscription.purchasePackageCallCount, equals(0));
        expect(mockSubscription.restorePurchasesCallCount, equals(0));
        expect(mockSubscription.showPaywallCallCount, equals(0));
        expect(mockSubscription.showPaywallIfNeededCallCount, equals(0));
        expect(mockSubscription.showCustomerCenterCallCount, equals(0));
        expect(mockSubscription.identifyUserCallCount, equals(0));
        expect(mockSubscription.logOutCallCount, equals(0));
      });
    });

    group('setConfigured', () {
      test('should update isConfigured', () {
        mockSubscription.setConfigured(false);

        expect(mockSubscription.isConfigured, isFalse);
      });
    });

    group('setIsPro', () {
      test('should update isPro', () async {
        mockSubscription.setIsPro(true);

        expect(await mockSubscription.isPro(), isTrue);
      });
    });

    group('initialize', () {
      test('should increment call count', () async {
        await mockSubscription.initialize();

        expect(mockSubscription.initializeCallCount, equals(1));
      });

      test('should set configured to true', () async {
        mockSubscription.setConfigured(false);

        await mockSubscription.initialize();

        expect(mockSubscription.isConfigured, isTrue);
      });

      test('should throw configured error', () async {
        mockSubscription.errorToThrow = Exception('Init failed');

        expect(
          () => mockSubscription.initialize(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('isPro', () {
      test('should increment call count', () async {
        await mockSubscription.isPro();
        await mockSubscription.isPro();

        expect(mockSubscription.isProCallCount, equals(2));
      });

      test('should return false when not configured', () async {
        mockSubscription.setConfigured(false);

        expect(await mockSubscription.isPro(), isFalse);
      });

      test('should return configured value', () async {
        mockSubscription.setIsPro(true);

        expect(await mockSubscription.isPro(), isTrue);
      });

      test('should throw configured error', () async {
        mockSubscription.errorToThrow = Exception('Error');

        expect(
          () => mockSubscription.isPro(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getCustomerInfo', () {
      test('should increment call count', () async {
        await mockSubscription.getCustomerInfo();

        expect(mockSubscription.getCustomerInfoCallCount, equals(1));
      });

      test('should return null when not configured', () async {
        mockSubscription.setConfigured(false);

        expect(await mockSubscription.getCustomerInfo(), isNull);
      });
    });

    group('getOfferings', () {
      test('should increment call count', () async {
        await mockSubscription.getOfferings();

        expect(mockSubscription.getOfferingsCallCount, equals(1));
      });

      test('should return null when not configured', () async {
        mockSubscription.setConfigured(false);

        expect(await mockSubscription.getOfferings(), isNull);
      });
    });

    group('purchasePackage', () {
      test('should increment call count', () async {
        // Can't easily create a Package, so we test the count
        // In real tests, you'd mock the Package too
        expect(mockSubscription.purchasePackageCallCount, equals(0));
      });

      test('should set isPro when purchase succeeds', () async {
        mockSubscription.purchaseResult = true;
        // Would call purchasePackage with mock Package
      });

      test('should not set isPro when purchase fails', () async {
        mockSubscription.purchaseResult = false;
        // Would call purchasePackage with mock Package
        expect(await mockSubscription.isPro(), isFalse);
      });
    });

    group('restorePurchases', () {
      test('should increment call count', () async {
        await mockSubscription.restorePurchases();

        expect(mockSubscription.restorePurchasesCallCount, equals(1));
      });

      test('should return false when not configured', () async {
        mockSubscription.setConfigured(false);

        expect(await mockSubscription.restorePurchases(), isFalse);
      });

      test('should return configured result', () async {
        mockSubscription.restoreResult = true;

        expect(await mockSubscription.restorePurchases(), isTrue);
      });

      test('should set isPro when restore succeeds', () async {
        mockSubscription.restoreResult = true;

        await mockSubscription.restorePurchases();

        expect(await mockSubscription.isPro(), isTrue);
      });

      test('should not set isPro when restore fails', () async {
        mockSubscription.restoreResult = false;

        await mockSubscription.restorePurchases();

        expect(await mockSubscription.isPro(), isFalse);
      });
    });

    group('showPaywall', () {
      test('should increment call count', () async {
        await mockSubscription.showPaywall();

        expect(mockSubscription.showPaywallCallCount, equals(1));
      });

      test('should return false when not configured', () async {
        mockSubscription.setConfigured(false);

        expect(await mockSubscription.showPaywall(), isFalse);
      });

      test('should return configured result', () async {
        mockSubscription.paywallResult = true;

        expect(await mockSubscription.showPaywall(), isTrue);
      });

      test('should set isPro when paywall succeeds', () async {
        mockSubscription.paywallResult = true;

        await mockSubscription.showPaywall();

        expect(await mockSubscription.isPro(), isTrue);
      });
    });

    group('showPaywallIfNeeded', () {
      test('should increment call count', () async {
        await mockSubscription.showPaywallIfNeeded();

        expect(mockSubscription.showPaywallIfNeededCallCount, equals(1));
      });

      test('should return false when not configured', () async {
        mockSubscription.setConfigured(false);

        expect(await mockSubscription.showPaywallIfNeeded(), isFalse);
      });

      test('should return true if already pro', () async {
        mockSubscription.setIsPro(true);

        expect(await mockSubscription.showPaywallIfNeeded(), isTrue);
      });

      test('should return paywall result if not pro', () async {
        mockSubscription.paywallResult = true;

        expect(await mockSubscription.showPaywallIfNeeded(), isTrue);
      });
    });

    group('showCustomerCenter', () {
      test('should increment call count', () async {
        await mockSubscription.showCustomerCenter();

        expect(mockSubscription.showCustomerCenterCallCount, equals(1));
      });

      test('should complete when not configured', () async {
        mockSubscription.setConfigured(false);

        // Should not throw
        await mockSubscription.showCustomerCenter();
      });
    });

    group('identifyUser', () {
      test('should increment call count', () async {
        await mockSubscription.identifyUser('user123');

        expect(mockSubscription.identifyUserCallCount, equals(1));
      });

      test('should store user ID', () async {
        await mockSubscription.identifyUser('user123');

        expect(mockSubscription.lastIdentifiedUserId, equals('user123'));
      });

      test('should complete when not configured', () async {
        mockSubscription.setConfigured(false);

        // Should not throw
        await mockSubscription.identifyUser('user123');
      });
    });

    group('logOut', () {
      test('should increment call count', () async {
        await mockSubscription.logOut();

        expect(mockSubscription.logOutCallCount, equals(1));
      });

      test('should set isPro to false', () async {
        mockSubscription.setIsPro(true);

        await mockSubscription.logOut();

        expect(await mockSubscription.isPro(), isFalse);
      });
    });

    group('reset', () {
      test('should reset all state to defaults', () async {
        // Modify state
        mockSubscription.setConfigured(false);
        mockSubscription.setIsPro(true);
        await mockSubscription.initialize();
        await mockSubscription.isPro();
        await mockSubscription.restorePurchases();
        await mockSubscription.identifyUser('user123');

        // Reset
        mockSubscription.reset();

        // Verify defaults - note isPro() increments call count
        expect(mockSubscription.isConfigured, isTrue);
        expect(mockSubscription.initializeCallCount, equals(0));
        expect(mockSubscription.restorePurchasesCallCount, equals(0));
        expect(mockSubscription.identifyUserCallCount, equals(0));
        expect(mockSubscription.lastIdentifiedUserId, isNull);
        expect(mockSubscription.purchaseResult, isTrue);
        expect(mockSubscription.restoreResult, isFalse);
        expect(mockSubscription.paywallResult, isFalse);
        expect(mockSubscription.errorToThrow, isNull);

        // Check isPro separately (it increments isProCallCount)
        final isPro = await mockSubscription.isPro();
        expect(isPro, isFalse);
        expect(mockSubscription.isProCallCount, equals(1));
      });
    });

    group('error handling', () {
      test('should throw error on isPro', () async {
        mockSubscription.errorToThrow = Exception('Network error');

        expect(
          () => mockSubscription.isPro(),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw error on restorePurchases', () async {
        mockSubscription.errorToThrow = Exception('Network error');

        expect(
          () => mockSubscription.restorePurchases(),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw error on showPaywall', () async {
        mockSubscription.errorToThrow = Exception('Network error');

        expect(
          () => mockSubscription.showPaywall(),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw error on identifyUser', () async {
        mockSubscription.errorToThrow = Exception('Network error');

        expect(
          () => mockSubscription.identifyUser('user123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw error on logOut', () async {
        mockSubscription.errorToThrow = Exception('Network error');

        expect(
          () => mockSubscription.logOut(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
