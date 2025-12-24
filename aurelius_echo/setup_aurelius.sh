#!/bin/bash
set -e

# 1. Setup Directories
echo "Creating project structure..."
mkdir -p aurelius_app/src/components
mkdir -p aurelius_app/src/services
mkdir -p aurelius_app/src/utils
cd aurelius_app

# 2. Configuration Files
echo "Writing config files..."

cat > package.json << 'INNEREOF'
{
  "name": "aurelius-echo",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "start": "node server.js"
  },
  "dependencies": {
    "@google/genai": "^0.1.1",
    "dotenv": "^16.4.5",
    "express": "^4.18.2",
    "lucide-react": "^0.344.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/react": "^18.2.64",
    "@types/react-dom": "^18.2.21",
    "@vitejs/plugin-react": "^4.2.1",
    "autoprefixer": "^10.4.18",
    "postcss": "^8.4.35",
    "tailwindcss": "^3.4.1",
    "typescript": "^5.4.2",
    "vite": "^5.1.6"
  }
}
INNEREOF

cat > tsconfig.json << 'INNEREOF'
{
  "compilerOptions": {
    "target": "ES2020", "useDefineForClassFields": true, "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext", "skipLibCheck": true, "moduleResolution": "bundler",
    "allowImportingTsExtensions": true, "resolveJsonModule": true, "isolatedModules": true,
    "noEmit": true, "jsx": "react-jsx", "strict": true, "noUnusedLocals": false,
    "noUnusedParameters": false, "noFallthroughCasesInSwitch": true
  },
  "include": ["src/**/*.ts", "src/**/*.tsx"], "exclude": ["node_modules"]
}
INNEREOF

cat > vite.config.ts << 'INNEREOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig({
  plugins: [react()],
  define: { 'process.env.API_KEY': JSON.stringify(process.env.API_KEY) },
});
INNEREOF

cat > index.html << 'INNEREOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <title>Aurelius Echo</title>
    <link rel="manifest" href="/manifest.json">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
      tailwind.config = {
        theme: {
          extend: {
            fontFamily: { serif: ['Georgia', 'serif'], sans: ['"Inter"', 'sans-serif'] },
            colors: { stone: { 800: '#292524', 900: '#1c1917', 950: '#0c0a09' }, gold: { 500: '#d4af37', 600: '#b08d26' } }
          }
        }
      }
    </script>
    <style>body { background-color: #0c0a09; color: #e7e5e4; -webkit-font-smoothing: antialiased; } .pb-safe { padding-bottom: env(safe-area-inset-bottom); }</style>
  </head>
  <body><div id="root"></div><script type="module" src="/src/index.tsx"></script></body>
</html>
INNEREOF

cat > manifest.json << 'INNEREOF'
{
  "name": "Aurelius Echo", "short_name": "Aurelius", "start_url": "/", "display": "standalone",
  "background_color": "#0c0a09", "theme_color": "#0c0a09", "orientation": "portrait",
  "icons": [ { "src": "https://api.iconify.design/lucide:book-open.svg?color=%23d4af37", "sizes": "192x192", "type": "image/svg+xml" } ]
}
INNEREOF

# 3. Source Code
echo "Writing source code..."

cat > src/types.ts << 'INNEREOF'
export interface Coordinates { latitude: number; longitude: number; }
export interface Landmark { id: string; name: string; coords: Coordinates; radius: number; lastTriggered: number | null; }
export interface Schedule { id: string; time: string; label: string; lastTriggeredDate: string | null; }
export interface Quote { text: string; interpretation: string; context: string; timestamp: number; }
export enum AppView { HOME = 'HOME', LANDMARKS = 'LANDMARKS', SCHEDULES = 'SCHEDULES' }
INNEREOF

cat > src/utils/geo.ts << 'INNEREOF'
import { Coordinates } from '../types';
export const getDistanceInMeters = (coord1: Coordinates, coord2: Coordinates): number => {
  const R = 6371e3; const lat1 = (coord1.latitude * Math.PI)/180; const lat2 = (coord2.latitude * Math.PI)/180;
  const dLat = ((coord2.latitude-coord1.latitude)*Math.PI)/180; const dLon = ((coord2.longitude-coord1.longitude)*Math.PI)/180;
  const a = Math.sin(dLat/2)*Math.sin(dLat/2) + Math.cos(lat1)*Math.cos(lat2)*Math.sin(dLon/2)*Math.sin(dLon/2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
};
export const getCurrentPosition = (): Promise<Coordinates> => {
  return new Promise((res, rej) => { navigator.geolocation ? navigator.geolocation.getCurrentPosition(p => res({latitude: p.coords.latitude, longitude: p.coords.longitude}), rej) : rej(new Error("No Geo")); });
};
INNEREOF

cat > src/services/notifications.ts << 'INNEREOF'
export const requestNotificationPermission = async () => {
  if (!('Notification' in window)) return false;
  return (await Notification.requestPermission()) === 'granted';
};
export const getNotificationPermissionState = () => ('Notification' in window) ? Notification.permission : 'denied';
export const sendNotification = (title: string, body: string) => {
  if ('Notification' in window && Notification.permission === 'granted') {
    new Notification(title, { body, tag: 'aurelius-quote', silent: false });
  }
};
INNEREOF

cat > src/services/gemini.ts << 'INNEREOF'
export const fetchStoicQuote = async (context?: string) => {
  try {
    const res = await fetch('/api/quote', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify({context}) });
    if (!res.ok) throw new Error("Backend unreachable");
    return await res.json();
  } catch (e) {
    return { quote: "You have power over your mind - not outside events.", interpretation: "Focus on your own head." };
  }
};
export const findPlaceCoordinates = async (query: string) => {
  try {
    const res = await fetch('/api/place', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify({query}) });
    if (!res.ok) throw new Error("Backend unreachable");
    return await res.json();
  } catch (e) { return null; }
};
INNEREOF

cat > src/App.tsx << 'INNEREOF'
import React, { useState, useEffect, useCallback } from 'react';
import { AppView, Quote, Landmark, Schedule } from './types';
import { fetchStoicQuote } from './services/gemini';
import { getDistanceInMeters } from './utils/geo';
import { sendNotification } from './services/notifications';
import QuoteCard from './components/QuoteCard';
import LandmarkManager from './components/LandmarkManager';
import ScheduleManager from './components/ScheduleManager';
import Navigation from './components/Navigation';

export default function App() {
  const [view, setView] = useState<AppView>(AppView.HOME);
  const [quote, setQuote] = useState<Quote|null>(null);
  const [loading, setLoading] = useState(false);
  const [landmarks, setLandmarks] = useState<Landmark[]>(() => JSON.parse(localStorage.getItem('aurelius_landmarks')||'[]'));
  const [schedules, setSchedules] = useState<Schedule[]>(() => JSON.parse(localStorage.getItem('aurelius_schedules')||'[]'));

  useEffect(() => { localStorage.setItem('aurelius_landmarks', JSON.stringify(landmarks)); }, [landmarks]);
  useEffect(() => { localStorage.setItem('aurelius_schedules', JSON.stringify(schedules)); }, [schedules]);

  const getQuote = useCallback(async (ctx: string = 'General', force=false, notify=false) => {
    setLoading(true);
    const {quote: q, interpretation: i} = await fetchStoicQuote(ctx);
    setQuote({text: q, interpretation: i, context: ctx, timestamp: Date.now()});
    if(force) setView(AppView.HOME);
    if(notify) sendNotification("Aurelius Echo", q);
    setLoading(false);
  }, []);

  useEffect(() => { if(!quote) getQuote("opening app"); }, []);

  useEffect(() => {
    if(!navigator.geolocation) return;
    const id = navigator.geolocation.watchPosition(pos => {
      const now = Date.now();
      const coords = {latitude: pos.coords.latitude, longitude: pos.coords.longitude};
      const updated = landmarks.map(l => {
        if(getDistanceInMeters(coords, l.coords) <= l.radius && (!l.lastTriggered || now - l.lastTriggered > 3600000)) {
          getQuote(`arriving at ${l.name}`, true, true);
          return {...l, lastTriggered: now};
        }
        return l;
      });
      if(JSON.stringify(updated) !== JSON.stringify(landmarks)) setLandmarks(updated);
    });
    return () => navigator.geolocation.clearWatch(id);
  }, [landmarks, getQuote]);

  useEffect(() => {
    const i = setInterval(() => {
      const now = new Date();
      const timeStr = now.toLocaleTimeString('en-US', {hour12:false, hour:'2-digit', minute:'2-digit'});
      const dateStr = now.toISOString().split('T')[0];
      let trig = false;
      const updated = schedules.map(s => {
        if(s.time === timeStr && s.lastTriggeredDate !== dateStr) {
          getQuote(`it is ${s.label}`, true, true);
          trig = true;
          return {...s, lastTriggeredDate: dateStr};
        }
        return s;
      });
      if(trig) setSchedules(updated);
    }, 10000);
    return () => clearInterval(i);
  }, [schedules, getQuote]);

  return (
    <div className="bg-stone-950 min-h-screen text-stone-200 flex flex-col pb-20">
      {view === AppView.HOME && <QuoteCard quote={quote} isLoading={loading} onRefresh={() => getQuote("seeking wisdom")} />}
      {view === AppView.LANDMARKS && <LandmarkManager landmarks={landmarks} onAddLandmark={l=>setLandmarks([...landmarks,l])} onRemoveLandmark={id=>setLandmarks(landmarks.filter(l=>l.id!==id))} />}
      {view === AppView.SCHEDULES && <ScheduleManager schedules={schedules} onAddSchedule={s=>setSchedules([...schedules,s])} onRemoveSchedule={id=>setSchedules(schedules.filter(s=>s.id!==id))} />}
      <Navigation currentView={view} onChangeView={setView} />
    </div>
  );
}
INNEREOF

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
