# Git Repos Tab — Design Spec

## Goal

Add a "Git Repos" tab to the existing Tauri GUI that discovers all git repositories under user-configured root paths, shows per-repo git status at a glance, and allows common git actions (fetch, pull, push, branch management, stash) directly from the UI.

## Architecture

The tab lives inside the existing Tauri GUI (`apps/gui`) alongside Disk Cleaner and Memory tabs. It follows the same event-streaming pattern already used by `scan_disk_usage`:

- **Rust backend** — new Tauri commands in `main.rs`:
  - `scan_git_repos(roots: Vec<String>)` — walks each root path, finds `.git` directories, streams a `GitRepoSummary` event per discovered repo via `window.emit("git-repo-found", ...)`. Emits `git-scan-done` when complete.
  - `get_repo_detail(path: String) → GitRepoDetail` — runs git shell commands to fetch full repo info.
  - `git_action(path: String, action: GitAction) → Result<String, String>` — executes a mutation and returns stdout or an error string.
- **TypeScript bridge** (`packages/gui-engine/src/index.ts`) — adds `GitRepoSummary`, `GitRepoDetail`, `GitBranch`, `GitCommit`, `GitRemote`, `GitStash` interfaces and new `guiCommands` methods.
- **Frontend** (`apps/gui/src/components/GitReposTab.tsx`) — two-panel layout using existing shadcn components.
- **Settings** — `git_scan_roots: Vec<String>` added to the `UserSettings` struct and schema. Defaults to `["~"]`.

The system `git` binary (on PATH) is used for all operations. No libgit2 or extra Rust crates required.

## Data Structures

### GitRepoSummary (streamed on scan)
```typescript
interface GitRepoSummary {
  path: string;          // absolute path to repo root
  name: string;          // last path segment
  current_branch: string;
  is_dirty: boolean;     // uncommitted changes
  ahead: number;         // commits ahead of remote tracking branch
  behind: number;        // commits behind remote tracking branch
  last_commit_msg: string;
  last_commit_ts: number; // unix timestamp
  stash_count: number;
}
```

### GitRepoDetail (loaded on click)
```typescript
interface GitRepoDetail {
  summary: GitRepoSummary;
  branches: GitBranch[];
  commits: GitCommit[];   // last 30
  remotes: GitRemote[];
  stashes: GitStash[];
  tags: string[];
}

interface GitBranch {
  name: string;
  is_remote: boolean;
  is_current: boolean;
  ahead: number | null;
  behind: number | null;
  last_commit_hash: string;
  last_commit_msg: string;
}

interface GitCommit {
  short_hash: string;
  full_hash: string;
  message: string;
  author: string;
  ts: number;
}

interface GitRemote {
  name: string;
  url: string;
}

interface GitStash {
  index: number;
  message: string;
  ts: number;
}
```

### GitAction (discriminated union sent to Rust)
```typescript
type GitAction =
  | { type: 'fetch'; remote: string }
  | { type: 'pull'; remote: string; branch: string }
  | { type: 'push'; remote: string; branch: string }
  | { type: 'checkout'; branch: string }
  | { type: 'create_branch'; name: string; from: string }
  | { type: 'delete_branch'; name: string; force: boolean }
  | { type: 'stash_push'; message: string | null }
  | { type: 'stash_pop'; index: number }
  | { type: 'stash_drop'; index: number }
  | { type: 'open_terminal' }
  | { type: 'open_vscode' }
```

## Rust Implementation Notes

**Scanning:**
- Use `std::process::Command` to run `find <root> -name .git -type d -not -path '*/.git/*'` (or the `walkdir` crate for cross-platform).
- For each found path, strip the trailing `/.git` to get the repo root.
- Run these git commands per repo for the summary:
  - `git -C <path> rev-parse --abbrev-ref HEAD` → current branch
  - `git -C <path> status --porcelain` → dirty if output non-empty
  - `git -C <path> rev-list --count @{u}..HEAD 2>/dev/null` → ahead (0 if no upstream)
  - `git -C <path> rev-list --count HEAD..@{u} 2>/dev/null` → behind
  - `git -C <path> log -1 --format="%s|%ct"` → last commit message + timestamp
  - `git -C <path> stash list | wc -l` → stash count

**Detail loading:**
- Branches: `git -C <path> branch -a --format="%(refname:short)|%(objectname:short)|%(subject)|%(upstream:track)"` 
- Commits: `git -C <path> log -30 --format="%h|%H|%s|%an|%ct"`
- Remotes: `git -C <path> remote -v | awk '!seen[$1]++' | awk '{print $1"|"$2}'`
- Stashes: `git -C <path> stash list --format="%gd|%s|%ct"`
- Tags: `git -C <path> tag --sort=-creatordate`

**Actions:**
- All actions run `git -C <path> <args>` via `std::process::Command`, capture stdout+stderr, return as `Result<String, String>`.
- `open_terminal`: macOS → `open -a Terminal <path>`, Linux → detect `$TERM` or fallback to `xterm`, Windows → `cmd /c start cmd /k "cd /d <path>"`.
- `open_vscode`: `code <path>` on all platforms.

## UI Layout

### Left Panel (320px, fixed)

```
┌─────────────────────────────┐
│ [⚙ Scan Roots]  [+ Add]     │ ← collapsible settings
│  ~/Dev  ×                   │
│  ~/work ×                   │
├─────────────────────────────┤
│ 🔍 Filter repos...          │
├─────────────────────────────┤
│ [Scan] or scanning…  ██░░░  │
├─────────────────────────────┤
│ ● dotfiles          main    │
│   ~/Dev/z-pessoal/dotfiles  │
│   ● dirty  ↑2 ↓0  "feat…"  │
├─────────────────────────────┤
│   my-project        feat/x  │
│   ~/Dev/my-project          │
│   clean             "fix…"  │
└─────────────────────────────┘
```

- Repos sorted by `last_commit_ts` descending.
- Dirty repos get an orange dot indicator.
- Ahead/behind shown as `↑N ↓N` (hidden if both 0).
- Clicking a repo selects it and loads detail in the right panel.

### Right Panel (flex, fills remaining space)

```
┌──────────────────────────────────────────────────────┐
│ dotfiles                              main ● dirty    │
│ ~/Dev/z-pessoal/dotfiles                             │
│ [Fetch] [Pull] [Push]   [Terminal] [VS Code]         │
├──────────────────────────────────────────────────────┤
│ ▼ Branches                          [+ New Branch]   │
│   ● main          ↑2 ↓0   "feat: add disk…"  [✓]    │
│     feat/x               "wip: thing"   [Checkout]   │
│     origin/main          "feat: add disk…"            │
├──────────────────────────────────────────────────────┤
│ ▼ Commits                                            │
│   a3f2b1  feat: add disk cleaner tab   you  2h ago   │
│   9e1c44  fix: port conflict           you  3h ago   │
│   ...                                                │
├──────────────────────────────────────────────────────┤
│ ▶ Remotes                                            │
├──────────────────────────────────────────────────────┤
│ ▶ Stashes (2)                                        │
└──────────────────────────────────────────────────────┘
```

- All sections use shadcn `Accordion` (same as Disk Cleaner tab).
- Action buttons show a spinner + disable during in-progress operations.
- Errors from git actions shown inline below the action bar (red, dismissible).
- Branches: local branches first, then remote. Current branch has a filled circle. Checkout button on non-current local branches. Delete button (requires confirmation) on non-current local branches.

## Settings

`git_scan_roots` is stored in `UserSettings` (the existing settings JSON). Default value: `["~"]`. The UI shows the list at the top of the left panel with a remove button per entry and an "Add root" button that opens a native folder picker (`rfd` crate already in use).

**Home dir expansion:** When the Rust `scan_git_repos` command receives a path that starts with `~`, expand it using `dirs::home_dir()` before scanning. The `dirs` crate is already a transitive dependency; add it explicitly if needed.

## File Changes

| File | Change |
|------|--------|
| `packages/schema/src/index.ts` | Add `git_scan_roots?: string[]` to `UserSettings` |
| `packages/gui-engine/src/index.ts` | Add all new interfaces + `scanGitRepos`, `getRepoDetail`, `gitAction` commands |
| `apps/gui/src-tauri/src/main.rs` | Add `scan_git_repos`, `get_repo_detail`, `git_action` commands + all structs |
| `apps/gui/src/components/GitReposTab.tsx` | New component (two-panel layout) |
| `apps/gui/src/App.tsx` | Add "Git Repos" tab to tab list |

## Out of Scope

- Merge/rebase operations (complex conflict UI, deferred)
- Diff viewer (deferred)
- Submodule awareness (repos inside repos are skipped during scan)
- Authentication / SSH key management
