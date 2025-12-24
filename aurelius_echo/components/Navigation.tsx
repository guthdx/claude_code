import React from 'react';
import { AppView } from '../types';
import { BookOpen, MapPin, Clock } from 'lucide-react';

interface NavigationProps {
  currentView: AppView;
  onChangeView: (view: AppView) => void;
}

const Navigation: React.FC<NavigationProps> = ({ currentView, onChangeView }) => {
  
  const navItemClass = (view: AppView) => 
    `flex flex-col items-center justify-center w-full h-full space-y-1 transition-colors duration-200 ${
      currentView === view ? 'text-gold-500' : 'text-stone-600 hover:text-stone-400'
    }`;

  return (
    <div className="fixed bottom-0 left-0 w-full h-16 bg-stone-950 border-t border-stone-800 z-50 pb-safe">
      <div className="flex justify-around items-center h-full max-w-md mx-auto">
        
        <button onClick={() => onChangeView(AppView.SCHEDULES)} className={navItemClass(AppView.SCHEDULES)}>
          <Clock size={20} strokeWidth={currentView === AppView.SCHEDULES ? 2.5 : 2} />
          <span className="text-[10px] uppercase tracking-wider font-medium">Schedule</span>
        </button>

        <button onClick={() => onChangeView(AppView.HOME)} className={navItemClass(AppView.HOME)}>
          <div className={`p-2 rounded-full ${currentView === AppView.HOME ? 'bg-stone-900' : ''}`}>
             <BookOpen size={24} strokeWidth={currentView === AppView.HOME ? 2.5 : 2} />
          </div>
        </button>

        <button onClick={() => onChangeView(AppView.LANDMARKS)} className={navItemClass(AppView.LANDMARKS)}>
          <MapPin size={20} strokeWidth={currentView === AppView.LANDMARKS ? 2.5 : 2} />
          <span className="text-[10px] uppercase tracking-wider font-medium">Places</span>
        </button>

      </div>
    </div>
  );
};

export default Navigation;