cat >> setup_aurelius.sh << 'EOF'
# 4. Components
cat > src/index.tsx << 'INNEREOF'
import React from 'react'; import ReactDOM from 'react-dom/client'; import App from './App'; import './index.css';
ReactDOM.createRoot(document.getElementById('root')!).render(<React.StrictMode><App /></React.StrictMode>);
INNEREOF
touch src/index.css

cat > src/components/QuoteCard.tsx << 'INNEREOF'
import React, { useState } from 'react';
import { Quote } from '../types';
import { RefreshCw, Share2, Check } from 'lucide-react';
export default function QuoteCard({quote, isLoading, onRefresh}: any) {
  const [c, setC] = useState(false);
  const share = async () => {
    if(!quote) return;
    const txt = `"${quote.text}"\n\n${quote.interpretation}`;
    if(navigator.share) { try { await navigator.share({text: txt}); return; } catch(e){} }
    await navigator.clipboard.writeText(txt); setC(true); setTimeout(()=>setC(false), 2000);
  };
  return (
    <div className="flex flex-col items-center justify-center h-full w-full max-w-md mx-auto p-6 pt-10">
      <div className="w-full bg-stone-900 border border-stone-800 p-8 rounded-lg relative min-h-[450px] flex flex-col justify-between">
        <div className="text-center mb-4"><h2 className="text-gold-600 text-xs tracking-[0.3em] font-bold">IMPERATOR</h2></div>
        <div className="flex-grow flex flex-col items-center justify-center my-2 space-y-8">
          {isLoading ? <div className="animate-pulse text-stone-600">Consulting the Stoics...</div> : (
            <>
              <p className="text-stone-200 font-serif text-xl italic text-center">{quote ? quote.text : "Tap refresh."}</p>
              {quote?.interpretation && <div className="pt-6 border-t border-stone-800/50"><p className="text-[10px] text-stone-600 uppercase tracking-widest text-center mb-2">Translation</p><p className="text-stone-400 text-sm text-center">{quote.interpretation}</p></div>}
            </>
          )}
        </div>
        <div className="flex justify-center gap-6 mt-6">
          <button onClick={onRefresh} className="p-3 rounded-full bg-stone-800 hover:text-gold-500"><RefreshCw size={18} className={isLoading?'animate-spin':''} /></button>
          <button onClick={share} className="p-3 rounded-full bg-stone-800 hover:text-gold-500">{c?<Check size={18}/>:<Share2 size={18}/>}</button>
        </div>
      </div>
    </div>
  );
}
INNEREOF

cat > src/components/Navigation.tsx << 'INNEREOF'
import React from 'react'; import { AppView } from '../types'; import { BookOpen, MapPin, Clock } from 'lucide-react';
export default function Navigation({currentView, onChangeView}: any) {
  const cls = (v:any) => `flex flex-col items-center ${currentView===v?'text-gold-500':'text-stone-600'}`;
  return (
    <div className="fixed bottom-0 w-full h-16 bg-stone-950 border-t border-stone-800 pb-safe flex justify-around items-center z-50">
      <button onClick={()=>onChangeView(AppView.SCHEDULES)} className={cls(AppView.SCHEDULES)}><Clock size={20}/><span className="text-[10px]">Time</span></button>
      <button onClick={()=>onChangeView(AppView.HOME)} className={cls(AppView.HOME)}><BookOpen size={24}/></button>
      <button onClick={()=>onChangeView(AppView.LANDMARKS)} className={cls(AppView.LANDMARKS)}><MapPin size={20}/><span className="text-[10px]">Place</span></button>
    </div>
  );
}
INNEREOF

cat > src/components/LandmarkManager.tsx << 'INNEREOF'
import React, { useState } from 'react'; import { MapPin, Plus, Search, Trash2 } from 'lucide-react'; import { getCurrentPosition } from '../utils/geo'; import { findPlaceCoordinates } from '../services/gemini';
export default function LandmarkManager({landmarks, onAddLandmark, onRemoveLandmark}: any) {
  const [q, setQ] = useState(''); const [curr, setCurr] = useState<any>(null); const [name, setName] = useState('');
  const loc = async () => { try { const c = await getCurrentPosition(); setCurr(c); setName('Current Location'); } catch(e){} };
  const search = async () => { const r = await findPlaceCoordinates(q); if(r) { setCurr(r); setName(r.name); } };
  return (
    <div className="p-6 pb-24 overflow-auto h-full">
      <h2 className="text-xl font-serif text-stone-200 mb-4">Landmarks</h2>
      <div className="bg-stone-900 p-4 rounded mb-6 space-y-2">
        <div className="flex gap-2"><input value={q} onChange={e=>setQ(e.target.value)} className="bg-stone-950 border border-stone-800 text-sm p-2 flex-1 rounded" placeholder="Search place..." /><button onClick={search} className="p-2 bg-stone-800 rounded"><Search size={16}/></button></div>
        <button onClick={loc} className="text-[10px] text-gold-500 uppercase">Use GPS</button>
        {curr && <div className="mt-2"><input value={name} onChange={e=>setName(e.target.value)} className="bg-transparent border-b border-gold-500 w-full mb-2 text-gold-500"/><button onClick={()=>{onAddLandmark({id:crypto.randomUUID(), name, coords:curr, radius:100}); setCurr(null);}} className="w-full bg-gold-600 text-black py-2 rounded text-xs font-bold">ADD</button></div>}
      </div>
      <div className="space-y-2">{landmarks.map((l:any)=><div key={l.id} className="p-3 border border-stone-800 rounded flex justify-between"><div className="text-sm">{l.name}</div><button onClick={()=>onRemoveLandmark(l.id)}><Trash2 size={14}/></button></div>)}</div>
    </div>
  );
}
INNEREOF

cat > src/components/ScheduleManager.tsx << 'INNEREOF'
import React, { useState } from 'react'; import { Clock, Plus, Trash2 } from 'lucide-react'; import { requestNotificationPermission } from '../services/notifications';
export default function ScheduleManager({schedules, onAddSchedule, onRemoveSchedule}: any) {
  const [t, setT] = useState(''); const [l, setL] = useState('');
  return (
    <div className="p-6 pb-24 overflow-auto h-full">
      <h2 className="text-xl font-serif text-stone-200 mb-4">Schedule</h2>
      <button onClick={requestNotificationPermission} className="text-xs bg-stone-900 p-2 rounded mb-4 w-full border border-stone-800 text-gold-500">Enable Notifications</button>
      <div className="bg-stone-900 p-4 rounded mb-6 flex gap-2"><input type="time" value={t} onChange={e=>setT(e.target.value)} className="bg-stone-950 border border-stone-800 rounded p-2 text-white"/><input value={l} onChange={e=>setL(e.target.value)} placeholder="Label" className="bg-stone-950 border border-stone-800 rounded p-2 flex-1"/><button onClick={()=>{if(t&&l){onAddSchedule({id:crypto.randomUUID(), time:t, label:l, lastTriggeredDate:null}); setT(''); setL('');}}} className="bg-stone-800 p-2 rounded"><Plus size={16}/></button></div>
      <div className="space-y-2">{schedules.map((s:any)=><div key={s.id} className="p-3 border border-stone-800 rounded flex justify-between"><div className="text-sm">{s.time} - {s.label}</div><button onClick={()=>onRemoveSchedule(s.id)}><Trash2 size={14}/></button></div>)}</div>
    </div>
  );
}
INNEREOF

# 5. Server
cat > server.js << 'INNEREOF'
import express from 'express'; import path from 'path'; import { fileURLToPath } from 'url'; import dotenv from 'dotenv'; import { GoogleGenAI } from "@google/genai";
dotenv.config();
const app = express(); const PORT = 3333; const API_KEY = process.env.API_KEY;
const __dirname = path.dirname(fileURLToPath(import.meta.url));
app.use(express.json()); app.use(express.static(path.join(__dirname, 'dist')));
app.post('/api/quote', async (req, res) => {
  try {
    const ai = new GoogleGenAI({ apiKey: API_KEY });
    const prompt = `Quote from Marcus Aurelius relevant to: ${req.body.context || 'life'}. Return JSON: {"quote": "text", "interpretation": "blunt modern explanation"}`;
    const r = await ai.models.generateContent({ model: 'gemini-2.5-flash', contents: prompt, config: { responseMimeType: "application/json", temperature: 0.9 } });
    res.json(JSON.parse(r.text));
  } catch (e) { res.json({quote:"Power over mind.", interpretation:"Focus."}); }
});
app.post('/api/place', async (req, res) => {
  try {
    const ai = new GoogleGenAI({ apiKey: API_KEY });
    const r = await ai.models.generateContent({ model: 'gemini-2.5-flash', contents: `Coords for "${req.body.query}". JSON: {"name":"","latitude":0,"longitude":0}`, config: { responseMimeType: "application/json" } });
    res.json(JSON.parse(r.text));
  } catch (e) { res.status(404).send(); }
});
app.get('*', (req, res) => res.sendFile(path.join(__dirname, 'dist', 'index.html')));
app.listen(PORT, () => console.log(`Server on ${PORT}`));
INNEREOF

# 6. Install & Build
echo "Installing dependencies..."
npm install
echo "Building..."
npm run build
echo "Starting..."
pm2 start server.js --name "aurelius"
echo "Done! Runs on port 3333."
EOF