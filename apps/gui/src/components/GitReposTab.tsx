import React, { useState, useEffect, useCallback, useRef } from 'react';
import { guiCommands, type GitRepoSummary, type GitRepoDetail } from '@dotfiles/gui-engine';
import { ScrollArea } from '@/components/ui/scroll-area';
import { RepoDetail, relativeTime } from './GitRepoDetail';

export const GitReposTab: React.FC = () => {
  const [repos, setRepos] = useState<GitRepoSummary[]>([]);
  const [selected, setSelected] = useState<string | null>(null);
  const [detail, setDetail] = useState<GitRepoDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [scanning, setScanning] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [scanRoots, setScanRoots] = useState<string[]>(['~']);
  const [newRoot, setNewRoot] = useState('');
  const [actionError, setActionError] = useState<string | null>(null);
  const [inProgress, setInProgress] = useState<string | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null);
  const [showRoots, setShowRoots] = useState(false);
  const hasScanRan = useRef(false);

  const doScan = useCallback(async (roots: string[]) => {
    setScanning(true);
    setRepos([]);
    try {
      await guiCommands.scanGitRepos(
        roots,
        (repo) => setRepos(prev => [...prev, repo]),
      );
    } finally {
      setScanning(false);
    }
  }, []);

  // Load saved roots then auto-scan once on mount
  useEffect(() => {
    if (hasScanRan.current) return;
    hasScanRan.current = true;
    (async () => {
      let roots = ['~'];
      try {
        const s = await guiCommands.getUserSettings();
        const saved = (s as any).git_scan_roots as string[] | undefined;
        if (saved && saved.length > 0) {
          roots = saved;
          setScanRoots(saved);
        }
      } catch {}
      doScan(roots);
    })();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const selectRepo = async (path: string) => {
    setSelected(path);
    setDetail(null);
    setDetailLoading(true);
    setActionError(null);
    try {
      const d = await guiCommands.getRepoDetail(path);
      setDetail(d);
    } finally {
      setDetailLoading(false);
    }
  };

  const handleAction = async (actionType: string, params: Record<string, unknown> = {}) => {
    if (!selected || inProgress) return;
    setInProgress(actionType);
    setActionError(null);
    try {
      await guiCommands.gitAction(selected, actionType, params);
      if (!['open_terminal', 'open_vscode'].includes(actionType)) {
        const d = await guiCommands.getRepoDetail(selected);
        setDetail(d);
        setRepos(prev => prev.map(r => r.path === selected ? d.summary : r));
      }
    } catch (e) {
      setActionError(String(e));
    } finally {
      setInProgress(null);
    }
  };

  const saveScanRoots = async (roots: string[]) => {
    setScanRoots(roots);
    try {
      const s = await guiCommands.getUserSettings();
      await guiCommands.saveUserSettings({ ...s, git_scan_roots: roots } as any);
    } catch {}
  };

  const addRoot = () => {
    const trimmed = newRoot.trim();
    if (!trimmed) return;
    const updated = [...scanRoots, trimmed];
    saveScanRoots(updated);
    setNewRoot('');
  };

  const removeRoot = (root: string) => saveScanRoots(scanRoots.filter(r => r !== root));

  const filtered = repos
    .filter(r => !searchQuery || r.name.toLowerCase().includes(searchQuery.toLowerCase()) || r.path.toLowerCase().includes(searchQuery.toLowerCase()))
    .sort((a, b) => b.last_commit_ts - a.last_commit_ts);

  return (
    <div className="flex h-full overflow-hidden">
      {/* ── Left panel ─────────────────────────────────────────────────── */}
      <div className="w-80 shrink-0 border-r border-border flex flex-col overflow-hidden">

        {/* Scan roots collapsible */}
        <div className="border-b border-border">
          <button
            className="w-full flex items-center justify-between px-4 py-2.5 text-[10px] font-bold uppercase tracking-widest text-muted-foreground hover:text-foreground hover:bg-muted/30 transition-colors"
            onClick={() => setShowRoots(v => !v)}
          >
            <span>Scan Roots</span>
            <span>{showRoots ? '▲' : '▼'}</span>
          </button>
          {showRoots && (
            <div className="px-3 pb-3 space-y-1.5">
              {scanRoots.map(root => (
                <div key={root} className="flex items-center justify-between px-2.5 py-1.5 rounded-md bg-muted/40 border border-border gap-2">
                  <span className="text-xs font-mono text-foreground truncate">{root}</span>
                  <button onClick={() => removeRoot(root)} className="text-muted-foreground hover:text-red-400 text-sm shrink-0 leading-none">×</button>
                </div>
              ))}
              <div className="flex gap-1.5">
                <input
                  value={newRoot}
                  onChange={e => setNewRoot(e.target.value)}
                  onKeyDown={e => e.key === 'Enter' && addRoot()}
                  placeholder="~/path/to/projects"
                  className="flex-1 text-xs bg-background border border-border rounded-md px-2 py-1.5 text-foreground placeholder:text-muted-foreground outline-none focus:border-primary"
                />
                <button onClick={addRoot} className="text-xs px-2.5 py-1.5 rounded-md bg-primary text-primary-foreground font-semibold">+</button>
              </div>
              <button
                onClick={() => doScan(scanRoots)}
                disabled={scanning}
                className="w-full text-xs py-1.5 rounded-md border border-border hover:bg-accent text-muted-foreground hover:text-foreground transition-colors disabled:opacity-50"
              >
                {scanning ? 'Scanning…' : '↻ Re-scan'}
              </button>
            </div>
          )}
        </div>

        {/* Search */}
        <div className="px-3 py-2 border-b border-border">
          <input
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            placeholder="Filter repos…"
            className="w-full text-xs bg-muted/30 border border-border rounded-md px-3 py-1.5 text-foreground placeholder:text-muted-foreground outline-none focus:border-primary"
          />
        </div>

        {/* Scan status bar */}
        {scanning && (
          <div className="px-4 py-2 text-[10px] text-muted-foreground border-b border-border animate-pulse">
            Scanning… {repos.length} found
          </div>
        )}
        {!scanning && repos.length > 0 && (
          <div className="px-4 py-1.5 text-[10px] text-muted-foreground border-b border-border">
            {filtered.length === repos.length ? `${repos.length} repos` : `${filtered.length} of ${repos.length}`}
          </div>
        )}

        {/* Repo list */}
        <ScrollArea className="flex-1">
          {filtered.length === 0 && !scanning && (
            <div className="px-4 py-8 text-xs text-muted-foreground text-center">
              {repos.length === 0
                ? 'No repos found.\nExpand Scan Roots to configure.'
                : 'No repos match filter.'}
            </div>
          )}
          {filtered.map(repo => (
            <button
              key={repo.path}
              onClick={() => selectRepo(repo.path)}
              className={`w-full text-left px-4 py-3 border-b border-border/50 transition-colors ${
                selected === repo.path
                  ? 'bg-primary/10 border-l-2 border-l-primary'
                  : 'hover:bg-muted/30'
              }`}
            >
              <div className="flex items-center justify-between gap-2 mb-0.5">
                <span className="text-xs font-semibold text-foreground truncate">{repo.name}</span>
                <div className="flex items-center gap-1 shrink-0">
                  {repo.is_dirty && <span className="w-1.5 h-1.5 rounded-full bg-amber-400" title="dirty" />}
                  {repo.ahead > 0 && <span className="text-[9px] text-emerald-400 font-mono">↑{repo.ahead}</span>}
                  {repo.behind > 0 && <span className="text-[9px] text-blue-400 font-mono">↓{repo.behind}</span>}
                </div>
              </div>
              <div className="flex items-center gap-1.5 mb-1">
                <span className="text-[10px] text-primary font-mono">{repo.current_branch}</span>
                {repo.stash_count > 0 && <span className="text-[9px] text-muted-foreground">· {repo.stash_count} stash</span>}
              </div>
              <div className="text-[10px] text-muted-foreground truncate">{repo.last_commit_msg || 'No commits'}</div>
              {repo.last_commit_ts > 0 && (
                <div className="text-[9px] text-muted-foreground/60 mt-0.5">{relativeTime(repo.last_commit_ts)}</div>
              )}
            </button>
          ))}
        </ScrollArea>
      </div>

      {/* ── Right panel ────────────────────────────────────────────────── */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {!selected ? (
          <div className="flex-1 flex items-center justify-center">
            <span className="text-xs text-muted-foreground">Select a repo to view details</span>
          </div>
        ) : detailLoading ? (
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
