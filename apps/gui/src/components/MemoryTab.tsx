import React, { useState, useEffect, useCallback } from 'react';
import { guiCommands, type MemoryInfo, type ProcInfo } from '@dotfiles/gui-engine';

type SortKey = 'memory' | 'cpu' | 'uptime';
type FilterKey = 'all' | 'idle' | 'zombie';

function formatMB(mb: number): string {
  if (mb < 1024) return `${mb.toFixed(0)} MB`;
  return `${(mb / 1024).toFixed(1)} GB`;
}

function formatElapsed(secs: number): string {
  if (secs < 60) return `${secs}s`;
  if (secs < 3600) {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return s > 0 ? `${m}m ${s}s` : `${m}m`;
  }
  if (secs < 86400) {
    const h = Math.floor(secs / 3600);
    const m = Math.floor((secs % 3600) / 60);
    return m > 0 ? `${h}h ${m}m` : `${h}h`;
  }
  const d = Math.floor(secs / 86400);
  const h = Math.floor((secs % 86400) / 3600);
  return h > 0 ? `${d}d ${h}h` : `${d}d`;
}

function procStatusLabel(status: string): { label: string; color: string } {
  const s = status.charAt(0).toUpperCase();
  if (s === 'Z') return { label: 'zombie', color: '#ef4444' };
  if (s === 'R') return { label: 'running', color: '#22c55e' };
  if (s === 'D') return { label: 'disk wait', color: '#f59e0b' };
  return { label: 'sleeping', color: '#6b7280' };
}

function isIdleHog(p: ProcInfo): boolean {
  const s = p.status.charAt(0).toUpperCase();
  return (s === 'S' || s === 'I') && p.cpu_pct < 0.5 && p.memory_mb > 200 && p.elapsed_secs > 3600;
}

function isZombie(p: ProcInfo): boolean {
  return p.status.charAt(0).toUpperCase() === 'Z';
}

export const MemoryTab: React.FC = () => {
  const [memInfo, setMemInfo] = useState<MemoryInfo | null>(null);
  const [procs, setProcs] = useState<ProcInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [killing, setKilling] = useState<Record<number, boolean>>({});
  const [confirmKill, setConfirmKill] = useState<number | null>(null);
  const [sortBy, setSortBy] = useState<SortKey>('memory');
  const [filter, setFilter] = useState<FilterKey>('all');

  const refresh = useCallback(async () => {
    try {
      const [mem, ps] = await Promise.all([
        guiCommands.getMemoryInfo(),
        guiCommands.getTopProcesses(50),
      ]);
      setMemInfo(mem);
      setProcs(ps);
    } catch (e) {
      console.error('Memory fetch error:', e);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh();
    const interval = setInterval(refresh, 5000);
    return () => clearInterval(interval);
  }, [refresh]);

  const handleKill = async (pid: number) => {
    if (confirmKill !== pid) {
      setConfirmKill(pid);
      setTimeout(() => setConfirmKill(null), 3000);
      return;
    }
    setConfirmKill(null);
    setKilling(prev => ({ ...prev, [pid]: true }));
    try {
      await guiCommands.killProcess(pid);
      await refresh();
    } catch (e) {
      console.error('Kill error:', e);
    } finally {
      setKilling(prev => ({ ...prev, [pid]: false }));
    }
  };

  if (loading && !memInfo) {
    return (
      <div className="flex items-center justify-center h-full">
        <span className="text-xs text-muted-foreground">Loading memory info...</span>
      </div>
    );
  }

  const mem = memInfo ?? { total_mb: 0, used_mb: 0, available_mb: 0, inactive_mb: 0, wired_mb: 0 };
  const totalMb = mem.total_mb || 1;
  const usedPct = Math.min(100, (mem.used_mb / totalMb) * 100);
  const wiredPct = Math.min(100, (mem.wired_mb / totalMb) * 100);
  const inactivePct = Math.min(100, (mem.inactive_mb / totalMb) * 100);

  const filtered = procs.filter(p => {
    if (filter === 'idle') return isIdleHog(p);
    if (filter === 'zombie') return isZombie(p);
    return true;
  });

  const sorted = [...filtered].sort((a, b) => {
    if (sortBy === 'memory') return b.memory_mb - a.memory_mb;
    if (sortBy === 'cpu') return b.cpu_pct - a.cpu_pct;
    return b.elapsed_secs - a.elapsed_secs;
  });

  const idleCount = procs.filter(isIdleHog).length;
  const zombieCount = procs.filter(isZombie).length;

  return (
    <div className="p-6 pb-10 space-y-4">

      {/* RAM Usage */}
      <div className="rounded-xl border border-border bg-card p-5">
        <div className="flex items-baseline justify-between mb-4">
          <span className="text-sm font-bold text-foreground">RAM Usage</span>
          <span className="text-xs text-muted-foreground">{formatMB(mem.total_mb)} total</span>
        </div>

        <div className="h-4 rounded-full overflow-hidden bg-muted border border-border flex mb-4">
          <div className="bg-blue-500 transition-[width] duration-300 ease-out" style={{ width: `${usedPct}%` }} />
          <div className="bg-red-500/70 transition-[width] duration-300 ease-out" style={{ width: `${wiredPct}%` }} />
          <div className="bg-amber-500/50 transition-[width] duration-300 ease-out" style={{ width: `${inactivePct}%` }} />
        </div>

        <div className="flex gap-6 flex-wrap">
          <MemStat label="Used" value={formatMB(mem.used_mb)} color="bg-blue-500" />
          <MemStat label="Wired" value={formatMB(mem.wired_mb)} color="bg-red-500" />
          <MemStat label="Inactive" value={formatMB(mem.inactive_mb)} color="bg-amber-500" />
          <MemStat label="Available" value={formatMB(mem.available_mb)} color="bg-emerald-500" />
        </div>
      </div>

      {/* Process list */}
      <div className="rounded-xl border border-border bg-card overflow-hidden">

        {/* Header row */}
        <div className="flex items-center justify-between px-5 py-3 border-b border-border">
          <span className="text-xs font-bold text-foreground">Processes</span>
          <button
            onClick={refresh}
            className="text-xs text-muted-foreground hover:text-foreground px-3 py-1.5 rounded-md border border-border hover:bg-accent transition-colors"
          >
            ↻ Refresh
          </button>
        </div>

        {/* Sort + filter bar */}
        <div className="flex items-center gap-4 px-5 py-2.5 border-b border-border bg-muted/30">
          {/* Sort tabs */}
          <div className="flex items-center gap-1">
            <span className="text-[10px] text-muted-foreground mr-1 uppercase tracking-wide">Sort</span>
            {(['memory', 'cpu', 'uptime'] as SortKey[]).map(k => (
              <button
                key={k}
                onClick={() => setSortBy(k)}
                className={`text-[10px] px-2.5 py-1 rounded-md font-medium transition-colors ${
                  sortBy === k
                    ? 'bg-primary text-primary-foreground'
                    : 'text-muted-foreground hover:text-foreground hover:bg-accent'
                }`}
              >
                {k.charAt(0).toUpperCase() + k.slice(1)}
              </button>
            ))}
          </div>

          <div className="h-4 w-px bg-border" />

          {/* Filter pills */}
          <div className="flex items-center gap-1">
            <FilterPill active={filter === 'all'} onClick={() => setFilter('all')}>All ({procs.length})</FilterPill>
            {idleCount > 0 && (
              <FilterPill active={filter === 'idle'} onClick={() => setFilter('idle')} warn>
                Idle hogs ({idleCount})
              </FilterPill>
            )}
            {zombieCount > 0 && (
              <FilterPill active={filter === 'zombie'} onClick={() => setFilter('zombie')} danger>
                Zombies ({zombieCount})
              </FilterPill>
            )}
          </div>
        </div>

        {/* Table header */}
        <div className="grid grid-cols-[1fr_56px_80px_56px_72px_64px] px-5 py-2 border-b border-border bg-background/50">
          {['Name', 'PID', 'Memory', 'CPU', 'Uptime', 'Kill'].map(h => (
            <span key={h} className="text-[9px] font-bold text-muted-foreground uppercase tracking-widest">{h}</span>
          ))}
        </div>

        {sorted.length === 0 && (
          <div className="py-8 text-center text-xs text-muted-foreground">
            {filter === 'idle' ? 'No idle hogs detected' : filter === 'zombie' ? 'No zombie processes' : 'No process data available'}
          </div>
        )}

        <div className="max-h-[420px] overflow-y-auto">
          {sorted.map(proc => {
            const isKilling = killing[proc.pid];
            const isConfirming = confirmKill === proc.pid;
            const idle = isIdleHog(proc);
            const zombie = isZombie(proc);
            const { label: statusLabel, color: statusColor } = procStatusLabel(proc.status);
            return (
              <div
                key={proc.pid}
                className={`grid grid-cols-[1fr_56px_80px_56px_72px_64px] px-5 py-2.5 border-b border-border/50 items-center transition-colors ${
                  zombie ? 'bg-red-500/5' : idle ? 'bg-amber-500/5' : 'hover:bg-muted/30'
                }`}
              >
                <div className="flex items-center gap-2 min-w-0">
                  <span className="text-[11px] font-medium text-foreground truncate">{proc.name}</span>
                  {(idle || zombie) && (
                    <span
                      className="text-[9px] font-semibold px-1.5 py-0.5 rounded shrink-0"
                      style={{ background: zombie ? 'rgba(239,68,68,0.15)' : 'rgba(245,158,11,0.15)', color: zombie ? '#ef4444' : '#f59e0b' }}
                    >
                      {zombie ? 'zombie' : 'idle'}
                    </span>
                  )}
                </div>

                <span className="text-[10px] text-muted-foreground">{proc.pid}</span>

                <span className={`text-[11px] font-semibold ${
                  proc.memory_mb > 1024 ? 'text-red-400' : proc.memory_mb > 256 ? 'text-amber-400' : 'text-muted-foreground'
                }`}>
                  {proc.memory_mb >= 1024
                    ? `${(proc.memory_mb / 1024).toFixed(1)} GB`
                    : `${proc.memory_mb.toFixed(0)} MB`}
                </span>

                <span className={`text-[10px] font-medium ${proc.cpu_pct > 10 ? 'text-amber-400' : 'text-muted-foreground'}`}>
                  {proc.cpu_pct.toFixed(1)}%
                </span>

                <div className="flex flex-col gap-0.5">
                  <span className="text-[10px] text-muted-foreground font-mono">{formatElapsed(proc.elapsed_secs)}</span>
                  <span className="text-[9px]" style={{ color: statusColor }}>{statusLabel}</span>
                </div>

                <button
                  onClick={() => handleKill(proc.pid)}
                  disabled={isKilling}
                  className={`text-[10px] font-semibold px-2.5 py-1 rounded-md border transition-all ${
                    isConfirming
                      ? 'border-red-400/50 bg-red-500/20 text-red-400'
                      : 'border-red-400/25 bg-red-500/8 text-red-400 hover:bg-red-500/15 hover:border-red-400/40'
                  } disabled:opacity-50 disabled:cursor-not-allowed`}
                >
                  {isKilling ? '…' : isConfirming ? 'Sure?' : '✕ Kill'}
                </button>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

function MemStat({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <div className="flex items-center gap-2">
      <div className={`w-2 h-2 rounded-sm shrink-0 ${color}`} />
      <span className="text-[10px] text-muted-foreground">{label}:</span>
      <span className="text-[11px] font-semibold text-foreground">{value}</span>
    </div>
  );
}

function FilterPill({ children, active, onClick, warn, danger }: {
  children: React.ReactNode;
  active: boolean;
  onClick: () => void;
  warn?: boolean;
  danger?: boolean;
}) {
  return (
    <button
      onClick={onClick}
      className={`text-[10px] px-2.5 py-1 rounded-full font-medium border transition-colors ${
        active
          ? danger ? 'bg-red-500/20 border-red-400/40 text-red-400'
            : warn ? 'bg-amber-500/20 border-amber-400/40 text-amber-400'
            : 'bg-primary text-primary-foreground border-transparent'
          : 'border-border text-muted-foreground hover:text-foreground hover:bg-accent'
      }`}
    >
      {children}
    </button>
  );
}
