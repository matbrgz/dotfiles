import React from 'react';
import { type DotfileManifest } from '@dotfiles/schema';
import { Check, X, RefreshCw } from 'lucide-react';
import { useTranslation } from 'react-i18next';

interface EnvironmentTabProps {
  dotfiles: Record<string, DotfileManifest>;
  dotfileStatus: Record<string, boolean>;
  onApply: () => void;
  isApplying: boolean;
}

export const EnvironmentTab: React.FC<EnvironmentTabProps> = ({ dotfiles, dotfileStatus, onApply, isApplying }) => {
  const { t } = useTranslation('environment');
  const entries = Object.entries(dotfiles);
  const syncedCount = Object.values(dotfileStatus).filter(Boolean).length;

  return (
    <div style={{ padding: '20px 24px 40px' }}>
      {/* Summary bar */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: 20, padding: '12px 16px',
        background: 'var(--color-surface)', border: '1px solid var(--color-border)',
        borderRadius: 8,
      }}>
        <div style={{ display: 'flex', gap: 20 }}>
          <Stat label={t('statTotal')} value={entries.length} />
          <Stat label={t('statSynced')} value={syncedCount} color="green" />
          <Stat label={t('statMissing')} value={entries.length - syncedCount} color={entries.length - syncedCount > 0 ? 'red' : undefined} />
        </div>
        <button
          onClick={onApply}
          disabled={isApplying}
          style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '7px 16px', borderRadius: 6,
            border: '1px solid rgba(52,211,153,0.3)',
            background: 'var(--color-green-bg)',
            color: 'var(--color-green)',
            fontSize: 11, fontWeight: 600, fontFamily: 'inherit',
            cursor: isApplying ? 'not-allowed' : 'pointer',
          }}
        >
          <RefreshCw size={11} style={{ animation: isApplying ? 'spin 1s linear infinite' : 'none' }} />
          {t('btnSyncAll')}
        </button>
      </div>

      {/* Dotfile list */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {entries.map(([id, dot]) => {
          const synced = dotfileStatus[id] ?? false;
          const target = (dot as any).target;
          return (
            <div
              key={id}
              style={{
                display: 'flex', alignItems: 'center',
                padding: '12px 16px', gap: 14,
                background: 'var(--color-surface)',
                border: `1px solid ${synced ? 'rgba(52,211,153,0.12)' : 'var(--color-border)'}`,
                borderRadius: 8,
              }}
            >
              {/* Status icon */}
              <div style={{
                width: 28, height: 28, borderRadius: 6, flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                background: synced ? 'var(--color-green-bg)' : 'var(--color-surface-2)',
                border: `1px solid ${synced ? 'rgba(52,211,153,0.2)' : 'var(--color-border)'}`,
              }}>
                {synced
                  ? <Check size={13} style={{ color: 'var(--color-green)' }} />
                  : <X size={13} style={{ color: 'var(--color-text-3)' }} />
                }
              </div>

              {/* Info */}
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--color-text)', marginBottom: 2 }}>
                  {dot.name}
                </div>
                <div style={{ fontSize: 10, color: 'var(--color-text-3)' }}>
                  {dot.description}
                </div>
              </div>

              {/* Source → Target */}
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 10, color: 'var(--color-text-3)', flexShrink: 0 }}>
                <code style={{ color: 'var(--color-text-2)', background: 'var(--color-surface-2)', padding: '2px 6px', borderRadius: 3 }}>
                  {(dot as any).source?.split('/').pop() ?? '—'}
                </code>
                <span>→</span>
                <code style={{ color: synced ? 'var(--color-green)' : 'var(--color-text-3)', background: 'var(--color-surface-2)', padding: '2px 6px', borderRadius: 3 }}>
                  {target ?? '—'}
                </code>
              </div>

              {/* Type badge */}
              <div style={{
                fontSize: 9, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em',
                color: 'var(--color-text-3)', background: 'var(--color-surface-2)',
                border: '1px solid var(--color-border)', borderRadius: 3, padding: '2px 6px', flexShrink: 0,
              }}>
                {dot.type}
              </div>
            </div>
          );
        })}
      </div>

      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  );
};

function Stat({ label, value, color }: { label: string; value: number; color?: 'green' | 'red' }) {
  const textColor = color === 'green' ? 'var(--color-green)' : color === 'red' ? 'var(--color-red)' : 'var(--color-text)';
  return (
    <div>
      <div style={{ fontSize: 18, fontWeight: 700, color: textColor, lineHeight: 1 }}>{value}</div>
      <div style={{ fontSize: 10, color: 'var(--color-text-3)', marginTop: 2 }}>{label}</div>
    </div>
  );
}
