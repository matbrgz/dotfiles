# Git Repos Tab Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Git Repos tab with a localStorage project book, category/subcategory grouped card grid, user-defined tags, pinning, and a slide-in detail panel.

**Architecture:** The `ProjectBook` lives in `localStorage` — repos load instantly from cache, then a background scan merges fresh git status. Pins and tags survive scans. A slide-in right panel replaces the fixed two-panel layout. No backend changes required.

**Tech Stack:** React, TypeScript, localStorage, `@tauri-apps/api/path` (homeDir), existing Tauri commands, Tailwind CSS, shadcn/ui (Accordion, ScrollArea).

---

## File Structure

| File | Role |
|------|------|
| `apps/gui/src/components/GitRepoDetail.tsx` | NEW — extracted `RepoDetail` + `ActionBtn` (no logic changes) |
| `apps/gui/src/lib/projectBook.ts` | NEW — `ProjectEntry`/`ProjectBook` types + localStorage utilities |
| `apps/gui/src/components/GitReposTab.tsx` | REWRITE — new layout: filter bar, card grid, slide-in panel |

---

### Task 1: Extract GitRepoDetail component

**Files:**
- Create: `apps/gui/src/components/GitRepoDetail.tsx`
- Modify: `apps/gui/src/components/GitReposTab.tsx` (lines 1–14, 246–553)

- [ ] **Step 1: Create `GitRepoDetail.tsx`**

Create `apps/gui/src/components/GitRepoDetail.tsx` with this exact content (extracted verbatim from the current `GitReposTab.tsx`):

```tsx
import React, { useState } from 'react';
import { type GitRepoDetail } from '@dotfiles/gui-engine';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';
import { ScrollArea } from '@/components/ui/scroll-area';

export function relativeTime(ts: number): string {
  if (!ts) return '';
  const diff = Math.floor(Date.now() / 1000) - ts;
  if (diff < 60) return `${diff}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  if (diff < 86400 * 30) return `${Math.floor(diff / 86400)}d ago`;
  return new Date(ts * 1000).toLocaleDateString();
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

export interface RepoDetailProps {
  detail: GitRepoDetail;
  onAction: (type: string, params?: Record<string, unknown>) => Promise<void>;
  inProgress: string | null;
  actionError: string | null;
  onClearError: () => void;
  confirmDelete: string | null;
  setConfirmDelete: (v: string | null) => void;
}

export function RepoDetail({ detail, onAction, inProgress, actionError, onClearError, confirmDelete, setConfirmDelete }: RepoDetailProps) {
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

          {/* Git tags (only shown when present) */}
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
```

- [ ] **Step 2: Update imports in `GitReposTab.tsx`**

Replace the top section of `apps/gui/src/components/GitReposTab.tsx` (lines 1–4, the import block) from:

```tsx
import React, { useState, useEffect, useCallback, useRef } from 'react';
import { guiCommands, type GitRepoSummary, type GitRepoDetail } from '@dotfiles/gui-engine';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';
import { ScrollArea } from '@/components/ui/scroll-area';
```

to:

```tsx
import React, { useState, useEffect, useCallback, useRef } from 'react';
import { guiCommands, type GitRepoDetail } from '@dotfiles/gui-engine';
import { ScrollArea } from '@/components/ui/scroll-area';
import { RepoDetail, type RepoDetailProps } from './GitRepoDetail';
```

- [ ] **Step 3: Remove extracted code from `GitReposTab.tsx`**

Delete everything from line 6 (`function relativeTime`) to line 553 (end of file) — that is, delete `relativeTime`, `ActionBtn`, `RepoDetailProps`, and `RepoDetail`. Keep only lines 1–5 (new imports) and lines 16–244 (the `GitReposTab` component and `RepoDetail` usage).

The kept portion of `GitReposTab.tsx` should look like this (no changes to logic — only the extracted symbols removed):

```tsx
import React, { useState, useEffect, useCallback, useRef } from 'react';
import { guiCommands, type GitRepoDetail } from '@dotfiles/gui-engine';
import { ScrollArea } from '@/components/ui/scroll-area';
import { RepoDetail, type RepoDetailProps } from './GitRepoDetail';

export const GitReposTab: React.FC = () => {
  // ... (all existing state and handlers unchanged)
};
```

- [ ] **Step 4: Type-check**

```bash
cd /path/to/worktree && yarn workspace @dotfiles/gui exec tsc --noEmit 2>&1 | grep -v TS2882
```

Expected: no errors (the pre-existing `TS2882` from `main.tsx` can be ignored).

- [ ] **Step 5: Commit**

```bash
git add apps/gui/src/components/GitRepoDetail.tsx apps/gui/src/components/GitReposTab.tsx
git commit -m "refactor(gui): extract RepoDetail into GitRepoDetail.tsx"
```

---

### Task 2: Create projectBook.ts utility

**Files:**
- Create: `apps/gui/src/lib/projectBook.ts`

- [ ] **Step 1: Create `apps/gui/src/lib/projectBook.ts`**

```typescript
import { type GitRepoSummary } from '@dotfiles/gui-engine';

const BOOK_KEY = 'dotfiles-git-repos';

export interface ProjectEntry {
  path: string;
  name: string;
  category: string;
  subcategory: string;
  pinned: boolean;
  tags: string[];
  summary: GitRepoSummary | null;
  lastSeen: number;
  stale: boolean;
}

export type ProjectBook = Record<string, ProjectEntry>;

export function loadBook(): ProjectBook {
  try {
    const raw = localStorage.getItem(BOOK_KEY);
    return raw ? (JSON.parse(raw) as ProjectBook) : {};
  } catch { return {}; }
}

export function saveBook(book: ProjectBook): void {
  try {
    localStorage.setItem(BOOK_KEY, JSON.stringify(book));
  } catch { /* quota exceeded — ignore */ }
}

export function deriveCategory(
  repoPath: string,
  expandedRoots: string[],
): { category: string; subcategory: string } {
  const matchingRoot = expandedRoots
    .slice()
    .sort((a, b) => b.length - a.length)
    .find(root => {
      const normalized = root.endsWith('/') ? root : root + '/';
      return repoPath.startsWith(normalized);
    });

  if (!matchingRoot) {
    // Fallback: use last 3 path segments
    const parts = repoPath.split('/').filter(Boolean);
    return {
      category: parts.length >= 3 ? parts[parts.length - 3] : '',
      subcategory: parts.length >= 2 ? parts[parts.length - 2] : '',
    };
  }

  const normalized = matchingRoot.endsWith('/') ? matchingRoot : matchingRoot + '/';
  const relative = repoPath.slice(normalized.length);
  // e.g. "work/client-a/my-repo" → ["work", "client-a", "my-repo"]
  const parts = relative.split('/').filter(Boolean);
  const pathParts = parts.slice(0, -1); // strip repo name → ["work", "client-a"]

  if (pathParts.length === 0) return { category: '', subcategory: '' };
  if (pathParts.length === 1) return { category: pathParts[0], subcategory: '' };
  return {
    category: pathParts[0],
    subcategory: pathParts.slice(1).join('/'),
  };
}

export function mergeRepo(
  book: ProjectBook,
  repo: GitRepoSummary,
  expandedRoots: string[],
  scanStart: number,
): ProjectBook {
  const existing = book[repo.path];
  if (existing) {
    return {
      ...book,
      [repo.path]: { ...existing, summary: repo, lastSeen: scanStart, stale: false },
    };
  }
  const { category, subcategory } = deriveCategory(repo.path, expandedRoots);
  const entry: ProjectEntry = {
    path: repo.path,
    name: repo.name,
    category,
    subcategory,
    pinned: false,
    tags: [],
    summary: repo,
    lastSeen: scanStart,
    stale: false,
  };
  return { ...book, [repo.path]: entry };
}

export function markStale(book: ProjectBook, scanStart: number): ProjectBook {
  const updated: ProjectBook = {};
  for (const [path, entry] of Object.entries(book)) {
    updated[path] = entry.lastSeen < scanStart ? { ...entry, stale: true } : entry;
  }
  return updated;
}
```

- [ ] **Step 2: Type-check**

```bash
yarn workspace @dotfiles/gui exec tsc --noEmit 2>&1 | grep -v TS2882
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add apps/gui/src/lib/projectBook.ts
git commit -m "feat(gui): add projectBook localStorage utilities"
```

---

### Task 3: Rewrite GitReposTab.tsx

**Files:**
- Modify: `apps/gui/src/components/GitReposTab.tsx` (full rewrite)

This task replaces the entire `GitReposTab.tsx` with the new layout: project book state, filter bar, category/subcategory card grid, `RepoCard` sub-component with pin + tags, and a CSS-animated slide-in detail panel.

- [ ] **Step 1: Replace `apps/gui/src/components/GitReposTab.tsx` with the new implementation**

```tsx
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

function RepoCard({ entry, isSelected, onSelect, onPin, onAddTag, onRemoveTag }: RepoCardProps) {
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
            onBlur={commitTag}
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
}

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

  useEffect(() => {
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') setSelectedPath(null); };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, []);

  const selectRepo = async (path: string) => {
    if (selectedPath === path) { setSelectedPath(null); return; }
    setSelectedPath(path);
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
    if (!selectedPath || inProgress) return;
    setInProgress(actionType);
    setActionError(null);
    try {
      await guiCommands.gitAction(selectedPath, actionType, params);
      if (!['open_terminal', 'open_vscode'].includes(actionType)) {
        const d = await guiCommands.getRepoDetail(selectedPath);
        setDetail(d);
        updateBook(prev => mergeRepo(prev, d.summary, expandedRoots, Date.now()));
      }
    } catch (e) {
      setActionError(String(e));
    } finally {
      setInProgress(null);
    }
  };

  const handlePin = (path: string, pinned: boolean) =>
    updateBook(prev => ({ ...prev, [path]: { ...prev[path], pinned } }));

  const handleAddTag = (path: string, tag: string) =>
    updateBook(prev => {
      const entry = prev[path];
      if (!entry) return prev;
      return { ...prev, [path]: { ...entry, tags: Array.from(new Set([...entry.tags, tag])) } };
    });

  const handleRemoveTag = (path: string, tag: string) =>
    updateBook(prev => {
      const entry = prev[path];
      if (!entry) return prev;
      return { ...prev, [path]: { ...entry, tags: entry.tags.filter(t => t !== tag) } };
    });

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
            onClick={() => setSelectedPath(null)}
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
```

- [ ] **Step 2: Type-check**

```bash
yarn workspace @dotfiles/gui exec tsc --noEmit 2>&1 | grep -v TS2882
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add apps/gui/src/components/GitReposTab.tsx
git commit -m "feat(gui): redesign Git Repos tab with project book, card grid, and slide-in panel"
```
