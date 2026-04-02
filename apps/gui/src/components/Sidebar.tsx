import React from 'react';
import { LucideIcon } from 'lucide-react';

interface SidebarProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
  tabs: { id: string; label: string; icon: LucideIcon }[];
}

export const Sidebar: React.FC<SidebarProps> = ({ activeTab, onTabChange, tabs }) => {
  return (
    <aside className="w-16 flex flex-col items-center py-8 border-r border-zinc-900 bg-black/40 z-20">
      <div className="mb-12 p-2 bg-cyan-500 text-black shadow-[0_0_15px_rgba(34,211,238,0.3)]">
        <div className="w-6 h-6 border-2 border-black flex items-center justify-center font-black">D</div>
      </div>
      
      <nav className="flex-1 flex flex-col gap-8 text-[10px] font-black uppercase tracking-tighter">
        {tabs.map((tab) => (
          <button 
            key={tab.id}
            onClick={() => onTabChange(tab.id)} 
            className={`${activeTab === tab.id ? 'text-cyan-400' : 'text-zinc-600'} hover:text-cyan-400 transition-all flex flex-col items-center gap-1 group`}
          >
            <tab.icon className={`w-5 h-5 ${activeTab === tab.id ? 'drop-shadow-[0_0_5px_rgba(34,211,238,0.5)]' : ''}`} />
            <span className="opacity-0 group-hover:opacity-100 transition-opacity">{tab.label}</span>
          </button>
        ))}
      </nav>

      <div className="text-[10px] font-black text-zinc-800 rotate-180 [writing-mode:vertical-lr] uppercase tracking-[0.3em] mb-4">
        Universal Dotfiles v1.0
      </div>
    </aside>
  );
};
