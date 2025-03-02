import 'package:cloud_functions/cloud_functions.dart';

class OpenAIService {
  final FirebaseFunctions functions;

  OpenAIService() : functions = FirebaseFunctions.instanceFor(
    region: 'asia-southeast1',
  );

  Future<Map<String, dynamic>> getRecommendations({
    required String journalEntry,
    required DateTime lastPeriodDate,
  }) async {
    try {
      print('Initializing function call...');
      
      // Set origin for local development
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        print('Running in development mode');
        functions.useFunctionsEmulator('localhost', 5001);
      }

      print('Making function call...');
      final result = await functions.httpsCallable('getRecommendations').call({
        'journalEntry': journalEntry,
        'lastPeriodDate': lastPeriodDate.toString(),
        'currentDate': DateTime.now().toString(),
        'systemPrompt': '''
        You are a menstrual health expert. Analyze the user's journal entry and calculate their current menstrual phase based on their last period start date.

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
  "poetic_message": "A 20-word poetic, inspiring message about their current state and potential",
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

For the poetic_message, create a mystical, evocative message (max 15 words) about their energy and potential. Avoid mentioning the phase name directly. Examples:
- "Moonlit waters stir within, awakening ancient wisdom and untapped creative forces"
- "Like spring buds unfurling, your inner light grows stronger each moment"
- "Deep currents of transformation flow beneath still waters of contemplation"

Do not include any explanatory text outside the JSON structure. The response must be parseable JSON.'''
      });
      
      print('Function call completed. Result: ${result.data}');
      return result.data;
    } catch (e, stackTrace) {
      print('Error in OpenAI service: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
} 