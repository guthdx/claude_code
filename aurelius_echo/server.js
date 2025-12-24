import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import { GoogleGenerativeAI } from "@google/generative-ai";

// Load environment variables
dotenv.config();

const app = express();
// Default to 3333 to avoid conflicts with standard React/Node ports (3000) or n8n (5678)
const PORT = process.env.PORT || 3333;
const API_KEY = process.env.API_KEY;

// ESM fix for __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Middleware
app.use(express.json());
app.use(express.static(path.join(__dirname, 'dist')));

// -- API Routes --

// 1. Get Quote
app.post('/api/quote', async (req, res) => {
  try {
    if (!API_KEY) {
      throw new Error("Server missing API_KEY");
    }

    const ai = new GoogleGenerativeAI(API_KEY);
    const { context, previousQuotes = [] } = req.body;

    let promptContext = "";
    if (context) {
      promptContext = `The user is currently ${context}. The quote should be specifically relevant to this situation.`;
    } else {
      promptContext = "The quote should be general wisdom for daily life.";
    }

    // Enhanced variety generators
    const books = 12;
    const randomBook = Math.floor(Math.random() * books) + 1;
    const style = Math.random() > 0.7 ? "a lesser known, deep cut" : "a powerful, essential";

    // Add thematic variation
    const themes = [
      "mortality and the fleeting nature of life",
      "dealing with adversity and hardship",
      "duty and responsibility",
      "virtue and character",
      "managing anger and emotions",
      "relationships with others",
      "the natural order of things",
      "focus and attention",
      "accepting what you cannot control",
      "gratitude and appreciation",
      "self-discipline and willpower",
      "work and productivity",
      "dealing with difficult people",
      "fear and courage",
      "simplicity and minimalism"
    ];
    const randomTheme = themes[Math.floor(Math.random() * themes.length)];

    // Build previous quotes avoidance text
    let avoidanceText = "";
    if (previousQuotes.length > 0) {
      const recentQuotes = previousQuotes.slice(-10).map(q => q.substring(0, 50)).join('", "');
      avoidanceText = `\n   - IMPORTANT: Avoid using these recent quotes: "${recentQuotes}..."\n   - Choose a completely different passage.`;
    }

    const prompt = `
      I need two things based on the works of Marcus Aurelius (Meditations):
      1. A quote from Marcus Aurelius. ${promptContext}
         - Specifically look for ${style} quote from Book ${randomBook} of Meditations.
         - The quote should relate to the theme of: ${randomTheme}
         - Ensure it is a valid translation.${avoidanceText}
      2. A direct, modern interpretation of what that quote actually means for a modern human.
         - This interpretation should be honest and straightforward, but not overly harsh.
         - Be real and authentic, but avoid being unnecessarily snarky.
         - Focus on practical wisdom rather than trying to shock.
         - Keep it conversational and relatable.

      Return a JSON object with these keys:
      - "quote": The text of the quote.
      - "interpretation": The modern interpretation.
    `;

    const model = ai.getGenerativeModel({
      model: 'gemini-2.0-flash-exp',
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.9,
      },
      systemInstruction: "You are a thoughtful guide helping people understand Marcus Aurelius's wisdom in practical, modern terms.",
    });

    const result = await model.generateContent(prompt);
    const text = result.response.text();

    if (text) {
      let parsed = JSON.parse(text);
      // Normalize response - sometimes Gemini returns an array instead of object
      if (Array.isArray(parsed) && parsed.length > 0) {
        parsed = parsed[0];
      }
      res.json(parsed);
    } else {
      throw new Error("No text returned from AI");
    }

  } catch (error) {
    console.error("API Error:", error);
    // Fallback response so the app doesn't crash
    res.status(500).json({
      quote: "You have power over your mind - not outside events. Realize this, and you will find strength.",
      interpretation: "Stop freaking out about things you can't change. Focus on your own head."
    });
  }
});

// 2. Find Place
app.post('/api/place', async (req, res) => {
  try {
    if (!API_KEY) {
      throw new Error("Server missing API_KEY");
    }
    
    const ai = new GoogleGenerativeAI(API_KEY);
    const { query } = req.body;

    const prompt = `I need the approximate coordinates for a place matching this description: "${query}". 
    Return a JSON object with:
    - "name": A short, clean name for the place.
    - "latitude": The latitude as a number.
    - "longitude": The longitude as a number.
    If ambiguous, guess.`;

    const model = ai.getGenerativeModel({
      model: 'gemini-2.0-flash-exp',
      generationConfig: {
        responseMimeType: "application/json",
      }
    });

    const result = await model.generateContent(prompt);
    const text = result.response.text();

    if (text) {
      res.json(JSON.parse(text));
    } else {
      res.status(404).json({ error: "Not found" });
    }

  } catch (error) {
    console.error("API Error:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// -- Catch-all handler serves React app --
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});