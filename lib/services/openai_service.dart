import 'package:dart_openai/dart_openai.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  
  OpenAIService() {
    OpenAI.apiKey = _apiKey;
  }

  Future<Map<String, dynamic>> getRecommendations({
    required String journalEntry,
    required DateTime lastPeriodDate,
  }) async {
    try {
      print('Sending request to OpenAI...');
      final completion = await OpenAI.instance.chat.create(
        model: 'gpt-4',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                '''You are a menstrual health expert. Analyze the user's journal entry and calculate their current menstrual phase based on their last period start date.

To determine the current phase:
1. Calculate days since last period start date
2. Use standard cycle phases:
   - Menstrual Phase: Days 1-5
   - Follicular Phase: Days 6-13
   - Ovulatory Phase: Days 14-16
   - Luteal Phase: Days 17-28

Consider both the calculated phase and any symptoms mentioned in the journal entry to confirm the phase prediction.

Common symptoms for each phase:
- Menstrual: Bleeding, cramps, fatigue, lower back pain
- Follicular: Increased energy, improved mood, breast tenderness
- Ovulatory: Clear discharge, mild pain on one side, increased libido
- Luteal: Bloating, mood changes, breast tenderness, fatigue

IMPORTANT: Your response must be a valid JSON object with exactly this structure:
{
  "current_phase": "Menstrual/Follicular/Ovulatory/Luteal",
  "days_since_last_period": number,
  "keywords": ["keyword1", "keyword2", "keyword3"],
  "recommendations": {
    "exercise": ["pointer1", "pointer2", "pointer3"],
    "nutrition": ["pointer1", "pointer2", "pointer3"],
    "relationship": ["pointer1", "pointer2", "pointer3"],
    "emotional_wellbeing": ["pointer1", "pointer2", "pointer3"],
    "stress_management": ["pointer1", "pointer2", "pointer3"],
    "symptoms_management": ["pointer1", "pointer2", "pointer3"],
    "tell_partner": ["insight1", "insight2", "insight3"]
  }
}

For tell_partner, provide 3 key things a partner should know about supporting someone in this phase, considering the symptoms and experiences mentioned in the journal entry.

Do not include any explanatory text outside the JSON structure. The response must be parseable JSON.'''
              ),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                '''Journal Entry: $journalEntry
Last Period Date: ${lastPeriodDate.toString()}
Current Date: ${DateTime.now().toString()}'''
              ),
            ],
          ),
        ],
        temperature: 0.7,
        maxTokens: 1000,
        topP: 1,
        frequencyPenalty: 0,
        presencePenalty: 0,
      );

      print('Received response from OpenAI');
      
      final content = completion.choices.first.message.content;
      if (content == null || content.isEmpty) {
        throw Exception('No response from OpenAI');
      }

      final jsonResponse = content.first.text;
      if (jsonResponse == null) {
        throw Exception('Invalid response format from OpenAI');
      }

      try {
        // Try to clean the response if needed
        String cleanedResponse = jsonResponse.trim();
        if (!cleanedResponse.startsWith('{')) {
          // Try to find the start of the JSON object
          final startIndex = cleanedResponse.indexOf('{');
          if (startIndex >= 0) {
            cleanedResponse = cleanedResponse.substring(startIndex);
          }
        }
        
        final Map<String, dynamic> parsedJson = json.decode(cleanedResponse);
        print('Successfully parsed JSON: $parsedJson');
        return parsedJson;
      } catch (e) {
        print('JSON parsing error: $e');
        print('Raw response: $jsonResponse');
        throw Exception('Failed to parse OpenAI response as JSON: $e');
      }
    } catch (e) {
      print('Error in OpenAI service: $e');
      return {
        'error': 'Failed to get recommendations: ${e.toString()}',
      };
    }
  }
} 