import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/config/ai_config.dart';
import 'package:prosepal/core/services/remote_config_service.dart';

import '../mocks/mocks.dart';

/// RemoteConfigService Unit Tests
///
/// Tests BOTH mock behavior (for testability) and real service behavior
/// (for graceful degradation when Firebase is unavailable).
///
/// Each test answers: "What bug does this catch?"
///
/// ## Test Categories
/// 1. Version Comparison - Core logic that's testable without Firebase
/// 2. Mock Service - Tests using MockRemoteConfigService for full control
/// 3. Real Service (Uninitialized) - Verifies graceful defaults
void main() {
  group('RemoteConfigService - Version Comparison Logic', () {
    // Bug: Wrong version comparison causes incorrect force update behavior
    // This is pure logic that can be tested without Firebase SDK

    late RemoteConfigService service;

    setUp(() {
      service = RemoteConfigService.instance;
    });

    test('equal versions return 0', () {
      expect(service.compareVersions('1.0.0', '1.0.0'), equals(0));
      expect(service.compareVersions('2.5.3', '2.5.3'), equals(0));
      expect(service.compareVersions('10.20.30', '10.20.30'), equals(0));
    });

    test('v1 < v2 returns negative', () {
      // Major version difference
      expect(service.compareVersions('1.0.0', '2.0.0'), lessThan(0));

      // Minor version difference
      expect(service.compareVersions('1.0.0', '1.1.0'), lessThan(0));

      // Patch version difference
      expect(service.compareVersions('1.0.0', '1.0.1'), lessThan(0));

      // Multiple component differences
      expect(service.compareVersions('1.2.3', '1.2.4'), lessThan(0));
      expect(service.compareVersions('1.9.9', '2.0.0'), lessThan(0));
    });

    test('v1 > v2 returns positive', () {
      // Major version difference
      expect(service.compareVersions('2.0.0', '1.0.0'), greaterThan(0));

      // Minor version difference
      expect(service.compareVersions('1.1.0', '1.0.0'), greaterThan(0));

      // Patch version difference
      expect(service.compareVersions('1.0.1', '1.0.0'), greaterThan(0));

      // Multiple component differences
      expect(service.compareVersions('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('handles versions with fewer than 3 components', () {
      // Bug: Crash when version string is incomplete
      expect(service.compareVersions('1.0', '1.0.0'), equals(0));
      expect(service.compareVersions('1', '1.0.0'), equals(0));
      expect(service.compareVersions('2', '1.9.9'), greaterThan(0));
    });

    test('handles versions with non-numeric components gracefully', () {
      // Bug: Crash on malformed version strings
      // Should treat non-numeric as 0
      expect(service.compareVersions('1.0.0', '1.0.abc'), equals(0));
      expect(service.compareVersions('1.0.1', '1.0.abc'), greaterThan(0));
    });

    test('handles edge case version numbers', () {
      // Bug: Integer overflow or comparison issues with large numbers
      expect(service.compareVersions('99.99.99', '99.99.99'), equals(0));
      expect(service.compareVersions('100.0.0', '99.99.99'), greaterThan(0));
    });
  });

  group('MockRemoteConfigService - Force Update Logic', () {
    // Tests using mock to verify force update business logic

    late MockRemoteConfigService mockService;

    setUp(() {
      mockService = MockRemoteConfigService();
    });

    test('isUpdateRequired returns true when current < minimum', () async {
      // Bug: User not prompted to update when they should be
      mockService.simulateForceUpdateRequired(
        currentVersion: '1.0.0',
        minVersion: '2.0.0',
      );

      expect(await mockService.isUpdateRequired(), isTrue);
    });

    test('isUpdateRequired returns false when current >= minimum', () async {
      // Bug: User incorrectly prompted to update
      mockService.simulateNoUpdateRequired(currentVersion: '2.0.0');

      expect(await mockService.isUpdateRequired(), isFalse);
    });

    test('isUpdateRequired returns false when current == minimum', () async {
      // Bug: Edge case - exact match should NOT require update
      mockService.mockCurrentAppVersion = '1.5.0';
      mockService.mockMinAppVersion = '1.5.0';

      expect(await mockService.isUpdateRequired(), isFalse);
    });

    test('isUpdateRequired returns false when force update disabled', () async {
      // Bug: Force update not respecting kill switch
      mockService.mockForceUpdateEnabled = false;
      mockService.mockCurrentAppVersion = '1.0.0';
      mockService.mockMinAppVersion = '99.0.0';

      expect(await mockService.isUpdateRequired(), isFalse);
    });

    test('handles patch version differences correctly', () async {
      // Bug: Patch versions ignored in comparison
      mockService.mockCurrentAppVersion = '1.0.0';
      mockService.mockMinAppVersion = '1.0.1';

      expect(await mockService.isUpdateRequired(), isTrue);
    });

    test('handles minor version differences correctly', () async {
      // Bug: Minor version not compared correctly
      mockService.mockCurrentAppVersion = '1.0.9';
      mockService.mockMinAppVersion = '1.1.0';

      expect(await mockService.isUpdateRequired(), isTrue);
    });
  });

  group('MockRemoteConfigService - AI Model Config', () {
    // Tests using mock to verify AI model fallback logic

    late MockRemoteConfigService mockService;

    setUp(() {
      mockService = MockRemoteConfigService();
    });

    test('returns configured AI model', () {
      // Bug: Wrong model used for generation
      mockService.mockAiModel = 'gemini-3-flash-preview';

      expect(mockService.aiModel, equals('gemini-3-flash-preview'));
    });

    test('returns configured fallback model', () {
      // Bug: Wrong fallback used when primary fails
      mockService.mockAiModelFallback = 'gemini-2.5-flash';

      expect(mockService.aiModelFallback, equals('gemini-2.5-flash'));
    });

    test('aiModel and aiModelFallback are independent', () {
      // Bug: Changing one affects the other
      mockService.mockAiModel = 'model-a';
      mockService.mockAiModelFallback = 'model-b';

      expect(mockService.aiModel, equals('model-a'));
      expect(mockService.aiModelFallback, equals('model-b'));
    });
  });

  group('MockRemoteConfigService - Initialization', () {
    late MockRemoteConfigService mockService;

    setUp(() {
      mockService = MockRemoteConfigService();
    });

    test('starts uninitialized', () {
      expect(mockService.isInitialized, isFalse);
    });

    test('isInitialized becomes true after initialize()', () async {
      await mockService.initialize();

      expect(mockService.isInitialized, isTrue);
    });

    test('tracks initialize call count', () async {
      expect(mockService.initializeCallCount, equals(0));

      await mockService.initialize();
      expect(mockService.initializeCallCount, equals(1));

      await mockService.initialize();
      expect(mockService.initializeCallCount, equals(2));
    });

    test('can simulate initialization failure', () async {
      mockService.initializeError = Exception('Network error');

      expect(() => mockService.initialize(), throwsA(isA<Exception>()));
    });
  });

  group('MockRemoteConfigService - Refresh', () {
    late MockRemoteConfigService mockService;

    setUp(() {
      mockService = MockRemoteConfigService();
    });

    test('tracks refresh call count', () async {
      expect(mockService.refreshCallCount, equals(0));

      await mockService.refresh();
      expect(mockService.refreshCallCount, equals(1));

      await mockService.refresh();
      await mockService.refresh();
      expect(mockService.refreshCallCount, equals(3));
    });
  });

  group('MockRemoteConfigService - Reset', () {
    late MockRemoteConfigService mockService;

    setUp(() {
      mockService = MockRemoteConfigService();
    });

    test('reset restores all defaults', () async {
      // Modify everything
      await mockService.initialize();
      mockService.mockAiModel = 'custom-model';
      mockService.mockMinAppVersion = '5.0.0';
      mockService.mockForceUpdateEnabled = false;
      await mockService.refresh();

      // Reset
      mockService.reset();

      // Verify defaults restored
      expect(mockService.isInitialized, isFalse);
      expect(mockService.mockAiModel, equals('gemini-2.5-flash'));
      expect(mockService.mockMinAppVersion, equals('1.0.0'));
      expect(mockService.mockForceUpdateEnabled, isTrue);
      expect(mockService.initializeCallCount, equals(0));
      expect(mockService.refreshCallCount, equals(0));
    });
  });

  group('RemoteConfigService - Uninitialized Defaults', () {
    // Bug: App crashes or misbehaves when Firebase unavailable
    // These tests verify graceful degradation with sensible defaults

    test('aiModel returns default when uninitialized', () {
      final service = RemoteConfigService.instance;
      // Note: Can't reset singleton, but we can verify it returns valid defaults
      // even if Firebase fails or is never initialized

      final model = service.aiModel;
      expect(model, isNotEmpty);
      expect(model, equals(AiConfig.defaultModel));
    });

    test('aiModelFallback returns default when uninitialized', () {
      final service = RemoteConfigService.instance;

      final fallback = service.aiModelFallback;
      expect(fallback, isNotEmpty);
      expect(fallback, equals(AiConfig.defaultFallbackModel));
    });

    test('minAppVersion returns safe default when uninitialized', () {
      final service = RemoteConfigService.instance;

      final minVersion = service.minAppVersion;
      expect(minVersion, equals('1.0.0'));
    });

    test('isForceUpdateEnabled defaults to true', () {
      final service = RemoteConfigService.instance;

      // Default to true so we can enable force update via Remote Config
      // If this defaulted to false, we couldn't push a force update to old apps
      expect(service.isForceUpdateEnabled, isTrue);
    });

    test('storeUrl returns valid URL', () {
      final service = RemoteConfigService.instance;

      final url = service.storeUrl;
      expect(url, startsWith('https://'));
    });

    test('refresh completes without error when uninitialized', () async {
      final service = RemoteConfigService.instance;

      // Should not throw even if Firebase isn't set up
      await expectLater(service.refresh(), completes);
    });
  });

  group('RemoteConfigService - Singleton Behavior', () {
    test('instance returns same object', () {
      final instance1 = RemoteConfigService.instance;
      final instance2 = RemoteConfigService.instance;

      expect(identical(instance1, instance2), isTrue);
    });
  });
}
