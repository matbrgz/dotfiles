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
