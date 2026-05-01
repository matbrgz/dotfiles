import React, { useState, useCallback } from 'react';
import { guiCommands, type DiskCategory, type CleanEvent, type LargeFile } from '@dotfiles/gui-engine';

function formatBytes(bytes: number): string {
  if (bytes < 1_048_576) return `${(bytes / 1024).toFixed(0)} KB`;
  if (bytes < 1_073_741_824) return `${(bytes / 1_048_576).toFixed(1)} MB`;
  return `${(bytes / 1_073_741_824).toFixed(1)} GB`;
}

export const DiskCleanerTab: React.FC = () => {
  const [categories, setCategories] = useState<DiskCategory[]>([]);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [scanning, setScanning] = useState(false);
  const [cleaning, setCleaning] = useState(false);
  const [cleanLog, setCleanLog] = useState<string[]>([]);
  const [largeFiles, setLargeFiles] = useState<LargeFile[]>([]);
  const [loadingLarge, setLoadingLarge] = useState(false);

  const totalFound = categories.reduce((sum, c) => sum + c.size_bytes, 0);

  const handleScan = useCallback(async () => {
    setScanning(true);
    setCategories([]);
    setLargeFiles([]);
    setCleanLog([]);
    try {
      await guiCommands.scanDisk((cat) => {
        setCategories(prev => {
          const exists = prev.find(c => c.id === cat.id);
          if (exists) return prev.map(c => c.id === cat.id ? cat : c);
          return [...prev, cat];
        });
      });
      setLoadingLarge(true);
      const large = await guiCommands.scanLargeFiles();
      setLargeFiles(large);
    } catch (e) {
      console.error('Scan error:', e);
    } finally {
      setScanning(false);
      setLoadingLarge(false);
    }
  }, []);

  const handleClean = useCallback(async () => {
    if (selected.size === 0 || cleaning) return;
    const confirmed = window.confirm(
      `Clean ${selected.size} item(s) totaling ${formatBytes(
        categories.filter(c => selected.has(c.id)).reduce((s, c) => s + c.size_bytes, 0)
      )}?\n\nThis cannot be undone.`
    );
    if (!confirmed) return;

    setCleaning(true);
    setCleanLog([]);
    try {
      await guiCommands.cleanItems(Array.from(selected), (ev: CleanEvent) => {
        const msg = ev.error
          ? `[ERR] ${ev.id}: ${ev.error}`
          : `✓ ${ev.id} cleaned`;
        setCleanLog(prev => [...prev, msg]);
      });
      setCleanLog(prev => [...prev, 'Done! Rescanning...']);
      setSelected(new Set());
      await guiCommands.scanDisk((cat) => {
        setCategories(prev => prev.map(c => c.id === cat.id ? cat : c));
      });
    } catch (e) {
      setCleanLog(prev => [...prev, `[ERR] ${e}`]);
    } finally {
      setCleaning(false);
    }
  }, [selected, categories, cleaning]);

  const toggleSelect = (id: string) => {
    setSelected(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  };

  const selectSafe = () => {
    setSelected(new Set(categories.filter(c => c.safe).map(c => c.id)));
  };

  const clearSelection = () => setSelected(new Set());

  const toggleGroup = (group: string, cats: DiskCategory[]) => {
    const groupIds = cats.filter(c => c.group === group).map(c => c.id);
    const allSelected = groupIds.every(id => selected.has(id));
    setSelected(prev => {
      const next = new Set(prev);
      if (allSelected) {
        groupIds.forEach(id => next.delete(id));
      } else {
        groupIds.forEach(id => next.add(id));
      }
      return next;
    });
  };

  const groups = Array.from(new Set(categories.map(c => c.group)));
  const selectedCategories = categories.filter(c => selected.has(c.id));
  const selectedBytes = selectedCategories.reduce((s, c) => s + c.size_bytes, 0);

  const btnStyle = (variant: 'primary' | 'ghost' | 'danger', disabled: boolean): React.CSSProperties => ({
    padding: '6px 14px', borderRadius: 6, fontSize: 11, fontWeight: 600,
    fontFamily: 'inherit', cursor: disabled ? 'not-allowed' : 'pointer',
    border: variant === 'ghost' ? '1px solid var(--color-border)'
      : variant === 'danger' ? '1px solid rgba(239,68,68,0.3)' : 'none',
    background: variant === 'primary'
      ? (disabled ? 'var(--color-surface-2)' : 'var(--color-green)')
      : variant === 'danger'
      ? (disabled ? 'var(--color-surface-2)' : 'rgba(239,68,68,0.12)')
      : 'transparent',
    color: variant === 'primary'
      ? (disabled ? 'var(--color-text-3)' : '#000')
      : variant === 'danger'
      ? (disabled ? 'var(--color-text-3)' : 'var(--color-red)')
      : 'var(--color-text-2)',
    transition: 'all 0.15s ease',
  });

  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* Sticky top toolbar */}
      <div style={{
        position: 'sticky', top: 0, zIndex: 10,
        padding: '12px 20px',
        borderBottom: '1px solid var(--color-border)',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        background: 'var(--color-surface)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <button
            onClick={handleScan}
            disabled={scanning}
            style={btnStyle('primary', scanning)}
          >
            {scanning ? 'Scanning...' : '⟳ Scan System'}
          </button>
          {categories.length > 0 && (
            <span style={{ fontSize: 11, color: 'var(--color-text-3)' }}>
              Total: <strong style={{ color: 'var(--color-text)' }}>{formatBytes(totalFound)}</strong> found in{' '}
              <strong style={{ color: 'var(--color-text)' }}>{categories.length}</strong> categories
            </span>
          )}
        </div>
      </div>

      {/* Scrollable content */}
      <div style={{ flex: 1, padding: '16px 20px' }}>
        {categories.length === 0 && !scanning && (
          <div style={{ textAlign: 'center', color: 'var(--color-text-3)', fontSize: 12, marginTop: 60 }}>
            Click "Scan System" to analyze disk usage
          </div>
        )}

        {scanning && categories.length === 0 && (
          <div style={{ textAlign: 'center', color: 'var(--color-amber)', fontSize: 11, marginTop: 40 }}>
            Scanning...
          </div>
        )}

        {groups.map(group => {
          const groupCats = categories.filter(c => c.group === group);
          const groupIds = groupCats.map(c => c.id);
          const allGroupSelected = groupIds.length > 0 && groupIds.every(id => selected.has(id));
          const someGroupSelected = groupIds.some(id => selected.has(id));

          return (
            <section key={group} style={{ marginBottom: 24 }}>
              <div style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                marginBottom: 8,
              }}>
                <span style={{
                  fontSize: 10, fontWeight: 700, color: 'var(--color-text-3)',
                  textTransform: 'uppercase', letterSpacing: '0.1em',
                }}>
                  {group}
                </span>
                <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer', fontSize: 10, color: 'var(--color-text-3)' }}>
                  <input
                    type="checkbox"
                    checked={allGroupSelected}
                    ref={el => { if (el) el.indeterminate = someGroupSelected && !allGroupSelected; }}
                    onChange={() => toggleGroup(group, categories)}
                    style={{ cursor: 'pointer' }}
                  />
                  Select group
                </label>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                {groupCats.map(cat => (
                  <label
                    key={cat.id}
                    style={{
                      display: 'flex', alignItems: 'center', gap: 12,
                      padding: '10px 14px',
                      background: selected.has(cat.id) ? 'var(--color-surface-2)' : 'var(--color-surface)',
                      border: `1px solid ${selected.has(cat.id) ? 'var(--color-border-2)' : 'var(--color-border)'}`,
                      borderRadius: 8, cursor: 'pointer',
                      transition: 'all 0.1s ease',
                    }}
                  >
                    <input
                      type="checkbox"
                      checked={selected.has(cat.id)}
                      onChange={() => toggleSelect(cat.id)}
                      style={{ cursor: 'pointer', flexShrink: 0 }}
                    />
                    <span style={{ fontSize: 15 }}>{cat.icon}</span>
                    <span style={{ flex: 1, fontSize: 12, color: 'var(--color-text)', fontWeight: 500 }}>
                      {cat.label}
                    </span>
                    {cat.item_count > 0 && (
                      <span style={{ fontSize: 10, color: 'var(--color-text-3)' }}>
                        {cat.item_count} {cat.item_count === 1 ? 'item' : 'items'}
                      </span>
                    )}
                    <span style={{
                      fontSize: 11, fontWeight: 600, minWidth: 70, textAlign: 'right',
                      color: cat.size_bytes > 1_073_741_824 ? 'var(--color-red)'
                        : cat.size_bytes > 104_857_600 ? 'var(--color-amber)'
                        : 'var(--color-text-2)',
                    }}>
                      {cat.size_bytes > 0 ? formatBytes(cat.size_bytes) : '—'}
                    </span>
                    <span style={{
                      fontSize: 9, fontWeight: 600, padding: '2px 6px', borderRadius: 3,
                      textTransform: 'uppercase', letterSpacing: '0.05em',
                      background: cat.safe ? 'var(--color-green-bg)' : 'rgba(239,68,68,0.1)',
                      color: cat.safe ? 'var(--color-green)' : 'var(--color-red)',
                      border: `1px solid ${cat.safe ? 'rgba(52,211,153,0.2)' : 'rgba(239,68,68,0.2)'}`,
                      flexShrink: 0,
                    }}>
                      {cat.safe ? 'safe' : 'caution'}
                    </span>
                  </label>
                ))}
              </div>
            </section>
          );
        })}

        {/* Large files */}
        {(largeFiles.length > 0 || loadingLarge) && (
          <section style={{ marginTop: 8, marginBottom: 24 }}>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 12, marginBottom: 10,
            }}>
              <div style={{ height: 1, flex: 1, background: 'var(--color-border)' }} />
              <span style={{ fontSize: 10, fontWeight: 700, color: 'var(--color-text-3)', textTransform: 'uppercase', letterSpacing: '0.1em', whiteSpace: 'nowrap' }}>
                Large Files (&gt;100 MB)
              </span>
              <div style={{ height: 1, flex: 1, background: 'var(--color-border)' }} />
            </div>

            {loadingLarge && (
              <div style={{ fontSize: 10, color: 'var(--color-amber)', padding: '8px 0' }}>
                Scanning for large files...
              </div>
            )}

            {largeFiles.map((f, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '8px 14px', marginBottom: 4,
                background: 'var(--color-surface)',
                border: '1px solid var(--color-border)',
                borderRadius: 8,
              }}>
                <span style={{ fontSize: 13 }}>📄</span>
                <span style={{ flex: 1, fontSize: 11, color: 'var(--color-text-2)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {f.path}
                </span>
                <span style={{ fontSize: 11, fontWeight: 600, color: 'var(--color-red)', flexShrink: 0 }}>
                  {formatBytes(f.size_bytes)}
                </span>
              </div>
            ))}
          </section>
        )}

        {/* Clean log */}
        {cleanLog.length > 0 && (
          <div style={{
            marginTop: 16, padding: '10px 14px',
            background: 'var(--color-bg)',
            border: '1px solid var(--color-border)',
            borderRadius: 8,
          }}>
            {cleanLog.map((line, i) => (
              <div key={i} style={{
                fontSize: 10, lineHeight: 1.8,
                color: line.startsWith('[ERR]') ? 'var(--color-red)'
                  : line.startsWith('✓') ? 'var(--color-green)'
                  : 'var(--color-text-2)',
                fontFamily: 'var(--font-mono)',
              }}>
                {line}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Sticky bottom action bar */}
      <div style={{
        position: 'sticky', bottom: 0,
        padding: '10px 20px',
        borderTop: '1px solid var(--color-border)',
        background: 'var(--color-surface)',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <button onClick={selectSafe} disabled={scanning} style={btnStyle('ghost', scanning)}>Select safe</button>
          <button onClick={clearSelection} disabled={selected.size === 0} style={btnStyle('ghost', selected.size === 0)}>Clear</button>
          {selected.size > 0 && (
            <span style={{ fontSize: 11, color: 'var(--color-text-3)' }}>
              Selected: <strong style={{ color: 'var(--color-text)' }}>{selected.size}</strong> items,{' '}
              <strong style={{ color: 'var(--color-amber)' }}>{formatBytes(selectedBytes)}</strong>
            </span>
          )}
        </div>
        <button
          onClick={handleClean}
          disabled={selected.size === 0 || cleaning}
          style={btnStyle('danger', selected.size === 0 || cleaning)}
        >
          {cleaning ? 'Cleaning...' : `🗑 Clean selected (${selected.size})`}
        </button>
      </div>
    </div>
  );
};
