import React, { useState, useEffect, useCallback, useRef } from 'react';
import { guiCommands, type GitRepoSummary, type GitRepoDetail } from '@dotfiles/gui-engine';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';
import { ScrollArea } from '@/components/ui/scroll-area';

function relativeTime(ts: number): string {
  if (!ts) return '';
  const diff = Math.floor(Date.now() / 1000) - ts;
  if (diff < 60) return `${diff}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  if (diff < 86400 * 30) return `${Math.floor(diff / 86400)}d ago`;
  return new Date(ts * 1000).toLocaleDateString();
}

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

interface RepoDetailProps {
  detail: GitRepoDetail;
  onAction: (type: string, params?: Record<string, unknown>) => Promise<void>;
  inProgress: string | null;
  actionError: string | null;
  onClearError: () => void;
  confirmDelete: string | null;
  setConfirmDelete: (v: string | null) => void;
}

function ActionBtn({ label, type, params, danger = false, inProgress, onAction }: {
  label: string;
  type: string;
  params?: Record<string, unknown>;
  danger?: boolean;
  inProgress: string | null;
  onAction: (type: string, params?: Record<string, unknown>) => Promise<void>;
}) {
  return (
    <button
      onClick={() => onAction(type, params)}
      disabled={!!inProgress}
      className={`text-xs px-3 py-1.5 rounded-md border transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${
        danger
          ? 'border-red-400/30 text-red-400 hover:bg-red-500/10'
          : 'border-border text-muted-foreground hover:text-foreground hover:bg-accent'
      }`}
    >
      {inProgress === type ? '…' : label}
    </button>
  );
}

function RepoDetail({ detail, onAction, inProgress, actionError, onClearError, confirmDelete, setConfirmDelete }: RepoDetailProps) {
  const { summary, branches, commits, remotes, stashes, tags } = detail;
  const localBranches = branches.filter(b => !b.is_remote);
  const remoteBranches = branches.filter(b => b.is_remote);
  const [newBranchName, setNewBranchName] = useState('');
  const [showNewBranch, setShowNewBranch] = useState(false);
  const [stashMsg, setStashMsg] = useState('');
  const [showStashInput, setShowStashInput] = useState(false);
  const defaultRemote = remotes[0]?.name ?? 'origin';

  return (
    <div className="flex flex-col h-full overflow-hidden">
      {/* Header */}
      <div className="px-5 py-4 border-b border-border bg-card/50 shrink-0">
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="min-w-0">
            <h2 className="text-sm font-bold text-foreground">{summary.name}</h2>
            <p className="text-[10px] text-muted-foreground font-mono truncate mt-0.5">{summary.path}</p>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <span className="text-[10px] font-mono text-primary bg-primary/10 px-2 py-1 rounded-md border border-primary/20">{summary.current_branch}</span>
            <span className={`text-[10px] px-2 py-1 rounded-md border ${summary.is_dirty ? 'text-amber-400 bg-amber-500/10 border-amber-400/20' : 'text-emerald-400 bg-emerald-500/10 border-emerald-400/20'}`}>
              {summary.is_dirty ? '● dirty' : '✓ clean'}
            </span>
          </div>
        </div>

        {/* Action bar */}
        <div className="flex items-center gap-2 flex-wrap">
          <ActionBtn label="Fetch" type="fetch" params={{ remote: defaultRemote }} inProgress={inProgress} onAction={onAction} />
          <ActionBtn label="Pull" type="pull" params={{ remote: defaultRemote, branch: summary.current_branch }} inProgress={inProgress} onAction={onAction} />
          <ActionBtn label="Push" type="push" params={{ remote: defaultRemote, branch: summary.current_branch }} inProgress={inProgress} onAction={onAction} />
          <div className="w-px h-4 bg-border mx-1" />
          <ActionBtn label="Terminal" type="open_terminal" inProgress={inProgress} onAction={onAction} />
          <ActionBtn label="VS Code" type="open_vscode" inProgress={inProgress} onAction={onAction} />
        </div>

        {actionError && (
          <div className="mt-2 px-3 py-2 rounded-md bg-red-500/10 border border-red-400/30 text-xs text-red-400 flex items-start justify-between gap-2">
            <span className="font-mono break-all">{actionError}</span>
            <button onClick={onClearError} className="shrink-0 hover:opacity-70 text-sm leading-none">×</button>
          </div>
        )}
      </div>

      {/* Accordion sections */}
      <ScrollArea className="flex-1">
        <Accordion type="multiple" defaultValue={['branches', 'commits']} className="px-4 py-2">

          {/* Branches */}
          <AccordionItem value="branches">
            <AccordionTrigger className="text-xs font-semibold py-3">
              Branches
              <span className="text-muted-foreground font-normal ml-1.5">
                ({localBranches.length} local{remoteBranches.length > 0 ? `, ${remoteBranches.length} remote` : ''})
              </span>
            </AccordionTrigger>
            <AccordionContent className="space-y-1 pb-3">
              {localBranches.map(b => (
                <div key={b.name} className={`flex items-center justify-between gap-2 px-2.5 py-2 rounded-md ${b.is_current ? 'bg-primary/10 border border-primary/20' : 'hover:bg-muted/30'}`}>
                  <div className="flex items-center gap-2 min-w-0">
                    {b.is_current && <span className="text-primary text-[10px] shrink-0">●</span>}
                    <span className="text-xs font-mono text-foreground truncate">{b.name}</span>
                    {b.ahead != null && b.ahead > 0 && <span className="text-[9px] text-emerald-400 shrink-0">↑{b.ahead}</span>}
                    {b.behind != null && b.behind > 0 && <span className="text-[9px] text-blue-400 shrink-0">↓{b.behind}</span>}
                  </div>
                  {!b.is_current && (
                    <div className="flex items-center gap-1 shrink-0">
                      <button
                        onClick={() => onAction('checkout', { branch: b.name })}
                        disabled={!!inProgress}
                        className="text-[10px] px-2 py-0.5 rounded border border-border text-muted-foreground hover:text-foreground hover:bg-accent disabled:opacity-50"
                      >
                        Checkout
                      </button>
                      <button
                        onClick={() => {
                          if (confirmDelete === b.name) {
                            onAction('delete_branch', { name: b.name, force: false });
                            setConfirmDelete(null);
                          } else {
                            setConfirmDelete(b.name);
                            setTimeout(() => setConfirmDelete(null), 3000);
                          }
                        }}
                        disabled={!!inProgress}
                        className={`text-[10px] px-2 py-0.5 rounded border disabled:opacity-50 transition-colors ${
                          confirmDelete === b.name
                            ? 'border-red-400/50 bg-red-500/10 text-red-400'
                            : 'border-border text-muted-foreground hover:text-red-400'
                        }`}
                      >
                        {confirmDelete === b.name ? 'Sure?' : '✕'}
                      </button>
                    </div>
                  )}
                </div>
              ))}

              {remoteBranches.length > 0 && (
                <div className="mt-3 space-y-1">
                  <p className="text-[9px] text-muted-foreground uppercase tracking-widest px-1 mb-1.5">Remote</p>
                  {remoteBranches.map(b => (
                    <div key={b.name} className="flex items-center justify-between gap-2 px-2.5 py-1.5 rounded-md hover:bg-muted/20">
                      <span className="text-[10px] font-mono text-muted-foreground truncate">{b.name}</span>
                      <button
                        onClick={() => onAction('checkout', { branch: b.name.replace(/^origin\//, '') })}
                        disabled={!!inProgress}
                        className="text-[10px] px-2 py-0.5 rounded border border-border text-muted-foreground hover:text-foreground hover:bg-accent disabled:opacity-50"
                      >
                        Track
                      </button>
                    </div>
                  ))}
                </div>
              )}

              <div className="mt-3">
                {showNewBranch ? (
                  <div className="flex gap-1.5">
                    <input
                      value={newBranchName}
                      onChange={e => setNewBranchName(e.target.value)}
                      onKeyDown={e => {
                        if (e.key === 'Enter' && newBranchName.trim()) {
                          onAction('create_branch', { name: newBranchName.trim(), from: 'HEAD' });
                          setNewBranchName('');
                          setShowNewBranch(false);
                        }
                      }}
                      placeholder="new-branch-name"
                      className="flex-1 text-xs bg-background border border-border rounded-md px-2 py-1.5 text-foreground placeholder:text-muted-foreground outline-none focus:border-primary"
                      autoFocus
                    />
                    <button
                      onClick={() => { if (newBranchName.trim()) { onAction('create_branch', { name: newBranchName.trim(), from: 'HEAD' }); setNewBranchName(''); setShowNewBranch(false); } }}
                      className="text-xs px-3 py-1.5 rounded-md bg-primary text-primary-foreground"
                    >
                      Create
                    </button>
                    <button onClick={() => setShowNewBranch(false)} className="text-xs px-2 py-1.5 rounded-md border border-border text-muted-foreground">Cancel</button>
                  </div>
                ) : (
                  <button onClick={() => setShowNewBranch(true)} className="text-xs text-primary hover:opacity-80">+ New branch</button>
                )}
              </div>
            </AccordionContent>
          </AccordionItem>

          {/* Commits */}
          <AccordionItem value="commits">
            <AccordionTrigger className="text-xs font-semibold py-3">
              Commits <span className="text-muted-foreground font-normal ml-1.5">({commits.length})</span>
            </AccordionTrigger>
            <AccordionContent className="space-y-0.5 pb-3">
              {commits.map(c => (
                <div key={c.full_hash} className="flex items-start gap-3 px-2 py-2 rounded-md hover:bg-muted/20">
                  <span className="text-[10px] font-mono text-primary shrink-0 mt-0.5">{c.short_hash}</span>
                  <div className="min-w-0 flex-1">
                    <p className="text-xs text-foreground truncate">{c.message}</p>
                    <p className="text-[9px] text-muted-foreground mt-0.5">{c.author} · {relativeTime(c.ts)}</p>
                  </div>
                </div>
              ))}
            </AccordionContent>
          </AccordionItem>

          {/* Remotes */}
          <AccordionItem value="remotes">
            <AccordionTrigger className="text-xs font-semibold py-3">
              Remotes <span className="text-muted-foreground font-normal ml-1.5">({remotes.length})</span>
            </AccordionTrigger>
            <AccordionContent className="pb-3">
              {remotes.length === 0 ? (
                <p className="text-xs text-muted-foreground px-2">No remotes configured</p>
              ) : (
                <div className="space-y-1">
                  {remotes.map(r => (
                    <div key={r.name} className="flex items-center justify-between gap-3 px-2.5 py-2.5 rounded-md bg-muted/20">
                      <div className="min-w-0">
                        <p className="text-xs font-semibold text-foreground">{r.name}</p>
                        <p className="text-[10px] font-mono text-muted-foreground truncate">{r.url}</p>
                      </div>
                      <button
                        onClick={() => navigator.clipboard.writeText(r.url)}
                        className="text-[10px] text-muted-foreground hover:text-foreground shrink-0 px-2 py-0.5 rounded border border-border hover:bg-accent transition-colors"
                      >
                        Copy
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </AccordionContent>
          </AccordionItem>

          {/* Stashes */}
          <AccordionItem value="stashes">
            <AccordionTrigger className="text-xs font-semibold py-3">
              Stashes <span className="text-muted-foreground font-normal ml-1.5">({stashes.length})</span>
            </AccordionTrigger>
            <AccordionContent className="pb-3">
              <div className="mb-2">
                {showStashInput ? (
                  <div className="flex gap-1.5">
                    <input
                      value={stashMsg}
                      onChange={e => setStashMsg(e.target.value)}
                      onKeyDown={e => {
                        if (e.key === 'Enter') {
                          onAction('stash_push', { message: stashMsg.trim() || null });
                          setStashMsg('');
                          setShowStashInput(false);
                        }
                      }}
                      placeholder="Stash message (optional)"
                      className="flex-1 text-xs bg-background border border-border rounded-md px-2 py-1.5 text-foreground placeholder:text-muted-foreground outline-none focus:border-primary"
                      autoFocus
                    />
                    <button
                      onClick={() => { onAction('stash_push', { message: stashMsg.trim() || null }); setStashMsg(''); setShowStashInput(false); }}
                      className="text-xs px-3 py-1.5 rounded-md bg-primary text-primary-foreground"
                    >
                      Stash
                    </button>
                    <button onClick={() => setShowStashInput(false)} className="text-xs px-2 py-1.5 rounded-md border border-border text-muted-foreground">Cancel</button>
                  </div>
                ) : (
                  <button onClick={() => setShowStashInput(true)} className="text-xs text-primary hover:opacity-80">+ Stash changes</button>
                )}
              </div>
              {stashes.length === 0 ? (
                <p className="text-xs text-muted-foreground px-2">No stashes</p>
              ) : (
                <div className="space-y-1">
                  {stashes.map(s => (
                    <div key={s.index} className="flex items-center justify-between gap-2 px-2.5 py-2 rounded-md bg-muted/20">
                      <div className="min-w-0">
                        <p className="text-xs text-foreground truncate">{s.message}</p>
                        {s.ts > 0 && <p className="text-[9px] text-muted-foreground">{relativeTime(s.ts)}</p>}
                      </div>
                      <div className="flex gap-1 shrink-0">
                        <button onClick={() => onAction('stash_pop', { index: s.index })} disabled={!!inProgress} className="text-[10px] px-2 py-0.5 rounded border border-border text-muted-foreground hover:text-foreground hover:bg-accent disabled:opacity-50">Pop</button>
                        <button onClick={() => onAction('stash_drop', { index: s.index })} disabled={!!inProgress} className="text-[10px] px-2 py-0.5 rounded border border-red-400/30 text-red-400 hover:bg-red-500/10 disabled:opacity-50">Drop</button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </AccordionContent>
          </AccordionItem>

          {/* Tags (only shown when present) */}
          {tags.length > 0 && (
            <AccordionItem value="tags">
              <AccordionTrigger className="text-xs font-semibold py-3">
                Tags <span className="text-muted-foreground font-normal ml-1.5">({tags.length})</span>
              </AccordionTrigger>
              <AccordionContent className="pb-3">
                <div className="flex flex-wrap gap-1.5">
                  {tags.map(tag => (
                    <span key={tag} className="text-[10px] font-mono px-2 py-0.5 rounded-md bg-muted/40 border border-border text-muted-foreground">
                      {tag}
                    </span>
                  ))}
                </div>
              </AccordionContent>
            </AccordionItem>
          )}

        </Accordion>
      </ScrollArea>
    </div>
  );
}
