import type { DiskCategory } from '@dotfiles/gui-engine';

const SCAN_KEY = 'disk-cleaner:scan';
const SEL_KEY  = 'disk-cleaner:selection';
const GRP_KEY  = 'disk-cleaner:group';

export interface CachedScan {
  timestamp: number;
  categories: DiskCategory[];
}

// ── scan ────────────────────────────────────────────────────────────────────

export function saveScan(categories: DiskCategory[]): void {
  try {
    localStorage.setItem(SCAN_KEY, JSON.stringify({ timestamp: Date.now(), categories }));
  } catch { /* quota exceeded — ignore */ }
}

export function loadScan(): CachedScan | null {
  try {
    const raw = localStorage.getItem(SCAN_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as CachedScan;
  } catch { return null; }
}

export function clearScan(): void {
  localStorage.removeItem(SCAN_KEY);
}

// ── selection ────────────────────────────────────────────────────────────────

type RawSel = Record<string, 'all' | string[]>;

export function saveSelection(sel: Map<string, 'all' | Set<string>>): void {
  try {
    const raw: RawSel = {};
    for (const [id, v] of sel) {
      raw[id] = v === 'all' ? 'all' : Array.from(v);
    }
    localStorage.setItem(SEL_KEY, JSON.stringify(raw));
  } catch { /* ignore */ }
}

export function loadSelection(): Map<string, 'all' | Set<string>> {
  try {
    const raw = localStorage.getItem(SEL_KEY);
    if (!raw) return new Map();
    const parsed = JSON.parse(raw) as RawSel;
    const m = new Map<string, 'all' | Set<string>>();
    for (const [id, v] of Object.entries(parsed)) {
      m.set(id, v === 'all' ? 'all' : new Set(v));
    }
    return m;
  } catch { return new Map(); }
}

export function clearSelection(): void {
  localStorage.removeItem(SEL_KEY);
}

// ── active group ─────────────────────────────────────────────────────────────

export function saveGroup(group: string): void {
  try { localStorage.setItem(GRP_KEY, group); } catch { /* ignore */ }
}

export function loadGroup(): string | null {
  try { return localStorage.getItem(GRP_KEY); } catch { return null; }
}
