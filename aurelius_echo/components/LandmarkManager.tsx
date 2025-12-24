import React, { useState } from 'react';
import { Landmark, Coordinates } from '../types';
import { MapPin, Trash2, Plus, Navigation, Search, Loader2 } from 'lucide-react';
import { getCurrentPosition } from '../utils/geo';
import { findPlaceCoordinates } from '../services/gemini';

interface LandmarkManagerProps {
  landmarks: Landmark[];
  onAddLandmark: (landmark: Landmark) => void;
  onRemoveLandmark: (id: string) => void;
}

const LandmarkManager: React.FC<LandmarkManagerProps> = ({ landmarks, onAddLandmark, onRemoveLandmark }) => {
  const [isLocating, setIsLocating] = useState(false);
  const [isSearching, setIsSearching] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [currentCoords, setCurrentCoords] = useState<Coordinates | null>(null);
  const [foundName, setFoundName] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handleLocate = async () => {
    setIsLocating(true);
    setError(null);
    setSearchQuery(''); 
    try {
      const coords = await getCurrentPosition();
      setCurrentCoords(coords);
      setFoundName("Current Location");
    } catch (err) {
        console.error(err);
      setError("Could not fetch location. Ensure permissions are enabled.");
    } finally {
      setIsLocating(false);
    }
  };

  const handleSearch = async () => {
    if (!searchQuery.trim()) return;
    setIsSearching(true);
    setError(null);
    setCurrentCoords(null);
    
    try {
        const result = await findPlaceCoordinates(searchQuery);
        if (result) {
            setCurrentCoords({ latitude: result.latitude, longitude: result.longitude });
            setFoundName(result.name);
        } else {
            setError("Could not find a location matching that description.");
        }
    } catch (err) {
        setError("Search failed. Please try again.");
    } finally {
        setIsSearching(false);
    }
  };

  const handleAdd = () => {
    if (currentCoords && foundName) {
      const newLandmark: Landmark = {
        id: crypto.randomUUID(),
        name: foundName,
        coords: currentCoords,
        radius: 100, // default 100m radius
        lastTriggered: null
      };
      onAddLandmark(newLandmark);
      setSearchQuery('');
      setFoundName('');
      setCurrentCoords(null);
    }
  };

  return (
    <div className="p-6 w-full max-w-md mx-auto h-full overflow-y-auto no-scrollbar pb-24">
      <div className="mb-8">
        <h2 className="text-xl font-serif text-stone-200 mb-2">Stoic Landmarks</h2>
        <p className="text-stone-500 text-sm">Receive wisdom when you arrive at these locations.</p>
      </div>

      {/* Add New Section */}
      <div className="bg-stone-900 border border-stone-800 rounded-lg p-4 mb-6 space-y-4 shadow-lg">
        <div className="flex items-center justify-between border-b border-stone-800 pb-2">
             <span className="text-stone-400 text-xs font-medium uppercase tracking-wider">Add Location</span>
             <button 
                onClick={handleLocate}
                disabled={isLocating || isSearching}
                className="text-gold-500 text-[10px] uppercase tracking-wider hover:text-gold-400 disabled:opacity-50 flex items-center gap-1"
             >
                {isLocating ? <Loader2 size={10} className="animate-spin"/> : <Navigation size={10}/>}
                Locate Me
             </button>
        </div>

        <div className="flex gap-2">
            <input 
                type="text" 
                placeholder="Search place (e.g. 'Central Park')"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                className="flex-1 bg-stone-950 border border-stone-800 text-stone-200 text-sm rounded px-3 py-2 focus:outline-none focus:border-gold-600 placeholder-stone-700"
            />
            <button 
                onClick={handleSearch}
                disabled={isSearching || !searchQuery.trim()}
                className="bg-stone-800 text-stone-400 p-2 rounded border border-stone-700 disabled:opacity-50 hover:text-gold-500 hover:border-gold-600 transition-colors"
            >
                {isSearching ? <Loader2 size={18} className="animate-spin"/> : <Search size={18} />}
            </button>
        </div>

        {error && <p className="text-red-400 text-xs animate-pulse">{error}</p>}

        {currentCoords && (
            <div className="bg-stone-950 rounded p-3 border border-stone-800 animate-fade-in">
                <div className="flex justify-between items-center mb-2">
                    <input 
                        value={foundName}
                        onChange={(e) => setFoundName(e.target.value)}
                        className="bg-transparent text-gold-500 font-medium text-sm focus:outline-none border-b border-transparent focus:border-gold-600 w-full"
                    />
                </div>
                <div className="text-[10px] text-stone-600 font-mono mb-3">
                    {currentCoords.latitude.toFixed(4)}, {currentCoords.longitude.toFixed(4)}
                </div>
                <button 
                    onClick={handleAdd}
                    className="w-full bg-gold-600 text-stone-950 py-2 rounded text-xs font-bold uppercase tracking-widest hover:bg-gold-500 transition-colors flex items-center justify-center gap-2"
                >
                    <Plus size={14} /> Add Landmark
                </button>
            </div>
        )}
      </div>

      {/* List Section */}
      <div className="space-y-3">
        {landmarks.length === 0 ? (
            <div className="text-center py-10 border border-dashed border-stone-800 rounded-lg opacity-50">
                <MapPin size={24} className="mx-auto text-stone-700 mb-2" />
                <p className="text-stone-600 text-xs">No landmarks defined.</p>
            </div>
        ) : (
            landmarks.map(l => (
                <div key={l.id} className="bg-stone-900/50 border border-stone-800/50 rounded-lg p-4 flex items-center justify-between group hover:border-stone-700 transition-colors">
                    <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-stone-800 flex items-center justify-center text-stone-400 group-hover:text-gold-500 transition-colors">
                            <MapPin size={14} />
                        </div>
                        <div>
                            <h3 className="text-stone-300 text-sm font-medium">{l.name}</h3>
                            <p className="text-stone-600 text-[10px] font-mono">
                                {l.coords.latitude.toFixed(3)}, {l.coords.longitude.toFixed(3)}
                            </p>
                        </div>
                    </div>
                    <button 
                        onClick={() => onRemoveLandmark(l.id)}
                        className="text-stone-600 hover:text-red-400 transition-colors p-2 opacity-0 group-hover:opacity-100"
                    >
                        <Trash2 size={16} />
                    </button>
                </div>
            ))
        )}
      </div>
    </div>
  );
};

export default LandmarkManager;
