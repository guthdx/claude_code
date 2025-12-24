cat >> setup_aurelius.sh << 'EOF'
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
EOF