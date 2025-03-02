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
          content: data.systemPrompt
        },
        {
          role: 'user',
          content: `Journal Entry: ${data.journalEntry}\nLast Period Date: ${data.lastPeriodDate}\nCurrent Date: ${data.currentDate}`
        }
      ],
      temperature: 0.7,
      max_tokens: 1000,
      top_p: 1,
      frequency_penalty: 0,
      presence_penalty: 0
    });

    console.log('OpenAI response received:', completion.choices[0].message);
    
    const jsonResponse = JSON.parse(completion.choices[0].message.content ?? '{}');
    return jsonResponse;
  } catch (error) {
    console.error('Detailed error:', error);
    throw new functions.https.HttpsError('internal', `Failed to get recommendations: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}); 