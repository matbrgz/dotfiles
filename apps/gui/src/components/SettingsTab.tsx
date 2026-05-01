import React from 'react';
import { type UserSettings } from '@dotfiles/schema';

interface SettingsTabProps {
  settings: UserSettings;
  setSettings: (s: UserSettings) => void;
  onSave: () => void;
  isSaving: boolean;
}

const Input: React.FC<{ label: string; value: string; type?: string; onChange: (v: string) => void }> = ({ label, value, type = 'text', onChange }) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
    <label style={{ fontSize: 10, fontWeight: 600, color: 'var(--color-text-3)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>{label}</label>
    <input
      type={type}
      value={value}
      onChange={e => onChange(e.target.value)}
      style={{
        background: 'var(--color-bg)', border: '1px solid var(--color-border)',
        borderRadius: 6, padding: '9px 12px', fontSize: 12,
        color: 'var(--color-text)', fontFamily: 'inherit', outline: 'none',
      }}
      onFocus={e => (e.target.style.borderColor = 'var(--color-border-2)')}
      onBlur={e => (e.target.style.borderColor = 'var(--color-border)')}
    />
  </div>
);

const Toggle: React.FC<{ label: string; desc: string; value: boolean; onChange: (v: boolean) => void }> = ({ label, desc, value, onChange }) => (
  <div style={{
    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    padding: '12px 16px', background: 'var(--color-surface)',
    border: '1px solid var(--color-border)', borderRadius: 8,
  }}>
    <div>
      <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--color-text)', marginBottom: 2 }}>{label}</div>
      <div style={{ fontSize: 10, color: 'var(--color-text-3)' }}>{desc}</div>
    </div>
    <button
      onClick={() => onChange(!value)}
      style={{
        width: 40, height: 22, borderRadius: 11, border: 'none',
        background: value ? 'var(--color-green)' : 'var(--color-border-2)',
        position: 'relative', cursor: 'pointer', transition: 'background 0.2s ease', flexShrink: 0,
      }}
    >
      <div style={{
        position: 'absolute', top: 3, width: 16, height: 16, borderRadius: '50%',
        background: '#fff', transition: 'left 0.2s ease',
        left: value ? 21 : 3,
      }} />
    </button>
  </div>
);

export const SettingsTab: React.FC<SettingsTabProps> = ({ settings, setSettings, onSave, isSaving }) => {
  const updatePersonal = (key: string, value: string) =>
    setSettings({ ...settings, personal: { ...settings.personal, [key]: value } });

  const updateBehavior = (key: string, value: boolean) =>
    setSettings({ ...settings, system: { ...settings.system, behavior: { ...settings.system.behavior, [key]: value } } });

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 24px 180px' }}>
      <div style={{ maxWidth: 560, display: 'flex', flexDirection: 'column', gap: 32 }}>

        {/* Identity */}
        <section>
          <SectionTitle>Identity</SectionTitle>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <Input label="Name" value={settings.personal.name} onChange={v => updatePersonal('name', v)} />
            <Input label="Email" type="email" value={settings.personal.email} onChange={v => updatePersonal('email', v)} />
            <Input label="GitHub user" value={(settings.personal as any).githubuser ?? ''} onChange={v => updatePersonal('githubuser', v)} />
          </div>
        </section>

        {/* Behavior */}
        <section>
          <SectionTitle>Behavior</SectionTitle>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <Toggle label="Debug mode" desc="Verbose output during operations" value={(settings.system.behavior as any).debug_mode ?? false} onChange={v => updateBehavior('debug_mode', v)} />
            <Toggle label="Auto backup" desc="Backup existing files before overwriting" value={(settings.system.behavior as any).backup_configs ?? false} onChange={v => updateBehavior('backup_configs', v)} />
            <Toggle label="Purge mode" desc="Remove old configs during sync" value={(settings.system.behavior as any).purge_mode ?? false} onChange={v => updateBehavior('purge_mode', v)} />
            <Toggle label="Parallel installs" desc="Install multiple packages simultaneously" value={(settings.system.behavior as any).parallel_installs ?? false} onChange={v => updateBehavior('parallel_installs', v)} />
          </div>
        </section>

        {/* Save */}
        <button
          onClick={onSave}
          disabled={isSaving}
          style={{
            padding: '11px 0', borderRadius: 8,
            border: 'none', background: isSaving ? 'var(--color-surface-2)' : 'var(--color-green)',
            color: isSaving ? 'var(--color-text-3)' : '#000',
            fontSize: 12, fontWeight: 700, fontFamily: 'inherit',
            cursor: isSaving ? 'not-allowed' : 'pointer', transition: 'all 0.15s ease',
          }}
        >
          {isSaving ? 'Saving...' : 'Save settings'}
        </button>
      </div>
    </div>
  );
};

function SectionTitle({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14 }}>
      <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--color-text)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>{children}</span>
      <div style={{ flex: 1, height: 1, background: 'var(--color-border)' }} />
    </div>
  );
}
