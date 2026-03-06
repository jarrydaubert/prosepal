/// Normalized auth telemetry helpers used by analytics, logs, and diagnostics.
///
/// Keeps provider/source fields deterministic across linked-account scenarios.
abstract final class AuthTelemetry {
  static String? metadataProvider(Map<String, dynamic>? appMetadata) {
    if (appMetadata == null) return null;
    final value = appMetadata['provider'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim().toLowerCase();
    }
    return null;
  }

  static List<String> linkedProviders({
    required String? metadataProvider,
    required dynamic metadataProvidersRaw,
    required Iterable<String?>? identityProviders,
  }) {
    final candidates = <String?>[
      metadataProvider,
      if (metadataProvidersRaw is List)
        ...metadataProvidersRaw.whereType<String>(),
      ...?identityProviders,
    ];
    final normalized = <String>{};
    for (final value in candidates) {
      final trimmed = value?.trim().toLowerCase();
      if (trimmed != null && trimmed.isNotEmpty) {
        normalized.add(trimmed);
      }
    }
    final sorted = normalized.toList()..sort();
    return sorted;
  }

  static String linkedProvidersValue(List<String> providers) {
    if (providers.isEmpty) return 'none';
    return providers.join('|');
  }

  static String mostRecentIdentityProvider(
    List<Map<String, String?>>? identityRows, {
    required String? fallbackProvider,
  }) {
    if (identityRows == null || identityRows.isEmpty) {
      return fallbackProvider ?? 'unknown';
    }

    DateTime? newestTimestamp;
    String? newestProvider;
    for (final row in identityRows) {
      final provider = row['provider']?.trim().toLowerCase();
      final timestampRaw = row['lastSignInAt'];
      if (provider == null || provider.isEmpty) continue;

      final parsedTimestamp = timestampRaw == null
          ? null
          : DateTime.tryParse(timestampRaw)?.toUtc();
      if (parsedTimestamp == null) {
        newestProvider ??= provider;
        continue;
      }
      if (newestTimestamp == null || parsedTimestamp.isAfter(newestTimestamp)) {
        newestTimestamp = parsedTimestamp;
        newestProvider = provider;
      }
    }
    return newestProvider ?? fallbackProvider ?? 'unknown';
  }

  static String currentSessionSource({
    required bool hasSession,
    required String? sessionProvider,
    required String? fallbackProvider,
  }) {
    if (!hasSession) return 'none';
    return sessionProvider ?? fallbackProvider ?? 'unknown';
  }

  static String providerLabel(String? provider) => provider ?? 'unknown';

  static String? truncatedUserId(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    if (userId.length <= 8) return userId;
    return '${userId.substring(0, 8)}...';
  }

  static Map<String, Object> authStateAnalyticsParams({
    required String event,
    required bool hasSession,
    required String lastSignInProvider,
    required String currentSessionSource,
    required int linkedProviderCount,
  }) => <String, Object>{
    'event': event,
    'has_session': hasSession,
    'last_sign_in_provider': lastSignInProvider,
    'current_session_source': currentSessionSource,
    'linked_provider_count': linkedProviderCount,
  };
}
