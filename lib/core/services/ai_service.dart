import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

class AiService {
  AiService({required String apiKey}) : _apiKey = apiKey;

  final String _apiKey;
  GenerativeModel? _model;
  final _uuid = Uuid();

  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.9,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
    return _model!;
  }

  Future<GenerationResult> generateMessages({
    required Occasion occasion,
    required Relationship relationship,
    required Tone tone,
    String? recipientName,
    String? personalDetails,
  }) async {
    final prompt = _buildPrompt(
      occasion: occasion,
      relationship: relationship,
      tone: tone,
      recipientName: recipientName,
      personalDetails: personalDetails,
    );

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '';

    final messages = _parseMessages(
      text,
      occasion: occasion,
      relationship: relationship,
      tone: tone,
      recipientName: recipientName,
      personalDetails: personalDetails,
    );

    return GenerationResult(
      messages: messages,
      occasion: occasion,
      relationship: relationship,
      tone: tone,
      recipientName: recipientName,
      personalDetails: personalDetails,
    );
  }

  String _buildPrompt({
    required Occasion occasion,
    required Relationship relationship,
    required Tone tone,
    String? recipientName,
    String? personalDetails,
  }) {
    final recipientPart = recipientName != null && recipientName.isNotEmpty
        ? 'The recipient\'s name is $recipientName.'
        : '';

    final detailsPart = personalDetails != null && personalDetails.isNotEmpty
        ? 'Additional context: $personalDetails'
        : '';

    return '''
You are a skilled greeting card message writer. Generate exactly 3 different message options for a greeting card.

Context:
- Occasion: ${occasion.prompt}
- Recipient: ${relationship.prompt}
- Tone: ${tone.prompt}
$recipientPart
$detailsPart

Requirements:
1. Each message should be 2-4 sentences
2. Messages should feel personal and genuine, not generic
3. Each option should have a different approach/angle
4. Do NOT include greetings like "Dear [Name]" at the start
5. Do NOT include sign-offs like "Best wishes" or "Love" at the end
6. Just the message body content

Format your response EXACTLY like this:
MESSAGE 1:
[First message here]

MESSAGE 2:
[Second message here]

MESSAGE 3:
[Third message here]
''';
  }

  List<GeneratedMessage> _parseMessages(
    String response, {
    required Occasion occasion,
    required Relationship relationship,
    required Tone tone,
    String? recipientName,
    String? personalDetails,
  }) {
    final messages = <GeneratedMessage>[];
    final now = DateTime.now();

    // Split by MESSAGE markers
    final pattern = RegExp(r'MESSAGE\s*\d+:\s*', caseSensitive: false);
    final parts = response.split(pattern);

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty && trimmed.length > 10) {
        messages.add(GeneratedMessage(
          id: _uuid.v4(),
          text: trimmed,
          occasion: occasion,
          relationship: relationship,
          tone: tone,
          createdAt: now,
          recipientName: recipientName,
          personalDetails: personalDetails,
        ));
      }
    }

    // Fallback: if parsing failed, treat whole response as one message
    if (messages.isEmpty && response.trim().isNotEmpty) {
      messages.add(GeneratedMessage(
        id: _uuid.v4(),
        text: response.trim(),
        occasion: occasion,
        relationship: relationship,
        tone: tone,
        createdAt: now,
        recipientName: recipientName,
        personalDetails: personalDetails,
      ));
    }

    return messages.take(3).toList();
  }
}
