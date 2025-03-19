import * as functions from 'firebase-functions';
import OpenAI from 'openai';
import * as dotenv from 'dotenv';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.GCLOUD_PROJECT,
  });
}

// Load environment variables for local development
dotenv.config();

// Set the region for all functions
const region = functions.region('asia-southeast1');

// Add a version identifier
const VERSION = '1.0.4'; // increment this when you deploy

// Define the interface for our request data
interface RecommendationRequest {
  systemPrompt: string;
  journalEntry: string;
  lastPeriodDate: string;
  currentDate: string;
}

interface NutritionRequest {
  nutritionText: string;
  systemPrompt: string;
  exerciseText?: string;  // Optional field for exercise information
  date: string;  // Add date field to nutrition request
}

// Helper function to format date as YYYY-MM-DD
function formatDate(date: string): string {
  try {
    // Handle different date formats
    let dateObj: Date;
    if (date.includes('T')) {
      // If date is in ISO format
      dateObj = new Date(date);
    } else if (date.includes('-')) {
      // If date is already in YYYY-MM-DD format
      return date;
    } else {
      // If date is in a different format (e.g., "YYYY-MM-DD HH:mm:ss.SSS")
      dateObj = new Date(date.split(' ')[0]);
    }

    if (isNaN(dateObj.getTime())) {
      throw new Error('Invalid date');
    }

    return dateObj.toISOString().split('T')[0];
  } catch (error) {
    console.error('Error formatting date:', error);
    // Return today's date as fallback
    return new Date().toISOString().split('T')[0];
  }
}

// Helper function to update or create daily entry
async function updateDailyEntry(date: string, data: any) {
  const formattedDate = formatDate(date);
  console.log('Formatting date:', date, 'to:', formattedDate);
  const dailyRef = admin.firestore().collection('dailyEntries').doc(formattedDate);

  try {
    await admin.firestore().runTransaction(async (transaction) => {
      const doc = await transaction.get(dailyRef);
      if (!doc.exists) {
        // For new documents, set initial data
        transaction.set(dailyRef, {
          ...data,
          createdAt: admin.firestore.FieldValue?.serverTimestamp?.() || new Date().toISOString(),
          updatedAt: admin.firestore.FieldValue?.serverTimestamp?.() || new Date().toISOString()
        });
      } else {
        // For existing documents, merge with existing data
        const existingData = doc.data() || {};
        transaction.update(dailyRef, {
          ...existingData,
          ...data,
          updatedAt: admin.firestore.FieldValue?.serverTimestamp?.() || new Date().toISOString()
        });
      }
    });
    console.log('Successfully updated daily entry for:', formattedDate);
  } catch (error) {
    console.error('Error updating daily entry:', error);
    // Don't throw error, just log it
  }
}

// Specify the region explicitly
export const analyzeNutrition = region
  .https.onCall(async (data: NutritionRequest, context) => {
  console.log('Function called with data:', JSON.stringify(data, null, 2));
  console.log('Function called with auth:', context.auth);
  
  try {
    console.log(`Analyzing nutrition content...`);
    
    // Ensure we have a valid date
    const date = data.date || new Date().toISOString();
    console.log('Using date:', date);

    // Handle empty or "none" inputs
    if (data.nutritionText.toLowerCase() === 'none' && (!data.exerciseText || data.exerciseText.toLowerCase() === 'none')) {
      const defaultResponse = {
        fiber: 0,
        protein: 0,
        bodyStressLevel: null
      };

      // Store the default analysis
      await updateDailyEntry(date, {
        nutrition: {
          ...defaultResponse,
          nutritionText: data.nutritionText,
          exerciseText: data.exerciseText || null,
          userId: context.auth?.uid || 'anonymous',
          isDefault: true
        }
      });
      
      return defaultResponse;
    }

    let apiKey: string | undefined;
    
    try {
      apiKey = functions.config().openai?.key;
      console.log('Firebase config key available:', Boolean(apiKey));
    } catch (e) {
      console.log('Error getting Firebase config:', e);
    }

    if (!apiKey) {
      apiKey = process.env.OPENAI_API_KEY;
      console.log('Falling back to env var, available:', Boolean(apiKey));
    }

    if (!apiKey) {
      console.error('No API key found in any configuration');
      throw new Error('OpenAI API key not found in any configuration');
    }

    console.log('API Key available:', Boolean(apiKey));
    console.log('API Key starts with:', apiKey.substring(0, 7));

    const openai = new OpenAI({
      apiKey: apiKey
    });

    // Default system prompt if none provided
    const systemPrompt = data.systemPrompt || `You are a nutrition and exercise analyzer. Analyze the text and extract information about nutrition and exercise intensity.

IMPORTANT: You must return ONLY a JSON object with NO additional text. The response must follow this exact format:
{
  "fiber": number,  // Fiber content in grams
  "protein": number, // Protein content in grams
  "bodyStressLevel": number | null  // Scale of 1-10, where 1 is very light and 10 is extremely intense. Null if no exercise mentioned.
}`;

    console.log('Making OpenAI API call with prompt:', systemPrompt);
    console.log('User content:', `${data.nutritionText}${data.exerciseText ? '\nExercise: ' + data.exerciseText : ''}`);

    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: systemPrompt
        },
        {
          role: 'user',
          content: `${data.nutritionText}${data.exerciseText ? '\nExercise: ' + data.exerciseText : ''}`
        }
      ],
      temperature: 0.7,
      max_tokens: 100
    });

    console.log('Raw OpenAI response:', JSON.stringify(completion, null, 2));
    
    const messageContent = completion.choices[0].message.content;
    if (!messageContent) {
      console.error('OpenAI returned empty response');
      throw new Error('OpenAI returned empty response');
    }

    try {
      // Parse the content string into JSON
      console.log('About to parse message content:', messageContent);
      let parsedContent;
      try {
        parsedContent = JSON.parse(messageContent);
      } catch (parseError) {
        console.error('Failed to parse OpenAI response:', parseError);
        console.error('Invalid message content:', messageContent);
        parsedContent = {
          fiber: 0,
          protein: 0,
          bodyStressLevel: null
        };
      }
      
      // Validate and sanitize the response format
      const response = {
        fiber: typeof parsedContent.fiber === 'number' ? parsedContent.fiber : 0,
        protein: typeof parsedContent.protein === 'number' ? parsedContent.protein : 0,
        bodyStressLevel: typeof parsedContent.bodyStressLevel === 'number' ? parsedContent.bodyStressLevel : null
      };

      // Store the analysis
      await updateDailyEntry(date, {
        nutrition: {
          ...response,
          nutritionText: data.nutritionText,
          exerciseText: data.exerciseText || null,
          userId: context.auth?.uid || 'anonymous',
          isDefault: false
        }
      });

      console.log('Successfully parsed and validated response:', response);
      return response;
    } catch (e) {
      console.error('Error in analysis:', e);
      throw new functions.https.HttpsError('internal', 'Failed to process analysis');
    }
  } catch (e: any) {
    console.error('Error in nutrition analysis:', e);
    console.error('Stack trace:', e.stack);
    throw new functions.https.HttpsError(
      'internal',
      `Failed to analyze nutrition: ${e.message || 'Unknown error'}`,
      { details: e.stack }
    );
  }
});

export const getRecommendations = region
  .https.onCall(async (data: RecommendationRequest, context) => {
  try {
    console.log(`Function version ${VERSION} called`);
    
    // Format the date consistently using formatDate
    const date = formatDate(data.currentDate);
    console.log('Using date:', date);

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
      
      // Store recommendations
      await updateDailyEntry(date, {
        recommendations: {
          ...parsedContent,
          journalEntry: data.journalEntry,
          userId: context.auth?.uid || 'anonymous',
          lastPeriodDate: data.lastPeriodDate
        }
      });

      return parsedContent;
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