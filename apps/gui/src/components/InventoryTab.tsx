import React from 'react';
import { type ProgramManifest } from '@dotfiles/schema';
import { ProgramCard } from './ProgramCard';

interface InventoryTabProps {
  registry: Record<string, ProgramManifest>;
  searchQuery: string;
  installing: Record<string, boolean>;
  onInstall: (id: string) => void;
  installedStatus: Record<string, boolean>;
  scanning: boolean;
}

export const InventoryTab: React.FC<InventoryTabProps> = ({
  registry, searchQuery, installing, onInstall, installedStatus, scanning,
}) => {
  const term = searchQuery.toLowerCase();
  const filtered = Object.entries(registry).filter(([id, p]) =>
    !term || id.includes(term) || p.name.toLowerCase().includes(term) || p.description.toLowerCase().includes(term)
  );

  const categories = Array.from(new Set(filtered.map(([, p]) => p.category))).sort();

  if (filtered.length === 0) {
    return (
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', paddingBottom: 160 }}>
        <p style={{ color: 'var(--color-text-3)', fontSize: 12 }}>No packages match "{searchQuery}"</p>
      </div>
    );
  }

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '20px 24px 180px' }}>
      {scanning && (
        <div style={{
          marginBottom: 16, padding: '8px 14px',
          background: 'var(--color-amber-bg)', border: '1px solid rgba(251,191,36,0.2)',
          borderRadius: 6, fontSize: 11, color: 'var(--color-amber)',
        }}>
          Scanning installed packages...
        </div>
      )}

      {categories.map(cat => {
        const items = filtered.filter(([, p]) => p.category === cat);
        if (!items.length) return null;
        return (
          <section key={cat} style={{ marginBottom: 32 }}>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12,
            }}>
              <span style={{ fontSize: 10, fontWeight: 600, color: 'var(--color-text-3)', textTransform: 'uppercase', letterSpacing: '0.1em' }}>
                {cat}
              </span>
              <span style={{ fontSize: 10, color: 'var(--color-text-3)' }}>
                ({items.filter(([id]) => installedStatus[id]).length}/{items.length})
              </span>
              <div style={{ flex: 1, height: 1, background: 'var(--color-border)' }} />
            </div>

            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))',
              gap: 10,
            }}>
              {items.map(([id, prog]) => (
                <ProgramCard
                  key={id}
                  title={prog.name}
                  description={prog.description}
                  category={prog.category}
                  onAction={() => onInstall(id)}
                  actionLabel={
                    installing[id] ? 'Installing...' :
                    installedStatus[id] ? 'Reinstall' :
                    scanning ? '...' :
                    'Install'
                  }
                  status={
                    installing[id] ? 'installing' :
                    installedStatus[id] ? 'success' :
                    'ready'
                  }
                />
              ))}
            </div>
          </section>
        );
      })}
    </div>
  );
};
