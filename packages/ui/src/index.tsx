import React from 'react';
import { Terminal, Shield, Cpu, Box, CheckCircle2, AlertCircle } from 'lucide-react';

export interface CardProps {
  title: string;
  description: string;
  category: string;
  onAction: () => void;
  actionLabel: string;
  status?: 'ready' | 'installing' | 'success' | 'error';
}

export const ProgramCard: React.FC<CardProps> = ({ title, description, category, onAction, actionLabel, status = 'ready' }) => {
  const getIcon = () => {
    switch (category.toLowerCase()) {
      case 'development': return <Cpu className="w-4 h-4" />;
      case 'essential': return <Shield className="w-4 h-4" />;
      case 'devops': return <Box className="w-4 h-4" />;
      default: return <Terminal className="w-4 h-4" />;
    }
  };

  return (
    <div className="group relative bg-zinc-950/50 border border-cyan-500/20 p-5 hover:border-cyan-500/50 transition-all duration-300">
      {/* Blueprint Corner Accents */}
      <div className="absolute top-0 left-0 w-2 h-2 border-t border-l border-cyan-500/40"></div>
      <div className="absolute bottom-0 right-0 w-2 h-2 border-b border-r border-cyan-500/40"></div>

      <div className="flex justify-between items-start mb-4">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-cyan-500/10 border border-cyan-500/20 text-cyan-400">
            {getIcon()}
          </div>
          <div>
            <h2 className="text-lg font-black tracking-tight text-white uppercase">{title}</h2>
            <p className="text-[10px] text-cyan-500/60 font-bold uppercase tracking-widest leading-none">
              REF://{title.toLowerCase().replace(/\s/g, '_')}
            </p>
          </div>
        </div>
        <div className="px-2 py-0.5 bg-zinc-900 border border-zinc-800 text-[9px] font-black text-zinc-500 uppercase tracking-tighter">
          {category}
        </div>
      </div>

      <p className="text-zinc-400 text-xs mb-6 h-8 line-clamp-2 leading-relaxed">
        {description}
      </p>

      <button
        onClick={onAction}
        disabled={status === 'installing'}
        className={`w-full py-2.5 text-xs font-black uppercase tracking-[0.2em] border transition-all flex items-center justify-center gap-2
          ${status === 'installing' 
            ? 'bg-zinc-900 border-zinc-800 text-zinc-600 cursor-not-allowed' 
            : 'bg-white text-black border-white hover:bg-transparent hover:text-white'}`}
      >
        {status === 'installing' && <div className="w-3 h-3 border-2 border-zinc-600 border-t-white rounded-full animate-spin"></div>}
        {actionLabel}
      </button>

      {/* Telemetry Detail */}
      <div className="mt-4 pt-4 border-t border-zinc-900 flex justify-between items-center opacity-40 group-hover:opacity-100 transition-opacity">
        <div className="flex gap-2">
          <div className="w-1 h-3 bg-cyan-500/40"></div>
          <div className="w-1 h-3 bg-cyan-500/40"></div>
          <div className="w-1 h-3 bg-zinc-800"></div>
        </div>
        <span className="text-[8px] font-mono text-zinc-600 uppercase tracking-widest">
          ModuleStatus://{status.toUpperCase()}
        </span>
      </div>
    </div>
  );
};
