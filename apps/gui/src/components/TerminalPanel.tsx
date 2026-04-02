import React, { useState } from 'react';
import { Terminal as TerminalIcon, Copy, Check } from 'lucide-react';

interface TerminalPanelProps {
  logs: string[];
  scrollRef: React.RefObject<HTMLDivElement>;
}

export const TerminalPanel: React.FC<TerminalPanelProps> = ({ logs, scrollRef }) => {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    const text = logs.join('\n');
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <footer className="absolute bottom-0 left-0 right-0 h-56 bg-black border-t border-zinc-900 flex flex-col z-30 shadow-[0_-20px_50px_rgba(0,0,0,0.5)]">
      <div className="h-8 border-b border-zinc-900 px-4 flex items-center justify-between bg-zinc-950">
        <div className="flex items-center gap-2">
          <TerminalIcon className="w-3.5 h-3.5 text-cyan-500" />
          <span className="text-[10px] font-black text-cyan-500 uppercase tracking-[0.2em]">Live_Telemetry_Feed</span>
        </div>
        <div className="flex gap-4 items-center">
          <button 
            onClick={handleCopy}
            className={`flex items-center gap-1.5 px-2 py-0.5 border text-[9px] font-black uppercase tracking-widest transition-all
              ${copied ? 'bg-green-500/20 border-green-500 text-green-400' : 'bg-zinc-900 border-zinc-800 text-zinc-500 hover:border-cyan-500/50 hover:text-cyan-400'}`}
          >
            {copied ? <Check className="w-3 h-3" /> : <Copy className="w-3 h-3" />}
            {copied ? 'BUFFER_COPIED' : 'COPY_BUFFER'}
          </button>
          <div className="h-4 w-px bg-zinc-800 mx-1"></div>
          <div className="flex gap-1.5 items-center">
            <div className="w-1.5 h-1.5 bg-green-500 rounded-full animate-pulse shadow-[0_0_5px_#22c55e]"></div>
            <span className="text-[9px] text-green-500 font-bold uppercase tracking-widest">Uplink_Active</span>
          </div>
        </div>
      </div>
      <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 font-mono text-[11px] leading-relaxed bg-[#020202] custom-scrollbar">
        {logs.map((log, i) => (
          <div key={i} className="flex gap-4 group hover:bg-zinc-900/30 px-2 py-0.5 transition-colors">
            <span className="text-zinc-800 font-bold shrink-0 select-none">{String(i + 1).padStart(4, '0')}</span>
            <span className={`
              ${log.includes('ERROR') || log.includes('FAILURE') ? 'text-red-500 font-bold' : ''}
              ${log.includes('SUCCESS') ? 'text-green-400 font-bold' : ''}
              ${log.includes('INITIATING') || log.includes('SYNCING') || log.includes('PERSISTING') ? 'text-yellow-400 font-bold' : ''}
              ${!log.includes('ERROR') && !log.includes('FAILURE') && !log.includes('SUCCESS') && !log.includes('INITIATING') && !log.includes('SYNCING') && !log.includes('PERSISTING') ? 'text-zinc-500' : ''}
            `}>
              {log}
            </span>
          </div>
        ))}
        <div className="flex gap-4 px-2 py-0.5">
          <span className="text-zinc-800 font-bold shrink-0">{String(logs.length + 1).padStart(4, '0')}</span>
          <span className="text-cyan-500 animate-pulse">_</span>
        </div>
      </div>
    </footer>
  );
};
