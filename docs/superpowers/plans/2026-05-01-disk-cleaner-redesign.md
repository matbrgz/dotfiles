# Disk Cleaner Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Disk Cleaner tab with real-time scan progress, per-category detail expansion (paths, mtime, item count), granular selection, and shadcn/ui components throughout.

**Architecture:** Rust backend gains `DiskItem` sub-items and `ScanProgress` events emitted before each of 26 categories. TypeScript gui-engine forwards these to the frontend. `DiskCleanerTab` is rewritten using shadcn Accordion, Checkbox, Progress, Badge, Button, ScrollArea.

**Tech Stack:** Rust/Tauri, React 18, TypeScript, shadcn/ui, Tailwind CSS v4, lucide-react

---

## File Map

| File | Action |
|------|--------|
| `apps/gui/vite.config.ts` | Add `@/` path alias |
| `apps/gui/tsconfig.json` | Add `paths` for `@/*` |
| `apps/gui/components.json` | Create (shadcn config) |
| `apps/gui/src/index.css` | Add shadcn CSS var mappings |
| `apps/gui/src/lib/utils.ts` | Create — `cn()` helper |
| `apps/gui/src/components/ui/` | Create — shadcn generated components |
| `apps/gui/src/components/DiskCleanerTab.tsx` | Full rewrite |
| `packages/gui-engine/src/index.ts` | Add `DiskItem`, `ScanProgress`; update `scanDisk` |
| `apps/gui/src-tauri/src/main.rs` | Add structs, helpers, rewrite `scan_disk_usage` |

---

## Task 1: Setup shadcn/ui

**Files:**
- Modify: `apps/gui/vite.config.ts`
- Modify: `apps/gui/tsconfig.json`
- Create: `apps/gui/components.json`
- Modify: `apps/gui/src/index.css`
- Create: `apps/gui/src/lib/utils.ts`
- Create: `apps/gui/src/components/ui/` (via CLI)

- [ ] **Step 1.1 — Add `@/` alias to vite.config.ts**

Replace the entire file `apps/gui/vite.config.ts` with:

```ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
  server: {
    port: 1420,
    strictPort: true,
  },
  envPrefix: ['VITE_', 'TAURI_'],
  build: {
    target: process.env.TAURI_PLATFORM == 'windows' ? 'chrome105' : 'safari13',
    minify: !process.env.TAURI_DEBUG ? 'esbuild' : false,
    sourcemap: !!process.env.TAURI_DEBUG,
  },
})
```

- [ ] **Step 1.2 — Add path alias to tsconfig.json**

Replace `apps/gui/tsconfig.json` with:

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "jsx": "react-jsx",
    "rootDir": ".",
    "outDir": "dist",
    "baseUrl": ".",
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["src/**/*", "vite.config.ts"]
}
```

- [ ] **Step 1.3 — Create components.json**

Create `apps/gui/components.json`:

```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/index.css",
    "baseColor": "neutral",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "iconLibrary": "lucide"
}
```

- [ ] **Step 1.4 — Add shadcn CSS vars to index.css**

Append to `apps/gui/src/index.css` (after the existing content):

```css
/* shadcn/ui token mappings — dark theme matching the project design system */
:root {
  --background: #0d0d0f;
  --foreground: #e2e2e6;
  --card: #141417;
  --card-foreground: #e2e2e6;
  --popover: #141417;
  --popover-foreground: #e2e2e6;
  --primary: #34d399;
  --primary-foreground: #000000;
  --secondary: #1a1a1e;
  --secondary-foreground: #e2e2e6;
  --muted: #1a1a1e;
  --muted-foreground: #909098;
  --accent: #252528;
  --accent-foreground: #e2e2e6;
  --destructive: #fb7185;
  --destructive-foreground: #000000;
  --border: #252528;
  --input: #252528;
  --ring: #34d399;
  --radius: 0.375rem;
}
```

Also add to `@theme` block the Tailwind v4 color mappings so that `bg-background`, `text-foreground`, etc. work. Insert these lines **inside** the existing `@theme { ... }` block:

```css
  --color-background: #0d0d0f;
  --color-foreground: #e2e2e6;
  --color-card: #141417;
  --color-card-foreground: #e2e2e6;
  --color-popover: #141417;
  --color-popover-foreground: #e2e2e6;
  --color-primary: #34d399;
  --color-primary-foreground: #000000;
  --color-secondary: #1a1a1e;
  --color-secondary-foreground: #e2e2e6;
  --color-muted: #1a1a1e;
  --color-muted-foreground: #909098;
  --color-accent: #252528;
  --color-accent-foreground: #e2e2e6;
  --color-destructive: #fb7185;
  --color-destructive-foreground: #000000;
  --color-input: #252528;
  --color-ring: #34d399;
```

- [ ] **Step 1.5 — Create lib/utils.ts**

Create `apps/gui/src/lib/utils.ts`:

```ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

- [ ] **Step 1.6 — Install shadcn components**

Run from `apps/gui`:

```bash
cd apps/gui
npx shadcn@latest add accordion checkbox progress badge button scroll-area separator --yes
```

Expected: creates `src/components/ui/accordion.tsx`, `checkbox.tsx`, `progress.tsx`, `badge.tsx`, `button.tsx`, `scroll-area.tsx`, `separator.tsx`.

- [ ] **Step 1.7 — Verify Vite resolves `@/`**

Run from `apps/gui`:

```bash
cd apps/gui && yarn dev:web 2>&1 | head -10
```

Expected: Vite starts without "Cannot find module '@/...'" errors. Ctrl+C after confirming.

- [ ] **Step 1.8 — Commit**

```bash
git add apps/gui/vite.config.ts apps/gui/tsconfig.json apps/gui/components.json apps/gui/src/index.css apps/gui/src/lib/utils.ts apps/gui/src/components/ui/
git commit -m "feat: install and configure shadcn/ui"
```

---

## Task 2: Update Rust backend

**Files:**
- Modify: `apps/gui/src-tauri/src/main.rs`

- [ ] **Step 2.1 — Replace struct definitions**

In `main.rs`, replace the existing `DiskCategory` struct definition (lines ~24–32) with:

```rust
#[derive(Serialize, Clone)]
struct DiskItem {
    path: String,
    size_bytes: u64,
    modified_at: Option<u64>,
}

#[derive(Serialize, Clone)]
struct DiskCategory {
    id: String,
    label: String,
    icon: String,
    group: String,
    size_bytes: u64,
    item_count: u32,
    safe: bool,
    items: Vec<DiskItem>,
}

#[derive(Serialize, Clone)]
struct ScanProgress {
    current: String,
    step: u32,
    total: u32,
}
```

- [ ] **Step 2.2 — Add helper functions after `expand()`**

Add these two functions right after the `expand()` function (around line 109):

```rust
fn file_mtime(path: &str) -> Option<u64> {
    sh(&format!("stat -f %m \"{}\" 2>/dev/null", path))
        .trim()
        .parse::<u64>()
        .ok()
}

fn paths_size_items(paths: &[&str]) -> (u64, u32, Vec<DiskItem>) {
    let existing: Vec<&str> = paths.iter().copied()
        .filter(|p| std::path::Path::new(p).exists())
        .collect();
    if existing.is_empty() { return (0, 0, vec![]); }
    let quoted = existing.iter()
        .map(|p| format!("\"{}\"", p))
        .collect::<Vec<_>>()
        .join(" ");
    let raw = sh(&format!("nice -n 10 du -sk {} 2>/dev/null", quoted));
    let mut total_kb: u64 = 0;
    let mut items: Vec<DiskItem> = raw.lines().filter(|l| !l.is_empty()).filter_map(|line| {
        let mut parts = line.splitn(2, '\t');
        let kb = parts.next().and_then(|s| s.trim().parse::<u64>().ok()).unwrap_or(0);
        let path = parts.next()?.trim().to_string();
        if path.is_empty() { return None; }
        total_kb += kb;
        Some(DiskItem { path: path.clone(), size_bytes: kb * 1024, modified_at: file_mtime(&path) })
    }).collect();
    let count = items.len() as u32;
    (total_kb * 1024, count, items)
}
```

- [ ] **Step 2.3 — Replace scan_disk_usage body**

Replace the entire body of `fn scan_disk_usage(window: tauri::Window)` (everything inside the `std::thread::spawn(move || { ... })`) with the following. The function signature stays the same:

```rust
#[tauri::command]
fn scan_disk_usage(window: tauri::Window) {
    std::thread::spawn(move || {
        let home = std::env::var("HOME").unwrap_or_else(|_| "/tmp".to_string());
        let h = |p: &str| expand(p, &home);
        let mut step: u32 = 0;
        let total: u32 = 26;

        macro_rules! progress {
            ($label:expr) => { step += 1; let _ = window.emit("scan-progress", ScanProgress { current: format!("Scanning {}...", $label), step, total }); };
        }

        // ── Development ──────────────────────────────────────────────────────

        progress!("node_modules");
        {
            let (size_bytes, item_count, mut items) = if let Some(dev) = dev_dir(&home) {
                let dirs_raw = sh(&format!("find {} -maxdepth 6 -name node_modules -type d -prune 2>/dev/null", dev));
                let dirs: Vec<&str> = dirs_raw.lines().filter(|l| !l.is_empty()).collect();
                if dirs.is_empty() { (0, 0, vec![]) } else {
                    let quoted = dirs.iter().map(|p| format!("\"{}\"", p)).collect::<Vec<_>>().join(" ");
                    let raw = sh(&format!("nice -n 10 du -sk {} 2>/dev/null", quoted));
                    let mut total_kb: u64 = 0;
                    let mut items: Vec<DiskItem> = raw.lines().filter(|l| !l.is_empty()).filter_map(|line| {
                        let mut parts = line.splitn(2, '\t');
                        let kb = parts.next().and_then(|s| s.trim().parse::<u64>().ok()).unwrap_or(0);
                        let path = parts.next()?.trim().to_string();
                        if path.is_empty() { return None; }
                        total_kb += kb;
                        Some(DiskItem { path: path.clone(), size_bytes: kb * 1024, modified_at: file_mtime(&path) })
                    }).collect();
                    items.sort_by(|a, b| b.size_bytes.cmp(&a.size_bytes));
                    (total_kb * 1024, dirs.len() as u32, items)
                }
            } else { (0, 0, vec![]) };
            items.truncate(20);
            let _ = window.emit("scan-category", DiskCategory { id: "node_modules".into(), label: "node_modules".into(), icon: "📦".into(), group: "Development".into(), size_bytes, item_count, safe: true, items });
        }

        progress!("build outputs");
        {
            let (size_bytes, item_count, mut items) = if let Some(dev) = dev_dir(&home) {
                let dirs_raw = sh(&format!("find {} -maxdepth 5 -type d \\( -name dist -o -name build -o -name .next -o -name .turbo -o -name .cache -o -name out -o -name .nuxt -o -name .svelte-kit \\) -prune 2>/dev/null", dev));
                let dirs: Vec<&str> = dirs_raw.lines().filter(|l| !l.is_empty()).collect();
                if dirs.is_empty() { (0, 0, vec![]) } else {
                    let quoted = dirs.iter().map(|p| format!("\"{}\"", p)).collect::<Vec<_>>().join(" ");
                    let raw = sh(&format!("nice -n 10 du -sk {} 2>/dev/null", quoted));
                    let mut total_kb: u64 = 0;
                    let mut items: Vec<DiskItem> = raw.lines().filter(|l| !l.is_empty()).filter_map(|line| {
                        let mut parts = line.splitn(2, '\t');
                        let kb = parts.next().and_then(|s| s.trim().parse::<u64>().ok()).unwrap_or(0);
                        let path = parts.next()?.trim().to_string();
                        if path.is_empty() { return None; }
                        total_kb += kb;
                        Some(DiskItem { path: path.clone(), size_bytes: kb * 1024, modified_at: file_mtime(&path) })
                    }).collect();
                    items.sort_by(|a, b| b.size_bytes.cmp(&a.size_bytes));
                    (total_kb * 1024, dirs.len() as u32, items)
                }
            } else { (0, 0, vec![]) };
            items.truncate(20);
            let _ = window.emit("scan-category", DiskCategory { id: "build_outputs".into(), label: "Build outputs".into(), icon: "🏗".into(), group: "Development".into(), size_bytes, item_count, safe: true, items });
        }

        progress!(".DS_Store files");
        {
            let (size_bytes, item_count, items) = if let Some(dev) = dev_dir(&home) {
                let files_raw = sh(&format!("find {} -name .DS_Store 2>/dev/null", dev));
                let files: Vec<&str> = files_raw.lines().filter(|l| !l.is_empty()).collect();
                let count = files.len() as u32;
                let items: Vec<DiskItem> = files.iter().take(20).map(|f| DiskItem { path: f.to_string(), size_bytes: 6144, modified_at: file_mtime(f) }).collect();
                (count as u64 * 6144, count, items)
            } else { (0, 0, vec![]) };
            let _ = window.emit("scan-category", DiskCategory { id: "ds_store".into(), label: ".DS_Store files".into(), icon: "🫧".into(), group: "Development".into(), size_bytes, item_count, safe: true, items });
        }

        // ── Package Caches ───────────────────────────────────────────────────

        progress!("npm cache");
        { let p = h("~/.npm/_cacache"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "npm_cache".into(), label: "npm cache".into(), icon: "📦".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Yarn cache");
        { let p = h("~/Library/Caches/Yarn"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "yarn_cache".into(), label: "Yarn cache".into(), icon: "🧶".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        progress!("pnpm store");
        { let p = h("~/Library/pnpm/store"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "pnpm_store".into(), label: "pnpm store".into(), icon: "⚡".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        progress!("pip cache");
        {
            let pip_dir = sh("python3 -m pip cache dir 2>/dev/null").trim().to_string();
            let (size_bytes, item_count, items) = if pip_dir.is_empty() || !std::path::Path::new(&pip_dir).exists() { (0, 0, vec![]) } else { paths_size_items(&[&pip_dir]) };
            let _ = window.emit("scan-category", DiskCategory { id: "pip_cache".into(), label: "pip cache".into(), icon: "🐍".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items });
        }

        progress!("Cargo cache");
        { let p1 = h("~/.cargo/registry/cache"); let p2 = h("~/.cargo/git/db"); let (size_bytes, item_count, items) = paths_size_items(&[&p1, &p2]); let _ = window.emit("scan-category", DiskCategory { id: "cargo_cache".into(), label: "Cargo cache".into(), icon: "🦀".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Gradle cache");
        { let p = h("~/.gradle/caches"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "gradle_cache".into(), label: "Gradle cache".into(), icon: "🐘".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Maven cache");
        { let p = h("~/.m2/repository"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "maven_cache".into(), label: "Maven cache".into(), icon: "☕".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Go cache");
        {
            let go_dir = sh("go env GOCACHE 2>/dev/null").trim().to_string();
            let (size_bytes, item_count, items) = if go_dir.is_empty() || !std::path::Path::new(&go_dir).exists() { (0, 0, vec![]) } else { paths_size_items(&[&go_dir]) };
            let _ = window.emit("scan-category", DiskCategory { id: "go_cache".into(), label: "Go cache".into(), icon: "🐹".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items });
        }

        progress!("Ruby gems");
        { let p = h("~/.gem"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "gem_cache".into(), label: "Ruby gems".into(), icon: "💎".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        // ── macOS ─────────────────────────────────────────────────────────────

        progress!("Homebrew cache");
        {
            let brew_cache = sh("brew --cache 2>/dev/null").trim().to_string();
            let (size_bytes, item_count, items) = if brew_cache.is_empty() || !std::path::Path::new(&brew_cache).exists() { (0, 0, vec![]) } else { paths_size_items(&[&brew_cache]) };
            let _ = window.emit("scan-category", DiskCategory { id: "brew_cache".into(), label: "Homebrew cache".into(), icon: "🍺".into(), group: "macOS".into(), size_bytes, item_count, safe: true, items });
        }

        progress!("Homebrew logs");
        { let p = h("~/Library/Logs/Homebrew"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "brew_logs".into(), label: "Homebrew logs".into(), icon: "🍺".into(), group: "macOS".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Xcode DerivedData");
        { let p = h("~/Library/Developer/Xcode/DerivedData"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "xcode_derived".into(), label: "Xcode DerivedData".into(), icon: "🔨".into(), group: "macOS".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Xcode Archives");
        { let p = h("~/Library/Developer/Xcode/Archives"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "xcode_archives".into(), label: "Xcode Archives".into(), icon: "📦".into(), group: "macOS".into(), size_bytes, item_count, safe: false, items }); }

        progress!("iOS Simulators");
        { let p = h("~/Library/Developer/CoreSimulator/Devices"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "ios_sims".into(), label: "iOS Simulators (unavailable)".into(), icon: "📱".into(), group: "macOS".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Library/Caches");
        {
            let p = h("~/Library/Caches");
            let (size_bytes, item_count, _) = paths_size_items(&[&p]);
            let items: Vec<DiskItem> = if std::path::Path::new(&p).exists() {
                let raw = sh(&format!("nice -n 10 du -sk \"{}\"/* 2>/dev/null | sort -rn | head -20", p));
                raw.lines().filter(|l| !l.is_empty()).filter_map(|line| {
                    let mut parts = line.splitn(2, '\t');
                    let kb = parts.next().and_then(|s| s.trim().parse::<u64>().ok()).unwrap_or(0);
                    let path = parts.next()?.trim().to_string();
                    if path.is_empty() { return None; }
                    Some(DiskItem { path: path.clone(), size_bytes: kb * 1024, modified_at: file_mtime(&path) })
                }).collect()
            } else { vec![] };
            let _ = window.emit("scan-category", DiskCategory { id: "lib_caches".into(), label: "~/Library/Caches".into(), icon: "📂".into(), group: "macOS".into(), size_bytes, item_count, safe: false, items });
        }

        progress!("Trash");
        { let p = h("~/.Trash"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "trash".into(), label: "Trash".into(), icon: "🗑".into(), group: "macOS".into(), size_bytes, item_count, safe: false, items }); }

        // ── AI Tools ─────────────────────────────────────────────────────────

        progress!("Claude Code cache");
        { let p1 = h("~/.claude/cache"); let p2 = h("~/.claude/paste-cache"); let p3 = h("~/.claude/shell-snapshots"); let p4 = h("~/.claude/telemetry"); let p5 = h("~/.claude/file-history"); let (size_bytes, item_count, items) = paths_size_items(&[&p1, &p2, &p3, &p4, &p5]); let _ = window.emit("scan-category", DiskCategory { id: "claude_cache".into(), label: "Claude Code cache".into(), icon: "🤖".into(), group: "AI Tools".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Codex cache");
        { let p1 = h("~/.codex/log"); let p2 = h("~/.codex/sessions"); let p3 = h("~/Library/Application Support/Codex"); let (size_bytes, item_count, items) = paths_size_items(&[&p1, &p2, &p3]); let _ = window.emit("scan-category", DiskCategory { id: "codex_cache".into(), label: "Codex cache".into(), icon: "🤖".into(), group: "AI Tools".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Gemini CLI temp");
        { let p = h("~/.gemini/tmp"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "gemini_tmp".into(), label: "Gemini CLI temp".into(), icon: "🤖".into(), group: "AI Tools".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Fly.io logs");
        { let p1 = h("~/.fly/agent-logs"); let p2 = h("~/.fly/logs"); let (size_bytes, item_count, items) = paths_size_items(&[&p1, &p2]); let _ = window.emit("scan-category", DiskCategory { id: "fly_logs".into(), label: "Fly.io logs".into(), icon: "🪰".into(), group: "AI Tools".into(), size_bytes, item_count, safe: true, items }); }

        progress!("npm logs");
        { let p = h("~/.npm/_logs"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "npm_logs".into(), label: "npm logs".into(), icon: "📋".into(), group: "AI Tools".into(), size_bytes, item_count, safe: true, items }); }

        // ── Other ─────────────────────────────────────────────────────────────

        progress!("Downloads folder");
        { let p = h("~/Downloads"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "downloads".into(), label: "Downloads folder".into(), icon: "📥".into(), group: "Other".into(), size_bytes, item_count, safe: false, items }); }

        progress!("zsh sessions");
        { let p = h("~/.zsh_sessions"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "zsh_sessions".into(), label: "zsh sessions".into(), icon: "🐚".into(), group: "Other".into(), size_bytes, item_count, safe: true, items }); }

        let _ = window.emit("scan-done", ());
    });
}
```

- [ ] **Step 2.4 — Verify Rust compiles**

```bash
cd apps/gui/src-tauri && cargo build 2>&1 | tail -20
```

Expected: `Finished dev [unoptimized + debuginfo] target(s)` with no errors. Fix any compile errors before continuing.

- [ ] **Step 2.5 — Commit**

```bash
git add apps/gui/src-tauri/src/main.rs
git commit -m "feat(rust): add DiskItem/ScanProgress, emit scan-progress events, populate items per category"
```

---

## Task 3: Update gui-engine TypeScript types

**Files:**
- Modify: `packages/gui-engine/src/index.ts`

- [ ] **Step 3.1 — Replace types and scanDisk in gui-engine**

In `packages/gui-engine/src/index.ts`, replace the `DiskCategory` interface and `scanDisk` method with the following. Keep all other interfaces and methods unchanged.

Replace:
```ts
export interface DiskCategory {
  id: string;
  label: string;
  icon: string;
  group: string;
  size_bytes: number;
  item_count: number;
  safe: boolean;
}
```

With:
```ts
export interface DiskItem {
  path: string;
  size_bytes: number;
  modified_at: number | null;
}

export interface DiskCategory {
  id: string;
  label: string;
  icon: string;
  group: string;
  size_bytes: number;
  item_count: number;
  safe: boolean;
  items: DiskItem[];
}

export interface ScanProgress {
  current: string;
  step: number;
  total: number;
}
```

Replace the `scanDisk` method in `guiCommands`:
```ts
  scanDisk: async (
    onCategory?: (cat: DiskCategory) => void,
    onProgress?: (prog: ScanProgress) => void,
  ): Promise<void> => {
    return new Promise(async (resolve, reject) => {
      const unlisteners: Array<() => void> = [];

      if (onCategory) {
        const ul = await listen<DiskCategory>('scan-category', (e) => onCategory(e.payload));
        unlisteners.push(ul);
      }
      if (onProgress) {
        const ul = await listen<ScanProgress>('scan-progress', (e) => onProgress(e.payload));
        unlisteners.push(ul);
      }

      const cleanup = () => unlisteners.forEach(fn => fn());

      const doneUl = await listen<null>('scan-done', () => {
        cleanup();
        doneUl();
        resolve();
      });

      invoke('scan_disk_usage').catch((err) => {
        cleanup();
        doneUl();
        reject(err);
      });
    });
  },
```

- [ ] **Step 3.2 — Build gui-engine**

```bash
cd packages/gui-engine && yarn build 2>&1 | tail -10
```

Expected: `dist/index.js` emitted, no TypeScript errors.

- [ ] **Step 3.3 — Commit**

```bash
git add packages/gui-engine/src/index.ts
git commit -m "feat(gui-engine): add DiskItem, ScanProgress types; add onProgress to scanDisk"
```

---

## Task 4: Rewrite DiskCleanerTab

**Files:**
- Modify: `apps/gui/src/components/DiskCleanerTab.tsx`

- [ ] **Step 4.1 — Replace DiskCleanerTab.tsx entirely**

Replace the full content of `apps/gui/src/components/DiskCleanerTab.tsx` with:

```tsx
import React, { useState, useCallback, useMemo } from 'react';
import { guiCommands, type DiskCategory, type ScanProgress } from '@dotfiles/gui-engine';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';
import { Checkbox } from '@/components/ui/checkbox';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Separator } from '@/components/ui/separator';

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
  if (current === 'all') { next.delete(catId); return next; }
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
  const [categories, setCategories] = useState<DiskCategory[]>([]);
  const [selection, setSelection] = useState<Selection>(new Map());
  const [scanning, setScanning] = useState(false);
  const [progress, setProgress] = useState<ScanProgress | null>(null);
  const [cleaning, setCleaning] = useState(false);
  const [cleanLog, setCleanLog] = useState<string[]>([]);
  const [activeGroup, setActiveGroup] = useState<string>(ALL);

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
    finally { setScanning(false); setProgress(null); }
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
```

- [ ] **Step 4.2 — Type-check**

```bash
cd apps/gui && yarn type-check 2>&1
```

Expected: no errors. Common issues and fixes:
- `'indeterminate'` not assignable to Checkbox `checked` → ensure shadcn Checkbox accepts `'indeterminate'` (it does in the default shadcn component)
- Module not found `@/components/ui/...` → confirm shadcn components were installed in Step 1.6

- [ ] **Step 4.3 — Commit**

```bash
git add apps/gui/src/components/DiskCleanerTab.tsx
git commit -m "feat(gui): rewrite DiskCleanerTab with shadcn, progress bar, expandable details, granular selection"
```

---

## Task 5: Build and verify

**Files:** none — verification only

- [ ] **Step 5.1 — Start dev server**

Kill any existing Tauri process, then:

```bash
cd /path/to/dotfiles && bash run-gui.sh
```

Expected: Vite starts on port 1420, Rust compiles, Tauri window opens.

- [ ] **Step 5.2 — Open Disk Cleaner tab and click Scan System**

Verify:
- Progress bar appears in the toolbar
- Label updates ("Scanning node_modules...", "Scanning npm cache...", etc.)
- Step counter increments (e.g. "3/26")
- Categories appear one by one in the list as they complete

- [ ] **Step 5.3 — Verify category details**

Click the chevron on any category (e.g. node_modules):
- Expands to show individual paths
- Each row shows path, relative date ("2d ago"), and size
- Sizes are colour-coded (red > 1 GB, amber > 100 MB)

- [ ] **Step 5.4 — Verify selection**

- Click a category checkbox → row highlights
- Click "Select safe" → all safe categories selected, total shown in action bar
- Click group checkbox → all categories in group selected
- Expand a category and check an individual item → category goes indeterminate
- Check all items in a category → category goes fully checked

- [ ] **Step 5.5 — Verify group pills**

Click "Development" pill → only Development categories visible.
Click "All" → all categories visible.

- [ ] **Step 5.6 — Commit final verification**

If any visual fixes are needed, apply and commit. Then:

```bash
git add -p
git commit -m "fix(gui): post-verification tweaks to disk cleaner"
```
