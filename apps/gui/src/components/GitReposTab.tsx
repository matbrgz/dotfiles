import React, { useState, useEffect, useCallback, useRef } from 'react';
import { guiCommands, type GitRepoDetail } from '@dotfiles/gui-engine';
import { homeDir } from '@tauri-apps/api/path';
import { ScrollArea } from '@/components/ui/scroll-area';
import { RepoDetail, relativeTime } from './GitRepoDetail';
import {
  loadBook, saveBook, mergeRepo, markStale,
  type ProjectBook, type ProjectEntry,
} from '../lib/projectBook';

// ── RepoCard ─────────────────────────────────────────────────────────────────

interface RepoCardProps {
  entry: ProjectEntry;
  isSelected: boolean;
  onSelect: (path: string) => void;
  onPin: (path: string, pinned: boolean) => void;
  onAddTag: (path: string, tag: string) => void;
  onRemoveTag: (path: string, tag: string) => void;
}

const RepoCard = React.memo(function RepoCard({ entry, isSelected, onSelect, onPin, onAddTag, onRemoveTag }: RepoCardProps) {
  const [addingTag, setAddingTag] = useState(false);
  const [tagInput, setTagInput] = useState('');
  const { summary } = entry;

  const commitTag = () => {
    tagInput.split(',').map(t => t.trim().toLowerCase()).filter(Boolean).forEach(t => onAddTag(entry.path, t));
    setTagInput('');
    setAddingTag(false);
  };

  return (
    <div
      className={`relative rounded-xl border p-3 cursor-pointer transition-all ${
        isSelected
          ? 'border-primary bg-primary/5'
          : entry.stale
          ? 'border-border/40 bg-card opacity-50'
          : 'border-border bg-card hover:border-border/80 hover:bg-card/80'
      }`}
      onClick={() => onSelect(entry.path)}
    >
      {entry.stale && (
        <span className="absolute top-2 right-2 text-[8px] font-bold uppercase tracking-widest text-muted-foreground bg-muted px-1.5 py-0.5 rounded">
          not found
        </span>
      )}

      {/* Header: pin + name */}
      <div className="flex items-start gap-2 mb-1.5">
        <button
          onClick={e => { e.stopPropagation(); onPin(entry.path, !entry.pinned); }}
          className="text-sm leading-none mt-0.5 shrink-0 hover:opacity-70 transition-opacity"
          title={entry.pinned ? 'Unpin' : 'Pin'}
        >
          {entry.pinned ? '★' : '☆'}
        </button>
        <span className="text-xs font-semibold text-foreground truncate flex-1">{entry.name}</span>
      </div>

      {/* Git status */}
      {summary ? (
        <>
          <div className="flex items-center gap-1.5 mb-1 pl-5">
            <span className="text-[10px] text-primary font-mono">{summary.current_branch}</span>
            {summary.is_dirty && <span className="w-1.5 h-1.5 rounded-full bg-amber-400 shrink-0" title="dirty" />}
            {summary.ahead > 0 && <span className="text-[9px] text-emerald-400 font-mono">↑{summary.ahead}</span>}
            {summary.behind > 0 && <span className="text-[9px] text-blue-400 font-mono">↓{summary.behind}</span>}
            {summary.stash_count > 0 && <span className="text-[9px] text-muted-foreground">· {summary.stash_count}s</span>}
          </div>
          <p className="text-[10px] text-muted-foreground truncate pl-5 mb-1">{summary.last_commit_msg || 'No commits'}</p>
          {summary.last_commit_ts > 0 && (
            <p className="text-[9px] text-muted-foreground/60 pl-5 mb-2">{relativeTime(summary.last_commit_ts)}</p>
          )}
        </>
      ) : (
        <p className="text-[10px] text-muted-foreground/50 pl-5 mb-2">Not yet scanned</p>
      )}

      {/* Tags */}
      <div className="flex items-center flex-wrap gap-1 pl-5" onClick={e => e.stopPropagation()}>
        {entry.tags.map(tag => (
          <span
            key={tag}
            className="group flex items-center gap-0.5 text-[9px] px-1.5 py-0.5 rounded-full bg-primary/10 border border-primary/20 text-primary cursor-default"
          >
            #{tag}
            <button
              onClick={() => onRemoveTag(entry.path, tag)}
              className="opacity-0 group-hover:opacity-100 text-primary hover:text-red-400 leading-none transition-opacity ml-0.5"
            >
              ×
            </button>
          </span>
        ))}
        {addingTag ? (
          <input
            autoFocus
            value={tagInput}
            onChange={e => setTagInput(e.target.value)}
            onKeyDown={e => {
              if (e.key === 'Enter' || e.key === ',') { e.preventDefault(); commitTag(); }
              if (e.key === 'Escape') { setTagInput(''); setAddingTag(false); }
            }}
            onBlur={() => { if (tagInput.trim()) commitTag(); else { setTagInput(''); setAddingTag(false); } }}
            placeholder="tag…"
            className="text-[9px] w-16 bg-transparent border-b border-primary outline-none text-foreground placeholder:text-muted-foreground"
          />
        ) : (
          <button
            onClick={() => setAddingTag(true)}
            className="text-[9px] text-muted-foreground hover:text-primary px-1 py-0.5 rounded-full border border-dashed border-border hover:border-primary transition-colors"
          >
            +
          </button>
        )}
      </div>
    </div>
  );
});

// ── GitReposTab ──────────────────────────────────────────────────────────────

export const GitReposTab: React.FC = () => {
  const [book, setBook] = useState<ProjectBook>({});
  const [view, setView] = useState<'pinned' | 'all'>('pinned');
  const [searchQuery, setSearchQuery] = useState('');
  const [tagFilters, setTagFilters] = useState<string[]>([]);
  const [scanning, setScanning] = useState(false);
  const [scanCount, setScanCount] = useState(0);
  const [selectedPath, setSelectedPath] = useState<string | null>(null);
  const [detail, setDetail] = useState<GitRepoDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [inProgress, setInProgress] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null);
  const [scanRoots, setScanRoots] = useState<string[]>(['~']);
  const [expandedRoots, setExpandedRoots] = useState<string[]>([]);
  const [collapsedCategories, setCollapsedCategories] = useState<Set<string>>(() => {
    try {
      const raw = sessionStorage.getItem('git-repos:collapsed');
      return raw ? new Set(JSON.parse(raw) as string[]) : new Set();
    } catch { return new Set(); }
  });
  const hasScanRan = useRef(false);
  const selectedPathRef = useRef<string | null>(null);

  const updateBook = useCallback((updater: (prev: ProjectBook) => ProjectBook) => {
    setBook(prev => {
      const next = updater(prev);
      saveBook(next);
      return next;
    });
  }, []);

  const doScan = useCallback(async (roots: string[], expRoots: string[]) => {
    setScanning(true);
    setScanCount(0);
    const scanStart = Date.now();
    try {
      await guiCommands.scanGitRepos(roots, (repo) => {
        setScanCount(n => n + 1);
        updateBook(prev => mergeRepo(prev, repo, expRoots, scanStart));
      });
      updateBook(prev => markStale(prev, scanStart));
    } finally {
      setScanning(false);
    }
  }, [updateBook]);

  useEffect(() => {
    if (hasScanRan.current) return;
    hasScanRan.current = true;
    (async () => {
      setBook(loadBook());

      let roots = ['~'];
      try {
        const s = await guiCommands.getUserSettings();
        const saved = (s as any).git_scan_roots as string[] | undefined;
        if (saved && saved.length > 0) { roots = saved; setScanRoots(saved); }
      } catch {}

      let expRoots = roots;
      try {
        const home = await homeDir();
        expRoots = roots.map(r => r.startsWith('~') ? home + r.slice(1) : r);
      } catch {}
      setExpandedRoots(expRoots);

      doScan(roots, expRoots);
    })();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const closePanel = useCallback(() => {
    selectedPathRef.current = null;
    setSelectedPath(null);
  }, []);

  useEffect(() => {
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') closePanel(); };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [closePanel]);

  const selectRepo = useCallback(async (path: string) => {
    if (selectedPathRef.current === path) {
      setSelectedPath(null);
      selectedPathRef.current = null;
      return;
    }
    selectedPathRef.current = path;
    setSelectedPath(path);
    setDetail(null);
    setDetailLoading(true);
    setActionError(null);
    try {
      const d = await guiCommands.getRepoDetail(path);
      if (selectedPathRef.current !== path) return;
      setDetail(d);
    } finally {
      if (selectedPathRef.current === path) setDetailLoading(false);
    }
  }, []);

  const handleAction = useCallback(async (actionType: string, params: Record<string, unknown> = {}) => {
    if (!selectedPath || inProgress) return;
    setInProgress(actionType);
    setActionError(null);
    try {
      await guiCommands.gitAction(selectedPath, actionType, params);
      if (selectedPathRef.current !== selectedPath) return;
      if (!['open_terminal', 'open_vscode'].includes(actionType)) {
        const d = await guiCommands.getRepoDetail(selectedPath);
        if (selectedPathRef.current !== selectedPath) return;
        setDetail(d);
        updateBook(prev => mergeRepo(prev, d.summary, expandedRoots, Date.now()));
      }
    } catch (e) {
      setActionError(String(e));
    } finally {
      setInProgress(null);
    }
  }, [selectedPath, expandedRoots, inProgress, updateBook]);

  const handlePin = useCallback((path: string, pinned: boolean) =>
    updateBook(prev => ({ ...prev, [path]: { ...prev[path], pinned } })), [updateBook]);

  const handleAddTag = useCallback((path: string, tag: string) =>
    updateBook(prev => {
      const entry = prev[path];
      if (!entry) return prev;
      return { ...prev, [path]: { ...entry, tags: Array.from(new Set([...entry.tags, tag])) } };
    }), [updateBook]);

  const handleRemoveTag = useCallback((path: string, tag: string) =>
    updateBook(prev => {
      const entry = prev[path];
      if (!entry) return prev;
      return { ...prev, [path]: { ...entry, tags: entry.tags.filter(t => t !== tag) } };
    }), [updateBook]);

  const toggleCategory = (category: string) => {
    setCollapsedCategories(prev => {
      const next = new Set(prev);
      if (next.has(category)) next.delete(category); else next.add(category);
      try { sessionStorage.setItem('git-repos:collapsed', JSON.stringify(Array.from(next))); } catch {}
      return next;
    });
  };

  // Derived: filtered + grouped
  const allEntries = Object.values(book);
  const allTags = Array.from(new Set(allEntries.flatMap(e => e.tags))).sort();

  const filtered = allEntries.filter(entry => {
    if (view === 'pinned' && !entry.pinned) return false;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      if (!entry.name.toLowerCase().includes(q) && !entry.path.toLowerCase().includes(q)) return false;
    }
    if (tagFilters.length > 0 && !tagFilters.every(t => entry.tags.includes(t))) return false;
    return true;
  });

  type SubMap = Map<string, ProjectEntry[]>;
  type GroupedData = Map<string, SubMap>;
  const grouped: GroupedData = new Map();
  for (const entry of filtered.sort((a, b) =>
    (b.summary?.last_commit_ts ?? 0) - (a.summary?.last_commit_ts ?? 0)
  )) {
    const cat = entry.category || '(root)';
    const sub = entry.subcategory || '';
    if (!grouped.has(cat)) grouped.set(cat, new Map());
    const subMap = grouped.get(cat)!;
    if (!subMap.has(sub)) subMap.set(sub, []);
    subMap.get(sub)!.push(entry);
  }

  const panelOpen = selectedPath !== null;

  return (
    <div className="flex h-full overflow-hidden">
      {/* ── Main area ─────────────────────────────────────────────────── */}
      <div
        className="flex flex-col overflow-hidden transition-[width] duration-200 ease-out"
        style={{ width: panelOpen ? '55%' : '100%' }}
      >
        {/* Filter bar */}
        <div className="flex items-center gap-2 px-4 py-2.5 border-b border-border flex-wrap shrink-0">
          <div className="flex rounded-lg overflow-hidden border border-border">
            {(['pinned', 'all'] as const).map(v => (
              <button
                key={v}
                onClick={() => setView(v)}
                className={`text-[10px] font-semibold px-3 py-1.5 transition-colors ${
                  view === v ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:text-foreground hover:bg-accent'
                }`}
              >
                {v === 'pinned' ? '★ Pinned' : 'All'}
              </button>
            ))}
          </div>

          <input
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            placeholder="Search repos…"
            className="text-xs bg-muted/30 border border-border rounded-md px-3 py-1.5 text-foreground placeholder:text-muted-foreground outline-none focus:border-primary w-40"
          />

          {allTags.map(tag => (
            <button
              key={tag}
              onClick={() => setTagFilters(prev =>
                prev.includes(tag) ? prev.filter(t => t !== tag) : [...prev, tag]
              )}
              className={`text-[9px] px-2 py-1 rounded-full border font-medium transition-colors ${
                tagFilters.includes(tag)
                  ? 'bg-primary/20 border-primary/40 text-primary'
                  : 'border-border text-muted-foreground hover:text-foreground hover:bg-accent'
              }`}
            >
              #{tag}
            </button>
          ))}

          <button
            onClick={() => doScan(scanRoots, expandedRoots)}
            disabled={scanning}
            className="ml-auto text-xs px-3 py-1.5 rounded-md border border-border text-muted-foreground hover:text-foreground hover:bg-accent disabled:opacity-50 transition-colors"
          >
            {scanning ? `Scanning… ${scanCount}` : '↻ Scan'}
          </button>
        </div>

        {/* Grouped card grid */}
        <ScrollArea className="flex-1">
          <div className="p-4 space-y-4">
            {grouped.size === 0 && (
              <div className="py-12 text-center text-xs text-muted-foreground">
                {view === 'pinned' && !allEntries.some(e => e.pinned)
                  ? 'No pinned repos yet. Click ☆ on any repo card to pin it.'
                  : allEntries.length === 0
                  ? 'No repos found. Click ↻ Scan to discover repos.'
                  : 'No repos match your search.'}
              </div>
            )}

            {Array.from(grouped.entries()).map(([category, subMap]) => {
              const isCollapsed = collapsedCategories.has(category);
              const total = Array.from(subMap.values()).reduce((n, arr) => n + arr.length, 0);
              return (
                <div key={category}>
                  <button
                    onClick={() => toggleCategory(category)}
                    className="flex items-center gap-2 mb-2 w-full text-left"
                  >
                    <span className="text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
                      {isCollapsed ? '▶' : '▼'} {category}
                    </span>
                    <span className="text-[9px] text-muted-foreground/60">({total})</span>
                    <div className="flex-1 h-px bg-border/50 ml-1" />
                  </button>

                  {!isCollapsed && Array.from(subMap.entries()).map(([sub, entries]) => (
                    <div key={sub} className="mb-3">
                      {sub && (
                        <p className="text-[9px] text-muted-foreground uppercase tracking-widest mb-2 pl-0.5">{sub}</p>
                      )}
                      <div className="grid gap-2" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))' }}>
                        {entries.map(entry => (
                          <RepoCard
                            key={entry.path}
                            entry={entry}
                            isSelected={selectedPath === entry.path}
                            onSelect={selectRepo}
                            onPin={handlePin}
                            onAddTag={handleAddTag}
                            onRemoveTag={handleRemoveTag}
                          />
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              );
            })}
          </div>
        </ScrollArea>
      </div>

      {/* ── Detail panel ──────────────────────────────────────────────── */}
      <div
        className={`flex flex-col border-l border-border overflow-hidden transition-[width,opacity] duration-200 ease-out ${
          panelOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'
        }`}
        style={{ width: panelOpen ? '45%' : '0%' }}
      >
        <div className="flex items-center justify-between px-4 py-2 border-b border-border shrink-0 bg-card/50">
          <span className="text-xs font-semibold text-foreground truncate">
            {selectedPath ? (book[selectedPath]?.name ?? '') : ''}
          </span>
          <button
            onClick={closePanel}
            className="text-muted-foreground hover:text-foreground text-sm leading-none ml-2 shrink-0"
          >
            ×
          </button>
        </div>

        {detailLoading ? (
          <div className="flex-1 flex items-center justify-center">
            <span className="text-xs text-muted-foreground animate-pulse">Loading…</span>
          </div>
        ) : detail ? (
          <RepoDetail
            detail={detail}
            onAction={handleAction}
            inProgress={inProgress}
            actionError={actionError}
            onClearError={() => setActionError(null)}
            confirmDelete={confirmDelete}
            setConfirmDelete={setConfirmDelete}
          />
        ) : null}
      </div>
    </div>
  );
};
