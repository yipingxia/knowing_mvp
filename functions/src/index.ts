import * as functions from 'firebase-functions';
import OpenAI from 'openai';
import * as dotenv from 'dotenv';

// Load environment variables for local development
dotenv.config();

// Add a version identifier
const VERSION = '1.0.4'; // increment this when you deploy

// Define the interface for our request data
interface RecommendationRequest {
  systemPrompt: string;
  journalEntry: string;
  lastPeriodDate: string;
  currentDate: string;
}

// Specify the region explicitly
export const getRecommendations = functions
  .region('asia-southeast1')
  .https.onCall(async (data: RecommendationRequest) => {
  try {
    console.log(`Function version ${VERSION} called`);
    
    // Log the entire config for debugging
    console.log('Full config:', JSON.stringify(functions.config()));
    
    let apiKey: string | undefined;
    
    try {
      apiKey = functions.config().openai?.key;
      console.log('Firebase config key available:', Boolean(apiKey));
    } catch (e) {
      console.log('Error getting Firebase config:', e);
    }

    if (!apiKey) {
      apiKey = process.env.OPENAI_API_KEY;
      console.log('Falling back to env var');
    }

    if (!apiKey) {
      throw new Error('OpenAI API key not found in any configuration');
    }

    console.log('API Key available:', Boolean(apiKey));
    console.log('API Key starts with:', apiKey.substring(0, 7));

    const openai = new OpenAI({
      apiKey: apiKey
    });

    console.log('Function called at:', new Date().toISOString(), {
      version: VERSION,
      journalEntry: data.journalEntry ? data.journalEntry.length : 0,
      lastPeriodDate: data.lastPeriodDate,
      currentDate: data.currentDate
    });

    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: `You are a menstrual health expert. Analyze the user's journal entry and calculate their current menstrual phase based on their last period start date.

IMPORTANT: You must return ONLY a JSON object with NO additional text. The phase MUST be one of: "Menstrual", "Follicular", "Ovulatory", or "Luteal".

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


IMPORTANT: Your response must follow this exact structure as a valid JSON object:
{
  "current_phase": "Menstrual" | "Follicular" | "Ovulatory" | "Luteal",
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

For relationship, provide some tips around how to better manage relationship conflicts and improve communication.

For stress_management, provide some tips around how to deal with stress and anxiety.
For tell_partner, provide 3 key things a partner should know about supporting someone in this phase, considering the symptoms and experiences mentioned in the journal entry.

For the poetic_message, create a mystical, evocative message (max 15 words) about their energy and potential. Avoid mentioning the phase name directly. Examples:
- "Moonlit waters stir within, awakening ancient wisdom and untapped creative forces"
- "Like spring buds unfurling, your inner light grows stronger each moment"
- "Deep currents of transformation flow beneath still waters of contemplation"
}`
        },
        {
          role: 'user',
          content: `Journal Entry: ${data.journalEntry}\nLast Period Date: ${data.lastPeriodDate}\nCurrent Date: ${data.currentDate}`
        }
      ],
      temperature: 0.7,
      max_tokens: 1000
    });

    console.log('Raw OpenAI response:', completion);
    
    const messageContent = completion.choices[0].message.content;
    if (!messageContent) {
      throw new Error('OpenAI returned empty response');
    }

    try {
      // Parse the content string into JSON
      console.log('About to parse message content:', messageContent);
      const parsedContent = JSON.parse(messageContent);
      
      console.log('Raw parsed content:', parsedContent);
      
      // Check if current_phase exists and has the right format
      if (!parsedContent.current_phase || 
          !['Menstrual', 'Follicular', 'Ovulatory', 'Luteal'].includes(parsedContent.current_phase)) {
        console.log('Invalid phase detected:', parsedContent.current_phase);
      }
      
      // Create the response object - directly use the parsed content
      const response = {
        current_phase: parsedContent.current_phase || 'Unknown',
        days_since_last_period: parsedContent.days_since_last_period || 0,
        keywords: parsedContent.keywords || [],
        poetic_message: parsedContent.poetic_message || 'No message available',
        recommendations: {
          exercise: parsedContent.recommendations?.exercise || [],
          nutrition: parsedContent.recommendations?.nutrition || [],
          emotional_wellbeing: parsedContent.recommendations?.emotional_wellbeing || [],
          symptoms_management: parsedContent.recommendations?.symptoms_management || [],
          relationship: parsedContent.recommendations?.relationship || [],
          stress_management: parsedContent.recommendations?.stress_management || [],
          tell_partner: parsedContent.recommendations?.tell_partner || []
        }
      };

      console.log('Created response object:', JSON.stringify(response, null, 2));
      console.log('About to return response');
      return response;

    } catch (parseError: unknown) {
      console.error('JSON parsing error:', parseError);
      console.error('Message content was:', messageContent);
      const message = parseError instanceof Error ? parseError.message : 'Unknown parsing error';
      throw new Error(`Failed to parse OpenAI response as JSON: ${message}`);
    }
  } catch (error) {
    console.error('Detailed error:', error);
    throw new functions.https.HttpsError('internal', `Failed to get recommendations: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}); 