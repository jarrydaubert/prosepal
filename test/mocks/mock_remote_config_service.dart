import 'package:prosepal/core/interfaces/remote_config_interface.dart';

/// Mock implementation of [IRemoteConfigService] for testing.
///
/// Provides full control over remote config values without requiring
/// Firebase SDK. Use this to test:
/// - AI model selection and fallback logic
/// - Force update flows
/// - Feature flag behavior
///
/// ## Usage
/// ```dart
/// final mockConfig = MockRemoteConfigService();
///
/// // Test force update
/// mockConfig.mockMinAppVersion = '2.0.0';
/// mockConfig.mockCurrentAppVersion = '1.0.0';
/// expect(await mockConfig.isUpdateRequired(), isTrue);
///
/// // Test AI model fallback
/// mockConfig.mockAiModel = 'gemini-new-model';
/// expect(mockConfig.aiModel, equals('gemini-new-model'));
/// ```
class MockRemoteConfigService implements IRemoteConfigService {
  // ===== Mock State =====

  bool _initialized = false;

  /// Mock value for [aiModel]. Defaults to 'gemini-2.5-flash'.
  String mockAiModel = 'gemini-2.5-flash';

  /// Mock value for [aiModelFallback]. Defaults to 'gemini-2.0-flash'.
  String mockAiModelFallback = 'gemini-2.0-flash';

  /// Mock value for [isForceUpdateEnabled]. Defaults to true.
  bool mockForceUpdateEnabled = true;

  /// Mock value for [minAppVersion]. Defaults to '1.0.0'.
  String mockMinAppVersion = '1.0.0';

  /// Mock value for current app version (used in [isUpdateRequired]).
  /// Defaults to '1.0.0'.
  String mockCurrentAppVersion = '1.0.0';

  /// Mock store URL. Defaults to a test URL.
  String mockStoreUrl = 'https://example.com/app';

  /// Number of times [initialize] was called.
  int initializeCallCount = 0;

  /// Number of times [refresh] was called.
  int refreshCallCount = 0;

  /// If set, [initialize] will throw this exception.
  Exception? initializeError;

  /// If set, [isUpdateRequired] will throw this exception.
  Exception? isUpdateRequiredError;

  // ===== Interface Implementation =====

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    if (initializeError != null) {
      throw initializeError!;
    }
    _initialized = true;
  }

  @override
  String get aiModel => mockAiModel;

  @override
  String get aiModelFallback => mockAiModelFallback;

  @override
  bool get isForceUpdateEnabled => mockForceUpdateEnabled;

  @override
  String get minAppVersion => mockMinAppVersion;

  @override
  Future<bool> isUpdateRequired() async {
    if (isUpdateRequiredError != null) {
      throw isUpdateRequiredError!;
    }
    if (!mockForceUpdateEnabled) return false;

    final comparison = compareVersions(
      mockCurrentAppVersion,
      mockMinAppVersion,
    );
    return comparison < 0;
  }

  @override
  String get storeUrl => mockStoreUrl;

  @override
  Future<void> refresh() async {
    refreshCallCount++;
  }

  @override
  int compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    // Pad to 3 parts for consistent comparison
    while (parts1.length < 3) {
      parts1.add(0);
    }
    while (parts2.length < 3) {
      parts2.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return 0;
  }

  // ===== Test Helpers =====

  /// Reset all mock state to defaults.
  void reset() {
    _initialized = false;
    mockAiModel = 'gemini-2.5-flash';
    mockAiModelFallback = 'gemini-2.0-flash';
    mockForceUpdateEnabled = true;
    mockMinAppVersion = '1.0.0';
    mockCurrentAppVersion = '1.0.0';
    mockStoreUrl = 'https://example.com/app';
    initializeCallCount = 0;
    refreshCallCount = 0;
    initializeError = null;
    isUpdateRequiredError = null;
  }

  /// Configure for a force update scenario.
  ///
  /// Sets [mockCurrentAppVersion] below [mockMinAppVersion].
  void simulateForceUpdateRequired({
    String currentVersion = '1.0.0',
    String minVersion = '2.0.0',
  }) {
    mockCurrentAppVersion = currentVersion;
    mockMinAppVersion = minVersion;
    mockForceUpdateEnabled = true;
  }

  /// Configure for no update required.
  void simulateNoUpdateRequired({String currentVersion = '2.0.0'}) {
    mockCurrentAppVersion = currentVersion;
    mockMinAppVersion = '1.0.0';
    mockForceUpdateEnabled = true;
  }
}
