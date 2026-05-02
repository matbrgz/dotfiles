import React, { useState, useCallback, useMemo, useEffect } from 'react';
import { guiCommands, type DiskCategory, type ScanProgress } from '@dotfiles/gui-engine';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';
import { Checkbox } from '@/components/ui/checkbox';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Separator } from '@/components/ui/separator';
import {
  saveScan, loadScan,
  saveSelection, loadSelection, clearSelection,
  saveGroup, loadGroup,
} from '@/lib/diskCleanerCache';

type CatSel = 'all' | Set<string>;
type Selection = Map<string, CatSel>;

function formatBytes(bytes: number): string {
  if (bytes < 1_048_576) return `${(bytes / 1024).toFixed(0)} KB`;
  if (bytes < 1_073_741_824) return `${(bytes / 1_048_576).toFixed(1)} MB`;
  return `${(bytes / 1_073_741_824).toFixed(1)} GB`;
}

function formatRelative(ts: number): string {
  const diff = Math.floor(Date.now() / 1000) - ts;
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  if (diff < 604800) return `${Math.floor(diff / 86400)}d ago`;
  if (diff < 2592000) return `${Math.floor(diff / 604800)}w ago`;
  return `${Math.floor(diff / 2592000)}mo ago`;
}

function catChecked(sel: Selection, id: string): true | false | 'indeterminate' {
  const s = sel.get(id);
  if (s === 'all') return true;
  if (s instanceof Set && s.size > 0) return 'indeterminate';
  return false;
}

function groupChecked(sel: Selection, cats: DiskCategory[]): true | false | 'indeterminate' {
  if (cats.every(c => sel.get(c.id) === 'all')) return true;
  if (cats.some(c => sel.has(c.id))) return 'indeterminate';
  return false;
}

function itemChecked(sel: Selection, catId: string, path: string): boolean {
  const s = sel.get(catId);
  return s === 'all' || (s instanceof Set && s.has(path));
}

function toggleCat(sel: Selection, id: string): Selection {
  const next = new Map(sel);
  if (sel.get(id) === 'all') next.delete(id); else next.set(id, 'all');
  return next;
}

function toggleGroup(sel: Selection, cats: DiskCategory[]): Selection {
  const next = new Map(sel);
  const allSel = cats.every(c => sel.get(c.id) === 'all');
  for (const cat of cats) { if (allSel) next.delete(cat.id); else next.set(cat.id, 'all'); }
  return next;
}

function toggleItem(sel: Selection, catId: string, path: string, cat: DiskCategory): Selection {
  const next = new Map(sel);
  const current = sel.get(catId);
  if (current === 'all') {
    const set = new Set(cat.items.map(i => i.path));
    set.delete(path);
    if (set.size === 0) next.delete(catId); else next.set(catId, set);
    return next;
  }
  const set = new Set(current instanceof Set ? current : []);
  if (set.has(path)) {
    set.delete(path);
    if (set.size === 0) next.delete(catId); else next.set(catId, set);
  } else {
    set.add(path);
    if (cat.items.length > 0 && set.size === cat.items.length) next.set(catId, 'all');
    else next.set(catId, set);
  }
  return next;
}

function selectedBytes(sel: Selection, categories: DiskCategory[]): number {
  let total = 0;
  for (const cat of categories) {
    const s = sel.get(cat.id);
    if (!s) continue;
    if (s === 'all') { total += cat.size_bytes; continue; }
    for (const path of s) {
      const item = cat.items.find(i => i.path === path);
      if (item) total += item.size_bytes;
    }
  }
  return total;
}

const ALL = 'All';

export const DiskCleanerTab: React.FC = () => {
  const cached = useMemo(() => loadScan(), []);
  const [categories, setCategories] = useState<DiskCategory[]>(cached?.categories ?? []);
  const [lastScanAt, setLastScanAt] = useState<number | null>(cached?.timestamp ?? null);
  const [selection, setSelection] = useState<Selection>(() => loadSelection());
  const [scanning, setScanning] = useState(false);
  const [progress, setProgress] = useState<ScanProgress | null>(null);
  const [cleaning, setCleaning] = useState(false);
  const [cleanLog, setCleanLog] = useState<string[]>([]);
  const [activeGroup, setActiveGroup] = useState<string>(() => loadGroup() ?? ALL);

  useEffect(() => { saveSelection(selection); }, [selection]);
  useEffect(() => { saveGroup(activeGroup); }, [activeGroup]);

  const groups = useMemo(() => [ALL, ...Array.from(new Set(categories.map(c => c.group)))], [categories]);

  const visible = useMemo(
    () => activeGroup === ALL ? categories : categories.filter(c => c.group === activeGroup),
    [categories, activeGroup],
  );

  const groupMap = useMemo(() => {
    const m = new Map<string, DiskCategory[]>();
    for (const cat of visible) {
      const g = m.get(cat.group) ?? [];
      g.push(cat);
      m.set(cat.group, g);
    }
    return m;
  }, [visible]);

  const selBytes = useMemo(() => selectedBytes(selection, categories), [selection, categories]);
  const selCount = selection.size;

  const runScan = useCallback(async (
    onCat: (c: DiskCategory) => void,
    onProg: (p: ScanProgress) => void,
  ) => {
    await guiCommands.scanDisk(onCat, onProg);
  }, []);

  const handleScan = useCallback(async () => {
    setScanning(true);
    setCategories([]);
    setSelection(new Map());
    setCleanLog([]);
    setProgress(null);
    try {
      await runScan(
        (cat) => setCategories(prev => {
          const idx = prev.findIndex(c => c.id === cat.id);
          return idx >= 0 ? prev.map((c, i) => i === idx ? cat : c) : [...prev, cat];
        }),
        setProgress,
      );
    } catch (e) { console.error('Scan error:', e); }
    finally {
      setScanning(false);
      setProgress(null);
      setCategories(prev => { const ts = Date.now(); saveScan(prev); setLastScanAt(ts); return prev; });
    }
  }, [runScan]);

  const handleClean = useCallback(async () => {
    if (selCount === 0 || cleaning) return;
    const ids = Array.from(selection.keys());
    if (!window.confirm(`Clean ${ids.length} item(s) totaling ${formatBytes(selBytes)}?\n\nThis cannot be undone.`)) return;
    setCleaning(true);
    setCleanLog([]);
    try {
      await guiCommands.cleanItems(ids, (ev) => {
        setCleanLog(prev => [...prev, ev.error ? `[ERR] ${ev.id}: ${ev.error}` : `✓ ${ev.id} cleaned`]);
      });
      setCleanLog(prev => [...prev, 'Done! Rescanning...']);
      setSelection(new Map());
      clearSelection();
      setCategories([]);
      await runScan(
        (cat) => setCategories(prev => {
          const idx = prev.findIndex(c => c.id === cat.id);
          return idx >= 0 ? prev.map((c, i) => i === idx ? cat : c) : [...prev, cat];
        }),
        setProgress,
      );
    } catch (e) { setCleanLog(prev => [...prev, `[ERR] ${e}`]); }
    finally { setCleaning(false); setProgress(null); }
  }, [selCount, cleaning, selection, selBytes, runScan]);

  const selectSafe = () => {
    const next = new Map<string, CatSel>();
    for (const cat of categories) { if (cat.safe) next.set(cat.id, 'all'); }
    setSelection(next);
  };

  const pct = progress ? Math.round((progress.step / progress.total) * 100) : 0;

  return (
    <div className="flex flex-col h-full">
      {/* Toolbar */}
      <div className="flex items-center gap-3 px-5 py-3 border-b border-border sticky top-0 bg-card z-10 shrink-0">
        <Button variant="default" size="sm" onClick={handleScan} disabled={scanning} className="shrink-0">
          {scanning ? 'Scanning...' : '⟳ Scan System'}
        </Button>
        {scanning && progress && (
          <div className="flex-1 flex items-center gap-3 min-w-0">
            <span className="text-xs text-muted-foreground truncate">{progress.current}</span>
            <div className="flex items-center gap-2 shrink-0 ml-auto">
              <Progress value={pct} className="w-24 h-1.5" />
              <span className="text-xs text-muted-foreground tabular-nums">{progress.step}/{progress.total}</span>
            </div>
          </div>
        )}
        {!scanning && categories.length > 0 && (
          <span className="text-xs text-muted-foreground">
            {categories.length} categories ·{' '}
            <span className="text-foreground font-semibold">
              {formatBytes(categories.reduce((s, c) => s + c.size_bytes, 0))}
            </span>
            {lastScanAt != null && (
              <> · <span className="text-muted-foreground/60">scanned {formatRelative(Math.floor(lastScanAt / 1000))}</span></>
            )}
          </span>
        )}
      </div>

      {/* Group pills */}
      {categories.length > 0 && (
        <div className="flex items-center gap-1.5 px-5 py-2 border-b border-border overflow-x-auto shrink-0">
          {groups.map(g => (
            <button
              key={g}
              onClick={() => setActiveGroup(g)}
              className={`px-3 py-1 rounded-full text-xs font-medium shrink-0 transition-colors ${
                activeGroup === g
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-secondary text-secondary-foreground hover:bg-accent'
              }`}
            >
              {g}
            </button>
          ))}
        </div>
      )}

      {/* Content */}
      <ScrollArea className="flex-1">
        <div className="px-5 py-4 space-y-1">
          {categories.length === 0 && !scanning && (
            <p className="text-center text-muted-foreground text-xs mt-14">
              Click "Scan System" to analyze disk usage
            </p>
          )}
          {scanning && categories.length === 0 && (
            <p className="text-center text-muted-foreground text-xs mt-14 animate-pulse">Scanning...</p>
          )}

          <Accordion type="multiple">
            {Array.from(groupMap.entries()).map(([group, cats], gi) => (
              <div key={group}>
                {gi > 0 && <Separator className="my-4" />}
                {/* Group header */}
                <div className="flex items-center justify-between mb-2 px-1">
                  <div className="flex items-center gap-2">
                    <Checkbox
                      checked={groupChecked(selection, cats)}
                      onCheckedChange={() => setSelection(toggleGroup(selection, cats))}
                    />
                    <span className="text-xs font-bold text-muted-foreground uppercase tracking-widest">{group}</span>
                  </div>
                  <span className="text-xs text-muted-foreground">
                    {formatBytes(cats.reduce((s, c) => s + c.size_bytes, 0))}
                  </span>
                </div>

                {/* Category items */}
                {cats.map(cat => (
                  <AccordionItem
                    key={cat.id}
                    value={cat.id}
                    className="border border-border rounded-lg mb-1.5 overflow-hidden bg-card"
                  >
                    <div className="flex items-center gap-2 pl-3">
                      <Checkbox
                        checked={catChecked(selection, cat.id)}
                        onCheckedChange={() => setSelection(toggleCat(selection, cat.id))}
                        onClick={e => e.stopPropagation()}
                      />
                      <AccordionTrigger className="flex-1 py-2.5 hover:no-underline">
                        <div className="flex items-center gap-2.5 flex-1 min-w-0 mr-2">
                          <span className="text-sm leading-none shrink-0">{cat.icon}</span>
                          <span className="text-xs font-medium text-foreground truncate flex-1 text-left">
                            {cat.label}
                          </span>
                          {cat.item_count > 0 && (
                            <span className="text-xs text-muted-foreground shrink-0 tabular-nums">
                              {cat.item_count}
                            </span>
                          )}
                          <span className={`text-xs font-semibold shrink-0 tabular-nums ${
                            cat.size_bytes > 1_073_741_824 ? 'text-destructive'
                            : cat.size_bytes > 104_857_600 ? 'text-amber-400'
                            : 'text-muted-foreground'
                          }`}>
                            {cat.size_bytes > 0 ? formatBytes(cat.size_bytes) : '—'}
                          </span>
                          <Badge
                            variant={cat.safe ? 'outline' : 'destructive'}
                            className="shrink-0 text-[9px] px-1.5 py-0"
                          >
                            {cat.safe ? 'safe' : 'caution'}
                          </Badge>
                        </div>
                      </AccordionTrigger>
                    </div>

                    <AccordionContent className="pb-0">
                      {cat.items.length === 0
                        ? <p className="px-10 py-2 text-xs text-muted-foreground">No detail available</p>
                        : (
                          <div className="border-t border-border">
                            {cat.items.map((item, i) => (
                              <div
                                key={item.path}
                                className={`flex items-center gap-2.5 pl-10 pr-3 py-2 text-xs ${
                                  i < cat.items.length - 1 ? 'border-b border-border/50' : ''
                                }`}
                              >
                                <Checkbox
                                  checked={itemChecked(selection, cat.id, item.path)}
                                  onCheckedChange={() => setSelection(toggleItem(selection, cat.id, item.path, cat))}
                                />
                                <span className="flex-1 text-muted-foreground truncate font-mono">
                                  {item.path}
                                </span>
                                {item.modified_at != null && (
                                  <span className="text-muted-foreground/50 shrink-0">
                                    {formatRelative(item.modified_at)}
                                  </span>
                                )}
                                <span className={`font-semibold shrink-0 tabular-nums ${
                                  item.size_bytes > 1_073_741_824 ? 'text-destructive'
                                  : item.size_bytes > 104_857_600 ? 'text-amber-400'
                                  : 'text-muted-foreground'
                                }`}>
                                  {formatBytes(item.size_bytes)}
                                </span>
                              </div>
                            ))}
                          </div>
                        )
                      }
                    </AccordionContent>
                  </AccordionItem>
                ))}
              </div>
            ))}
          </Accordion>

          {cleanLog.length > 0 && (
            <div className="mt-4 rounded-lg border border-border p-3 bg-background font-mono">
              {cleanLog.map((line, i) => (
                <div key={i} className={`text-xs leading-relaxed ${
                  line.startsWith('[ERR]') ? 'text-destructive'
                  : line.startsWith('✓') ? 'text-primary'
                  : 'text-muted-foreground'
                }`}>{line}</div>
              ))}
            </div>
          )}
        </div>
      </ScrollArea>

      {/* Action bar */}
      <div className="flex items-center justify-between px-5 py-3 border-t border-border bg-card shrink-0">
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={selectSafe} disabled={scanning}>Select safe</Button>
          <Button variant="outline" size="sm" onClick={() => setSelection(new Map())} disabled={selCount === 0}>Clear</Button>
          {selCount > 0 && (
            <span className="text-xs text-muted-foreground">
              <span className="text-foreground font-semibold">{selCount}</span> selected ·{' '}
              <span className="text-amber-400 font-semibold">{formatBytes(selBytes)}</span>
            </span>
          )}
        </div>
        <Button variant="destructive" size="sm" onClick={handleClean} disabled={selCount === 0 || cleaning}>
          {cleaning ? 'Cleaning...' : `🗑 Clean (${selCount})`}
        </Button>
      </div>
    </div>
  );
};
