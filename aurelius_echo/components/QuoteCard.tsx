import React, { useState } from 'react';
import { Quote } from '../types';
import { RefreshCw, Share2, Check } from 'lucide-react';

interface QuoteCardProps {
  quote: Quote | null;
  isLoading: boolean;
  onRefresh: () => void;
}

const QuoteCard: React.FC<QuoteCardProps> = ({ quote, isLoading, onRefresh }) => {
  const [isCopied, setIsCopied] = useState(false);

  const handleShare = async () => {
    if (!quote) return;
    const textToShare = `"${quote.text}" - Marcus Aurelius\n\nTranslation: ${quote.interpretation}`;

    // 1. Try Native Share (Works best on iPhone/Android)
    if (navigator.share) {
      try {
        await navigator.share({
          title: 'Aurelius Echo',
          text: textToShare,
        });
        return; // If share opened successfully, stop here
      } catch (err) {
        // User cancelled share or it failed, fall back to clipboard
        console.debug('Share cancelled or failed, falling back to clipboard');
      }
    }

    // 2. Fallback to Clipboard
    try {
      await navigator.clipboard.writeText(textToShare);
      setIsCopied(true);
      setTimeout(() => setIsCopied(false), 2000);
    } catch (err) {
      console.error("Failed to copy", err);
    }
  };

  return (
    <div className="flex flex-col items-center justify-center h-full w-full max-w-md mx-auto p-6">
      
      <div className="w-full bg-stone-900 border border-stone-800 p-8 rounded-lg shadow-2xl relative overflow-hidden min-h-[450px] flex flex-col justify-between">
        
        {/* Background decoration */}
        <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-stone-800 via-gold-600 to-stone-800 opacity-50"></div>
        <div className="absolute -right-10 -top-10 w-40 h-40 bg-stone-800 rounded-full opacity-10 blur-3xl"></div>
        
        {/* Header */}
        <div className="text-center mb-4">
            <h2 className="text-gold-600 text-xs tracking-[0.3em] uppercase font-bold mb-2">Imperator Caesar</h2>
            <h1 className="text-stone-400 text-sm tracking-widest uppercase">Marcus Aurelius</h1>
        </div>

        {/* Content */}
        <div className="flex-grow flex flex-col items-center justify-center my-2 space-y-8">
          {isLoading ? (
            <div className="animate-pulse space-y-4 w-full my-10">
              <div className="h-2 bg-stone-800 rounded w-3/4 mx-auto"></div>
              <div className="h-2 bg-stone-800 rounded w-5/6 mx-auto"></div>
              <div className="h-2 bg-stone-800 rounded w-2/3 mx-auto"></div>
            </div>
          ) : (
            <>
                <div className="relative z-10 w-full">
                    <span className="absolute -top-6 -left-2 text-5xl text-stone-800 font-serif opacity-50">“</span>
                    <p className="text-stone-200 font-serif text-xl leading-relaxed text-center italic px-2">
                        {quote ? quote.text : "Tap refresh to receive wisdom."}
                    </p>
                    <span className="absolute -bottom-8 -right-2 text-5xl text-stone-800 font-serif opacity-50">”</span>
                </div>

                {quote && quote.interpretation && (
                    <div className="w-full pt-6 border-t border-stone-800/50">
                        <p className="text-[10px] text-stone-600 uppercase tracking-widest font-bold text-center mb-2">Translation</p>
                        <p className="text-stone-400 font-sans text-sm font-medium leading-normal text-center">
                            {quote.interpretation}
                        </p>
                    </div>
                )}
            </>
          )}
        </div>

        {/* Footer / Actions */}
        <div className="mt-6 flex justify-center gap-6">
          <button 
            onClick={onRefresh}
            disabled={isLoading}
            className="group flex items-center justify-center w-12 h-12 rounded-full bg-stone-800 border border-stone-700 hover:border-gold-600 hover:text-gold-500 transition-all duration-300"
            aria-label="Refresh Quote"
          >
            <RefreshCw size={18} className={`text-stone-400 group-hover:text-gold-500 ${isLoading ? 'animate-spin' : ''}`} />
          </button>
          
          <button 
            onClick={handleShare}
            disabled={isLoading || !quote}
            className="group flex items-center justify-center w-12 h-12 rounded-full bg-stone-800 border border-stone-700 hover:border-gold-600 hover:text-gold-500 transition-all duration-300"
            aria-label="Share Quote"
          >
            {isCopied ? (
              <Check size={18} className="text-green-500" />
            ) : (
              <Share2 size={18} className="text-stone-400 group-hover:text-gold-500" />
            )}
          </button>
        </div>
        
      </div>
    </div>
  );
};

export default QuoteCard;