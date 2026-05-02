import React from 'react';
import { LucideIcon } from 'lucide-react';
import { useTranslation } from 'react-i18next';

interface SidebarProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
  tabs: { id: string; label: string; icon: LucideIcon }[];
}

export const Sidebar: React.FC<SidebarProps> = ({ activeTab, onTabChange, tabs }) => {
  const { t } = useTranslation('layout');

  return (
    <aside style={{
      width: 200,
      background: 'var(--color-surface)',
      borderRight: '1px solid var(--color-border)',
      display: 'flex',
      flexDirection: 'column',
      flexShrink: 0,
    }}>
      <div style={{ padding: '20px 16px 16px', borderBottom: '1px solid var(--color-border)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 28, height: 28,
            background: 'var(--color-green)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            borderRadius: 6, flexShrink: 0,
          }}>
            <span style={{ color: '#000', fontSize: 13, fontWeight: 700 }}>D</span>
          </div>
          <div>
            <div style={{ color: 'var(--color-text)', fontSize: 12, fontWeight: 700, lineHeight: 1.2 }}>{t('appName')}</div>
            <div style={{ color: 'var(--color-text-3)', fontSize: 10, lineHeight: 1 }}>{t('appVersion')}</div>
          </div>
        </div>
      </div>

      <nav style={{ padding: '12px 8px', flex: 1 }}>
        <div style={{ fontSize: 9, color: 'var(--color-text-3)', fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', padding: '0 8px 8px' }}>
          {t('navSection')}
        </div>
        {tabs.map((tab) => {
          const active = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              style={{
                width: '100%', display: 'flex', alignItems: 'center', gap: 10,
                padding: '8px 10px', borderRadius: 6, border: 'none', cursor: 'pointer',
                background: active ? 'var(--color-surface-2)' : 'transparent',
                color: active ? 'var(--color-text)' : 'var(--color-text-2)',
                fontSize: 12, fontWeight: active ? 600 : 400, fontFamily: 'inherit',
                transition: 'all 0.1s ease', textAlign: 'left', marginBottom: 2,
              }}
              onMouseEnter={e => { if (!active) { (e.currentTarget as HTMLButtonElement).style.background = 'var(--color-surface-2)'; (e.currentTarget as HTMLButtonElement).style.color = 'var(--color-text)'; }}}
              onMouseLeave={e => { if (!active) { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = 'var(--color-text-2)'; }}}
            >
              <tab.icon size={14} style={{ flexShrink: 0, color: active ? 'var(--color-green)' : 'currentColor' }} />
              {tab.label}
              {active && (
                <div style={{ marginLeft: 'auto', width: 4, height: 4, borderRadius: '50%', background: 'var(--color-green)' }} />
              )}
            </button>
          );
        })}
      </nav>

      <div style={{ padding: '12px 16px', borderTop: '1px solid var(--color-border)' }}>
        <div style={{ fontSize: 9, color: 'var(--color-text-3)' }}>{t('appFooter')}</div>
      </div>
    </aside>
  );
};
