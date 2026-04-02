import React from 'react';
import { Monitor, Cpu, Search, Zap } from 'lucide-react';

interface HeaderProps {
  osInfo: { os: string; platform: string };
  isApplying: boolean;
  onApplyDotfiles: () => void;
  searchQuery: string;
  onSearchChange: (query: string) => void;
  activeTab: string;
}

export const Header: React.FC<HeaderProps> = ({ 
  osInfo, isApplying, onApplyDotfiles, searchQuery, onSearchChange, activeTab 
}) => {
  return (
    <header className="h-20 border-b border-zinc-900 flex items-center justify-between px-8 bg-black/20 backdrop-blur-sm z-10">
      <div className="flex items-center gap-12">
        <div>
          <h1 className="text-xl font-black text-white tracking-tighter italic flex items-center gap-2 uppercase">
            CORE<span className="text-cyan-500">_MANIFEST</span>
          </h1>
          <p className="text-[9px] text-zinc-600 uppercase font-bold tracking-widest leading-none">
            {activeTab.replace('_', ' ')}
          </p>
        </div>

        <div className="flex gap-8">
          <div className="flex items-center gap-3">
            <Monitor className="w-4 h-4 text-zinc-700" />
            <div>
              <p className="text-[8px] text-zinc-600 uppercase font-bold">Host_OS</p>
              <p className="text-[10px] text-blue-400 font-bold uppercase tracking-wider">{osInfo.os}</p>
            </div>
          </div>
          <div className="flex items-center gap-3 border-l border-zinc-900 pl-8">
            <Cpu className="w-4 h-4 text-zinc-700" />
            <div>
              <p className="text-[8px] text-zinc-600 uppercase font-bold">Architecture</p>
              <p className="text-[10px] text-purple-400 font-bold uppercase tracking-wider">{osInfo.platform}</p>
            </div>
          </div>
        </div>
      </div>

      <div className="flex items-center gap-6">
        <button 
          onClick={onApplyDotfiles}
          disabled={isApplying}
          className={`flex items-center gap-2 px-4 py-2 border text-[10px] font-black uppercase tracking-widest transition-all
            ${isApplying 
              ? 'bg-zinc-900 border-zinc-800 text-zinc-600 animate-pulse' 
              : 'bg-cyan-500/10 border-cyan-500/40 text-cyan-400 hover:bg-cyan-500 hover:text-black'}`}
        >
          <Zap className={`w-3.5 h-3.5 ${isApplying ? '' : 'fill-current'}`} />
          {isApplying ? 'SYNCING...' : 'SYNC_DOTFILES'}
        </button>

        <div className="relative group">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-zinc-600" />
          <input 
            type="text" 
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder="SEARCH_MODULE..."
            className="bg-zinc-950 border border-zinc-900 py-2 pl-10 pr-4 text-[10px] text-cyan-500 placeholder:text-zinc-800 focus:outline-none focus:border-cyan-500/50 transition-all w-64 uppercase font-bold tracking-wider"
          />
        </div>
      </div>
    </header>
  );
};
