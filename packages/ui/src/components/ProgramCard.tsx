import React from 'react';

export interface CardProps {
  title: string;
  description: string;
  category: string;
  onAction: () => void;
  actionLabel: string;
  status?: 'ready' | 'installing' | 'success' | 'error';
}

const categoryColors: Record<string, string> = {
  development: '#60a5fa',
  desktop:     '#a78bfa',
  devops:      '#34d399',
  ai:          '#f472b6',
  essential:   '#fbbf24',
};

export const ProgramCard: React.FC<CardProps> = ({ title, description, category, onAction, actionLabel, status = 'ready' }) => {
  const isInstalled = status === 'success';
  const isInstalling = status === 'installing';
  const catColor = categoryColors[category.toLowerCase()] ?? '#909098';

  return (
    <div style={{
      background: 'var(--color-surface)',
      border: `1px solid ${isInstalled ? 'rgba(52,211,153,0.15)' : 'var(--color-border)'}`,
      borderRadius: 8,
      padding: '14px 16px',
      display: 'flex',
      flexDirection: 'column',
      gap: 10,
      transition: 'border-color 0.15s ease',
      cursor: 'default',
    }}
    onMouseEnter={e => { if (!isInstalled) (e.currentTarget as HTMLDivElement).style.borderColor = 'var(--color-border-2)'; }}
    onMouseLeave={e => { if (!isInstalled) (e.currentTarget as HTMLDivElement).style.borderColor = 'var(--color-border)'; }}
    >
      {/* Top row */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 8 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--color-text)', lineHeight: 1.3, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {title}
          </div>
          <div style={{ fontSize: 10, color: catColor, marginTop: 2, fontWeight: 500 }}>
            {category}
          </div>
        </div>

        {/* Status dot */}
        <div style={{
          width: 8, height: 8, borderRadius: '50%', flexShrink: 0, marginTop: 3,
          background: isInstalling ? 'var(--color-amber)' : isInstalled ? 'var(--color-green)' : 'var(--color-border-2)',
          animation: isInstalling ? 'pulse 1s ease infinite' : 'none',
          boxShadow: isInstalled ? '0 0 6px rgba(52,211,153,0.4)' : 'none',
        }} />
      </div>

      {/* Description */}
      <p style={{
        fontSize: 11, color: 'var(--color-text-2)', lineHeight: 1.5, margin: 0,
        display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden',
      }}>
        {description}
      </p>

      {/* Action button */}
      <button
        onClick={onAction}
        disabled={isInstalling}
        style={{
          width: '100%',
          padding: '7px 0',
          borderRadius: 5,
          border: isInstalled
            ? '1px solid rgba(52,211,153,0.2)'
            : '1px solid var(--color-border)',
          background: isInstalled
            ? 'var(--color-green-bg)'
            : isInstalling
            ? 'var(--color-surface-2)'
            : 'var(--color-surface-2)',
          color: isInstalled
            ? 'var(--color-green)'
            : isInstalling
            ? 'var(--color-amber)'
            : 'var(--color-text-2)',
          fontSize: 11,
          fontWeight: 600,
          fontFamily: 'inherit',
          cursor: isInstalling ? 'not-allowed' : 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 6,
          transition: 'all 0.15s ease',
        }}
        onMouseEnter={e => {
          if (!isInstalling && !isInstalled) {
            (e.currentTarget as HTMLButtonElement).style.borderColor = 'var(--color-border-2)';
            (e.currentTarget as HTMLButtonElement).style.color = 'var(--color-text)';
          }
        }}
        onMouseLeave={e => {
          if (!isInstalling && !isInstalled) {
            (e.currentTarget as HTMLButtonElement).style.borderColor = 'var(--color-border)';
            (e.currentTarget as HTMLButtonElement).style.color = 'var(--color-text-2)';
          }
        }}
      >
        {isInstalling && (
          <div style={{
            width: 10, height: 10, borderRadius: '50%',
            border: '2px solid var(--color-amber)', borderTopColor: 'transparent',
            animation: 'spin 0.8s linear infinite',
          }} />
        )}
        {actionLabel}
      </button>

      <style>{`
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }
        @keyframes spin  { to{transform:rotate(360deg)} }
      `}</style>
    </div>
  );
};
