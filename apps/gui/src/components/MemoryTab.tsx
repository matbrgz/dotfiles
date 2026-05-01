import React, { useState, useEffect, useCallback } from 'react';
import { guiCommands, type MemoryInfo, type ProcInfo } from '@dotfiles/gui-engine';

function formatMB(mb: number): string {
  if (mb < 1024) return `${mb} MB`;
  return `${(mb / 1024).toFixed(1)} GB`;
}

export const MemoryTab: React.FC = () => {
  const [memInfo, setMemInfo] = useState<MemoryInfo | null>(null);
  const [procs, setProcs] = useState<ProcInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [killing, setKilling] = useState<Record<number, boolean>>({});
  const [confirmKill, setConfirmKill] = useState<number | null>(null);

  const refresh = useCallback(async () => {
    try {
      const [mem, ps] = await Promise.all([
        guiCommands.getMemoryInfo(),
        guiCommands.getTopProcesses(20),
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
    const interval = setInterval(refresh, 3000);
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
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' }}>
        <span style={{ fontSize: 11, color: 'var(--color-text-3)' }}>Loading memory info...</span>
      </div>
    );
  }

  const mem = memInfo ?? { total_mb: 0, used_mb: 0, available_mb: 0, inactive_mb: 0, wired_mb: 0 };
  const totalMb = mem.total_mb || 1;

  const usedPct = Math.min(100, (mem.used_mb / totalMb) * 100);
  const wiredPct = Math.min(100, (mem.wired_mb / totalMb) * 100);
  const inactivePct = Math.min(100, (mem.inactive_mb / totalMb) * 100);
  const freePct = Math.max(0, 100 - usedPct - inactivePct);

  return (
    <div style={{ padding: '20px 24px 40px' }}>

      {/* RAM Usage */}
      <div style={{
        background: 'var(--color-surface)',
        border: '1px solid var(--color-border)',
        borderRadius: 10, padding: '20px 24px', marginBottom: 20,
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 16 }}>
          <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--color-text)' }}>RAM Usage</span>
          <span style={{ fontSize: 11, color: 'var(--color-text-3)' }}>{formatMB(mem.total_mb)} total</span>
        </div>

        {/* Bar */}
        <div style={{
          height: 20, borderRadius: 10, overflow: 'hidden',
          background: 'var(--color-surface-2)', border: '1px solid var(--color-border)',
          display: 'flex', marginBottom: 14,
        }}>
          <div style={{ width: `${usedPct}%`, background: 'var(--color-blue, #3b82f6)', transition: 'width 0.4s ease' }} />
          <div style={{ width: `${wiredPct}%`, background: 'var(--color-red, #ef4444)', opacity: 0.7, transition: 'width 0.4s ease' }} />
          <div style={{ width: `${inactivePct}%`, background: '#f59e0b', opacity: 0.5, transition: 'width 0.4s ease' }} />
          <div style={{ flex: freePct / 100, background: 'transparent' }} />
        </div>

        {/* Legend */}
        <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap' }}>
          <Stat label="Used" value={formatMB(mem.used_mb)} color="var(--color-blue, #3b82f6)" />
          <Stat label="Wired" value={formatMB(mem.wired_mb)} color="var(--color-red, #ef4444)" />
          <Stat label="Inactive" value={formatMB(mem.inactive_mb)} color="#f59e0b" />
          <Stat label="Available" value={formatMB(mem.available_mb)} color="var(--color-green)" />
        </div>
      </div>

      {/* Process list */}
      <div style={{
        background: 'var(--color-surface)',
        border: '1px solid var(--color-border)',
        borderRadius: 10, overflow: 'hidden',
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '14px 20px', borderBottom: '1px solid var(--color-border)',
        }}>
          <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--color-text)' }}>Top Processes by Memory</span>
          <button
            onClick={refresh}
            style={{
              display: 'flex', alignItems: 'center', gap: 5,
              padding: '5px 12px', borderRadius: 6,
              border: '1px solid var(--color-border)',
              background: 'transparent', color: 'var(--color-text-2)',
              fontSize: 11, fontFamily: 'inherit', cursor: 'pointer',
            }}
          >
            ↻ Refresh
          </button>
        </div>

        {/* Table header */}
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 80px 90px 70px 70px',
          padding: '8px 20px',
          borderBottom: '1px solid var(--color-border)',
          background: 'var(--color-bg)',
        }}>
          {['Name', 'PID', 'Memory', 'CPU', 'Kill'].map(h => (
            <span key={h} style={{ fontSize: 9, fontWeight: 700, color: 'var(--color-text-3)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>{h}</span>
          ))}
        </div>

        {procs.length === 0 && (
          <div style={{ padding: '20px', textAlign: 'center', fontSize: 11, color: 'var(--color-text-3)' }}>
            No process data available
          </div>
        )}

        {procs.map(proc => {
          const isKilling = killing[proc.pid];
          const isConfirming = confirmKill === proc.pid;
          return (
            <div
              key={proc.pid}
              style={{
                display: 'grid', gridTemplateColumns: '1fr 80px 90px 70px 70px',
                padding: '8px 20px',
                borderBottom: '1px solid var(--color-border)',
                alignItems: 'center',
              }}
            >
              <span style={{
                fontSize: 11, color: 'var(--color-text)', fontWeight: 500,
                overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
              }}>
                {proc.name}
              </span>
              <span style={{ fontSize: 10, color: 'var(--color-text-3)' }}>{proc.pid}</span>
              <span style={{
                fontSize: 11, fontWeight: 600,
                color: proc.memory_mb > 1024 ? 'var(--color-red)'
                  : proc.memory_mb > 256 ? 'var(--color-amber)'
                  : 'var(--color-text-2)',
              }}>
                {proc.memory_mb >= 1024
                  ? `${(proc.memory_mb / 1024).toFixed(1)} GB`
                  : `${proc.memory_mb.toFixed(0)} MB`}
              </span>
              <span style={{ fontSize: 10, color: 'var(--color-text-3)' }}>
                {proc.cpu_pct.toFixed(1)}%
              </span>
              <button
                onClick={() => handleKill(proc.pid)}
                disabled={isKilling}
                style={{
                  padding: '3px 10px', borderRadius: 5,
                  border: `1px solid ${isConfirming ? 'rgba(239,68,68,0.5)' : 'rgba(239,68,68,0.25)'}`,
                  background: isConfirming ? 'rgba(239,68,68,0.18)' : 'rgba(239,68,68,0.07)',
                  color: 'var(--color-red)',
                  fontSize: 10, fontWeight: 600, fontFamily: 'inherit',
                  cursor: isKilling ? 'not-allowed' : 'pointer',
                  transition: 'all 0.15s ease',
                }}
              >
                {isKilling ? '...' : isConfirming ? 'Sure?' : '✕'}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
};

function Stat({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
      <div style={{ width: 8, height: 8, borderRadius: 2, background: color, flexShrink: 0 }} />
      <span style={{ fontSize: 10, color: 'var(--color-text-3)' }}>{label}:</span>
      <span style={{ fontSize: 11, fontWeight: 600, color: 'var(--color-text)' }}>{value}</span>
    </div>
  );
}
