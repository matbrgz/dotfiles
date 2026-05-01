import React, { useState, useEffect } from 'react';
import { guiCommands } from '@dotfiles/gui-engine';
import { type UserSettings, type ProgramManifest, type DotfileManifest } from '@dotfiles/schema';

interface ProfileTabProps {
  settings: UserSettings;
  registry: Record<string, ProgramManifest>;
  dotfiles: Record<string, DotfileManifest>;
  osInfo: { os: string; platform: string };
}

export const ProfileTab: React.FC<ProfileTabProps> = ({ settings, registry, dotfiles, osInfo }) => {
  const [runtimeInfo, setRuntimeInfo] = useState({ node: '...', tauri: '...' });

  useEffect(() => {
    guiCommands.getRuntimeInfo().then(setRuntimeInfo);
  }, []);

  const telemetry = [
    { label: 'OS',           value: osInfo.os },
    { label: 'Architecture', value: osInfo.platform },
    { label: 'Node',         value: runtimeInfo.node },
    { label: 'Tauri',        value: runtimeInfo.tauri },
  ];

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 24px 180px' }}>
      <div style={{ maxWidth: 720, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>

        {/* Identity card */}
        <div style={{ background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 10, padding: 24, gridColumn: '1 / -1' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <div style={{
              width: 52, height: 52, borderRadius: 12,
              background: 'var(--color-green-bg)', border: '1px solid rgba(52,211,153,0.2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 22, fontWeight: 700, color: 'var(--color-green)',
            }}>
              {settings.personal.name?.[0]?.toUpperCase() ?? 'U'}
            </div>
            <div>
              <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--color-text)', lineHeight: 1.2 }}>
                {settings.personal.name}
              </div>
              <div style={{ fontSize: 11, color: 'var(--color-text-2)', marginTop: 3 }}>
                {settings.personal.email}
              </div>
              {(settings.personal as any).githubuser && (
                <div style={{ fontSize: 10, color: 'var(--color-text-3)', marginTop: 2 }}>
                  github.com/{(settings.personal as any).githubuser}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Stats */}
        <StatCard title="Registry" items={[
          { label: 'Total packages', value: Object.keys(registry).length },
          { label: 'Categories', value: new Set(Object.values(registry).map(p => p.category)).size },
        ]} />

        <StatCard title="Dotfiles" items={[
          { label: 'Managed files', value: Object.keys(dotfiles).length },
        ]} />

        {/* Environment */}
        <div style={{ background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 10, padding: 20, gridColumn: '1 / -1' }}>
          <div style={{ fontSize: 10, fontWeight: 700, color: 'var(--color-text-3)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 16 }}>
            Environment
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
            {telemetry.map(t => (
              <div key={t.label}>
                <div style={{ fontSize: 9, color: 'var(--color-text-3)', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 4 }}>{t.label}</div>
                <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--color-text)' }}>{t.value}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

function StatCard({ title, items }: { title: string; items: { label: string; value: number }[] }) {
  return (
    <div style={{ background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 10, padding: 20 }}>
      <div style={{ fontSize: 10, fontWeight: 700, color: 'var(--color-text-3)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 16 }}>
        {title}
      </div>
      {items.map(item => (
        <div key={item.label} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10 }}>
          <span style={{ fontSize: 11, color: 'var(--color-text-2)' }}>{item.label}</span>
          <span style={{ fontSize: 22, fontWeight: 700, color: 'var(--color-text)' }}>{item.value}</span>
        </div>
      ))}
    </div>
  );
}
