# Git Repos Tab — Redesign Spec

## Goal

Redesign the existing Git Repos tab with a persistent "project book" (localStorage), a category/subcategory grouped card grid, user-defined tags, pinning, and a slide-in detail panel instead of the current fixed two-panel layout.

## Architecture

The frontend maintains a `ProjectBook` in `localStorage` (key: `dotfiles-git-repos`). On mount, the book loads immediately — zero loading for already-known repos — then the scan runs in background and merges results in. Pins and tags are never overwritten by scans. The Rust backend is unchanged: `scan_git_repos`, `get_repo_detail`, and `git_action` stay as-is.

**Tech Stack:** React, TypeScript, localStorage, existing Tauri commands, Tailwind CSS, shadcn/ui components.

---

## Data Model

### ProjectEntry (stored in localStorage)

```typescript
interface ProjectEntry {
  path: string;
  name: string;
  category: string;       // 1st folder level below scan root, e.g. "work"
  subcategory: string;    // 2nd folder level, e.g. "client-a" or "" if absent
  pinned: boolean;
  tags: string[];
  summary: GitRepoSummary | null;  // last known git status from scan
  lastSeen: number;                // unix timestamp of last scan hit
  stale: boolean;                  // true when last scan didn't find this path
}

type ProjectBook = Record<string, ProjectEntry>;  // keyed by absolute path
```

### Category/Subcategory Derivation

Given scan root `~/Dev` and repo path `~/Dev/work/client-a/my-repo`:
- Relative path segments (excluding repo name): `["work", "client-a"]`
- `category` = first segment = `"work"`
- `subcategory` = last segment before the repo name = `"client-a"`
- If only one segment (repo sits directly inside category folder, e.g. `~/Dev/work/my-repo`): `category = "work"`, `subcategory = ""`
- If repo sits directly in scan root (e.g. `~/Dev/my-repo`): `category = ""`, `subcategory = ""`
- For paths deeper than 3 levels (e.g. `~/Dev/work/client-a/team/my-repo`): `category = "work"`, `subcategory = "client-a/team"` (all intermediate segments joined with `/`)

### Scan Merge Logic

On each scan result (`GitRepoSummary` event):
1. If path exists in book: update `summary`, `lastSeen`, `stale = false`. Keep `pinned`, `tags`, `category`, `subcategory` unchanged.
2. If path is new: derive `category`/`subcategory` from path, set `pinned = false`, `tags = []`, `stale = false`.

After scan completes: any entry with `lastSeen` older than scan start time is marked `stale = true`.

### localStorage Schema

```
key:   "dotfiles-git-repos"
value: JSON.stringify(ProjectBook)
```

Writes happen on every mutation (pin toggle, tag add/remove, scan merge). Reads happen once on mount.

---

## UI Layout

### Filter Bar (top, full width)

- **Pinned / All** toggle (default: Pinned)
- Search input — filters by name and path
- Active tag chips — clicking a tag chip toggles it as a filter; only repos with that tag show
- `↻ Scan` button — triggers a fresh scan (re-runs `scanGitRepos` and merges results)
- Scan status shown inline next to the button: "Scanning… 12 found" → "47 repos"

### Main List Area

Repos grouped by **category** (collapsible sections), then **subcategory** (plain text divider header), then cards in a **responsive grid** (auto-fill, min 220px per card).

**Category section header:**
- Category name (bold), count of repos in section, collapse/expand chevron
- Collapsed state persisted in `sessionStorage` (not localStorage — resets per session)

**Subcategory divider:** small muted label between card rows when subcategory changes within a category.

**Repos with no category** (directly in scan root): grouped under a special `"(root)"` section.

### Repo Card

```
┌──────────────────────┐
│ ★  my-repo           │  ← pin toggle (★ pinned / ☆ unpinned) + name
│ main  ● ↑2 ↓0        │  ← branch, dirty dot, ahead/behind
│ "feat: add disk…"    │  ← last commit message (truncated)
│ 2h ago               │  ← relative time
│ #rust  #client  [+]  │  ← tag chips + add tag button
└──────────────────────┘
```

- Stale repos: 50% opacity, "not found" badge in top-right corner
- Clicking card body: opens detail panel (not the pin button or tag area)
- Active card (detail panel open): card highlighted with primary color border

### Detail Panel

Slides in from the right with a CSS transition (200ms ease-out). When open, the list area narrows to ~55% width. Closes via `×` button or pressing Escape.

Content: the existing `RepoDetail` component (branches, commits, remotes, stashes, action bar) — no changes needed to that component.

### Empty States

- **Pinned view, no pins yet:** "No pinned repos yet. Click ☆ on any repo card to pin it."
- **All view, no repos:** "No repos found. Click ↻ Scan to discover repos under your configured roots."
- **Search with no matches:** "No repos match your search."

### Tag Editing

Clicking `[+]` on a card shows a small inline input below the tag chips. Pressing Enter or comma commits the tag. Clicking an existing tag chip shows a `×` to remove it. Tags are stored lowercase, deduplicated.

---

## File Changes

| File | Change |
|------|--------|
| `apps/gui/src/components/GitReposTab.tsx` | Full rewrite — new layout, localStorage logic, card grid, tag editing, slide-in panel |
| `apps/gui/src/components/GitRepoDetail.tsx` | Extract existing `RepoDetail` + `ActionBtn` into its own file (no logic changes) |

No backend, schema, or gui-engine changes required.

---

## Out of Scope

- Drag-and-drop reordering of repos or categories
- Custom category name overrides (folder name is always the category)
- Syncing the project book to UserSettings/dotfiles backup
- Multi-select actions across repos
