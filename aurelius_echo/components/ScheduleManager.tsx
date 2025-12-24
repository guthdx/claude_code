
import React, { useState, useEffect } from 'react';
import { Schedule } from '../types';
import { Clock, Trash2, Plus, Sun, Sunset, Moon, Bell, BellOff, CheckCircle } from 'lucide-react';
import { requestNotificationPermission, getNotificationPermissionState } from '../services/notifications';

interface ScheduleManagerProps {
  schedules: Schedule[];
  onAddSchedule: (schedule: Schedule) => void;
  onRemoveSchedule: (id: string) => void;
}

const ScheduleManager: React.FC<ScheduleManagerProps> = ({ schedules, onAddSchedule, onRemoveSchedule }) => {
  const [time, setTime] = useState('');
  const [label, setLabel] = useState('');
  const [permissionState, setPermissionState] = useState<NotificationPermission>('default');

  useEffect(() => {
    setPermissionState(getNotificationPermissionState());
  }, []);

  const handleRequestPermission = async () => {
    const granted = await requestNotificationPermission();
    setPermissionState(granted ? 'granted' : 'denied');
  };

  const handleAdd = () => {
    if (time && label.trim()) {
      const newSchedule: Schedule = {
        id: crypto.randomUUID(),
        time,
        label: label.trim(),
        lastTriggeredDate: null
      };
      onAddSchedule(newSchedule);
      setTime('');
      setLabel('');
    }
  };

  const quickAdd = (presetTime: string, presetLabel: string) => {
     setTime(presetTime);
     setLabel(presetLabel);
  }

  return (
    <div className="p-6 w-full max-w-md mx-auto h-full overflow-y-auto no-scrollbar pb-24">
      <div className="mb-8">
        <h2 className="text-xl font-serif text-stone-200 mb-2">Daily Reflections</h2>
        <p className="text-stone-500 text-sm">Schedule moments for wisdom throughout your day.</p>
      </div>

      {/* Notification Permission Banner */}
      {permissionState !== 'granted' && (
        <div className={`mb-6 rounded-lg p-4 border flex items-center justify-between ${
            permissionState === 'denied' 
            ? 'bg-red-900/20 border-red-900/50' 
            : 'bg-stone-900 border-stone-800'
        }`}>
            <div className="flex items-center gap-3">
                {permissionState === 'denied' ? <BellOff size={18} className="text-red-500"/> : <Bell size={18} className="text-gold-500"/>}
                <div className="text-xs text-stone-300">
                    {permissionState === 'denied' 
                        ? 'Notifications blocked. Check iPhone settings.' 
                        : 'Enable notifications to receive quotes.'}
                </div>
            </div>
            {permissionState === 'default' && (
                <button 
                    onClick={handleRequestPermission}
                    className="text-[10px] uppercase font-bold bg-gold-600 text-stone-950 px-3 py-1.5 rounded hover:bg-gold-500 transition-colors"
                >
                    Enable
                </button>
            )}
        </div>
      )}

      {/* Add New Section */}
      <div className="bg-stone-900 border border-stone-800 rounded-lg p-4 mb-6 space-y-4 shadow-lg">
        
        {/* Quick Presets */}
        <div className="flex justify-between gap-2 mb-2">
            <button onClick={() => quickAdd('08:00', 'Morning Reflection')} className="flex-1 bg-stone-950 border border-stone-800 p-2 rounded flex flex-col items-center gap-1 hover:border-gold-600/50 transition-colors">
                <Sun size={14} className="text-gold-500"/>
                <span className="text-[10px] text-stone-400">Morning</span>
            </button>
            <button onClick={() => quickAdd('12:00', 'Midday Pause')} className="flex-1 bg-stone-950 border border-stone-800 p-2 rounded flex flex-col items-center gap-1 hover:border-gold-600/50 transition-colors">
                <Sun size={14} className="text-orange-400"/>
                <span className="text-[10px] text-stone-400">Noon</span>
            </button>
            <button onClick={() => quickAdd('20:00', 'Evening Review')} className="flex-1 bg-stone-950 border border-stone-800 p-2 rounded flex flex-col items-center gap-1 hover:border-gold-600/50 transition-colors">
                <Moon size={14} className="text-indigo-400"/>
                <span className="text-[10px] text-stone-400">Night</span>
            </button>
        </div>

        <div className="flex gap-2">
             <input 
                type="time" 
                value={time}
                onChange={(e) => setTime(e.target.value)}
                className="bg-stone-950 border border-stone-800 text-stone-200 text-sm rounded px-3 py-2 focus:outline-none focus:border-gold-600 [color-scheme:dark]"
            />
            <input 
                type="text" 
                placeholder="Label (e.g. Morning)"
                value={label}
                onChange={(e) => setLabel(e.target.value)}
                className="flex-1 bg-stone-950 border border-stone-800 text-stone-200 text-sm rounded px-3 py-2 focus:outline-none focus:border-gold-600"
            />
        </div>
        
        <button 
            onClick={handleAdd}
            disabled={!time || !label.trim()}
            className="w-full bg-stone-800 text-gold-500 p-2 rounded border border-stone-700 disabled:opacity-50 disabled:cursor-not-allowed hover:bg-stone-700 flex items-center justify-center gap-2"
        >
            <Plus size={16} /> Add Schedule
        </button>
      </div>

      {/* List Section */}
      <div className="space-y-3">
        {schedules.length === 0 ? (
            <div className="text-center py-10 border border-dashed border-stone-800 rounded-lg opacity-50">
                <Clock size={24} className="mx-auto text-stone-700 mb-2" />
                <p className="text-stone-600 text-xs">No times scheduled.</p>
            </div>
        ) : (
            schedules.map(s => (
                <div key={s.id} className="bg-stone-900/50 border border-stone-800/50 rounded-lg p-4 flex items-center justify-between group">
                    <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-stone-800 flex items-center justify-center text-stone-400 group-hover:text-gold-500 transition-colors">
                            <Clock size={14} />
                        </div>
                        <div>
                            <h3 className="text-stone-300 text-sm font-medium">{s.time}</h3>
                            <p className="text-stone-600 text-[10px]">{s.label}</p>
                        </div>
                    </div>
                    <button 
                        onClick={() => onRemoveSchedule(s.id)}
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

export default ScheduleManager;
