import React from 'react';
import { type DotfileManifest } from '@dotfiles/schema';
import { FileCode, ArrowRight } from 'lucide-react';

interface EnvironmentTabProps {
  dotfiles: Record<string, DotfileManifest>;
  onApply: () => void;
}

export const EnvironmentTab: React.FC<EnvironmentTabProps> = ({ dotfiles, onApply }) => {
  return (
    <div className="flex-1 overflow-y-auto p-8 pb-64 custom-scrollbar">
      <div className="mb-8 max-w-3xl">
        <h2 className="text-lg font-black text-white uppercase tracking-tight mb-2">Dotfiles_Repository</h2>
        <p className="text-xs text-zinc-500 font-bold uppercase tracking-wider">Sync local environment with centralized configurations.</p>
      </div>
      
      <div className="grid grid-cols-1 gap-4 max-w-4xl">
        {Object.entries(dotfiles).map(([id, dot]) => (
          <div key={id} className="bg-zinc-950/50 border border-zinc-900 p-6 flex items-center justify-between group hover:border-cyan-500/20 transition-all">
            <div className="flex items-center gap-6">
              <div className="p-3 bg-zinc-900 border border-zinc-800 text-zinc-500 group-hover:text-cyan-400 transition-colors">
                <FileCode className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-sm font-black text-white uppercase tracking-wider">{dot.name}</h3>
                <p className="text-[10px] text-zinc-600 font-bold uppercase mt-1">{dot.description}</p>
                <div className="flex items-center gap-2 mt-3 text-[9px] font-bold text-zinc-700">
                  <span className="bg-zinc-900 px-2 py-0.5 rounded uppercase">{dot.type}</span>
                  <ArrowRight className="w-2 h-2" />
                  <span className="font-mono text-zinc-500">{dot.target || 'N/A'}</span>
                </div>
              </div>
            </div>
            <button 
              onClick={onApply}
              className="px-6 py-2 border border-zinc-800 text-[10px] font-black uppercase tracking-[0.2em] text-zinc-500 hover:border-cyan-500 hover:text-cyan-400 transition-all"
            >
              Apply
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};
