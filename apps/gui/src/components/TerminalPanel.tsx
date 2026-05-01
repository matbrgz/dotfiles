import React, { useState } from 'react';
import { ChevronUp, ChevronDown, Copy, Check } from 'lucide-react';

interface TerminalPanelProps {
  logs: string[];
  scrollRef: React.RefObject<HTMLDivElement>;
}

export const TerminalPanel: React.FC<TerminalPanelProps> = ({ logs, scrollRef }) => {
  const [collapsed, setCollapsed] = useState(false);
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(logs.join('\n'));
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      height: collapsed ? 36 : 140,
      background: 'var(--color-surface)',
      borderTop: '1px solid var(--color-border)',
      display: 'flex', flexDirection: 'column',
      transition: 'height 0.2s ease',
      zIndex: 30,
    }}>
      {/* Toolbar */}
      <div style={{
        height: 36, flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '0 14px',
        borderBottom: collapsed ? 'none' : '1px solid var(--color-border)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--color-green)', boxShadow: '0 0 4px rgba(52,211,153,0.5)' }} />
          <span style={{ fontSize: 10, color: 'var(--color-text-3)', fontWeight: 500 }}>
            Log — {logs.length} lines
          </span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <button
            onClick={handleCopy}
            style={{
              display: 'flex', alignItems: 'center', gap: 4, padding: '3px 8px',
              borderRadius: 4, border: '1px solid var(--color-border)',
              background: 'transparent', color: copied ? 'var(--color-green)' : 'var(--color-text-3)',
              fontSize: 10, fontFamily: 'inherit', cursor: 'pointer',
            }}
          >
            {copied ? <Check size={10} /> : <Copy size={10} />}
            {copied ? 'Copied' : 'Copy'}
          </button>
          <button
            onClick={() => setCollapsed(c => !c)}
            style={{
              display: 'flex', alignItems: 'center', padding: '3px 6px',
              borderRadius: 4, border: '1px solid var(--color-border)',
              background: 'transparent', color: 'var(--color-text-3)',
              fontSize: 10, fontFamily: 'inherit', cursor: 'pointer',
            }}
          >
            {collapsed ? <ChevronUp size={12} /> : <ChevronDown size={12} />}
          </button>
        </div>
      </div>

      {/* Log content */}
      {!collapsed && (
        <div ref={scrollRef} style={{ flex: 1, overflowY: 'auto', padding: '8px 14px', fontFamily: 'inherit' }}>
          {logs.map((log, i) => (
            <div key={i} style={{ display: 'flex', gap: 12, lineHeight: 1.6 }}>
              <span style={{ fontSize: 10, color: 'var(--color-text-3)', flexShrink: 0, userSelect: 'none', minWidth: 32 }}>
                {String(i + 1).padStart(3, ' ')}
              </span>
              <span style={{
                fontSize: 10,
                color: log.includes('[ERR]') ? 'var(--color-red)'
                     : log.includes('installed') || log.includes('synced') || log.includes('saved') ? 'var(--color-green)'
                     : log.includes('Scanning') || log.includes('Syncing') || log.includes('Installing') || log.includes('Saving') ? 'var(--color-amber)'
                     : 'var(--color-text-2)',
              }}>
                {log}
              </span>
            </div>
          ))}
          <div style={{ display: 'flex', gap: 12 }}>
            <span style={{ fontSize: 10, color: 'var(--color-text-3)', minWidth: 32 }}>{String(logs.length + 1).padStart(3, ' ')}</span>
            <span style={{ fontSize: 10, color: 'var(--color-green)', animation: 'blink 1.2s ease infinite' }}>▍</span>
          </div>
        </div>
      )}

      <style>{`@keyframes blink { 0%,100%{opacity:1} 50%{opacity:0} }`}</style>
    </div>
  );
};
