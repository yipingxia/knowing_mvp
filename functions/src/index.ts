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

    const systemPrompt = `You are a menstrual health expert and data analyst. Analyze the user's journal entry to:
    1. Extract structured data about their day
    2. Calculate their current menstrual phase
    3. Provide recommendations

    IMPORTANT: Your response must be a valid JSON object with this exact structure:
    {
      "parsed_data": {
        "period_state": {
          "is_active": boolean,
          "flow": "none" | "light" | "medium" | "heavy",
          "spotting": boolean
        },
        "symptoms": {
          "physical": ["symptom1", "symptom2"],  // Extract mentioned physical symptoms
          "emotional": ["mood1", "mood2"]        // Extract emotional states
        },
        "lifestyle": {
          "sleep": {
            "mentioned": boolean,
            "quality": "poor" | "fair" | "good" | null,
            "hours": number | null
          },
          "food": {
            "meals": ["meal1", "meal2"],         // Extract mentioned foods
            "cravings": ["craving1", "craving2"],
            "hydration_mentioned": boolean
          },
          "exercise": {
            "mentioned": boolean,
            "type": ["activity1", "activity2"],
            "duration_minutes": number | null
          }
        }
      },
      "cycle_analysis": {
        "current_phase": "Menstrual" | "Follicular" | "Ovulatory" | "Luteal",
        "days_since_last_period": number,
        "keywords": ["keyword1", "keyword2", "keyword3"],
        "poetic_message": string
      },
      "recommendations": {
        "exercise": ["pointer1", "pointer2", "pointer3"],
        "nutrition": ["pointer1", "pointer2", "pointer3"],
        "emotional_wellbeing": ["pointer1", "pointer2", "pointer3"],
        "symptoms_management": ["pointer1", "pointer2", "pointer3"]
      }
    }

    Extract data conservatively - only include information explicitly mentioned in the journal entry. Use null or empty arrays for data not mentioned.`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: systemPrompt
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
    
    // Parse the response and restructure it
    const aiResponse = JSON.parse(completion.choices[0].message.content ?? '{}');
    
    // Restructure to match our expected format
    const response = {
      parsed_data: {
        period_state: {
          is_active: aiResponse.current_phase === "Menstrual",
          flow: "none",  // This should be extracted from the journal
          spotting: false  // This should be extracted from the journal
        },
        symptoms: {
          physical: aiResponse.keywords.filter((k: string) => k.includes("pain") || k.includes("cramps")),
          emotional: aiResponse.keywords.filter((k: string) => k.includes("mood") || k.includes("feeling"))
        },
        lifestyle: {
          sleep: {
            mentioned: false,
            quality: null,
            hours: null
          },
          food: {
            meals: [],
            cravings: [],
            hydration_mentioned: false
          },
          exercise: {
            mentioned: false,
            type: [],
            duration_minutes: null
          }
        }
      },
      cycle_analysis: {
        current_phase: aiResponse.current_phase,
        days_since_last_period: aiResponse.days_since_last_period,
        keywords: aiResponse.keywords,
        poetic_message: aiResponse.poetic_message
      },
      recommendations: aiResponse.recommendations
    };

    console.log('Structured response:', response);
    return response;
  } catch (error) {
    console.error('Detailed error:', error);
    throw new functions.https.HttpsError('internal', `Failed to get recommendations: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}); 