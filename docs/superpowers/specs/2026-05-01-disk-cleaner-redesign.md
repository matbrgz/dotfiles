# Disk Cleaner Redesign

**Date:** 2026-05-01  
**Status:** Approved

## Goal

Redesign the Disk Cleaner tab to show real-time scan progress, richer per-category details (individual paths, last modified date, file count), granular selection, and use shadcn/ui components throughout.

---

## Backend Changes (`apps/gui/src-tauri/src/main.rs`)

### New types

```rust
struct DiskItem {
    path: String,
    size_bytes: u64,
    modified_at: Option<u64>, // unix timestamp seconds
}

struct DiskCategory {
    id: String,
    label: String,
    icon: String,
    group: String,
    size_bytes: u64,
    item_count: u32,
    safe: bool,
    items: Vec<DiskItem>, // up to ~20 individual paths
}

struct ScanProgress {
    current: String, // e.g. "Escaneando node_modules..."
    step: u32,
    total: u32,
}
```

### New event: `scan-progress`

Emitted **before** each category starts being calculated. Payload: `ScanProgress`.

```rust
window.emit("scan-progress", ScanProgress { current: "Escaneando node_modules...".into(), step: 1, total: 22 });
// ... expensive du/find ...
window.emit("scan-category", DiskCategory { ..., items: vec![...] });
```

### Populating `items`

Each category collects up to 20 `DiskItem` entries:

- **node_modules / build_outputs**: each found directory becomes a `DiskItem` (path, size, mtime via `stat -f %m`)
- **path-based categories** (npm_cache, yarn_cache, etc.): single `DiskItem` pointing to the root path
- **lib_caches**: top-level subdirs of `~/Library/Caches` (one level deep, sorted by size desc, capped at 20)
- **large_files**: already individual files — each becomes a `DiskItem`

`modified_at` is populated via:
```bash
stat -f %m "<path>" 2>/dev/null
```

---

## Frontend Changes

### shadcn/ui Installation

Install shadcn/ui configured for Tailwind v4. Map project CSS vars to shadcn tokens in `index.css`:

```css
:root {
  --background: var(--color-bg);
  --card: var(--color-surface);
  --border: var(--color-border);
  --foreground: var(--color-text);
  --muted-foreground: var(--color-text-2);
  /* etc. */
}
```

Add `lib/utils.ts` with `cn()` helper.

### Components installed from shadcn

- `Accordion`
- `Checkbox`
- `Progress`
- `Badge`
- `Button`
- `ScrollArea`
- `Separator`

### Layout

```
┌─ Toolbar ─────────────────────────────────────────────────┐
│  [⟳ Scan System]   Escaneando ~/.cargo...  ████░░░ 14/22  │
├─ Group filter pills ──────────────────────────────────────┤
│  [All] [Development] [Package Caches] [macOS] [AI Tools]  │
├─ ScrollArea ──────────────────────────────────────────────┤
│  Accordion (group headers)                                │
│    ▾ Development                          ☐ select all   │
│      Accordion (categories)                               │
│        ▸ ☐ 📦 node_modules  312  4.2GB  [safe]           │
│            ├ ~/dev/proj-a/node_modules  3.1GB  2d ago    │
│            └ ~/dev/proj-b/node_modules  1.1GB  5d ago    │
│        ▸ ☐ 🏗 Build outputs  87  1.8GB  [safe]           │
├─ Action Bar (sticky) ─────────────────────────────────────┤
│  [Select safe] [Clear]   3 itens · 6.2 GB  [🗑 Clean]    │
└───────────────────────────────────────────────────────────┘
```

### Component tree

```
DiskCleanerTab
├── ScanToolbar          (Progress, Button, scan label)
├── GroupFilterPills     (pill buttons, one per group + "All")
├── ScrollArea
│   └── CategoryAccordion  (Accordion root, one item per group)
│       └── CategoryGroupItem  (Accordion.Item per group)
│           ├── GroupHeader  (Checkbox for whole group, group name, group total)
│           └── CategoryItem  (Accordion.Item per category)
│               ├── CategoryRow  (Checkbox, icon, label, count, size, Badge)
│               └── ItemList  (expanded: list of DiskItem rows)
│                   └── DiskItemRow  (Checkbox, path, size, relative date)
└── ActionBar            (Select safe, Clear, total, Clean button)
```

### Selection state

```ts
type Selection = Map<string, Set<string> | 'all'>
// key: category id
// value: 'all' (whole category selected) | Set<string> (individual item paths)
```

- Category checkbox: toggles between `undefined` (none) and `'all'`
- Item checkbox: adds/removes path from the Set; if all items checked → promotes to `'all'`
- Group checkbox: sets all categories in group to `'all'` or clears them
- shadcn `Checkbox` receives `checked={true | false | 'indeterminate'}`:
  - `true` when `'all'`
  - `'indeterminate'` when Set is non-empty but not all items
  - `false` when absent

### Progress bar

```ts
interface ScanProgress {
  current: string;
  step: number;
  total: number;
}
```

`Progress` value = `(step / total) * 100`. Label shows `current`. Resets to 0 when scan starts, stays at 100 briefly after `scan-done`.

### Clean behavior

- Clean operates per **category id** (unchanged from today)
- Granular item selection is for awareness/display only — cleaning always removes the full category
- Exception: large files section allows individual file deletion by path

### Relative dates

Display `modified_at` as human-relative string: "2h ago", "3d ago", "2w ago". Implemented with a small inline `formatRelative(ts: number): string` utility — no date library needed.

---

## File changes summary

| File | Change |
|------|--------|
| `src-tauri/src/main.rs` | Add `DiskItem`, `ScanProgress` structs; populate `items[]` per category; emit `scan-progress` events |
| `packages/gui-engine/src/index.ts` | Update `DiskCategory` type, add `DiskItem`, `ScanProgress`; listen to `scan-progress` event in `scanDisk()` |
| `apps/gui/src/index.css` | Add shadcn CSS token mappings |
| `apps/gui/src/lib/utils.ts` | Add `cn()` helper |
| `apps/gui/src/components/ui/` | shadcn generated components |
| `apps/gui/src/components/DiskCleanerTab.tsx` | Full rewrite using shadcn components and new design |

---

## Out of scope

- Persisting selection between sessions
- Undo after clean
- Scheduling automatic cleans
