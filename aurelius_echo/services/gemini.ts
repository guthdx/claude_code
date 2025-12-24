
import { Coordinates } from '../types';

export const fetchStoicQuote = async (context?: string, previousQuotes: string[] = []): Promise<{ quote: string; interpretation: string }> => {
  try {
    const response = await fetch('/api/quote', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ context, previousQuotes }),
    });

    // Check if we got an HTML response (which happens in SPA previews for unknown routes)
    // or if the status is 404. This means the backend isn't running.
    const contentType = response.headers.get("content-type");
    if (!response.ok || (contentType && contentType.includes("text/html"))) {
      console.warn("Backend API unreachable (Preview Mode). Using offline fallback.");
      throw new Error("Backend unreachable");
    }

    const result = await response.json();
    return {
      quote: result.quote || "The best revenge is to be unlike him who performed the injury.",
      interpretation: result.interpretation || "Don't let them drag you down to their level."
    };

  } catch (error) {
    // Fallback for Preview Mode or Offline
    console.log("Using local fallback quote.");
    // Simulate network delay for realism in preview
    await new Promise(resolve => setTimeout(resolve, 800));
    
    return {
      quote: "You have power over your mind - not outside events. Realize this, and you will find strength.",
      interpretation: "Stop freaking out about things you can't change. Focus on your own head. (Preview Mode)"
    };
  }
};

export const findPlaceCoordinates = async (query: string): Promise<{ name: string; latitude: number; longitude: number } | null> => {
  try {
    const response = await fetch('/api/place', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ query }),
    });

    const contentType = response.headers.get("content-type");
    if (!response.ok || (contentType && contentType.includes("text/html"))) {
       throw new Error("Backend unreachable");
    }

    return await response.json();
  } catch (error) {
    console.error("Error finding place (Preview/Offline):", error);
    // Mock response for preview
    if (query.toLowerCase().includes("gym")) {
        return { name: "Local Gym (Preview)", latitude: 40.7128, longitude: -74.0060 };
    }
    return null;
  }
};
