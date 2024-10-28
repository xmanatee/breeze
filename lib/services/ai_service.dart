import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:breeze/models/protocols.dart';
import 'package:breeze/services/storage.dart';

class AIService {
  Future<AIResponse> getChatCompletion({
    required final String prompt,
  }) async {
    final responseContent = await _getChatCompletionContent(
      prompt: prompt,
    );

    debugPrint('AI Response: $responseContent');

    try {
      final parsedJson = jsonDecode(responseContent);
      // Validate that 'action' field exists and is one of the expected values
      if (!parsedJson.containsKey('action') ||
          !['idle', 'auto', 'ask_user_input', 'ask_user_action']
              .contains(parsedJson['action'])) {
        throw Exception('Invalid or missing "action" field in AI response.');
      }

      // Additional validations based on action type
      switch (parsedJson['action']) {
        case 'idle':
          if (parsedJson['details'].isNotEmpty) {
            throw Exception('"details" should be empty for "idle" action.');
          }
          break;
        case 'auto':
          if (parsedJson['details'] is! List) {
            throw Exception('"details" should be a list for "auto" action.');
          }
          break;
        case 'ask_user_input':
          if (!parsedJson['details'].containsKey('prompt') ||
              !parsedJson['details'].containsKey('data_keys_needed')) {
            throw Exception(
                '"details" must contain "prompt" and "data_keys_needed" for "ask_user_input" action.');
          }
          break;
        case 'ask_user_action':
          if (!parsedJson['details'].containsKey('instruction') ||
              !parsedJson['details'].containsKey('condition_for_resume')) {
            throw Exception(
                '"details" must contain "instruction" and "condition_for_resume" for "ask_user_action" action.');
          }
          break;
        default:
          throw Exception('Unknown action type: ${parsedJson['action']}');
      }

      return AIResponse.fromJson(parsedJson);
    } catch (e) {
      throw Exception(
          'Error parsing or validating AI response: $e. Response: $responseContent');
    }
  }

  Future<Map<String, String>> parseUserData(final String freeFormText) async {
    final prompt = '''
Extract key-value pairs from the following text and return them in JSON format.

Text:
"$freeFormText"

Instructions:
- Only extract information that is useful for filling out forms.
- Use specific and precise key names (e.g., "passport_number", "legal_first_name", "legal_surname", "date_of_birth").
- Discard any entries that are not useful for form filling.
- Return the extracted data as a JSON object with keys and values.
- Ensure the keys are concise and represent the data accurately.
- Do not include any additional text or explanations outside the JSON response.
''';

    final responseContent = await _getChatCompletionContent(prompt: prompt);
    try {
      final parsedJson = jsonDecode(responseContent);
      if (parsedJson is Map<String, dynamic>) {
        return parsedJson.map((final key, final value) =>
            MapEntry(key.toString(), value.toString()));
      } else {
        throw Exception('AI response is not a JSON object.');
      }
    } catch (e) {
      throw Exception('Error parsing AI response: $e');
    }
  }

  Future<String> _getChatCompletionContent({
    required final String prompt,
  }) async {
    final aiBackend = BreezeStorage().getString(BreezeStorage.aiBackendKey);
    final aiModel = BreezeStorage().getString(BreezeStorage.aiModelKey);

    if (aiBackend == 'OpenAI') {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      return await _requestChatCompletionContent(
        apiUrl: 'https://api.openai.com/v1/chat/completions',
        apiKey: apiKey!,
        model: aiModel,
        prompt: prompt,
      );
    } else if (aiBackend == 'Anthropic') {
      final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
      return await _requestChatCompletionContent(
        apiUrl: 'https://api.anthropic.com/v1/complete',
        apiKey: apiKey!,
        model: aiModel,
        prompt: prompt,
        extraParams: {
          'max_tokens_to_sample': 512,
        },
      );
    } else if (aiBackend == 'Nebius AI') {
      final apiKey = dotenv.env['NEBIUS_API_KEY'];
      return await _requestChatCompletionContent(
        apiUrl: 'https://api.studio.nebius.ai/v1/chat/completions',
        apiKey: apiKey!,
        model: aiModel,
        prompt: prompt,
        extraParams: {
          'top_k': 50,
        },
      );
    } else {
      throw Exception('Unsupported AI backend: $aiBackend');
    }
  }

  Future<String> _requestChatCompletionContent({
    required final String apiUrl,
    required final String apiKey,
    required final String model,
    required final String prompt,
    final Map<String, dynamic> extraParams = const {},
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a helpful assistant that strictly follows the given instructions and returns responses only in the specified JSON format without any additional text or explanations.',
        },
        {
          'role': 'user',
          'content': prompt,
        },
      ],
      'temperature': 0.0,
      'max_tokens': 512,
      'top_p': 0.1,
    };

    body.addAll(extraParams);

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];

      return content;
    } else {
      throw Exception(
          'Error from $apiUrl: ${response.statusCode} - ${response.body}');
    }
  }
}
