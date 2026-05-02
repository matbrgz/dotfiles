# Git Repos Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Git Repos" tab to the existing Tauri GUI that discovers git repositories under user-configured roots and provides a two-panel explorer with full git actions.

**Architecture:** Rust backend adds three new Tauri commands (`scan_git_repos`, `get_repo_detail`, `git_action`) that call the system `git` binary via the existing `sh()` helper. The frontend is a single new component (`GitReposTab.tsx`) using the existing shadcn components. Scan roots are persisted in `settings.json` via the existing `UserSettings` mechanism.

**Tech Stack:** Rust (Tauri 1.4, serde_json), React 18, TypeScript, Tailwind v4, shadcn/ui (Accordion, ScrollArea already installed), Lucide React icons.

**Working directory for all tasks:** `/Users/jobs/Dev/z-pessoal/dotfiles/.worktrees/feat-disk-cleaner-redesign`

---

## File Map

| File | Change |
|------|--------|
| `packages/schema/src/index.ts` | Add `git_scan_roots` field to `UserSettingsSchema` |
| `packages/gui-engine/src/index.ts` | Add 6 interfaces, `GitAction` type, 3 new `guiCommands` methods |
| `apps/gui/src-tauri/src/main.rs` | Add 8 structs, 2 helper fns, 3 Tauri commands, register in `main()` |
| `apps/gui/src/components/GitReposTab.tsx` | New file — full two-panel UI |
| `apps/gui/src/App.tsx` | Add `GitBranch` icon, new tab entry, import + render |

---

## Task 1: Add `git_scan_roots` to UserSettings schema

**Files:**
- Modify: `packages/schema/src/index.ts:34-48`

- [ ] **Step 1: Open the file and locate `UserSettingsSchema`**

The relevant section is at line 34. It currently looks like:
```typescript
export const UserSettingsSchema = z.object({
  personal: z.object({
    name: z.string(),
    email: z.string().email(),
    githubuser: z.string(),
    defaultfolder: z.record(z.string()),
  }),
  system: z.object({
    behavior: z.object({
      debug_mode: z.boolean(),
      purge_mode: z.boolean(),
      backup_configs: z.boolean(),
    }),
  }),
});
```

- [ ] **Step 2: Add the `git_scan_roots` field**

Replace the entire `UserSettingsSchema` definition with:
```typescript
export const UserSettingsSchema = z.object({
  personal: z.object({
    name: z.string(),
    email: z.string().email(),
    githubuser: z.string(),
    defaultfolder: z.record(z.string()),
  }),
  system: z.object({
    behavior: z.object({
      debug_mode: z.boolean(),
      purge_mode: z.boolean(),
      backup_configs: z.boolean(),
    }),
  }),
  git_scan_roots: z.array(z.string()).optional().default(['~']),
});
```

- [ ] **Step 3: Build the schema package to verify**

```bash
cd /Users/jobs/Dev/z-pessoal/dotfiles
yarn workspace @dotfiles/schema build
```

Expected: no errors, `packages/schema/dist/` updated.

- [ ] **Step 4: Commit**

```bash
git add packages/schema/src/index.ts
git commit -m "feat(schema): add git_scan_roots to UserSettings"
```

---

## Task 2: Add TypeScript types + commands to gui-engine

**Files:**
- Modify: `packages/gui-engine/src/index.ts`

Context: `packages/gui-engine/src/index.ts` exports `guiCommands` and all shared interfaces. The `invoke` and `listen` imports from `@tauri-apps/api` are already present. Add new code after the existing `ProcInfo` interface (line ~60) and new command methods at the bottom of the `guiCommands` object (before the closing `};`).

- [ ] **Step 1: Add the new interfaces after `ProcInfo`**

After the `ProcInfo` interface (around line 60), insert:

```typescript
export interface GitRepoSummary {
  path: string;
  name: string;
  current_branch: string;
  is_dirty: boolean;
  ahead: number;
  behind: number;
  last_commit_msg: string;
  last_commit_ts: number;
  stash_count: number;
}

export interface GitBranch {
  name: string;
  is_remote: boolean;
  is_current: boolean;
  ahead: number | null;
  behind: number | null;
  last_commit_hash: string;
  last_commit_msg: string;
}

export interface GitCommit {
  short_hash: string;
  full_hash: string;
  message: string;
  author: string;
  ts: number;
}

export interface GitRemote {
  name: string;
  url: string;
}

export interface GitStash {
  index: number;
  message: string;
  ts: number;
}

export interface GitRepoDetail {
  summary: GitRepoSummary;
  branches: GitBranch[];
  commits: GitCommit[];
  remotes: GitRemote[];
  stashes: GitStash[];
  tags: string[];
}
```

- [ ] **Step 2: Add three new methods to `guiCommands`**

Add these three methods at the end of the `guiCommands` object, before the final `};`:

```typescript
  scanGitRepos: async (
    roots: string[],
    onRepo?: (repo: GitRepoSummary) => void,
    onCount?: (count: number) => void,
  ): Promise<void> => {
    return new Promise(async (resolve, reject) => {
      const unlisteners: Array<() => void> = [];

      if (onRepo) {
        const ul = await listen<GitRepoSummary>('git-repo-found', (e) => onRepo(e.payload));
        unlisteners.push(ul);
      }
      if (onCount) {
        const ul = await listen<number>('git-scan-count', (e) => onCount(e.payload));
        unlisteners.push(ul);
      }

      const cleanup = () => unlisteners.forEach(fn => fn());

      const doneUl = await listen<null>('git-scan-done', () => {
        cleanup();
        doneUl();
        resolve();
      });

      invoke('scan_git_repos', { roots }).catch((err) => {
        cleanup();
        doneUl();
        reject(err);
      });
    });
  },

  getRepoDetail: async (path: string): Promise<GitRepoDetail> => {
    return invoke<GitRepoDetail>('get_repo_detail', { path });
  },

  gitAction: async (path: string, actionType: string, params: Record<string, unknown> = {}): Promise<string> => {
    return invoke<string>('git_action', { path, action_type: actionType, params });
  },
```

- [ ] **Step 3: Build the package to verify**

```bash
cd /Users/jobs/Dev/z-pessoal/dotfiles
yarn workspace @dotfiles/gui-engine build
```

Expected: no TypeScript errors, `packages/gui-engine/dist/` updated.

- [ ] **Step 4: Commit**

```bash
git add packages/gui-engine/src/index.ts
git commit -m "feat(gui-engine): add Git Repos types and commands"
```

---

## Task 3: Rust — structs, helpers, and `scan_git_repos`

**Files:**
- Modify: `apps/gui/src-tauri/src/main.rs`

Context: `main.rs` has an `sh()` helper at line 87 that runs shell commands. The `expand()` helper at line 128 replaces `~` with the home dir. All existing structs use `#[derive(Serialize, Clone)]`. New code should be inserted before the `// ── Tauri commands ──` comment at line 162.

- [ ] **Step 1: Add the Git Repos structs before the Tauri commands section**

Insert the following block just before line 162 (`// ── Tauri commands ──`):

```rust
// ── Git Repos ──────────────────────────────────────────────────────────────────

#[derive(Serialize, Clone)]
struct GitRepoSummary {
    path: String,
    name: String,
    current_branch: String,
    is_dirty: bool,
    ahead: u32,
    behind: u32,
    last_commit_msg: String,
    last_commit_ts: i64,
    stash_count: u32,
}

#[derive(Serialize, Clone)]
struct GitBranch {
    name: String,
    is_remote: bool,
    is_current: bool,
    ahead: Option<u32>,
    behind: Option<u32>,
    last_commit_hash: String,
    last_commit_msg: String,
}

#[derive(Serialize, Clone)]
struct GitCommit {
    short_hash: String,
    full_hash: String,
    message: String,
    author: String,
    ts: i64,
}

#[derive(Serialize, Clone)]
struct GitRemote {
    name: String,
    url: String,
}

#[derive(Serialize, Clone)]
struct GitStash {
    index: u32,
    message: String,
    ts: i64,
}

#[derive(Serialize, Clone)]
struct GitRepoDetail {
    summary: GitRepoSummary,
    branches: Vec<GitBranch>,
    commits: Vec<GitCommit>,
    remotes: Vec<GitRemote>,
    stashes: Vec<GitStash>,
    tags: Vec<String>,
}

fn git(repo: &str, args: &str) -> String {
    sh(&format!("git -C \"{}\" {} 2>/dev/null", repo, args))
}

fn repo_summary(path: &str) -> GitRepoSummary {
    let name = std::path::Path::new(path)
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or(path)
        .to_string();
    let current_branch = git(path, "rev-parse --abbrev-ref HEAD").trim().to_string();
    let is_dirty = !git(path, "status --porcelain").trim().is_empty();
    let ahead: u32 = git(path, "rev-list --count @{u}..HEAD").trim().parse().unwrap_or(0);
    let behind: u32 = git(path, "rev-list --count HEAD..@{u}").trim().parse().unwrap_or(0);
    let last_log = git(path, "log -1 --format=%s|%ct");
    let mut parts = last_log.trim().splitn(2, '|');
    let last_commit_msg = parts.next().unwrap_or("").trim().to_string();
    let last_commit_ts: i64 = parts.next().and_then(|s| s.trim().parse().ok()).unwrap_or(0);
    let stash_count: u32 = git(path, "stash list").lines().filter(|l| !l.is_empty()).count() as u32;
    GitRepoSummary { path: path.to_string(), name, current_branch, is_dirty, ahead, behind, last_commit_msg, last_commit_ts, stash_count }
}
```

- [ ] **Step 2: Add the `scan_git_repos` command**

After the `repo_summary` function (still before `// ── Tauri commands ──`), add:

```rust
#[tauri::command]
fn scan_git_repos(roots: Vec<String>, window: tauri::Window) {
    std::thread::spawn(move || {
        let home = std::env::var("HOME").unwrap_or_default();
        let mut all_paths: Vec<String> = Vec::new();
        for root in &roots {
            let expanded = expand(root, &home);
            let found = sh(&format!(
                "find \"{}\" -name .git -type d -not -path '*/.git/*' -maxdepth 8 2>/dev/null",
                expanded
            ));
            for line in found.lines() {
                let line = line.trim();
                if line.is_empty() { continue; }
                if let Some(repo_root) = line.strip_suffix("/.git") {
                    all_paths.push(repo_root.to_string());
                }
            }
        }
        all_paths.sort();
        all_paths.dedup();
        let _ = window.emit("git-scan-count", all_paths.len() as u32);
        for path in &all_paths {
            let summary = repo_summary(path);
            let _ = window.emit("git-repo-found", summary);
        }
        let _ = window.emit("git-scan-done", ());
    });
}
```

- [ ] **Step 3: Compile to verify (don't register in main() yet — Task 4 does that)**

```bash
cd /Users/jobs/Dev/z-pessoal/dotfiles/.worktrees/feat-disk-cleaner-redesign/apps/gui/src-tauri
cargo build 2>&1 | grep -E "^error"
```

Expected: no `error` lines. Warnings about unused functions are fine.

- [ ] **Step 4: Commit**

```bash
git add apps/gui/src-tauri/src/main.rs
git commit -m "feat(rust): add Git Repos structs, helpers, and scan_git_repos command"
```

---

## Task 4: Rust — `get_repo_detail`, `git_action`, and registration

**Files:**
- Modify: `apps/gui/src-tauri/src/main.rs`

Context: Add two more commands after `scan_git_repos`, then register all three in `main()`. The `main()` function's `invoke_handler` is at the bottom of the file (~line 824).

- [ ] **Step 1: Add `get_repo_detail` after `scan_git_repos`**

```rust
#[tauri::command]
fn get_repo_detail(path: String) -> GitRepoDetail {
    let summary = repo_summary(&path);

    // Branches
    let branches_raw = git(&path, "branch -a --format=%(refname:short)|%(objectname:short)|%(subject)|%(upstream:track)");
    let branches: Vec<GitBranch> = branches_raw.lines().filter(|l| !l.is_empty()).map(|line| {
        let parts: Vec<&str> = line.splitn(4, '|').collect();
        let name = parts.first().copied().unwrap_or("").to_string();
        let last_commit_hash = parts.get(1).copied().unwrap_or("").to_string();
        let last_commit_msg = parts.get(2).copied().unwrap_or("").to_string();
        let track = parts.get(3).copied().unwrap_or("");
        let is_remote = name.contains('/');
        let is_current = name == summary.current_branch;
        let ahead = if track.contains("ahead") {
            track.split("ahead ").nth(1)
                .and_then(|s| s.split(|c: char| !c.is_ascii_digit()).next())
                .and_then(|s| s.parse().ok())
        } else { None };
        let behind = if track.contains("behind") {
            track.split("behind ").nth(1)
                .and_then(|s| s.split(|c: char| !c.is_ascii_digit()).next())
                .and_then(|s| s.parse().ok())
        } else { None };
        GitBranch { name, is_remote, is_current, ahead, behind, last_commit_hash, last_commit_msg }
    }).collect();

    // Commits (last 30)
    let commits_raw = git(&path, "log -30 --format=%h|%H|%s|%an|%ct");
    let commits: Vec<GitCommit> = commits_raw.lines().filter(|l| !l.is_empty()).filter_map(|line| {
        let parts: Vec<&str> = line.splitn(5, '|').collect();
        if parts.len() < 5 { return None; }
        Some(GitCommit {
            short_hash: parts[0].to_string(),
            full_hash: parts[1].to_string(),
            message: parts[2].to_string(),
            author: parts[3].to_string(),
            ts: parts[4].trim().parse().unwrap_or(0),
        })
    }).collect();

    // Remotes (deduplicated)
    let remotes_raw = git(&path, "remote -v");
    let mut seen: std::collections::HashSet<String> = std::collections::HashSet::new();
    let remotes: Vec<GitRemote> = remotes_raw.lines().filter(|l| !l.is_empty()).filter_map(|line| {
        let mut cols = line.split_whitespace();
        let name = cols.next()?.to_string();
        let url = cols.next()?.to_string();
        if !seen.insert(name.clone()) { return None; }
        Some(GitRemote { name, url })
    }).collect();

    // Stashes
    let stashes_raw = git(&path, "stash list --format=%gd|%s|%ct");
    let stashes: Vec<GitStash> = stashes_raw.lines().filter(|l| !l.is_empty()).enumerate().filter_map(|(i, line)| {
        let parts: Vec<&str> = line.splitn(3, '|').collect();
        Some(GitStash {
            index: i as u32,
            message: parts.get(1).copied().unwrap_or("").to_string(),
            ts: parts.get(2).and_then(|s| s.trim().parse().ok()).unwrap_or(0),
        })
    }).collect();

    // Tags (20 most recent)
    let tags_raw = git(&path, "tag --sort=-creatordate");
    let tags: Vec<String> = tags_raw.lines().filter(|l| !l.is_empty()).take(20).map(|s| s.to_string()).collect();

    GitRepoDetail { summary, branches, commits, remotes, stashes, tags }
}
```

- [ ] **Step 2: Add `git_action` after `get_repo_detail`**

```rust
#[tauri::command]
fn git_action(path: String, action_type: String, params: serde_json::Value) -> Result<String, String> {
    let git_run = |args: &str| -> Result<String, String> {
        let out = Command::new("sh")
            .args(["-c", &format!("git -C \"{}\" {} 2>&1", path, args)])
            .output()
            .map_err(|e| e.to_string())?;
        let stdout = String::from_utf8_lossy(&out.stdout).trim().to_string();
        if out.status.success() { Ok(stdout) } else { Err(stdout) }
    };
    match action_type.as_str() {
        "fetch" => git_run(&format!("fetch {}", params["remote"].as_str().unwrap_or("origin"))),
        "pull"  => git_run(&format!("pull {} {}", params["remote"].as_str().unwrap_or("origin"), params["branch"].as_str().unwrap_or(""))),
        "push"  => git_run(&format!("push {} {}", params["remote"].as_str().unwrap_or("origin"), params["branch"].as_str().unwrap_or(""))),
        "checkout"      => git_run(&format!("checkout {}", params["branch"].as_str().ok_or("missing branch")?)),
        "create_branch" => git_run(&format!("checkout -b {} {}", params["name"].as_str().ok_or("missing name")?, params["from"].as_str().unwrap_or("HEAD"))),
        "delete_branch" => git_run(&format!("branch {} {}", if params["force"].as_bool().unwrap_or(false) { "-D" } else { "-d" }, params["name"].as_str().ok_or("missing name")?)),
        "stash_push" => {
            if let Some(m) = params["message"].as_str() {
                git_run(&format!("stash push -m \"{}\"", m))
            } else {
                git_run("stash push")
            }
        }
        "stash_pop"  => git_run(&format!("stash pop stash@{{{}}}", params["index"].as_u64().unwrap_or(0))),
        "stash_drop" => git_run(&format!("stash drop stash@{{{}}}", params["index"].as_u64().unwrap_or(0))),
        "open_terminal" => {
            #[cfg(target_os = "macos")]
            let _ = Command::new("open").args(["-a", "Terminal", &path]).spawn();
            #[cfg(target_os = "linux")]
            { let _ = Command::new(std::env::var("TERMINAL").unwrap_or_else(|_| "xterm".to_string())).arg(&path).spawn(); }
            #[cfg(target_os = "windows")]
            let _ = Command::new("cmd").args(["/c", "start", "cmd", "/k", &format!("cd /d {}", path)]).spawn();
            Ok("opened".into())
        }
        "open_vscode" => {
            let _ = Command::new("code").arg(&path).spawn();
            Ok("opened".into())
        }
        _ => Err(format!("unknown action: {}", action_type))
    }
}
```

- [ ] **Step 3: Register the three new commands in `main()`**

Find the `tauri::generate_handler![` block (around line 825). It currently ends with `kill_process`. Add the three new commands:

```rust
        .invoke_handler(tauri::generate_handler![
            get_system_info,
            get_runtime_info,
            check_brew_package,
            check_dotfile_exists,
            get_registry_data,
            get_dotfiles_data,
            get_user_settings,
            save_user_settings,
            run_cli_command,
            scan_disk_usage,
            clean_items,
            scan_large_files,
            get_memory_info,
            get_top_processes,
            kill_process,
            scan_git_repos,
            get_repo_detail,
            git_action
        ])
```

- [ ] **Step 4: Compile to verify**

```bash
cd /Users/jobs/Dev/z-pessoal/dotfiles/.worktrees/feat-disk-cleaner-redesign/apps/gui/src-tauri
cargo build 2>&1 | grep -E "^error"
```

Expected: no `error` lines.

- [ ] **Step 5: Commit**

```bash
git add apps/gui/src-tauri/src/main.rs
git commit -m "feat(rust): add get_repo_detail, git_action commands"
```

---

## Task 5: Build `GitReposTab.tsx`

**Files:**
- Create: `apps/gui/src/components/GitReposTab.tsx`

Context: The existing tab components live in `apps/gui/src/components/`. They use shadcn components from `@/components/ui/` (Accordion, ScrollArea already installed). Tailwind v4 CSS-first classes like `bg-card`, `text-foreground`, `border-border`, `text-muted-foreground`, `text-primary` etc. are defined in `src/index.css`. The `@dotfiles/gui-engine` package exports all the new interfaces added in Task 2.

- [ ] **Step 1: Create the file with helpers and left panel**

Create `apps/gui/src/components/GitReposTab.tsx` with:

```tsx
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
```

- [ ] **Step 2: Add the `RepoDetail` sub-component to the same file**

Append the following after the `GitReposTab` component (end of file):

```tsx
interface RepoDetailProps {
  detail: GitRepoDetail;
  onAction: (type: string, params?: Record<string, unknown>) => Promise<void>;
  inProgress: string | null;
  actionError: string | null;
  onClearError: () => void;
  confirmDelete: string | null;
  setConfirmDelete: (v: string | null) => void;
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

  const ActionBtn = ({ label, type, params, danger = false }: { label: string; type: string; params?: Record<string, unknown>; danger?: boolean }) => (
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
          <ActionBtn label="Fetch" type="fetch" params={{ remote: defaultRemote }} />
          <ActionBtn label="Pull" type="pull" params={{ remote: defaultRemote, branch: summary.current_branch }} />
          <ActionBtn label="Push" type="push" params={{ remote: defaultRemote, branch: summary.current_branch }} />
          <div className="w-px h-4 bg-border mx-1" />
          <ActionBtn label="Terminal" type="open_terminal" />
          <ActionBtn label="VS Code" type="open_vscode" />
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
```

- [ ] **Step 3: Type-check**

```bash
cd /Users/jobs/Dev/z-pessoal/dotfiles/.worktrees/feat-disk-cleaner-redesign/apps/gui
npx tsc --noEmit 2>&1 | grep -v "index.css"
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add apps/gui/src/components/GitReposTab.tsx
git commit -m "feat(gui): add GitReposTab component"
```

---

## Task 6: Wire up in App.tsx

**Files:**
- Modify: `apps/gui/src/App.tsx`

Context: `App.tsx` imports components, defines a `TABS` array, and renders tabs conditionally. The existing imports at the top include icons from `lucide-react`. The `TABS` array ends with `{ id: 'memory', label: 'Memory', icon: Cpu }`.

- [ ] **Step 1: Add `GitBranch` to the lucide-react import**

The existing import line:
```typescript
import { Package, Settings, User, FileCode, HardDrive, Cpu } from 'lucide-react';
```

Change to:
```typescript
import { Package, Settings, User, FileCode, HardDrive, Cpu, GitBranch } from 'lucide-react';
```

- [ ] **Step 2: Import the new component**

Add this import after the `MemoryTab` import line:
```typescript
import { GitReposTab } from './components/GitReposTab';
```

- [ ] **Step 3: Add the tab to the `TABS` array**

The `TABS` array currently ends with:
```typescript
    { id: 'memory',       label: 'Memory',        icon: Cpu },
```

Add after it:
```typescript
    { id: 'git-repos',    label: 'Git Repos',     icon: GitBranch },
```

- [ ] **Step 4: Add the conditional render**

The block `{activeTab === 'memory' && <MemoryTab />}` is inside the scrollable content div. Add after it:
```tsx
            {activeTab === 'git-repos' && <GitReposTab />}
```

- [ ] **Step 5: Type-check**

```bash
cd /Users/jobs/Dev/z-pessoal/dotfiles/.worktrees/feat-disk-cleaner-redesign/apps/gui
npx tsc --noEmit 2>&1 | grep -v "index.css"
```

Expected: no errors.

- [ ] **Step 6: Build the gui-engine and launch the app**

```bash
cd /Users/jobs/Dev/z-pessoal/dotfiles
yarn workspace @dotfiles/gui-engine build
```

Then kill any existing instance on port 1420 and launch:
```bash
lsof -ti:1420 | xargs kill -9 2>/dev/null; true
```

```bash
cd /Users/jobs/Dev/z-pessoal/dotfiles/.worktrees/feat-disk-cleaner-redesign/apps/gui
yarn tauri dev
```

Expected: app launches, "Git Repos" tab appears in the sidebar. Clicking it auto-scans and streams repos into the left panel. Clicking a repo loads the detail panel with branches, commits, remotes, stashes.

- [ ] **Step 7: Commit**

```bash
git add apps/gui/src/App.tsx
git commit -m "feat(gui): add Git Repos tab to sidebar"
```
