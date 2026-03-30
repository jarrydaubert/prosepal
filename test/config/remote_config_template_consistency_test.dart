import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/config/ai_config.dart';

void main() {
  late Map<String, dynamic> jsonTemplate;
  late Map<String, dynamic> firebaseTemplate;
  late Map<String, dynamic> firebaseParameters;

  setUpAll(() async {
    jsonTemplate =
        jsonDecode(
              await File('docs/REMOTE_CONFIG_TEMPLATE.json').readAsString(),
            )
            as Map<String, dynamic>;
    firebaseTemplate =
        jsonDecode(
              await File(
                'docs/REMOTE_CONFIG_TEMPLATE.firebase.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    firebaseParameters = firebaseTemplate['parameters'] as Map<String, dynamic>;
  });

  group('Remote Config templates', () {
    bool isPinnedStableModelId(String modelId) =>
        modelId.isNotEmpty &&
        !modelId.contains('latest') &&
        !modelId.contains('preview');

    test('plain template keeps required AI controls and pinned defaults', () {
      expect(
        jsonTemplate.keys,
        containsAll([
          'config_schema_version',
          'ai_enabled',
          'paywall_enabled',
          'premium_enabled',
          'ai_model',
          'ai_model_fallback',
          'ai_use_limited_app_check_tokens',
          'force_update_enabled',
          'min_app_version_ios',
          'min_app_version_android',
        ]),
      );

      expect(jsonTemplate['config_schema_version'], equals(1));
      expect(jsonTemplate['ai_enabled'], isTrue);
      expect(jsonTemplate['paywall_enabled'], isTrue);
      expect(jsonTemplate['premium_enabled'], isTrue);
      expect(jsonTemplate['ai_use_limited_app_check_tokens'], isFalse);
      expect(jsonTemplate['force_update_enabled'], isTrue);
      expect(jsonTemplate['ai_model'], equals(AiConfig.defaultModel));
      expect(
        jsonTemplate['ai_model_fallback'],
        equals(AiConfig.defaultFallbackModel),
      );
      expect(AiConfig.allowedModelIds, contains(jsonTemplate['ai_model']));
      expect(
        AiConfig.allowedModelIds,
        contains(jsonTemplate['ai_model_fallback']),
      );
      expect(
        jsonTemplate['ai_model'],
        isNot(equals(jsonTemplate['ai_model_fallback'])),
      );
      expect(isPinnedStableModelId(jsonTemplate['ai_model'] as String), isTrue);
      expect(
        isPinnedStableModelId(jsonTemplate['ai_model_fallback'] as String),
        isTrue,
      );
    });

    test('firebase template mirrors required AI control defaults and types', () {
      expect(
        firebaseParameters.keys,
        containsAll([
          'config_schema_version',
          'ai_enabled',
          'paywall_enabled',
          'premium_enabled',
          'ai_model',
          'ai_model_fallback',
          'ai_use_limited_app_check_tokens',
          'force_update_enabled',
          'min_app_version_ios',
          'min_app_version_android',
        ]),
      );

      expect(
        firebaseParameters['config_schema_version']['defaultValue']['value'],
        equals('1'),
      );
      expect(
        firebaseParameters['config_schema_version']['valueType'],
        equals('NUMBER'),
      );

      expect(
        firebaseParameters['ai_enabled']['defaultValue']['value'],
        equals('true'),
      );
      expect(firebaseParameters['ai_enabled']['valueType'], equals('BOOLEAN'));
      expect(
        firebaseParameters['paywall_enabled']['defaultValue']['value'],
        equals('true'),
      );
      expect(
        firebaseParameters['paywall_enabled']['valueType'],
        equals('BOOLEAN'),
      );
      expect(
        firebaseParameters['premium_enabled']['defaultValue']['value'],
        equals('true'),
      );
      expect(
        firebaseParameters['premium_enabled']['valueType'],
        equals('BOOLEAN'),
      );

      expect(
        firebaseParameters['ai_model']['defaultValue']['value'],
        equals(AiConfig.defaultModel),
      );
      expect(firebaseParameters['ai_model']['valueType'], equals('STRING'));
      expect(
        firebaseParameters['ai_model_fallback']['defaultValue']['value'],
        equals(AiConfig.defaultFallbackModel),
      );
      expect(
        firebaseParameters['ai_model_fallback']['valueType'],
        equals('STRING'),
      );

      expect(
        firebaseParameters['ai_use_limited_app_check_tokens']['defaultValue']['value'],
        equals('false'),
      );
      expect(
        firebaseParameters['ai_use_limited_app_check_tokens']['valueType'],
        equals('BOOLEAN'),
      );
      expect(
        firebaseParameters['force_update_enabled']['defaultValue']['value'],
        equals('true'),
      );
      expect(
        firebaseParameters['force_update_enabled']['valueType'],
        equals('BOOLEAN'),
      );

      expect(
        firebaseParameters['ai_model']['defaultValue']['value'],
        isNot(
          equals(
            firebaseParameters['ai_model_fallback']['defaultValue']['value'],
          ),
        ),
      );
    });

    test('allowlist contains only pinned stable production model ids', () {
      expect(AiConfig.allowedModelIds, isNotEmpty);
      expect(AiConfig.allowedModelIds.length, equals(2));
      expect(AiConfig.allowedModelIds, contains(AiConfig.defaultModel));
      expect(AiConfig.allowedModelIds, contains(AiConfig.defaultFallbackModel));

      for (final modelId in AiConfig.allowedModelIds) {
        expect(isPinnedStableModelId(modelId), isTrue);
      }
    });
  });
}
