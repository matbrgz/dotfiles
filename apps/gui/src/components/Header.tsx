import React from 'react';
import { Search, RefreshCw } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import i18n from '../i18n';

interface HeaderProps {
  osInfo: { os: string; platform: string };
  isApplying: boolean;
  onApplyDotfiles: () => void;
  searchQuery: string;
  onSearchChange: (q: string) => void;
  activeTab: string;
  installedCount: number;
  totalCount: number;
  syncedCount: number;
  totalDotfiles: number;
  scanning: boolean;
}

const LANGUAGES = [
  { code: 'en', label: 'EN' },
  { code: 'pt-BR', label: 'PT' },
  { code: 'es', label: 'ES' },
] as const;

export const Header: React.FC<HeaderProps> = ({
  osInfo, isApplying, onApplyDotfiles, searchQuery, onSearchChange,
  activeTab, installedCount, totalCount, syncedCount, totalDotfiles, scanning,
}) => {
  const { t, i18n: i18nInstance } = useTranslation('layout');

  const tabTitles: Record<string, string> = {
    inventory:     t('tabPackages'),
    environment:   t('tabDotfiles'),
    settings:      t('tabSettings'),
    profile:       t('tabProfile'),
    'disk-cleaner': t('tabDiskCleaner'),
    memory:        t('tabMemory'),
    'git-repos':   t('tabGitRepos'),
  };

  const handleLangChange = (code: string) => {
    i18n.changeLanguage(code);
    try { localStorage.setItem('dotfiles-lang', code); } catch {}
  };

  return (
    <header style={{
      height: 56,
      borderBottom: '1px solid var(--color-border)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 20px',
      background: 'var(--color-surface)',
      flexShrink: 0,
    }}>
      {/* Left: title + stats */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
        <h1 style={{ fontSize: 13, fontWeight: 600, color: 'var(--color-text)', margin: 0 }}>
          {tabTitles[activeTab] ?? activeTab}
        </h1>

        <div style={{ display: 'flex', gap: 8 }}>
          {activeTab === 'inventory' && (
            <Pill
              label={scanning ? t('statsScanning') : t('statsInstalled', { count: installedCount, total: totalCount })}
              color={scanning ? 'amber' : installedCount === totalCount ? 'green' : 'text'}
            />
          )}
          {activeTab === 'environment' && (
            <Pill
              label={t('statsSynced', { count: syncedCount, total: totalDotfiles })}
              color={syncedCount === totalDotfiles ? 'green' : 'text'}
            />
          )}
          <Pill label={`${osInfo.os} · ${osInfo.platform}`} color="text" />
        </div>
      </div>

      {/* Right: search + lang switcher + sync */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        {activeTab === 'inventory' && (
          <div style={{ position: 'relative' }}>
            <Search size={12} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-3)', pointerEvents: 'none' }} />
            <input
              type="text"
              value={searchQuery}
              onChange={e => onSearchChange(e.target.value)}
              placeholder={t('searchPlaceholder')}
              style={{
                background: 'var(--color-bg)',
                border: '1px solid var(--color-border)',
                borderRadius: 6,
                padding: '6px 12px 6px 30px',
                fontSize: 11,
                color: 'var(--color-text)',
                fontFamily: 'inherit',
                outline: 'none',
                width: 200,
              }}
              onFocus={e => (e.target.style.borderColor = 'var(--color-border-2)')}
              onBlur={e => (e.target.style.borderColor = 'var(--color-border)')}
            />
          </div>
        )}

        {/* Language switcher */}
        <div style={{ display: 'flex', borderRadius: 6, border: '1px solid var(--color-border)', overflow: 'hidden' }}>
          {LANGUAGES.map(({ code, label }) => {
            const active = i18nInstance.language === code;
            return (
              <button
                key={code}
                onClick={() => handleLangChange(code)}
                style={{
                  padding: '4px 8px',
                  border: 'none',
                  background: active ? 'var(--color-green-bg)' : 'transparent',
                  color: active ? 'var(--color-green)' : 'var(--color-text-3)',
                  fontSize: 10,
                  fontWeight: 700,
                  fontFamily: 'inherit',
                  cursor: 'pointer',
                  transition: 'all 0.1s ease',
                }}
              >
                {label}
              </button>
            );
          })}
        </div>

        <button
          onClick={onApplyDotfiles}
          disabled={isApplying}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 6,
            padding: '6px 14px',
            borderRadius: 6,
            border: '1px solid var(--color-border)',
            background: isApplying ? 'var(--color-surface-2)' : 'var(--color-green-bg)',
            color: isApplying ? 'var(--color-text-3)' : 'var(--color-green)',
            fontSize: 11,
            fontWeight: 600,
            fontFamily: 'inherit',
            cursor: isApplying ? 'not-allowed' : 'pointer',
            transition: 'all 0.15s ease',
          }}
        >
          <RefreshCw size={11} style={{ animation: isApplying ? 'spin 1s linear infinite' : 'none' }} />
          {isApplying ? t('btnSyncing') : t('btnSync')}
        </button>
      </div>

      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </header>
  );
};

function Pill({ label, color }: { label: string; color: 'green' | 'amber' | 'text' }) {
  const colors: Record<string, { bg: string; text: string; border: string }> = {
    green: { bg: 'var(--color-green-bg)', text: 'var(--color-green)', border: 'rgba(52,211,153,0.2)' },
    amber: { bg: 'var(--color-amber-bg)', text: 'var(--color-amber)', border: 'rgba(251,191,36,0.2)' },
    text:  { bg: 'var(--color-surface-2)', text: 'var(--color-text-2)', border: 'var(--color-border)' },
  };
  const c = colors[color];
  return (
    <span style={{
      background: c.bg, color: c.text, border: `1px solid ${c.border}`,
      borderRadius: 4, padding: '2px 8px', fontSize: 10, fontWeight: 500,
    }}>
      {label}
    </span>
  );
}
